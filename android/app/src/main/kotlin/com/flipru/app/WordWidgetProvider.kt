package com.flipru.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Ana ekran widget'i: gunun kelimesi.
 *
 * Metinleri Flutter tarafi yaziyor (bkz. `WidgetService`); burada yalnizca
 * okunup goruntuye basiliyor. Dokununca uygulama aciliyor.
 */
class WordWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.word_widget).apply {
                setTextViewText(
                    R.id.widget_russian,
                    widgetData.getString("widget_russian", "приве́т"),
                )
                setTextViewText(
                    R.id.widget_translit,
                    widgetData.getString("widget_translit", "pri-VET"),
                )
                setTextViewText(
                    R.id.widget_turkish,
                    widgetData.getString("widget_turkish", "merhaba, selam"),
                )
                setTextViewText(
                    R.id.widget_level,
                    widgetData.getString("widget_level", "A1"),
                )
                setTextViewText(
                    R.id.widget_streak,
                    widgetData.getString("widget_streak", ""),
                )

                setOnClickPendingIntent(
                    R.id.widget_russian,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
