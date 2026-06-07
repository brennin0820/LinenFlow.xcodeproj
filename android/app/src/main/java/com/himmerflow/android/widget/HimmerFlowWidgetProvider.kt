package com.himmerflow.android.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.himmerflow.android.MainActivity
import com.himmerflow.android.R
import com.himmerflow.android.data.WidgetStateStore

class HimmerFlowWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(appWidgetId, buildViews(context))
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, HimmerFlowWidgetProvider::class.java))
            ids.forEach { id -> manager.updateAppWidget(id, buildViews(context)) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val (towerName, mode, rows) = WidgetStateStore.load(context)
            val content = if (rows.isEmpty()) {
                "Open app and select widget items"
            } else {
                rows.take(3).joinToString("\n") { "${it.itemName}: ${it.valueText}" }
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            return RemoteViews(context.packageName, R.layout.himmerflow_widget).apply {
                setTextViewText(R.id.widgetTitle, "$towerName Tower")
                setTextViewText(R.id.widgetSubtitle, mode)
                setTextViewText(R.id.widgetItems, content)
                setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            }
        }
    }
}
