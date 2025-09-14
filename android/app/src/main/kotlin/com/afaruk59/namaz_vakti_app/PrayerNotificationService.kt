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
import android.net.ConnectivityManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.Handler
import android.os.Looper
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.RingtoneManager
import android.net.Uri

class PrayerNotificationService : Service() {
    companion object {
        private const val TAG = "PrayerNotificationService"
        private const val NOTIFICATION_CHANNEL_ID = "prayer_notification_channel"
        private const val NOTIFICATION_CHANNEL_ID_SOUND_0 = "prayer_notification_channel_sound_0"
        private const val NOTIFICATION_CHANNEL_ID_SOUND_1 = "prayer_notification_channel_sound_1"
        private const val NOTIFICATION_CHANNEL_ID_SOUND_2 = "prayer_notification_channel_sound_2"
        
        // Ezan sesi için her vakit ayrı channel
        private const val NOTIFICATION_CHANNEL_ID_EZAN_IMSAK = "prayer_notification_channel_ezan_imsak"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_SABAH = "prayer_notification_channel_ezan_sabah"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_GUNES = "prayer_notification_channel_ezan_gunes"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_OGLE = "prayer_notification_channel_ezan_ogle"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_IKINDI = "prayer_notification_channel_ezan_ikindi"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_AKSAM = "prayer_notification_channel_ezan_aksam"
        private const val NOTIFICATION_CHANNEL_ID_EZAN_YATSI = "prayer_notification_channel_ezan_yatsi"
        
        private const val FOREGROUND_NOTIFICATION_ID = 1
        private const val PRAYER_NOTIFICATION_ID_START = 100
        private const val ACTION_START_SERVICE = "com.afaruk59.namaz_vakti_app.ACTION_START_SERVICE"
        private const val ACTION_STOP_SERVICE = "com.afaruk59.namaz_vakti_app.ACTION_STOP_SERVICE"
        private const val ACTION_PRAYER_TIME = "com.afaruk59.namaz_vakti_app.ACTION_PRAYER_TIME"
        private const val ACTION_CHECK_ALARMS = "com.afaruk59.namaz_vakti_app.ACTION_CHECK_ALARMS"
        private const val ACTION_UPDATE_TIMES = "com.afaruk59.namaz_vakti_app.ACTION_UPDATE_TIMES"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val BASE_URL = "https://www.namazvakti.com/XML.php?cityID="
        private const val ALARM_CHECK_INTERVAL = 60 * 1000L
        private const val TIME_UPDATE_INTERVAL = 60 * 60 * 1000L
        private val PRAYER_NAMES = arrayOf(
            R.string.imsak,R.string.sabah, R.string.gunes, R.string.ogle, R.string.ikindi, R.string.aksam, R.string.yatsi
        )
        
        fun startService(context: Context) {
            val intent = Intent(context, PrayerNotificationService::class.java)
            intent.action = ACTION_START_SERVICE
            
            if (VERSION.SDK_INT >= 34) {
                try {
                    context.startForegroundService(intent)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground service on Android 14+: ${e.message}")
                    showErrorNotification(context)
                }
            } else if (VERSION.SDK_INT >= VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        private fun showErrorNotification(context: Context) {
            try {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                
                if (VERSION.SDK_INT >= VERSION_CODES.O) {
                    val channel = NotificationChannel(
                        "service_error_channel",
                        "Servis Hatası",
                        NotificationManager.IMPORTANCE_HIGH
                    )
                    notificationManager.createNotificationChannel(channel)
                }
                
                val notification = NotificationCompat.Builder(context, "service_error_channel")
                    .setContentTitle("Namaz Vakti Bildirimleri Çalışmıyor")
                    .setContentText("Uygulama ayarlarından 'Arka plan izinleri'ni etkinleştirin.")
                    .setSmallIcon(R.drawable.calendar)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .build()
                
                notificationManager.notify(999, notification)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show error notification: ${e.message}")
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, PrayerNotificationService::class.java)
            intent.action = ACTION_STOP_SERVICE
            context.startService(intent)
        }
    }
    
    private lateinit var prefs: SharedPreferences
    private var currentDay = Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
    private var prayerTimes: Array<String>? = null
    private var lastFetchTime: Long = 0
    private var isDataFetchInProgress = false
    private lateinit var alarmManager: AlarmManager
    private var lastAlarmCheckTime: Long = 0
    private var lastLocationId: String = ""
    private var lastCheckedDay: Int = -1
    private var lastCurrentPrayerIndex: Int = -2 // -2 means not initialized
    private var lastCountdownText: String = ""
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        lastLocationId = prefs.getString("flutter.location", "") ?: ""
        lastCheckedDay = Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
        
        val isNotificationsEnabled = prefs.getBoolean("flutter.notifications", false)
        Log.d(TAG, "Service created with notifications enabled: $isNotificationsEnabled")
        
        createNotificationChannels()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                try {
                    // Önce eski kaydedilmiş vakitleri yükle
                    loadPrayerTimes()
                    startForeground(FOREGROUND_NOTIFICATION_ID, createForegroundNotification())
                    
                    // İlk mevcut vakit indeksini ve kalan süreyi kaydet
                    lastCurrentPrayerIndex = getCurrentPrayerIndex()
                    lastCountdownText = getTimeUntilNextPrayer()
                    Log.d(TAG, "Initial current prayer index: $lastCurrentPrayerIndex")
                    Log.d(TAG, "Initial countdown text: '$lastCountdownText'")
                    
                    // İnternet varsa yeni veri çekmeye çalış
                    checkAndFetchInitialData()
                    
                    // Vakit alarmlarını kur (mevcut verilerle)
                    schedulePrayerAlarms()
                    
                    schedulePeriodicChecks()
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting foreground service: ${e.message}")
                    stopSelf()
                }
            }
            ACTION_STOP_SERVICE -> {
                cancelAllAlarms()
                cancelPeriodicChecks()
                if (VERSION.SDK_INT >= VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    stopForeground(true)
                }
                stopSelf()
            }
            ACTION_PRAYER_TIME -> {
                val prayerIndex = intent.getIntExtra("prayer_index", -1)
                if (prayerIndex != -1) {
                    sendPrayerNotification(prayerIndex)
                }
            }
            ACTION_CHECK_ALARMS -> {
                checkAndUpdateAlarms()
            }
        }
        
