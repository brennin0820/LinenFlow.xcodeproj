package com.himmerflow.android.data

import android.content.Context

object WidgetStateStore {
    private const val PREFS = "himmerflow_widget"
    private const val LEGACY_PREFS = "linenflow_widget"
    private const val KEY_TOWER = "tower"
    private const val KEY_MODE = "mode"
    private const val KEY_ROWS = "rows"

    fun save(context: Context, tower: Tower, rows: List<WidgetItemRow>) {
        val encodedRows = rows.joinToString("|") { row ->
            listOf(row.itemName, row.label, row.valueText).joinToString("~")
        }

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_TOWER, tower.name)
            .putString(KEY_MODE, if (tower.deliveryMode == DeliveryMode.Bundles) "Bundles per floor" else "Pieces per floor")
            .putString(KEY_ROWS, encodedRows)
            .apply()
    }

    fun load(context: Context): Triple<String, String, List<WidgetItemRow>> {
        val prefs = resolvePrefs(context)
        val rows = prefs.getString(KEY_ROWS, "")
            .orEmpty()
            .split("|")
            .filter { it.isNotBlank() }
            .mapNotNull { encoded ->
                val parts = encoded.split("~")
                if (parts.size != 3) return@mapNotNull null
                WidgetItemRow(parts[0], parts[1], parts[2])
            }

        return Triple(
            prefs.getString(KEY_TOWER, "No Active Tower") ?: "No Active Tower",
            prefs.getString(KEY_MODE, "Open HimmerFlow") ?: "Open HimmerFlow",
            rows
        )
    }

    private fun resolvePrefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).let { prefs ->
            if (prefs.contains(KEY_TOWER) || prefs.contains(KEY_ROWS) || prefs.contains(KEY_MODE)) {
                prefs
            } else {
                context.getSharedPreferences(LEGACY_PREFS, Context.MODE_PRIVATE)
            }
        }
}
