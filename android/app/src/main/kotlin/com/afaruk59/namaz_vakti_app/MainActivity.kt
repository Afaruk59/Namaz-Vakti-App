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

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.content.Context
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.media.session.MediaButtonReceiver
import com.afaruk59.namaz_vakti_app.QuranMediaService

class MainActivity : FlutterActivity() {
    companion object {
        private const val WIDGET_CHANNEL = "com.afaruk59.namaz_vakti_app/widget"
        private const val NOTIFICATION_CHANNEL = "com.afaruk59.namaz_vakti_app/notifications"
    }
    private val CHANNEL = "com.afaruk59.namaz_vakti_app/media_controls"
    private val FLUTTER_CHANNEL = "com.afaruk59.namaz_vakti_app/media_service"
    
    // Kitap Audio Kanalları
    private val BOOK_MEDIA_CONTROLS_CHANNEL = "com.afaruk59.namaz_vakti_app/book_media_controls"
    private val BOOK_MEDIA_CALLBACK_CHANNEL = "com.afaruk59.namaz_vakti_app/book_media_callback"
    
    // Quran Audio Kanalları
    private val QURAN_MEDIA_CONTROLS_CHANNEL = "com.afaruk59.namaz_vakti_app/quran_media_controls"
    private val QURAN_MEDIA_CHANNEL = "com.afaruk59.namaz_vakti_app/quran_media"
    private val QURAN_MEDIA_CALLBACK_CHANNEL = "com.afaruk59.namaz_vakti_app/quran_media_callback"

    private var mediaService: MediaService? = null
    private var quranMediaService: QuranMediaService? = null
    
    private var methodChannel: MethodChannel? = null
    private var flutterMethodChannel: MethodChannel? = null
    private var bookMediaControlsChannel: MethodChannel? = null
    private var bookMediaCallbackChannel: MethodChannel? = null
    private var quranMediaControlsChannel: MethodChannel? = null
    private var quranMediaChannel: MethodChannel? = null
    private var quranMediaCallbackChannel: MethodChannel? = null
    
    private var bound = false
    private var quranBound = false
    private var pendingAction: String? = null
    private var isActivityResumed = false
    private var isProcessingAction = false
    
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Widget güncellemesi için MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    updateWidget()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
            
        // Bildirim servisi için MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startNotificationService" -> {
                        // Bildirim ayarını kontrol et
                        val prefs = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                        val isNotificationsEnabled = prefs.getBoolean("flutter.notifications", false)
                        
                        Log.d("MainActivity", "Notification service start requested, enabled: $isNotificationsEnabled")
                        
