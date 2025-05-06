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

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.*
import android.util.Log
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.StringReader
import java.net.HttpURLConnection
import java.net.URL
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import java.security.cert.X509Certificate

class PrayerNotificationService : Service() {
    companion object {
        private const val TAG = "PrayerNotificationService"
        private const val NOTIFICATION_CHANNEL_ID = "prayer_notification_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 1
        private const val PRAYER_NOTIFICATION_ID_START = 100
        private const val ACTION_START_SERVICE = "com.afaruk59.namaz_vakti_app.ACTION_START_SERVICE"
        private const val ACTION_STOP_SERVICE = "com.afaruk59.namaz_vakti_app.ACTION_STOP_SERVICE"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val BASE_URL = "http://www.namazvakti.com/XML.php?cityID="
        
        // Namaz vakitlerini kontrol etme aralığı (dakika)
        private const val CHECK_INTERVAL_MINUTES = 1L
        
        // Bildirimlerin adları
        private val PRAYER_NAMES = arrayOf(
            "İmsak", "Sabah", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"
        )
        
        fun startService(context: Context) {
            val intent = Intent(context, PrayerNotificationService::class.java)
            intent.action = ACTION_START_SERVICE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, PrayerNotificationService::class.java)
            intent.action = ACTION_STOP_SERVICE
            context.startService(intent)
        }
    }
    
    private val executor = Executors.newSingleThreadScheduledExecutor()
    private lateinit var prefs: SharedPreferences
    private var currentDay = Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
    private var prayerTimes: Array<String>? = null
    private var lastFetchTime: Long = 0
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Bildirim kanalı oluştur
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                // Önce mevcut vakitleri yükle
                loadPrayerTimes()
                // Foreground servisi başlat
                startForeground(FOREGROUND_NOTIFICATION_ID, createForegroundNotification())
                startPrayerTimeChecker()
            }
            ACTION_STOP_SERVICE -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        
        return START_STICKY
    }

    private fun loadPrayerTimes() {
        val calendar = Calendar.getInstance()
        val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
        val currentMonth = calendar.get(Calendar.MONTH) + 1

        // SharedPreferences'den kaydedilmiş vakitleri yükle
        val savedTimesStr = prefs.getString("flutter.prayerTimes", null)
        val savedDay = prefs.getInt("flutter.prayerTimesDay", -1)
        val savedMonth = prefs.getInt("flutter.prayerTimesMonth", -1)

        if (savedTimesStr != null && savedDay == currentDay && savedMonth == currentMonth) {
            try {
                prayerTimes = savedTimesStr.split(",").toTypedArray()
                Log.d(TAG, "Loaded saved prayer times: ${prayerTimes?.joinToString()}")
            } catch (e: Exception) {
                Log.e(TAG, "Error loading saved prayer times: ${e.message}")
            }
        }
    }

    private fun savePrayerTimes() {
        if (prayerTimes != null) {
            val calendar = Calendar.getInstance()
            val editor = prefs.edit()
            editor.putString("flutter.prayerTimes", prayerTimes!!.joinToString(","))
            editor.putInt("flutter.prayerTimesDay", calendar.get(Calendar.DAY_OF_MONTH))
            editor.putInt("flutter.prayerTimesMonth", calendar.get(Calendar.MONTH) + 1)
            editor.apply()
            Log.d(TAG, "Saved prayer times: ${prayerTimes!!.joinToString()}")
        }
    }

    private fun updateForegroundNotification() {
        try {
            val notification = createForegroundNotification()
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating foreground notification: ${e.message}")
        }
    }
    
    private fun startPrayerTimeChecker() {
        Log.d(TAG, "Starting prayer time checker")
        
        // İlk veri çekme işlemi
        fetchPrayerTimesData()
        
        // Saatlik güncelleme zamanlaması
        try {
            val initialDelay = getMinutesToNextHour()
            Log.d(TAG, "Scheduling hourly updates to start in $initialDelay minutes")
            
            executor.scheduleAtFixedRate({
                try {
                    Log.d(TAG, "Hourly prayer times update")
                    fetchPrayerTimesData()
                } catch (e: Exception) {
                    Log.e(TAG, "Error refreshing prayer times: ${e.message}")
                }
            }, initialDelay, 60, TimeUnit.MINUTES)
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling hourly updates: ${e.message}")
        }

        // Dakikalık namaz vakti kontrolü - sadece bir kez zamanlama yapılıyor
        executor.scheduleAtFixedRate({
            try {
                checkPrayerTimes()
            } catch (e: Exception) {
                Log.e(TAG, "Error checking prayer times: ${e.message}")
            }
        }, 0, CHECK_INTERVAL_MINUTES, TimeUnit.MINUTES)
    }
    
    // Bir sonraki saat başına kaç dakika kaldığını hesapla
    private fun getMinutesToNextHour(): Long {
        val calendar = Calendar.getInstance()
        val minutes = calendar.get(Calendar.MINUTE)
        
        // Saat başına kalan dakika (saniyeler dikkate alınmadı)
        // En az 1 dakika bekleyecek şekilde ayarla
        val minutesUntilNextHour = if (minutes >= 59) 1 else (60 - minutes)
        Log.d(TAG, "Minutes until next hour: $minutesUntilNextHour")
        return minutesUntilNextHour.toLong()
    }
    
    private fun checkPrayerTimes() {
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)
        val dayOfMonth = calendar.get(Calendar.DAY_OF_MONTH)
        
        // Gün değiştiyse yeni vakitleri çek
        if (dayOfMonth != currentDay) {
            currentDay = dayOfMonth
            fetchPrayerTimesData()
            return
        }
        
        if (prayerTimes == null) {
            Log.d(TAG, "Prayer times not available, fetching...")
            fetchPrayerTimesData()
            return
        }
        
        // Tüm vakitleri kontrol et
        for (i in 0 until 7) {
            try {
                // Alarm açık mı kontrol et
                val isAlarmEnabled = prefs.getBoolean("flutter.$i", false)
                if (!isAlarmEnabled) continue
                
                // Vakit zaman farkı - SharedPreferences'den Long değerini güvenli bir şekilde alma
                var timeOffset = 0
                try {
                    val prefKey = "flutter.${i}gap"
                    
                    // Doğrudan Long olarak almayı dene
                    try {
                        timeOffset = prefs.getLong(prefKey, 0).toInt()
                        Log.d(TAG, "Retrieved time offset as Long: $timeOffset")
                    } catch (e: ClassCastException) {
                        // Long olarak alınamıyorsa, Int olarak dene
                        try {
                            timeOffset = prefs.getInt(prefKey, 0)
                            Log.d(TAG, "Retrieved time offset as Int: $timeOffset")
                        } catch (e2: ClassCastException) {
                            // Int olarak da alınamıyorsa, String olarak dene
                            try {
                                val strValue = prefs.getString(prefKey, "0")
                                timeOffset = strValue?.toIntOrNull() ?: 0
                                Log.d(TAG, "Retrieved time offset as String: $timeOffset")
                            } catch (e3: Exception) {
                                Log.e(TAG, "Could not retrieve time offset in any format: ${e3.message}")
                                timeOffset = 0
                            }
                        }
                    }
                    
                    Log.d(TAG, "Final time offset for prayer $i: $timeOffset")
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting time offset for prayer $i: ${e.message}")
                    timeOffset = 0
                }
                
                // İlgili vakit için saati kontrol et (İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı)
                val timeIndex = when(i) {
                    0 -> 0  // İmsak
                    1 -> 1  // Sabah (İmsak ile aynı)
                    2 -> 2  // Güneş
                    3 -> 3  // Öğle
                    4 -> 4  // İkindi
                    5 -> 5  // Akşam
                    6 -> 6  // Yatsı
                    else -> continue
                }
                
                if (timeIndex >= prayerTimes!!.size) continue
                
                val prayerTime = prayerTimes!![timeIndex]
                if (prayerTime.isEmpty()) continue
                
                val timeParts = prayerTime.split(":")
                if (timeParts.size != 2) continue
                
                val prayerHour = timeParts[0].toInt()
                val prayerMinute = timeParts[1].toInt()
                
                // Zaman farkını hesapla
                val adjustedTime = Calendar.getInstance()
                adjustedTime.set(Calendar.HOUR_OF_DAY, prayerHour)
                adjustedTime.set(Calendar.MINUTE, prayerMinute)
                adjustedTime.add(Calendar.MINUTE, timeOffset)
                
                val adjustedHour = adjustedTime.get(Calendar.HOUR_OF_DAY)
                val adjustedMinute = adjustedTime.get(Calendar.MINUTE)
                
                Log.d(TAG, "Prayer $i: Current time ${currentHour}:${currentMinute}, Prayer time ${adjustedHour}:${adjustedMinute}")
                
                // Şu anki dakika ile kontrol edilecek dakika aynı mı?
                if (currentHour == adjustedHour && currentMinute == adjustedMinute) {
                    // Bildirim gönder
                    Log.d(TAG, "It's time for prayer $i: ${PRAYER_NAMES[i]}")
                    sendPrayerNotification(i)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing prayer time for index $i: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    private fun fetchPrayerTimesData() {
        Log.d(TAG, "Fetching prayer times data")
        
        Thread {
            try {
                val locationId = prefs.getString("flutter.location", "") ?: ""
                if (locationId.isEmpty()) {
                    Log.e(TAG, "Location ID is empty")
                    return@Thread
                }
                
                val url = URL(BASE_URL + locationId)
                Log.d(TAG, "Fetching data from URL: $url")
                
                // SSL hatalarını geçici olarak görmezden gel
                if (url.protocol.toLowerCase() == "https") {
                    try {
                        val trustAllCerts = arrayOf<TrustManager>(object : X509TrustManager {
                            override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
                            override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
                            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
                        })
                        
                        val sc = SSLContext.getInstance("TLS")
                        sc.init(null, trustAllCerts, java.security.SecureRandom())
                        HttpsURLConnection.setDefaultSSLSocketFactory(sc.socketFactory)
                        HttpsURLConnection.setDefaultHostnameVerifier { _, _ -> true }
                    } catch (e: Exception) {
                        Log.e(TAG, "SSL setup error: ${e.message}")
                    }
                }
                
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000 // 15 saniye
                connection.readTimeout = 15000 // 15 saniye
                connection.setRequestProperty("User-Agent", "Mozilla/5.0 Namaz-Vakti-App Notifications")
                connection.setRequestProperty("Accept", "application/xml")
                connection.setRequestProperty("Connection", "close")
                
                // Bağlantı durumunu kontrol et
                val responseCode = connection.responseCode
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    Log.e(TAG, "HTTP Error: $responseCode")
                    return@Thread
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
                    Log.e(TAG, "Empty XML response")
                    return@Thread
                }
                
                // XML parse işlemi
                prayerTimes = parseXmlResponse(xmlResponse)
                lastFetchTime = System.currentTimeMillis()
                
                Log.d(TAG, "Prayer times fetched: ${prayerTimes?.joinToString()}")
                savePrayerTimes()
                updateForegroundNotification()
            } catch (e: Exception) {
                Log.e(TAG, "Network error: ${e.message}")
            }
        }.start()
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
            
            Log.d(TAG, "Looking for day: $currentDay, month: $currentMonth")
            
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
                            times = Array(7) { "" } // 7 vakit için dizi oluştur
                            
                            val hasFajrAttr = parser.getAttributeValue(null, "fajr") != null
                            if (hasFajrAttr) {
                                times[0] = parser.getAttributeValue(null, "fajr") ?: "" // İmsak
                                times[1] = parser.getAttributeValue(null, "sunrise") ?: "" // Sabah
                                times[2] = parser.getAttributeValue(null, "sunrise") ?: "" // Güneş
                                times[3] = parser.getAttributeValue(null, "dhuhr") ?: "" // Öğle
                                times[4] = parser.getAttributeValue(null, "asr") ?: "" // İkindi
                                times[5] = parser.getAttributeValue(null, "maghrib") ?: "" // Akşam
                                times[6] = parser.getAttributeValue(null, "isha") ?: "" // Yatsı
                            } else {
                                eventType = parser.next()
                                if (eventType == XmlPullParser.TEXT) {
                                    val content = parser.text.trim()
                                    if (content.isNotEmpty()) {
                                        val prayerTimesArray = content.split(Regex("\\s+"))
                                        if (prayerTimesArray.size >= 12) {
                                            times[0] = prayerTimesArray.getOrNull(0) ?: "" // İmsak
                                            times[1] = prayerTimesArray.getOrNull(1) ?: "" // Sabah
                                            times[2] = prayerTimesArray.getOrNull(2) ?: "" // Güneş
                                            times[3] = prayerTimesArray.getOrNull(5) ?: "" // Öğle
                                            times[4] = prayerTimesArray.getOrNull(6) ?: "" // İkindi
                                            times[5] = prayerTimesArray.getOrNull(9) ?: "" // Akşam
                                            times[6] = prayerTimesArray.getOrNull(11) ?: "" // Yatsı
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
            Log.e(TAG, "XML parsing error: ${e.message}")
            return null
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Namaz Vakti Bildirimleri"
            val descriptionText = "Namaz vakitlerinde bildirim gösterir"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            // Bildirim kanalı özelliklerini ayarla
            channel.enableVibration(true)
            channel.enableLights(true)
            
            // Bildirim kanalını sisteme kaydet
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createForegroundNotification(): Notification {
        val pendingIntent: PendingIntent =
            Intent(this, MainActivity::class.java).let { notificationIntent ->
                PendingIntent.getActivity(
                    this, 0, notificationIntent,
                    PendingIntent.FLAG_IMMUTABLE
                )
            }

        val remoteViews = RemoteViews(packageName, R.layout.notification_layout)
        
        // Konum adını set et
        val cityName = prefs.getString("flutter.name", "") ?: ""
        remoteViews.setTextViewText(R.id.location_text, cityName)
        Log.d(TAG, "Setting city name in notification: $cityName")
        
        // Namaz vakitlerini set et
        if (prayerTimes != null) {
            Log.d(TAG, "Setting prayer times in notification: ${prayerTimes!!.joinToString()}")
            try {
                remoteViews.setTextViewText(R.id.imsak_time, prayerTimes!![0])   // İmsak
                remoteViews.setTextViewText(R.id.gunes_time, prayerTimes!![2])   // Güneş
                remoteViews.setTextViewText(R.id.ogle_time, prayerTimes!![3])    // Öğle
                remoteViews.setTextViewText(R.id.ikindi_time, prayerTimes!![4])  // İkindi
                remoteViews.setTextViewText(R.id.aksam_time, prayerTimes!![5])   // Akşam
                remoteViews.setTextViewText(R.id.yatsi_time, prayerTimes!![6])   // Yatsı
            } catch (e: Exception) {
                Log.e(TAG, "Error setting prayer times in notification: ${e.message}")
            }
        } else {
            Log.d(TAG, "Prayer times are null, fetching new data...")
            fetchPrayerTimesData()
        }
        
        // Bildirim oluştur ve güncelle
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.calendar)
            .setContent(remoteViews)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setContentIntent(pendingIntent)
            .setSilent(true)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET) // Kilit ekranında gizle
            .setShowWhen(false) // Zaman göstergesini gizle
            .setOnlyAlertOnce(true)
            .build()

        // Notification Manager'ı al ve bildirimi güncelle
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification)
        
        return notification
    }
    
    private fun sendPrayerNotification(prayerIndex: Int) {
        Log.d(TAG, "Sending notification for prayer: $prayerIndex")
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val cityName = prefs.getString("flutter.name", "") ?: ""
        val prayerName = PRAYER_NAMES[prayerIndex]
        
        // Bildirimi tıklayınca açılacak intent
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        // Bildirim oluştur
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("$prayerName Vakti")
            .setContentText("$cityName için $prayerName vakti geldi.")
            .setSmallIcon(R.drawable.alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(1000, 1000, 1000, 1000, 1000))
            .build()
        
        // Bildirimi göster
        notificationManager.notify(PRAYER_NOTIFICATION_ID_START + prayerIndex, notification)
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        executor.shutdown()
        super.onDestroy()
    }
}

// Uygulama boot'ta başlatma receiver'ı
class BootCompleteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootCompleteReceiver", "Boot completed, checking notification settings")
            
            // SharedPreferences'den bildirim ayarını kontrol et
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isNotificationsEnabled = prefs.getBoolean("flutter.notifications", false)
            
            if (isNotificationsEnabled) {
                Log.d("BootCompleteReceiver", "Notifications are enabled, starting service")
                PrayerNotificationService.startService(context)
            } else {
                Log.d("BootCompleteReceiver", "Notifications are disabled, not starting service")
            }
        }
    }
}