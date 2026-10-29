#!/usr/bin/env python3
"""Build the compact Android catalog asset from the supplied OMA XLSX/ZIP."""

from __future__ import annotations

import argparse
import gzip
import json
import sqlite3
import tempfile
import zipfile
from pathlib import Path

import openpyxl


def workbook_path(source: Path, temporary: Path) -> Path:
    if source.suffix.lower() == ".xlsx":
        return source
    if source.suffix.lower() != ".zip":
        raise ValueError("Source must be an XLSX file or a ZIP containing one XLSX file")
    with zipfile.ZipFile(source) as archive:
        names = [name for name in archive.namelist() if name.lower().endswith(".xlsx")]
        if len(names) != 1:
            raise ValueError(f"Expected one XLSX in ZIP, found {len(names)}")
        target = temporary / Path(names[0]).name
        with archive.open(names[0]) as incoming, target.open("wb") as outgoing:
            while chunk := incoming.read(1024 * 1024):
                outgoing.write(chunk)
        return target


def as_url_list(primary: object, all_images: object) -> list[str]:
    values: list[str] = []
    for source in (primary, all_images):
        if source is None:
            continue
        for value in str(source).replace("\r", "\n").split("\n"):
            url = value.strip()
            if url.startswith(("https://", "http://")) and url not in values:
                values.append(url)
    return values


def build(source: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="oma_catalog_") as temp_name:
        temporary = Path(temp_name)
        xlsx = workbook_path(source, temporary)
        workbook = openpyxl.load_workbook(xlsx, read_only=True, data_only=True)
        sheet = workbook.active
        rows = sheet.iter_rows(values_only=True)
        headers = [str(value).strip() if value is not None else "" for value in next(rows)]
        columns = {name: index for index, name in enumerate(headers)}
        required = {"Артикул", "Название", "Категория", "Фото", "Все фото"}
        missing = required - columns.keys()
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")

        database = temporary / "catalog.db"
        connection = sqlite3.connect(database)
        connection.executescript(
            """
            PRAGMA journal_mode=OFF;
            PRAGMA synchronous=OFF;
            PRAGMA temp_store=MEMORY;
            CREATE TABLE products (
                sku TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                category_path TEXT NOT NULL,
                price TEXT,
                old_price TEXT,
                unit TEXT NOT NULL,
                image_files TEXT NOT NULL,
                image_urls TEXT NOT NULL,
                brand TEXT NOT NULL
            );
            """
        )

        def value(row: tuple[object, ...], name: str) -> object:
            index = columns.get(name)
            return row[index] if index is not None and index < len(row) else None

        inserted = 0
        skipped_no_image = 0
        batch: list[tuple[object, ...]] = []
        statement = "INSERT OR REPLACE INTO products VALUES (?,?,?,?,?,?,?,?,?)"
        for row in rows:
            sku = str(value(row, "Артикул") or value(row, "ID товара") or "").strip()
            name = str(value(row, "Название") or "").strip()
            category = str(value(row, "Категория") or "").strip()
            urls = as_url_list(value(row, "Фото"), value(row, "Все фото"))
            if not sku or not name or not category:
                continue
            if not urls:
                skipped_no_image += 1
                continue
            unit = str(value(row, "Упаковка: Единицы измерения") or "шт").strip() or "шт"
            batch.append(
                (
                    sku,
                    name,
                    category,
                    value(row, "Цена"),
                    value(row, "Старая цена"),
                    unit,
                    "[]",
                    json.dumps(urls, ensure_ascii=False, separators=(",", ":")),
                    str(value(row, "Бренд") or "").strip(),
                )
            )
            if len(batch) >= 1000:
                connection.executemany(statement, batch)
                inserted += len(batch)
                batch.clear()
        if batch:
            connection.executemany(statement, batch)
            inserted += len(batch)

        connection.executescript(
            """
            CREATE INDEX products_category ON products(category_path);
            CREATE INDEX products_name ON products(name);
            CREATE INDEX products_brand ON products(brand);
            ANALYZE;
            VACUUM;
            """
        )
        unique_products = connection.execute("SELECT COUNT(*) FROM products").fetchone()[0]
        connection.close()
        workbook.close()

        with database.open("rb") as incoming, gzip.open(output, "wb", compresslevel=9) as outgoing:
            while chunk := incoming.read(1024 * 1024):
                outgoing.write(chunk)
        print(
            json.dumps(
                {
                    "inserted": unique_products,
                    "processed_rows": inserted,
                    "replaced_duplicate_skus": inserted - unique_products,
                    "skipped_without_image": skipped_no_image,
                    "database_bytes": database.stat().st_size,
                    "asset_bytes": output.stat().st_size,
                    "output": str(output),
                },
                ensure_ascii=False,
            )
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    build(args.source.resolve(), args.output.resolve())


if __name__ == "__main__":
    main()