                        if (isNotificationsEnabled) {
                            PrayerNotificationService.startService(context)
                            Log.d("MainActivity", "Prayer notification service started")
                            result.success(true)
                        } else {
                            PrayerNotificationService.stopService(context)
                            Log.d("MainActivity", "Prayer notification service stopped (notifications disabled)")
                            result.success(false)
                        }
                    }
                    "stopNotificationService" -> {
                        PrayerNotificationService.stopService(context)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // Mevcut Media Service kanalı
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val intent = Intent(this, MediaService::class.java)
                        bindService(intent, connection, Context.BIND_AUTO_CREATE)
                        startService(intent)
                        
                        handler.postDelayed({
                            methodChannel?.invokeMethod("onResume", null)
                        }, 500)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Servis başlatma hatası: ${e.message}")
                        result.error("SERVICE_START_ERROR", e.message, null)
                    }
                }
                "stopService" -> {
                    if (bound && mediaService != null) {
                        try {
                            mediaService?.stopAudio()
                        } catch (e: Exception) {
                            Log.e("MainActivity", "stopAudio çağrısı hatası: ${e.message}")
                        }
                    }
                    if (bound) {
                        unbindService(connection)
                        bound = false
                    }
                    val intent = Intent(this, MediaService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "updatePlaybackState" -> {
                    val state = call.argument<Number>("state")?.toInt() ?: 0
                    mediaService?.updatePlaybackState(state)
                    result.success(true)
                }
                "updateMetadata" -> {
                    val title = call.argument<String>("title") ?: ""
                    val author = call.argument<String>("author") ?: ""
                    val coverUrl = call.argument<String>("coverUrl") ?: ""
                    val duration = call.argument<Number>("duration")?.toLong() ?: 0L
                    mediaService?.updateMetadata(title, author, coverUrl, duration)
                    
                    handler.postDelayed({
                        mediaService?.updateMetadata(title, author, coverUrl, duration)
                    }, 300)
                    
                    result.success(true)
                }
                "updatePosition" -> {
                    val position = call.argument<Number>("position")?.toLong() ?: 0L
                    mediaService?.updatePosition(position)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        flutterMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLUTTER_CHANNEL)
        flutterMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initMediaService" -> {
                    MediaService.methodChannel = flutterMethodChannel
                    result.success(null)
                }
                "audio_completed" -> {
                    Log.d("MainActivity", "Audio completed, sending next command to Flutter")
                    try {
                        flutterMethodChannel?.invokeMethod("next", null)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Audio completed error: ${e.message}")
                        result.error("AUDIO_COMPLETED_ERROR", e.message, null)
                    }
                }
                "audio_error" -> {
                    Log.d("MainActivity", "Audio error received")
                    try {
                        flutterMethodChannel?.invokeMethod("audio_error", null)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Audio error notification error: ${e.message}")
                        result.error("AUDIO_ERROR_NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "getCurrentAudioPage" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val bookCode = prefs.getString("flutter.playing_book_code", "") ?: ""
                    val currentPage = prefs.getInt("flutter.${bookCode}_current_audio_page", 0)
                    result.success(currentPage)
                }
                "updateAudioPageState" -> {
                    val bookCode = call.argument<String>("bookCode") ?: ""
                    val currentPage = call.argument<Int>("currentPage") ?: 0
                    val firstPage = call.argument<Int>("firstPage") ?: 1
                    val lastPage = call.argument<Int>("lastPage") ?: 9999
                    
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.playing_book_code", bookCode)
                        .putInt("flutter.${bookCode}_current_audio_page", currentPage)
                        .putInt("flutter.${bookCode}_first_page", firstPage)
                        .putInt("flutter.${bookCode}_last_page", lastPage)
                        .apply()
                    
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // =================================================================================================
        // YENİ EKLENEN KISIMLAR (KİTAP VE KURAN ENTEGRASYONU)
        // =================================================================================================

        // Kitap Medya Kontrolleri Kanalı
        bookMediaControlsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BOOK_MEDIA_CONTROLS_CHANNEL)
        bookMediaControlsChannel?.setMethodCallHandler { call, result ->
            // Burada MediaService kullanılacak (çünkü kitaplar mevcut MediaService'i kullanıyor olabilir)
            // Eğer kitaplar için ayrı servis gerekiyorsa BookMediaService oluşturulmalı, 
            // ama example kodlarında BookMediaService vardı. Eğer taşınmadıysa mevcut MediaService adapte edilmeli.
            // Şimdilik mevcut MediaService üzerinden yönlendirme yapalım.
            
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, MediaService::class.java)
                    bindService(intent, connection, Context.BIND_AUTO_CREATE)
                    startService(intent)
                    result.success(true)
                }
                "stopService" -> {
                    // Stop işlemi
                    result.success(true)
                }
                // Diğer metodlar...
                else -> result.notImplemented()
            }
        }

        // Kitap Medya Callback Kanalı
        bookMediaCallbackChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BOOK_MEDIA_CALLBACK_CHANNEL)
        
        // Kuran Medya Kontrolleri Kanalı (QuranMediaService)
        quranMediaControlsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QURAN_MEDIA_CONTROLS_CHANNEL)
        quranMediaControlsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val intent = Intent(this, QuranMediaService::class.java)
                        bindService(intent, quranConnection, Context.BIND_AUTO_CREATE)
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Quran Service start error: ${e.message}")
                        result.error("SERVICE_START_ERROR", e.message, null)
                    }
                }
                "stopService" -> {
                    if (quranBound && quranMediaService != null) {
                         quranMediaService?.stopAudio()
                    }
                    if (quranBound) {
                        unbindService(quranConnection)
                        quranBound = false
                    }
                    val intent = Intent(this, QuranMediaService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "updatePlaybackState" -> {
                    val state = call.argument<Number>("state")?.toInt() ?: 0
                    quranMediaService?.updatePlaybackState(state)
                    result.success(true)
                }
                "updateMetadata" -> {
                    val title = call.argument<String>("title") ?: ""
                    val surahName = call.argument<String>("surahName") ?: ""
                    val ayahNumber = call.argument<Int>("ayahNumber") ?: 0
                    val duration = call.argument<Number>("duration")?.toLong() ?: 0L
                    quranMediaService?.updateMetadata(title, surahName, ayahNumber, duration)
                    result.success(true)
                }
                "updatePosition" -> {
                    val position = call.argument<Number>("position")?.toLong() ?: 0L
                    quranMediaService?.updatePosition(position)
                    result.success(true)
                }
                "activateMediaSession" -> {
                    quranMediaService?.activateMediaSession()
                    result.success(true)
                }
                "deactivateMediaSession" -> {
                    quranMediaService?.deactivateMediaSession()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Kuran Medya Callback Kanalı
        quranMediaCallbackChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QURAN_MEDIA_CALLBACK_CHANNEL)
        quranMediaCallbackChannel?.setMethodCallHandler { _, result ->
             // Callback işlemleri
             result.success(null)
        }
        
        // Kuran Medya Genel Kanalı
        quranMediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QURAN_MEDIA_CHANNEL)
        
        // Intent'ten gelen action'ı işle
        intent?.let { handleIntent(it) }
    }

    private fun updateWidget() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val thisWidget = ComponentName(this, PrayerTimesWidget::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
        
        val intent = Intent(this, PrayerTimesWidget::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        sendBroadcast(intent)
    }

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as MediaService.LocalBinder
            mediaService = binder.getService()
            bound = true
            
            // MethodChannel'ı servise ilet
            methodChannel?.let { channel ->
                mediaService?.setMethodChannel(channel)
            }
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            bound = false
            mediaService = null
        }
    }
    
    // Quran Service Connection
    private val quranConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as QuranMediaService.LocalBinder
            quranMediaService = binder.getService()
            quranBound = true
            
            // MethodChannel'ı servise ilet
            quranMediaControlsChannel?.let { channel ->
                quranMediaService?.setMethodChannel(channel)
            }
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            quranBound = false
            quranMediaService = null
        }
    }

    override fun onResume() {
        super.onResume()
        isActivityResumed = true
        
        processPendingAction()
        
        handler.postDelayed({
            methodChannel?.invokeMethod("onResume", null)
        }, 300)
        
        // MediaService bağlantı kontrolü
        if (mediaService == null && bound) {
            val intent = Intent(this, MediaService::class.java)
            bindService(intent, connection, Context.BIND_AUTO_CREATE)
        }
        
        // QuranMediaService bağlantı kontrolü
        if (quranMediaService == null && quranBound) {
            val intent = Intent(this, QuranMediaService::class.java)
            bindService(intent, quranConnection, Context.BIND_AUTO_CREATE)
        }
    }
    
    override fun onPause() {
        super.onPause()
        isActivityResumed = false
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        setIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        try {
            val action = intent.getStringExtra("action")
            if (action != null) {
                Log.d("MainActivity", "Alınan intent action: $action")
                
                Handler(Looper.getMainLooper()).postDelayed({
                    when (action) {
                        "next_page" -> flutterMethodChannel?.invokeMethod("next", null)
                        "previous_page" -> flutterMethodChannel?.invokeMethod("previous", null)
                        "toggle_play" -> flutterMethodChannel?.invokeMethod("togglePlay", null)
                    }
                }, 300) 
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Intent işleme hatası: ${e.message}")
        }
    }
    
    private fun processPendingAction() {
        if (pendingAction == null) {
            return
        }
        
        isProcessingAction = false
        
        try {
            isProcessingAction = true
            
            when (pendingAction) {
                "next_page" -> {
                    methodChannel?.invokeMethod("next", null)
                    handler.postDelayed({
                        isProcessingAction = false
                        pendingAction = null
                    }, 300)
                }
                "previous_page" -> {
                    methodChannel?.invokeMethod("previous", null)
                    handler.postDelayed({
                        isProcessingAction = false
                        pendingAction = null
                    }, 300)
                }
                else -> {
                    isProcessingAction = false
                    pendingAction = null
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Sayfa değişim komutu işleme hatası: ${e.message}")
            isProcessingAction = false
            pendingAction = null
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        
        if (bound) {
            mediaService?.stopAudio()
            unbindService(connection)
            bound = false
        }
        
        if (quranBound) {
            quranMediaService?.stopAudio()
            unbindService(quranConnection)
            quranBound = false
        }
        
        val intent = Intent(this, MediaService::class.java)
        stopService(intent)
        
        val quranIntent = Intent(this, QuranMediaService::class.java)
        stopService(quranIntent)
        
        super.onDestroy()
    }
}
