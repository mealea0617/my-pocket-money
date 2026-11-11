package com.pocket.money.pocket_money_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PocketWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pocket_widget_layout)
            val balance = widgetData.getString("balance_text", "300,000원")
            views.setTextViewText(R.id.balance_text, balance)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