        return START_REDELIVER_INTENT
    }
    
    private fun checkAndFetchInitialData() {
        Log.d(TAG, "Checking internet connection for initial data fetch")
        
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val networkInfo = connectivityManager.activeNetworkInfo
        
        if (networkInfo != null && networkInfo.isConnected) {
            Log.d(TAG, "Internet connection available, fetching fresh prayer times")
            fetchPrayerTimesData(isInitialFetch = true)
        } else {
            Log.d(TAG, "No internet connection, using saved prayer times")
            if (prayerTimes == null) {
                Log.w(TAG, "No saved prayer times available and no internet connection")
            } else {
                Log.d(TAG, "Using saved prayer times: ${prayerTimes?.joinToString()}")
            }
            // İnternet yokken de mevcut vakitlere göre alarmları kur
            schedulePrayerAlarms()
        }
    }
    
    private fun schedulePeriodicChecks() {
        Log.d(TAG, "🚀 Starting periodic notification update system")
        scheduleNextPeriodicCheck()
    }
    
    private fun getTimeUntilNextMinute(): Long {
        val now = Calendar.getInstance()
        val currentSeconds = now.get(Calendar.SECOND)
        val currentMillis = now.get(Calendar.MILLISECOND)
        
        // Bir sonraki tam dakikaya kadar kalan milisaniye
        return (60 - currentSeconds) * 1000L - currentMillis
    }
    
    private fun cancelPeriodicChecks() {
        val alarmCheckIntent = Intent(this, PrayerNotificationService::class.java).apply {
            action = ACTION_CHECK_ALARMS
        }
        
        val alarmCheckPendingIntent = PendingIntent.getService(
            this,
            1000,
            alarmCheckIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(alarmCheckPendingIntent)
        
        Log.d(TAG, "Cancelled periodic checks")
    }
    
    private fun checkAndUpdateAlarms() {
        val currentTime = System.currentTimeMillis()
        lastAlarmCheckTime = currentTime
        Log.d(TAG, "🔄 DAKIKALIK GÜNCELLEME - Starting periodic check and notification update")
        
        // Her durumda mevcut vakit ve kalan süreyi hesapla
        val currentPrayerIndex = getCurrentPrayerIndex()
        val currentCountdownText = getTimeUntilNextPrayer()
        
        // Değişiklik takibi (sadece log için)
        val prayerChanged = currentPrayerIndex != lastCurrentPrayerIndex
        val countdownChanged = currentCountdownText != lastCountdownText
        
        if (prayerChanged) {
            Log.d(TAG, "📿 Prayer changed: $lastCurrentPrayerIndex → $currentPrayerIndex")
            lastCurrentPrayerIndex = currentPrayerIndex
        }
        if (countdownChanged) {
            Log.d(TAG, "⏱️ Countdown changed: '$lastCountdownText' → '$currentCountdownText'")
            lastCountdownText = currentCountdownText
        }
        
        // 🚨 HER DAKIKA MUTLAKA BİLDİRİM GÜNCELLEMESİ
        try {
            updateForegroundNotification()
            Log.d(TAG, "✅ FOREGROUND NOTIFICATION UPDATED - Prayer: $currentPrayerIndex, Countdown: '$currentCountdownText'")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Notification update failed: ${e.message}")
            e.printStackTrace()
        }
        
        // Gün değişikliği kontrolü (bildirim güncellemesinden sonra)
        val currentDay = Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
        val isDayChanged = currentDay != lastCheckedDay
        
        // Konum değişikliği kontrolü
        val currentLocationId = prefs.getString("flutter.location", "") ?: ""
        val isLocationChanged = currentLocationId != lastLocationId
        
        if (isDayChanged) {
            Log.d(TAG, "📅 Day changed: $lastCheckedDay → $currentDay")
            lastCheckedDay = currentDay
            fetchPrayerTimesData(isDayChange = true)
        } else if (isLocationChanged) {
            Log.d(TAG, "📍 Location changed: $lastLocationId → $currentLocationId")
            lastLocationId = currentLocationId
            fetchPrayerTimesData(isLocationChange = true)
        }
        
        // Alarm zamanlamalarını güncelle
        schedulePrayerAlarms()
        
        // Bir sonraki dakikalık kontrol için alarm kur
        scheduleNextPeriodicCheck()
    }
    
    private fun scheduleNextPeriodicCheck() {
        val nextCheckIntent = Intent(this, PrayerNotificationService::class.java).apply {
            action = ACTION_CHECK_ALARMS
        }
        val nextCheckPendingIntent = PendingIntent.getService(
            this,
            1000,
            nextCheckIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Bir sonraki tam dakikaya kadar olan süreyi hesapla
        val millisecondsUntilNextMinute = getTimeUntilNextMinute()
        val nextMinuteTime = System.currentTimeMillis() + millisecondsUntilNextMinute
        
        if (VERSION.SDK_INT >= VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextMinuteTime,
                nextCheckPendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                nextMinuteTime,
                nextCheckPendingIntent
            )
        }
        
        val nextMinuteFormatted = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault()).format(java.util.Date(nextMinuteTime))
        Log.d(TAG, "⏰ NEXT NOTIFICATION UPDATE: ${millisecondsUntilNextMinute}ms (at $nextMinuteFormatted)")
    }
    
    private fun schedulePrayerAlarms() {
        if (prayerTimes == null) {
            Log.e(TAG, "Prayer times not available, fetching...")
            fetchPrayerTimesData(isRecoveryFetch = true)
            return
        }
        
        cancelAllAlarms()
        
        // Sadece en yakın aktif alarmı kur
        val nextActivePrayer = getNextActivePrayerIndex()
        if (nextActivePrayer != -1) {
            try {
                scheduleAlarmForToday(nextActivePrayer)
                Log.d(TAG, "Scheduled next active prayer alarm: $nextActivePrayer")
            } catch (e: Exception) {
                Log.e(TAG, "Error scheduling next active prayer alarm $nextActivePrayer: ${e.message}")
            }
        } else {
            Log.d(TAG, "No active prayer alarms to schedule or all prayers passed for today")
        }
    }
    
    private fun getNextActivePrayerIndex(): Int {
        if (prayerTimes == null) return -1
        
        val now = Calendar.getInstance()
        val currentTime = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        // Yatsı'dan sonra gece 12'ye kadar alarm kurma
        val yatsiTime = try {
            val timeParts = prayerTimes!![6].split(":")
            timeParts[0].toInt() * 60 + timeParts[1].toInt()
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing Yatsi time: ${e.message}")
            return -1
        }
        
        // Eğer Yatsı'dan sonra ve gece 12'den önceyse alarm kurma
        if (currentTime >= yatsiTime && currentTime < 24 * 60) {
            Log.d(TAG, "After Yatsi prayer, no alarms until midnight")
            return -1
        }
        
        // Vakitleri sırayla kontrol et ve bir sonraki aktif vakti bul
        for (i in 0 until 7) {
            try {
                // Bu vakit için alarm açık mı kontrol et
                val isAlarmEnabled = prefs.getBoolean("flutter.$i", false)
                if (!isAlarmEnabled) {
                    continue
                }
                
                val timeParts = prayerTimes!![i].split(":")
                if (timeParts.size != 2) continue
                
                val prayerHour = timeParts[0].toInt()
                val prayerMinute = timeParts[1].toInt()
                
                // Zaman offset'ini hesapla
                val timeOffset = try {
                    prefs.getLong("flutter.${i}gap", 0).toInt()
                } catch (e: Exception) {
                    0
                }
                
                val prayerTime = prayerHour * 60 + prayerMinute + timeOffset
                
                // Bu vakit henüz gelmedi mi?
                if (prayerTime > currentTime) {
                    Log.d(TAG, "Next active prayer found: $i at ${String.format("%02d:%02d", 
                        (prayerTime / 60) % 24, prayerTime % 60)} (offset: ${timeOffset}min)")
                    return i
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking prayer $i: ${e.message}")
                continue
            }
        }
        
        Log.d(TAG, "No more prayers for today")
        return -1
    }
    
    private fun scheduleAlarmForToday(prayerIndex: Int) {
        try {
            val timeIndex = when(prayerIndex) {
                0 -> 0
                1 -> 1
                2 -> 2
                3 -> 3
                4 -> 4
                5 -> 5
                6 -> 6
                else -> return
            }
            
            if (prayerTimes == null || timeIndex >= prayerTimes!!.size) {
                Log.e(TAG, "Invalid prayer time index: $timeIndex")
                return
            }
            
            val prayerTime = prayerTimes!![timeIndex]
            if (prayerTime.isEmpty()) {
                Log.e(TAG, "Empty prayer time for index $timeIndex")
                return
            }
            
            val timeParts = prayerTime.split(":")
            if (timeParts.size != 2) {
                Log.e(TAG, "Invalid prayer time format: $prayerTime")
                return
            }
            
            val prayerHour = timeParts[0].toInt()
            val prayerMinute = timeParts[1].toInt()
            
            var timeOffset = 0
            try {
                val prefKey = "flutter.${prayerIndex}gap"
                timeOffset = prefs.getLong(prefKey, 0).toInt()
            } catch (e: Exception) {
                Log.e(TAG, "Error getting time offset: ${e.message}")
            }
            
            val alarmTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, prayerHour)
                set(Calendar.MINUTE, prayerMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.MINUTE, timeOffset)
            }
            
            if (alarmTime.timeInMillis <= System.currentTimeMillis()) {
                Log.d(TAG, "Prayer time $prayerIndex has already passed for today")
                return
            }
            
            val intent = Intent(this, PrayerNotificationService::class.java).apply {
                action = ACTION_PRAYER_TIME
                putExtra("prayer_index", prayerIndex)
            }
            
            val pendingIntent = PendingIntent.getService(
                this,
                prayerIndex,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (VERSION.SDK_INT >= VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarmTime.timeInMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    alarmTime.timeInMillis,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Scheduled alarm for prayer $prayerIndex at ${alarmTime.time}")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm for today: ${e.message}")
        }
    }
    
    private fun cancelAllAlarms() {
        for (i in 0 until 7) {
            val intent = Intent(this, PrayerNotificationService::class.java).apply {
                action = ACTION_PRAYER_TIME
                putExtra("prayer_index", i)
            }
            val pendingIntent = PendingIntent.getService(
                this,
                i,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
        Log.d(TAG, "Cancelled all prayer alarms")
    }
    
    private fun loadPrayerTimes() {
        val calendar = Calendar.getInstance()
        val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
        val currentMonth = calendar.get(Calendar.MONTH) + 1

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
            Log.d(TAG, "🔄 Creating new foreground notification...")
            val notification = createForegroundNotification()
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification)
            Log.d(TAG, "✅ Foreground notification successfully updated with ID: $FOREGROUND_NOTIFICATION_ID")
        } catch (e: Exception) {
            Log.e(TAG, "❌ CRITICAL: Error updating foreground notification: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun fetchPrayerTimesData(
        isDayChange: Boolean = false,
        isRecoveryFetch: Boolean = false,
        isLocationChange: Boolean = false,
        isInitialFetch: Boolean = false
    ) {
        val reason = when {
            isDayChange -> "day change"
            isRecoveryFetch -> "recovery fetch (prayer times null)"
            isLocationChange -> "location change"
            isInitialFetch -> "initial fetch with internet"
            else -> "unknown"
        }
        Log.d(TAG, "Fetching prayer times data (reason: $reason)")
        
        if (isDataFetchInProgress) {
            Log.d(TAG, "Data fetch already in progress, skipping")
            return
        }
        
        val currentTime = System.currentTimeMillis()
        if (!isDayChange && !isRecoveryFetch && !isLocationChange && !isInitialFetch && currentTime - lastFetchTime < 5 * 60 * 1000) {
            Log.d(TAG, "Last fetch was less than 5 minutes ago, skipping (last fetch: ${(currentTime - lastFetchTime) / 1000} seconds ago)")
            return
        }
        
        isDataFetchInProgress = true
        
        Thread {
            try {
                val locationId = prefs.getString("flutter.location", "") ?: ""
                if (locationId.isEmpty()) {
                    Log.e(TAG, "Location ID is empty")
                    isDataFetchInProgress = false
                    return@Thread
                }
                
                val url = URL(BASE_URL + locationId)
                Log.d(TAG, "Fetching data from URL: $url")
                
                val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val networkInfo = connectivityManager.activeNetworkInfo
                if (networkInfo == null || !networkInfo.isConnected) {
                    Log.e(TAG, "No internet connection available")
                    loadPrayerTimes()
                    isDataFetchInProgress = false
                    return@Thread
                }
                
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
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.setRequestProperty("User-Agent", "Mozilla/5.0 Namaz-Vakti-App Notifications")
                connection.setRequestProperty("Accept", "application/xml")
                connection.setRequestProperty("Connection", "close")
                
                val responseCode = connection.responseCode
                if (responseCode != HttpURLConnection.HTTP_OK) {
                    Log.e(TAG, "HTTP Error: $responseCode")
                    isDataFetchInProgress = false
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
                    isDataFetchInProgress = false
                    return@Thread
                }
                
                val newPrayerTimes = parseXmlResponse(xmlResponse)
                if (newPrayerTimes != null) {
                    val hasChanged = prayerTimes == null || !prayerTimes!!.contentEquals(newPrayerTimes)
                    
                    if (hasChanged) {
                        prayerTimes = newPrayerTimes
                        lastFetchTime = System.currentTimeMillis()
                        Log.d(TAG, "New prayer times fetched: ${prayerTimes?.joinToString()}")
                        savePrayerTimes()
                        
                        // Main thread'de bildirim güncelleme
                        Handler(Looper.getMainLooper()).post {
                            updateForegroundNotification()
                            // Yeni verilerle mevcut vakit indeksini ve kalan süreyi güncelle
                            lastCurrentPrayerIndex = getCurrentPrayerIndex()
                            lastCountdownText = getTimeUntilNextPrayer()
                            Log.d(TAG, "Updated current prayer index after data fetch: $lastCurrentPrayerIndex")
                            Log.d(TAG, "Updated countdown text after data fetch: '$lastCountdownText'")
                        }
                        
                        // Yeni veriler geldiğinde alarmları güncelle
                            schedulePrayerAlarms()
                    } else {
                        Log.d(TAG, "Fetched prayer times are the same as current, no update needed")
                    }
                } else {
                    Log.e(TAG, "Failed to parse prayer times")
                    loadPrayerTimes()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Network error: ${e.message}")
                loadPrayerTimes()
            } finally {
                isDataFetchInProgress = false
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
                            times = Array(7) { "" }
                            
                            val hasFajrAttr = parser.getAttributeValue(null, "fajr") != null
                            if (hasFajrAttr) {
                                times[0] = parser.getAttributeValue(null, "fajr") ?: ""
                                times[1] = parser.getAttributeValue(null, "sunrise") ?: ""
                                times[2] = parser.getAttributeValue(null, "sunrise") ?: ""
                                times[3] = parser.getAttributeValue(null, "dhuhr") ?: ""
                                times[4] = parser.getAttributeValue(null, "asr") ?: ""
                                times[5] = parser.getAttributeValue(null, "maghrib") ?: ""
                                times[6] = parser.getAttributeValue(null, "isha") ?: ""
                            } else {
                                eventType = parser.next()
                                if (eventType == XmlPullParser.TEXT) {
                                    val content = parser.text.trim()
                                    if (content.isNotEmpty()) {
                                        val prayerTimesArray = content.split(Regex("\\s+"))
                                        if (prayerTimesArray.size >= 12) {
                                            times[0] = prayerTimesArray.getOrNull(0) ?: ""
                                            times[1] = prayerTimesArray.getOrNull(1) ?: ""
                                            times[2] = prayerTimesArray.getOrNull(2) ?: ""
                                            times[3] = prayerTimesArray.getOrNull(5) ?: ""
                                            times[4] = prayerTimesArray.getOrNull(6) ?: ""
                                            times[5] = prayerTimesArray.getOrNull(9) ?: ""
                                            times[6] = prayerTimesArray.getOrNull(11) ?: ""
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
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Foreground service için ana channel
            val mainChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW // Kalıcı bildirim için düşük öncelik
            ).apply {
                description = getString(R.string.notification_channel_desc)
                enableVibration(false)
                setSound(null, null)
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(mainChannel)
            
            // Bildirim sesi için channel
            val soundChannel0 = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_SOUND_0,
                "Namaz Vakti - Bildirim Sesi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Namaz vakti bildirimleri - Bildirim sesi"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(soundChannel0)
            
            // Alarm sesi için channel
            val soundChannel1 = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_SOUND_1,
                "Namaz Vakti - Alarm Sesi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Namaz vakti bildirimleri - Alarm sesi"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(soundChannel1)
            
            // Ezan sesi channel'ları - Her vakit için ayrı
            createEzanChannels(notificationManager)
            
            Log.d(TAG, "All notification channels created")
        }
    }
    
    private fun createEzanChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            
            // İmsak - Normal bildirim sesi
            val imsakChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_IMSAK,
                "Namaz Vakti - İmsak",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "İmsak vakti bildirimleri"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(imsakChannel)
            
            // Sabah - Sabah ezanı
            val sabahChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_SABAH,
                "Namaz Vakti - Sabah Ezanı",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Sabah vakti bildirimleri - Sabah ezanı"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    Uri.parse("android.resource://" + packageName + "/" + R.raw.sabah),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(sabahChannel)
            
            // Güneş - Normal bildirim sesi
            val gunesChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_GUNES,
                "Namaz Vakti - Güneş",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Güneş vakti bildirimleri"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(gunesChannel)
            
            // Öğle - Öğle ezanı
            val ogleChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_OGLE,
                "Namaz Vakti - Öğle Ezanı",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Öğle vakti bildirimleri - Öğle ezanı"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    Uri.parse("android.resource://" + packageName + "/" + R.raw.ogle),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(ogleChannel)
            
            // İkindi - İkindi ezanı
            val ikindiChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_IKINDI,
                "Namaz Vakti - İkindi Ezanı",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "İkindi vakti bildirimleri - İkindi ezanı"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    Uri.parse("android.resource://" + packageName + "/" + R.raw.ikindi),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(ikindiChannel)
            
            // Akşam - Akşam ezanı
            val aksamChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_AKSAM,
                "Namaz Vakti - Akşam Ezanı",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Akşam vakti bildirimleri - Akşam ezanı"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    Uri.parse("android.resource://" + packageName + "/" + R.raw.aksam),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(aksamChannel)
            
            // Yatsı - Yatsı ezanı
            val yatsiChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID_EZAN_YATSI,
                "Namaz Vakti - Yatsı Ezanı",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Yatsı vakti bildirimleri - Yatsı ezanı"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(
                    Uri.parse("android.resource://" + packageName + "/" + R.raw.yatsi),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(yatsiChannel)
            
            Log.d(TAG, "Ezan channels created for all prayer times")
        }
    }
    
    private fun getNotificationChannelId(prayerIndex: Int = -1): String {
        // Her vakit için ayrı ses tercihi oku
        val soundPreference = if (prayerIndex != -1) {
            try {
                // Flutter bazen Long olarak kaydediyor, önce Long olarak dene
                prefs.getLong("flutter.${prayerIndex}voice", 0).toInt()
            } catch (e: Exception) {
                try {
                    // Long olarak okunamadıysa Int olarak dene
                    prefs.getInt("flutter.${prayerIndex}voice", 0)
                } catch (e2: Exception) {
                    // Her ikisi de başarısızsa varsayılan değer
                    Log.e(TAG, "Error reading sound preference for prayer $prayerIndex: ${e.message}, ${e2.message}")
                    0
                }
            }
        } else {
            0 // Prayer index verilmemişse varsayılan
        }
        
        Log.d(TAG, "Prayer index: $prayerIndex, Sound preference: $soundPreference")
        
        return when (soundPreference) {
            0 -> NOTIFICATION_CHANNEL_ID_SOUND_0 // Bildirim sesi
            1 -> NOTIFICATION_CHANNEL_ID_SOUND_1 // Alarm sesi
            2 -> {
                // Ezan sesi - Vakit indeksine göre channel seç
                when (prayerIndex) {
                    0 -> NOTIFICATION_CHANNEL_ID_EZAN_SABAH    // İmsak - Sabah ezanı
                    1 -> NOTIFICATION_CHANNEL_ID_EZAN_SABAH    // Sabah - Sabah ezanı
                    2 -> NOTIFICATION_CHANNEL_ID_EZAN_SABAH    // Güneş - Sabah ezanı
                    3 -> NOTIFICATION_CHANNEL_ID_EZAN_OGLE     // Öğle - Öğle ezanı
                    4 -> NOTIFICATION_CHANNEL_ID_EZAN_IKINDI   // İkindi - İkindi ezanı
                    5 -> NOTIFICATION_CHANNEL_ID_EZAN_AKSAM    // Akşam - Akşam ezanı
                    6 -> NOTIFICATION_CHANNEL_ID_EZAN_YATSI    // Yatsı - Yatsı ezanı
                    else -> NOTIFICATION_CHANNEL_ID_EZAN_SABAH // Varsayılan
                }
            }
            else -> NOTIFICATION_CHANNEL_ID_SOUND_0 // Varsayılan
        }
    }
    
    private fun getCurrentPrayerIndex(): Int {
        if (prayerTimes == null) return -1
        
        val now = Calendar.getInstance()
        val currentTime = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        try {
            // Parse prayer times to minutes
            val prayerMinutes = Array(7) { 0 }
            for (i in 0 until 7) {
                val timeParts = prayerTimes!![i].split(":")
                if (timeParts.size == 2) {
                    prayerMinutes[i] = timeParts[0].toInt() * 60 + timeParts[1].toInt()
                }
            }
            
            // İmsak ile Güneş arasında -> İmsak bold (0)
            if (currentTime >= prayerMinutes[0] && currentTime < prayerMinutes[2]) {
                return 0
            }
            // Güneş ile Öğle arasında -> Güneş bold (2) 
            else if (currentTime >= prayerMinutes[2] && currentTime < prayerMinutes[3]) {
                return 2
            }
            // Öğle ile İkindi arasında -> Öğle bold (3)
            else if (currentTime >= prayerMinutes[3] && currentTime < prayerMinutes[4]) {
                return 3
            }
            // İkindi ile Akşam arasında -> İkindi bold (4)
            else if (currentTime >= prayerMinutes[4] && currentTime < prayerMinutes[5]) {
                return 4
            }
            // Akşam ile Yatsı arasında -> Akşam bold (5)
            else if (currentTime >= prayerMinutes[5] && currentTime < prayerMinutes[6]) {
                return 5
            }
            // Yatsı ile gece 12 arasında -> Yatsı bold (6)
            else if (currentTime >= prayerMinutes[6] && currentTime < 24 * 60) {
                return 6
            }
            // Gece 12'den İmsak'a kadar -> hiçbir vakit bold değil
            else {
                return -1
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating current prayer index: ${e.message}")
            return -1
        }
    }
    
    private fun getTimeUntilNextPrayer(): String {
        if (prayerTimes == null) return ""
        
        val now = Calendar.getInstance()
        val currentTime = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        try {
            // Parse prayer times to minutes
            val prayerMinutes = Array(7) { 0 }
            for (i in 0 until 7) {
                val timeParts = prayerTimes!![i].split(":")
                if (timeParts.size == 2) {
                    prayerMinutes[i] = timeParts[0].toInt() * 60 + timeParts[1].toInt()
                }
            }
            
            var nextPrayerTime: Int
            
            // Bir sonraki vakti bul
            if (currentTime < prayerMinutes[0]) {
                // Gece 12'den önce, İmsak'a kalan
                nextPrayerTime = prayerMinutes[0]
            } else if (currentTime < prayerMinutes[2]) {
                // İmsak ile Güneş arasında, Güneş'e kalan
                nextPrayerTime = prayerMinutes[2]
            } else if (currentTime < prayerMinutes[3]) {
                // Güneş ile Öğle arasında, Öğle'ye kalan
                nextPrayerTime = prayerMinutes[3]
            } else if (currentTime < prayerMinutes[4]) {
                // Öğle ile İkindi arasında, İkindi'ye kalan
                nextPrayerTime = prayerMinutes[4]
            } else if (currentTime < prayerMinutes[5]) {
                // İkindi ile Akşam arasında, Akşam'a kalan
                nextPrayerTime = prayerMinutes[5]
            } else if (currentTime < prayerMinutes[6]) {
                // Akşam ile Yatsı arasında, Yatsı'ya kalan
                nextPrayerTime = prayerMinutes[6]
            } else if (currentTime < 24 * 60) {
                // Yatsı ile gece 12 arasında, kalan süre gösterme
                return ""
            } else {
                // Gece 12'den sonra, ertesi gün İmsak'a kalan
                nextPrayerTime = prayerMinutes[0] + 24 * 60 // Ertesi gün İmsak
            }
            
            if (nextPrayerTime == -1) return ""
            
            val remainingMinutes = nextPrayerTime - currentTime
            if (remainingMinutes <= 0) return ""
            
            val hours = remainingMinutes / 60
            val minutes = remainingMinutes % 60
            
            return String.format("%02d:%02d", hours, minutes)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating time until next prayer: ${e.message}")
            return ""
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
        
        val cityName = prefs.getString("flutter.name", "") ?: ""
        remoteViews.setTextViewText(R.id.location_text, cityName)
        Log.d(TAG, "Setting city name in notification: $cityName")
        
        // Kalan süreyi ayarla
        val timeUntilNext = getTimeUntilNextPrayer()
        remoteViews.setTextViewText(R.id.countdown_text, timeUntilNext)
        Log.d(TAG, "Setting countdown text in notification: $timeUntilNext")
        
        if (prayerTimes != null) {
            Log.d(TAG, "Setting prayer times in notification: ${prayerTimes!!.joinToString()}")
            val currentPrayerIndex = getCurrentPrayerIndex()
            Log.d(TAG, "Current prayer index: $currentPrayerIndex")
            
            try {
                // Önce tüm normal görünümleri göster ve bold görünümleri gizle
                remoteViews.setViewVisibility(R.id.imsak_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.imsak_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.imsak_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.imsak_time_bold, android.view.View.GONE)
                
                remoteViews.setViewVisibility(R.id.gunes_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.gunes_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.gunes_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.gunes_time_bold, android.view.View.GONE)
                
                remoteViews.setViewVisibility(R.id.ogle_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.ogle_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.ogle_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.ogle_time_bold, android.view.View.GONE)
                
                remoteViews.setViewVisibility(R.id.ikindi_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.ikindi_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.ikindi_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.ikindi_time_bold, android.view.View.GONE)
                
                remoteViews.setViewVisibility(R.id.aksam_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.aksam_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.aksam_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.aksam_time_bold, android.view.View.GONE)
                
                remoteViews.setViewVisibility(R.id.yatsi_text, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.yatsi_text_bold, android.view.View.GONE)
                remoteViews.setViewVisibility(R.id.yatsi_time, android.view.View.VISIBLE)
                remoteViews.setViewVisibility(R.id.yatsi_time_bold, android.view.View.GONE)
                
                // Tüm vakitleri ayarla
                remoteViews.setTextViewText(R.id.imsak_time, prayerTimes!![0])
                remoteViews.setTextViewText(R.id.imsak_time_bold, prayerTimes!![0])
                remoteViews.setTextViewText(R.id.gunes_time, prayerTimes!![2])
                remoteViews.setTextViewText(R.id.gunes_time_bold, prayerTimes!![2])
                remoteViews.setTextViewText(R.id.ogle_time, prayerTimes!![3])
                remoteViews.setTextViewText(R.id.ogle_time_bold, prayerTimes!![3])
                remoteViews.setTextViewText(R.id.ikindi_time, prayerTimes!![4])
                remoteViews.setTextViewText(R.id.ikindi_time_bold, prayerTimes!![4])
                remoteViews.setTextViewText(R.id.aksam_time, prayerTimes!![5])
                remoteViews.setTextViewText(R.id.aksam_time_bold, prayerTimes!![5])
                remoteViews.setTextViewText(R.id.yatsi_time, prayerTimes!![6])
                remoteViews.setTextViewText(R.id.yatsi_time_bold, prayerTimes!![6])
                
                // Mevcut vakti bold yap
                when (currentPrayerIndex) {
                    0 -> {
                        remoteViews.setViewVisibility(R.id.imsak_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.imsak_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.imsak_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.imsak_time_bold, android.view.View.VISIBLE)
                    }
                    2 -> {
                        remoteViews.setViewVisibility(R.id.gunes_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.gunes_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.gunes_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.gunes_time_bold, android.view.View.VISIBLE)
                    }
                    3 -> {
                        remoteViews.setViewVisibility(R.id.ogle_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.ogle_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.ogle_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.ogle_time_bold, android.view.View.VISIBLE)
                    }
                    4 -> {
                        remoteViews.setViewVisibility(R.id.ikindi_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.ikindi_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.ikindi_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.ikindi_time_bold, android.view.View.VISIBLE)
                    }
                    5 -> {
                        remoteViews.setViewVisibility(R.id.aksam_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.aksam_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.aksam_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.aksam_time_bold, android.view.View.VISIBLE)
                    }
                    6 -> {
                        remoteViews.setViewVisibility(R.id.yatsi_text, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.yatsi_text_bold, android.view.View.VISIBLE)
                        remoteViews.setViewVisibility(R.id.yatsi_time, android.view.View.GONE)
                        remoteViews.setViewVisibility(R.id.yatsi_time_bold, android.view.View.VISIBLE)
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error setting prayer times in notification: ${e.message}")
            }
        } else {
            Log.d(TAG, "Prayer times are null in notification, fetching new data...")
            fetchPrayerTimesData()
        }

        val isLockScreenEnabled = prefs.getBoolean("flutter.lockScreen", false)
        val visibility = if (isLockScreenEnabled) {
            NotificationCompat.VISIBILITY_PUBLIC
        } else {
            NotificationCompat.VISIBILITY_SECRET
        }
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.calendar)
            .setContent(remoteViews)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setContentIntent(pendingIntent)
            .setSilent(true)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(visibility)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification)
        
        return notification
    }
    
    private fun sendPrayerNotification(prayerIndex: Int) {
        Log.d(TAG, "Sending notification for prayer: $prayerIndex")
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val cityName = prefs.getString("flutter.name", "") ?: ""
        val prayerName = when (prayerIndex) {
            0 -> getString(R.string.imsak)
            1 -> getString(R.string.sabah)
            2 -> getString(R.string.gunes)
            3 -> getString(R.string.ogle)
            4 -> getString(R.string.ikindi)
            5 -> getString(R.string.aksam)
            6 -> getString(R.string.yatsi)
            else -> getString(R.string.imsak)
        }
        
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this, prayerIndex, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val notificationTitle = getString(R.string.prayer_time_notification_title, prayerName)
        
        var notificationText = getString(R.string.prayer_time_notification_text, cityName, prayerName)
        
        try {
            val timeOffset = prefs.getLong("flutter.${prayerIndex}gap", 0)
            if (timeOffset != 0L) {
                val timeOffsetMinutes = timeOffset.toInt()
                val absTimeOffset = Math.abs(timeOffsetMinutes)
                notificationText = if (timeOffsetMinutes > 0) {
                    getString(R.string.time_after, cityName, prayerName, absTimeOffset)
                } else {
                    getString(R.string.time_before, cityName, prayerName, absTimeOffset)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting time offset: ${e.message}")
        }
        
        Log.d(TAG, "Creating notification with title: $notificationTitle and text: $notificationText")
        
        // Ses tercihine göre doğru channel'ı seç
        val channelId = getNotificationChannelId(prayerIndex)
        Log.d(TAG, "Using notification channel: $channelId")
        
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(notificationTitle)
            .setContentText(notificationText)
            .setSmallIcon(R.drawable.alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(1000, 1000, 1000, 1000, 1000))
            .build()
        
        try {
            notificationManager.notify(PRAYER_NOTIFICATION_ID_START + prayerIndex, notification)
            Log.d(TAG, "Notification sent successfully for prayer $prayerIndex with channel $channelId")
            
            // Bu alarm tetiklendikten sonra bir sonraki aktif alarmı kur
            Handler(Looper.getMainLooper()).postDelayed({
                schedulePrayerAlarms()
            }, 1000) // 1 saniye sonra bir sonraki alarmı kur
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send notification for prayer $prayerIndex: ${e.message}")
            e.printStackTrace()
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }
}

class BootCompleteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootCompleteReceiver", "Boot completed, checking notification settings")
            
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isNotificationsEnabled = prefs.getBoolean("flutter.notifications", false)
            
            if (isNotificationsEnabled) {
                Log.d("BootCompleteReceiver", "Notifications are enabled, starting service")
                
                if (VERSION.SDK_INT >= 34) {
                    try {
                        Log.d("BootCompleteReceiver", "Using delayed start for Android 14+")
                        
                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                PrayerNotificationService.startService(context)
                            } catch (e: Exception) {
                                Log.e("BootCompleteReceiver", "Delayed start failed: ${e.message}")
                            }
                        }, 10000)
                    } catch (e: Exception) {
                        Log.e("BootCompleteReceiver", "Failed to schedule delayed start: ${e.message}")
                    }
                } else {
                    PrayerNotificationService.startService(context)
                }
            } else {
                Log.d("BootCompleteReceiver", "Notifications are disabled, not starting service")
            }
        }
    }
}