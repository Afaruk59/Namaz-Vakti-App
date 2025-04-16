/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package com.afaruk59.namaz_vakti_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.StringReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import android.os.AsyncTask
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import android.os.Bundle
import java.util.concurrent.Executors

class PrayerTimesWidget : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val BASE_URL = "https://www.namazvakti.com/XML.php?cityID="
        private const val ACTION_REFRESH = "com.afaruk59.namaz_vakti_app.ACTION_REFRESH"
        private var backgroundThread: Thread? = null
        private val executor = Executors.newSingleThreadExecutor()
        private val handler = Handler(Looper.getMainLooper())
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_DELAY_MS = 2000L
        private const val CACHED_TIMES_KEY = "cached_prayer_times"
        private const val CACHED_CITY_KEY = "cached_city_name"
        private const val CACHED_DATE_KEY = "cached_update_date"

        private fun getFormattedDateTime(context: Context): String {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val now = Date()
            return context.getString(R.string.last_update, timeFormat.format(now))
        }

        private fun applyTheme(context: Context, views: RemoteViews) {
            val nightModeFlags = context.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK
            val isDarkTheme = nightModeFlags == Configuration.UI_MODE_NIGHT_YES

            // Arka plan ve metin renklerini ayarla
            views.setInt(R.id.widgetLayout, "setBackgroundResource",
                if (isDarkTheme) R.drawable.widget_background_dark else R.drawable.widget_background_light)

            val textColor = context.resources.getColor(
                if (isDarkTheme) R.color.widget_text_color_dark else R.color.widget_text_color_light)
            val textColorSecondary = context.resources.getColor(
                if (isDarkTheme) R.color.widget_text_color_secondary_dark else R.color.widget_text_color_secondary_light)

            // Ana metin renkleri
            views.setTextColor(R.id.widgetTitle, textColor)
            views.setTextColor(R.id.imsakTime, textColor)
            views.setTextColor(R.id.gunesTime, textColor)
            views.setTextColor(R.id.ogleTime, textColor)
            views.setTextColor(R.id.ikindiTime, textColor)
            views.setTextColor(R.id.aksamTime, textColor)
            views.setTextColor(R.id.yatsiTime, textColor)

            // Başlık renkleri
            val titleIds = intArrayOf(
                R.id.imsakLabel, R.id.gunesLabel, R.id.ogleLabel,
                R.id.ikindiLabel, R.id.aksamLabel, R.id.yatsiLabel
            )
            for (id in titleIds) {
                views.setTextColor(id, textColor)
            }

            // İkincil metin rengi
            views.setTextColor(R.id.lastUpdate, textColorSecondary)
        }

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                // Önceki thread'i iptal et
                if (backgroundThread != null && backgroundThread?.isAlive == true) {
                    Log.d("PrayerTimesWidget", "Mevcut thread iptal ediliyor")
                    backgroundThread?.interrupt()
                    backgroundThread = null
                }
                
                // Widget boyutunu ölç ve uygun layout'u seç
                val widgetInfo = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minWidth = widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
                val minHeight = widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
                
                Log.d("PrayerTimesWidget", "updateAppWidget: Widget size: $minWidth x $minHeight")
                
                // Widget genişliği ve yüksekliğine göre karar ver
                val layoutId = if (minHeight >= 110) {
                    R.layout.widget_layout_large  // Büyük widget için 2x3 düzen
                } else {
                    R.layout.widget_layout  // Küçük widget için tek satır düzen
                }
                
                val views = RemoteViews(context.packageName, layoutId)
                
                // Tema ayarlarını uygula
                applyTheme(context, views)
                
                // Widget'a tıklandığında uygulamayı açmak için intent
                val openAppIntent = Intent(context, MainActivity::class.java)
                openAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val openAppPendingIntent = PendingIntent.getActivity(
                    context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.widgetLayout, openAppPendingIntent)
                
                // Yenileme butonu için intent oluştur
                val refreshIntent = Intent(context, PrayerTimesWidget::class.java)
                refreshIntent.action = ACTION_REFRESH
                refreshIntent.putExtra("timestamp", System.currentTimeMillis()) // Yeni bir intent oluşturulduğundan emin olmak için
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context, appWidgetId, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.refreshButton, refreshPendingIntent)

                // Yükleniyor durumunu göster
                views.setTextViewText(R.id.widgetTitle, "...")
                views.setTextViewText(R.id.imsakTime, "...")
                views.setTextViewText(R.id.gunesTime, "...")
                views.setTextViewText(R.id.ogleTime, "...")
                views.setTextViewText(R.id.ikindiTime, "...")
                views.setTextViewText(R.id.aksamTime, "...")
                views.setTextViewText(R.id.yatsiTime, "...")
                views.setTextViewText(R.id.lastUpdate, context.getString(R.string.last_update, "..."))
                
                // Widget'ı güncelle
                appWidgetManager.updateAppWidget(appWidgetId, views)
                
                // Arkaplanda veri çekme işlemi
                backgroundThread = Thread {
                    try {
                        val data = fetchWidgetData(context)
                        
                        // UI threadine geri dön
                        handler.post {
                            try {
                                // Son güncelleme zamanını ekle
                                views.setTextViewText(R.id.lastUpdate, getFormattedDateTime(context))
                                
                                // Şehir adını ekle
                                views.setTextViewText(R.id.widgetTitle, data.cityName)
                                
                                if (data.times != null) {
                                    // Namaz vakitlerini widget'a ekle
                                    views.setTextViewText(R.id.imsakTime, data.times[0])
                                    views.setTextViewText(R.id.gunesTime, data.times[1])
                                    views.setTextViewText(R.id.ogleTime, data.times[2])
                                    views.setTextViewText(R.id.ikindiTime, data.times[3])
                                    views.setTextViewText(R.id.aksamTime, data.times[4])
                                    views.setTextViewText(R.id.yatsiTime, data.times[5])
                                } else {
                                    // Veriler alınamadıysa varsayılan değerleri göster
                                    setDefaultTimes(context, views, appWidgetManager, appWidgetId)
                                }
                                
                                // Widget'ı güncelle
                                appWidgetManager.updateAppWidget(appWidgetId, views)
                            } catch (e: Exception) {
                                Log.e("PrayerTimesWidget", "Error updating UI: ${e.message}")
                                setDefaultTimes(context, views, appWidgetManager, appWidgetId)
                            }
                        }
                    } catch (e: InterruptedException) {
                        Log.d("PrayerTimesWidget", "Data fetching interrupted")
                    } catch (e: Exception) {
                        Log.e("PrayerTimesWidget", "Error in background thread: ${e.message}")
                        e.printStackTrace()
                        
                        handler.post {
                            setDefaultTimes(context, views, appWidgetManager, appWidgetId)
                        }
                    }
                }
                
                backgroundThread?.start()
                
            } catch (e: Exception) {
                Log.e("PrayerTimesWidget", "Error in updateAppWidget: ${e.message}")
            }
        }

        private fun setDefaultTimes(context: Context, views: RemoteViews, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val defaultTime = "--:--"
            views.setTextViewText(R.id.imsakTime, defaultTime)
            views.setTextViewText(R.id.gunesTime, defaultTime)
            views.setTextViewText(R.id.ogleTime, defaultTime)
            views.setTextViewText(R.id.ikindiTime, defaultTime)
            views.setTextViewText(R.id.aksamTime, defaultTime)
            views.setTextViewText(R.id.yatsiTime, defaultTime)
            
            // Widget'ı güncelle
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // Arkaplanda veri çekme işlemi
        private fun fetchWidgetData(context: Context): WidgetData {
            // SharedPreferences işlemleri
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val locationId = prefs.getString("flutter.location", "") ?: ""
            val cityName = prefs.getString("flutter.name", context.getString(R.string.app_name)) ?: context.getString(R.string.app_name)

            if (locationId.isEmpty()) {
                Log.e("PrayerTimesWidget", "Location ID is empty")
                return getCachedData(context) ?: WidgetData(cityName, null)
            }

            // API'den veri çekme
            try {
                val url = URL(BASE_URL + locationId)
                Log.d("PrayerTimesWidget", "Fetching data from URL: $url")
                
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000 // 15 saniye
                connection.readTimeout = 15000 // 15 saniye
                connection.setRequestProperty("User-Agent", "Mozilla/5.0 Namaz-Vakti-App Widget")
                connection.setRequestProperty("Accept", "application/xml")
                connection.setRequestProperty("Connection", "close")
                
                // Bağlantı durumunu kontrol et
                val responseCode = connection.responseCode
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    Log.e("PrayerTimesWidget", "HTTP Error: $responseCode")
                    return getCachedData(context) ?: WidgetData(cityName, null)
                }
                
                val reader = BufferedReader(
                    InputStreamReader(connection.inputStream, "UTF-8")
                )
                
                val response = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                reader.close()
                connection.disconnect()

                val xmlResponse = response.toString()
                if (xmlResponse.isEmpty()) {
                    Log.e("PrayerTimesWidget", "Empty XML response")
                    return getCachedData(context) ?: WidgetData(cityName, null)
                }
                
                // XML parse işlemi
                val times = parseXmlResponse(xmlResponse)
                if (times != null) {
                    // Başarılı veri çekme durumunda önbelleğe kaydet
                    cacheData(context, cityName, times)
                    return WidgetData(cityName, times)
                } else {
                    Log.e("PrayerTimesWidget", "XML parsing failed")
                    return getCachedData(context) ?: WidgetData(cityName, null)
                }
            } catch (e: Exception) {
                Log.e("PrayerTimesWidget", "Network error: ${e.message}")
                return getCachedData(context) ?: WidgetData(cityName, null)
            }
        }

        private fun parseXmlResponse(xmlResponse: String): Array<String>? {
            try {
                val factory = XmlPullParserFactory.newInstance()
                factory.isNamespaceAware = true
                val parser = factory.newPullParser()
                parser.setInput(StringReader(xmlResponse))

                val calendar = Calendar.getInstance()
                val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
                val currentMonth = calendar.get(Calendar.MONTH) + 1
                
                Log.d("PrayerTimesWidget", "Looking for day: $currentDay, month: $currentMonth")

                var times: Array<String>? = null
                var eventType = parser.eventType
                
                while (eventType != XmlPullParser.END_DOCUMENT) {
                    if (eventType == XmlPullParser.START_TAG && parser.name == "prayertimes") {
                        val dayStr = parser.getAttributeValue(null, "day")
                        val monthStr = parser.getAttributeValue(null, "month")
                        
                        if (dayStr != null && monthStr != null) {
                            val day = dayStr.toInt()
                            val month = monthStr.toInt()
                            
                            if (day == currentDay && month == currentMonth) {
                                times = Array(6) { "" }
                                
                                val hasFajrAttr = parser.getAttributeValue(null, "fajr") != null
                                if (hasFajrAttr) {
                                    times[0] = parser.getAttributeValue(null, "fajr") ?: ""
                                    times[1] = parser.getAttributeValue(null, "sunrise") ?: ""
                                    times[2] = parser.getAttributeValue(null, "dhuhr") ?: ""
                                    times[3] = parser.getAttributeValue(null, "asr") ?: ""
                                    times[4] = parser.getAttributeValue(null, "maghrib") ?: ""
                                    times[5] = parser.getAttributeValue(null, "isha") ?: ""
                                } else {
                                    eventType = parser.next()
                                    if (eventType == XmlPullParser.TEXT) {
                                        val content = parser.text.trim()
                                        if (content.isNotEmpty()) {
                                            val prayerTimesArray = content.split(Regex("\\s+"))
                                            if (prayerTimesArray.size >= 12) {
                                                times[0] = prayerTimesArray.getOrNull(0) ?: ""
                                                times[1] = prayerTimesArray.getOrNull(2) ?: ""
                                                times[2] = prayerTimesArray.getOrNull(5) ?: ""
                                                times[3] = prayerTimesArray.getOrNull(6) ?: ""
                                                times[4] = prayerTimesArray.getOrNull(9) ?: ""
                                                times[5] = prayerTimesArray.getOrNull(11) ?: ""
                                            }
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                    eventType = parser.next()
                }
                
                return if (times != null && times.any { it.isNotEmpty() }) times else null
            } catch (e: Exception) {
                Log.e("PrayerTimesWidget", "XML parsing error: ${e.message}")
                return null
            }
        }

        private fun cacheData(context: Context, cityName: String, times: Array<String>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            editor.putString(CACHED_CITY_KEY, cityName)
            // Vakitleri sıralı bir şekilde kaydet
            editor.putString("${CACHED_TIMES_KEY}_0", times[0])
            editor.putString("${CACHED_TIMES_KEY}_1", times[1])
            editor.putString("${CACHED_TIMES_KEY}_2", times[2])
            editor.putString("${CACHED_TIMES_KEY}_3", times[3])
            editor.putString("${CACHED_TIMES_KEY}_4", times[4])
            editor.putString("${CACHED_TIMES_KEY}_5", times[5])
            editor.putLong(CACHED_DATE_KEY, System.currentTimeMillis())
            editor.apply()
        }

        private fun getCachedData(context: Context): WidgetData? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cachedCity = prefs.getString(CACHED_CITY_KEY, null)
            val cachedDate = prefs.getLong(CACHED_DATE_KEY, 0)
            
            if (cachedCity != null && cachedDate > 0) {
                // Önbellekteki verinin 24 saatten eski olup olmadığını kontrol et
                val currentTime = System.currentTimeMillis()
                if (currentTime - cachedDate <= 24 * 60 * 60 * 1000) {
                    // Vakitleri sıralı bir şekilde oku
                    val times = Array(6) { index ->
                        prefs.getString("${CACHED_TIMES_KEY}_$index", "") ?: ""
                    }
                    
                    // Tüm vakitlerin boş olup olmadığını kontrol et
                    if (times.any { it.isNotEmpty() }) {
                        Log.d("PrayerTimesWidget", "Using cached data")
                        return WidgetData(cachedCity, times)
                    }
                } else {
                    Log.d("PrayerTimesWidget", "Cached data is too old")
                }
            }
            return null
        }

        private fun retryUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, retryCount: Int) {
            if (retryCount >= MAX_RETRY_COUNT) {
                Log.e("PrayerTimesWidget", "Maksimum deneme sayısına ulaşıldı")
                return
            }

            Log.d("PrayerTimesWidget", "Veri çekme denemesi: ${retryCount + 1}/$MAX_RETRY_COUNT")
            
            // Önceki thread'i iptal et
            backgroundThread?.interrupt()
            backgroundThread = null

            // Yeni bir thread başlat
            backgroundThread = Thread {
                try {
                    val data = fetchWidgetData(context)
                    
                    // UI threadine geri dön
                    handler.post {
                        try {
                            val views = RemoteViews(context.packageName, 
                                if (appWidgetManager.getAppWidgetOptions(appWidgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) >= 110) {
                                    R.layout.widget_layout_large
                                } else {
                                    R.layout.widget_layout
                                }
                            )
                            
                            // Tema ayarlarını uygula
                            applyTheme(context, views)
                            
                            // Son güncelleme zamanını ekle
                            views.setTextViewText(R.id.lastUpdate, getFormattedDateTime(context))
                            
                            // Şehir adını ekle
                            views.setTextViewText(R.id.widgetTitle, data.cityName)
                            
                            if (data.times != null) {
                                // Namaz vakitlerini widget'a ekle
                                views.setTextViewText(R.id.imsakTime, data.times[0])
                                views.setTextViewText(R.id.gunesTime, data.times[1])
                                views.setTextViewText(R.id.ogleTime, data.times[2])
                                views.setTextViewText(R.id.ikindiTime, data.times[3])
                                views.setTextViewText(R.id.aksamTime, data.times[4])
                                views.setTextViewText(R.id.yatsiTime, data.times[5])
                                
                                // Widget'ı güncelle
                                appWidgetManager.updateAppWidget(appWidgetId, views)
                            } else {
                                // Veriler alınamadıysa tekrar dene
                                Log.e("PrayerTimesWidget", "Veri alınamadı, tekrar deneniyor...")
                                handler.postDelayed({
                                    retryUpdate(context, appWidgetManager, appWidgetId, retryCount + 1)
                                }, RETRY_DELAY_MS)
                            }
                        } catch (e: Exception) {
                            Log.e("PrayerTimesWidget", "UI güncelleme hatası: ${e.message}")
                            handler.postDelayed({
                                retryUpdate(context, appWidgetManager, appWidgetId, retryCount + 1)
                            }, RETRY_DELAY_MS)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("PrayerTimesWidget", "Veri çekme hatası: ${e.message}")
                    handler.postDelayed({
                        retryUpdate(context, appWidgetManager, appWidgetId, retryCount + 1)
                    }, RETRY_DELAY_MS)
                }
            }
            
            backgroundThread?.start()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d("PrayerTimesWidget", "onReceive çağrıldı: action=${intent.action}")
        
        if (ACTION_REFRESH == intent.action) {
            // Refresh butonuna tıklandığında - doğrudan güncelle
            Log.d("PrayerTimesWidget", "Refresh butonuna tıklandı")
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
            
            // Widget'ları güncelle
            for (appWidgetId in appWidgetIds) {
                val widgetInfo = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minHeight = widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
                
                // Doğru layout'u seç
                val layoutId = if (minHeight >= 110) {
                    R.layout.widget_layout_large
                } else {
                    R.layout.widget_layout
                }
                
                // Widget'ı güncelle
                val views = RemoteViews(context.packageName, layoutId)
                
                // Tema uygula
                applyTheme(context, views)
                
                // Yükleniyor durumu göster
                views.setTextViewText(R.id.widgetTitle, "...")
                views.setTextViewText(R.id.imsakTime, "...")
                views.setTextViewText(R.id.gunesTime, "...")
                views.setTextViewText(R.id.ogleTime, "...")
                views.setTextViewText(R.id.ikindiTime, "...")
                views.setTextViewText(R.id.aksamTime, "...")
                views.setTextViewText(R.id.yatsiTime, "...")
                views.setTextViewText(R.id.lastUpdate, context.getString(R.string.last_update, "..."))
                
                // Refresh butonu için intent oluştur
                val refreshIntent = Intent(context, PrayerTimesWidget::class.java)
                refreshIntent.action = ACTION_REFRESH
                refreshIntent.putExtra("timestamp", System.currentTimeMillis())
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context, appWidgetId, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.refreshButton, refreshPendingIntent)
                
                // Ana widget tıklama
                val openAppIntent = Intent(context, MainActivity::class.java)
                openAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val openAppPendingIntent = PendingIntent.getActivity(
                    context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.widgetLayout, openAppPendingIntent)
                
                // Widget'ı güncelle
                appWidgetManager.updateAppWidget(appWidgetId, views)
                
                // Veri güncelleme işlemini başlat
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        } else if (Intent.ACTION_CONFIGURATION_CHANGED == intent.action) {
            // Ekran yapılandırması değiştiğinde
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
            onUpdate(context, appWidgetManager, appWidgetIds)
        } else if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            // Widget güncelleme - normal güncelleme akışı
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (appWidgetIds != null) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
        
        // Widget ilk eklendiğinde hemen güncelleme yap
        if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
            for (appWidgetId in appWidgetIds) {
                // İlk güncelleme denemesini başlat
                retryUpdate(context, appWidgetManager, appWidgetId, 0)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        
        // Widget yeniden boyutlandırıldığında çağrılır
        val minWidth = newOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = newOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        
        Log.d("PrayerTimesWidget", "Widget resized: $minWidth x $minHeight")
        
        // Boyuta göre düzeni güncelle
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        backgroundThread?.interrupt()
        backgroundThread = null
    }

    private data class WidgetData(
        val cityName: String,
        val times: Array<String>?
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false

            other as WidgetData

            if (cityName != other.cityName) return false
            if (times != null) {
                if (other.times == null) return false
                if (!times.contentEquals(other.times)) return false
            } else if (other.times != null) return false

            return true
        }

        override fun hashCode(): Int {
            var result = cityName.hashCode()
            result = 31 * result + (times?.contentHashCode() ?: 0)
            return result
        }
    }
} 