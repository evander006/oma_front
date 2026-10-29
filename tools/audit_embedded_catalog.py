#!/usr/bin/env python3
"""Validate real OMA product coverage of the bundled Android SQLite database."""
from __future__ import annotations

import argparse
import gzip
import json
from collections import Counter
from pathlib import Path
import shutil
import sqlite3
from tempfile import TemporaryDirectory
from urllib.parse import urlparse


def audit(source: Path) -> dict:
    with TemporaryDirectory(prefix="oma_catalog_audit_") as temp:
        unpacked = Path(temp) / "catalog.db"
        if source.suffix.lower() in {".gz", ".bin"}:
            with gzip.open(source, "rb") as src, unpacked.open("wb") as target:
                shutil.copyfileobj(src, target, 1024 * 1024)
        else:
            shutil.copyfile(source, unpacked)

        database = sqlite3.connect(f"file:{unpacked}?mode=ro", uri=True)
        try:
            integrity = database.execute("PRAGMA quick_check").fetchone()[0]
            if integrity != "ok":
                raise ValueError(f"SQLite integrity failed: {integrity}")
            totals = Counter()
            categories = Counter()
            seen_skus = set()
            for sku, title, path, urls, price in database.execute(
                "SELECT sku,name,category_path,image_urls,price FROM products"
            ):
                totals["total"] += 1
                if not sku or not str(sku).strip() or sku in seen_skus:
                    totals["invalid_sku"] += 1
                seen_skus.add(sku)
                if not title or not str(title).strip():
                    totals["missing_title"] += 1
                if not path or not str(path).strip():
                    totals["missing_category"] += 1
                else:
                    categories[str(path).split(" / ")[0]] += 1
                try:
                    decoded = json.loads(urls)
                    valid = isinstance(decoded, list) and any(
                        isinstance(value, str)
                        and urlparse(value).scheme in {"http", "https"}
                        and bool(urlparse(value).netloc)
                        for value in decoded
                    )
                except (TypeError, ValueError):
                    valid = False
                if valid:
                    totals["image_urls_present"] += 1
                else:
                    totals["image_urls_missing_or_invalid"] += 1
                if price is None or str(price).strip() == "":
                    totals["missing_price"] += 1
            return {
                **totals, "integrity": integrity,
                "distinct_skus": len(seen_skus),
                "categories": dict(categories.most_common()),
                "image_urls_checked_for_syntax_not_live_availability": True,
            }
        finally:
            database.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--json", type=Path, default=None)
    parser.add_argument("--minimum-skus", type=int, default=120000)
    args = parser.parse_args()
    report = audit(args.source)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if report["total"] < args.minimum_skus:
        parser.exit(1, "Expected the complete OMA catalogue, not a demo subset\n")
    if any(report.get(key, 0) for key in (
        "invalid_sku", "missing_title", "missing_category",
        "image_urls_missing_or_invalid"
    )):
        parser.exit(1, "Catalog metadata quality gate failed\n")


if __name__ == "__main__":
    main()
