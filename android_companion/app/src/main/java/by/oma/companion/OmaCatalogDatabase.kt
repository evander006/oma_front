package by.oma.companion

import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import java.io.File
import java.util.Locale

/** Read-only paged access to imported catalog. Call exclusively off the UI thread. */
internal class OmaCatalogDatabase(private val directory: File) {
    private val file = File(directory, "catalog.db")

    data class Page(val records: List<Storefront.Item>, val total: Int)

    private fun <T> withDb(action: (SQLiteDatabase) -> T): T {
        require(file.isFile) { "Файл catalog.db не найден" }
        val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
        return try { action(db) } finally { db.close() }
    }

    fun validate(): Int = withDb { db ->
        val names = mutableSetOf<String>()
        db.rawQuery("PRAGMA table_info(products)", null).use { c ->
            while (c.moveToNext()) names.add(c.getString(1))
        }
        val required = setOf("sku", "name", "category_path", "price", "old_price",
            "unit", "image_files", "image_urls", "brand")
        require(names.containsAll(required)) { "В каталоге отсутствуют обязательные поля" }
        db.rawQuery(
            "SELECT COUNT(*) FROM products WHERE sku IS NOT NULL AND name IS NOT NULL " +
                "AND image_urls IS NOT NULL AND image_urls <> '[]'",
            null
        )
            .use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
    }

    private fun row(cursor: Cursor): Storefront.Item {
        val sku = cursor.getString(0).orEmpty()
        val title = cursor.getString(1).orEmpty()
        val category = cursor.getString(2).orEmpty().split(" / ")
        val files = runCatching { JSONArray(cursor.getString(6) ?: "[]") }.getOrDefault(JSONArray())
        val urls = runCatching { JSONArray(cursor.getString(7) ?: "[]") }.getOrDefault(JSONArray())
        val local = files.optString(0, "")
        val possible = if (local.isNotBlank()) File(directory, local) else null
        val image = if (possible != null && possible.isFile &&
            possible.canonicalPath.startsWith(directory.canonicalPath + File.separator)) {
            possible.path
        } else urls.optString(0, "")
        return Storefront.Item(
            sku, title, category.firstOrNull().orEmpty(), category.getOrElse(1) { "" },
            cursor.getString(3)?.toDoubleOrNull(), cursor.getString(4)?.toDoubleOrNull(),
            cursor.getString(5) ?: "шт", image, cursor.getString(8) ?: ""
        )
    }

    private val columns = "sku,name,category_path,price,old_price,unit,image_files,image_urls,brand"

    private fun likeVariants(text: String): List<String> {
        val q = text.trim()
        if (q.isBlank()) return emptyList()
        return listOf(q, q.replaceFirstChar { it.titlecase(Locale("ru", "RU")) },
            q.uppercase(Locale("ru", "RU"))).distinct()
    }

    fun page(
        category: String = "",
        subcategory: String = "",
        search: String = "",
        sorting: String = "",
        limit: Int = 20,
        offset: Int = 0
    ): Page = withDb { db ->
        val filters = mutableListOf(
            "sku IS NOT NULL", "name IS NOT NULL",
            "image_urls IS NOT NULL", "image_urls <> '[]'"
        )
        val args = mutableListOf<String>()
        if (category.isNotBlank()) {
            filters.add("(category_path = ? OR category_path LIKE ?)")
            args.add(category)
            args.add("$category / %")
        }
        if (subcategory.isNotBlank()) {
            filters.add("(category_path = ? OR category_path LIKE ?)")
            args.add("$category / $subcategory")
            args.add("$category / $subcategory / %")
        }
        val variants = likeVariants(search)
        if (variants.isNotEmpty()) {
            val predicates = mutableListOf<String>()
            for (v in variants) {
                predicates.add("(name LIKE ? OR category_path LIKE ? OR brand LIKE ? OR sku LIKE ?)")
                repeat(4) { args.add("%$v%") }
            }
            filters.add("(${predicates.joinToString(" OR ")})")
        }
        val where = filters.joinToString(" AND ")
        val total = db.rawQuery("SELECT COUNT(*) FROM products WHERE $where", args.toTypedArray())
            .use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
        val order = when (sorting) {
            "Цена ↑" -> "price IS NULL, CAST(price AS REAL) ASC"
            "Цена ↓" -> "price IS NULL, CAST(price AS REAL) DESC"
            else -> "rowid ASC"
        }
        val items = ArrayList<Storefront.Item>(limit.coerceIn(1, 100))
        db.rawQuery(
            "SELECT $columns FROM products WHERE $where ORDER BY $order LIMIT ? OFFSET ?",
            (args + listOf(limit.coerceIn(1, 100).toString(), offset.coerceAtLeast(0).toString())).toTypedArray()
        ).use { c -> while (c.moveToNext()) items.add(row(c)) }
        Page(items, total)
    }

    fun categories(): Map<String, List<String>> = withDb { db ->
        val categories = linkedMapOf<String, LinkedHashSet<String>>()
        db.rawQuery(
            "SELECT DISTINCT category_path FROM products WHERE category_path IS NOT NULL " +
                "AND image_urls IS NOT NULL AND image_urls <> '[]'",
            null
        )
            .use { c ->
                while (c.moveToNext()) {
                    val parts = c.getString(0).orEmpty().split(" / ")
                    val top = parts.firstOrNull().orEmpty()
                    if (top.isNotBlank()) {
                        val subcats = categories.getOrPut(top) { linkedSetOf() }
                        if (parts.size > 1 && parts[1].isNotBlank()) subcats.add(parts[1])
                    }
                }
            }
        categories.mapValues { it.value.toList() }
    }

    /** Resolve ordered backend image-search results against real embedded OMA SKUs.
     * A single SQL query avoids blocking on one database open for each result.
     */
    fun bySkus(skus: List<String>): List<Storefront.Item> = withDb { db ->
        val requested = skus.map { it.trim() }.filter { it.isNotEmpty() }.distinct().take(100)
        if (requested.isEmpty()) return@withDb emptyList()
        val placeholders = List(requested.size) { "?" }.joinToString(",")
        val resolved = HashMap<String, Storefront.Item>()
        db.rawQuery(
            "SELECT $columns FROM products WHERE sku IN ($placeholders) " +
                "AND image_urls IS NOT NULL AND image_urls <> '[]'",
            requested.toTypedArray()
        ).use { c ->
            while (c.moveToNext()) {
                val item = row(c)
                resolved[item.id] = item
            }
        }
        requested.mapNotNull(resolved::get)
    }

    fun bySku(sku: String): Storefront.Item? = withDb { db ->
        db.rawQuery(
            "SELECT $columns FROM products WHERE sku = ? " +
                "AND image_urls IS NOT NULL AND image_urls <> '[]' LIMIT 1",
            arrayOf(sku)
        )
            .use { c -> if (c.moveToFirst()) row(c) else null }
    }
}
