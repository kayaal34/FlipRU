package com.flipru.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Ana ekran widget'i: gunun kelimesi.
 *
 * Flutter tarafi (bkz. `WidgetService`) onumuzdeki donemlerin kelimelerini
 * `widget_schedule` altina pesinen yaziyor. Android widget'i en fazla yarim
 * saatte bir yeniliyor (`updatePeriodMillis`); her yenilemede o anki donemi
 * hesaplayip sirasi gelen kelimeyi burada seciyoruz. Boylece uygulama
 * gunlerce acilmasa da kelime degismeye devam ediyor.
 *
 * Seri de burada denetleniyor: son calisma gunu bugun ya da dun degilse
 * seri kopmustur ve alev gosterilmiyor.
 */
class WordWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val word = currentWord(widgetData)
        val streak = streakLabel(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.word_widget).apply {
                setTextViewText(R.id.widget_russian, word.ru)
                setTextViewText(R.id.widget_translit, word.translit)
                setTextViewText(R.id.widget_turkish, word.tr)
                setTextViewText(R.id.widget_level, word.level)
                setTextViewText(R.id.widget_streak, streak)

                // Widget'in herhangi bir yerine dokunmak uygulamayi acsin.
                val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, open)
                setOnClickPendingIntent(R.id.widget_russian, open)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private data class Entry(val ru: String, val translit: String, val tr: String, val level: String)

    /** Dart'taki `WidgetService.windowSeed` ile ayni hesap. */
    private fun currentWord(prefs: SharedPreferences): Entry {
        val fallback = Entry(
            prefs.getString("widget_russian", null) ?: "приве́т",
            prefs.getString("widget_translit", null) ?: "pri-VET",
            prefs.getString("widget_turkish", null) ?: "merhaba",
            prefs.getString("widget_level", null) ?: "A1",
        )
        return try {
            val hours = prefs.getString("widget_refresh_hours", null)?.toLongOrNull() ?: 24L
            val window = System.currentTimeMillis() / (hours * 3600L * 1000L)
            val list = JSONArray(prefs.getString("widget_schedule", null) ?: return fallback)
            for (i in 0 until list.length()) {
                val item = list.getJSONObject(i)
                if (item.getLong("w") == window) {
                    return Entry(
                        item.getString("ru"),
                        item.getString("tl"),
                        item.getString("tr"),
                        item.getString("lv"),
                    )
                }
            }
            // Takvim bitti (uygulama aylarca acilmadi): en azindan donmeye
            // devam etsin diye takvimi basa sararak kullan.
            if (list.length() > 0) {
                val item = list.getJSONObject((window % list.length()).toInt())
                Entry(item.getString("ru"), item.getString("tl"), item.getString("tr"), item.getString("lv"))
            } else {
                fallback
            }
        } catch (e: Exception) {
            fallback
        }
    }

    private fun streakLabel(prefs: SharedPreferences): String {
        val count = prefs.getString("widget_streak_count", null)?.toIntOrNull() ?: 0
        val last = prefs.getString("widget_last_study_day", null) ?: ""
        if (count <= 0 || last.isEmpty()) return ""

        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val today = Calendar.getInstance()
        val yesterday = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -1) }
        return when (last) {
            // Bugun calisildiysa seri tam; dun calisildiysa bugun hala
            // kurtarilabilir, sayi ayni kaliyor.
            fmt.format(today.time), fmt.format(yesterday.time) -> "🔥 $count"
            else -> ""
        }
    }
}
