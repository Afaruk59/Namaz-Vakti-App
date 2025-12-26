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

class MainActivity : FlutterActivity() {
    companion object {
        private const val WIDGET_CHANNEL = "com.afaruk59.namaz_vakti_app/widget"
        private const val NOTIFICATION_CHANNEL = "com.afaruk59.namaz_vakti_app/notifications"
    }
    private val CHANNEL = "com.afaruk59.namaz_vakti_app/media_controls"
    private val FLUTTER_CHANNEL = "com.afaruk59.namaz_vakti_app/media_service"
    private val CHANNEL_QURAN_MEDIA_CONTROLS = "com.afaruk59.namaz_vakti_app/quran_media_controls"
    private val CHANNEL_QURAN_MEDIA_CALLBACK = "com.afaruk59.namaz_vakti_app/quran_media_callback"
    private val CHANNEL_BOOK_MEDIA_CONTROLS = "com.afaruk59.namaz_vakti_app/book_media_controls"
    private val CHANNEL_BOOK_MEDIA_CALLBACK = "com.afaruk59.namaz_vakti_app/book_media_callback"
    private var mediaService: MediaService? = null
    private var quranMediaService: QuranMediaService? = null
    private var bookMediaService: BookMediaService? = null
    private var methodChannel: MethodChannel? = null
    private var flutterMethodChannel: MethodChannel? = null
    private var quranMethodChannel: MethodChannel? = null
    private var bookMethodChannel: MethodChannel? = null
    private var bound = false
    private var quranBound = false
    private var bookBound = false
    private var pendingAction: String? = null
    private var isActivityResumed = false
    private var isProcessingAction = false
    // Handler memory leak riskini önlemek için WeakReference kullanılabilir
    // Ancak Activity context'i gerekli olmadığı için static Handler güvenli
    private val handler = Handler(Looper.getMainLooper())
    
    // Debounce için değişkenler
    private var lastPlaybackState = -1
    private var lastPosition = -1L
    private var lastMetadataUpdate = 0L
    private val metadataDebounceDelay = 500L

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

            // Use background execution to ensure method calls work when app is in background
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val intent = Intent(this, MediaService::class.java)
                        bindService(intent, connection, Context.BIND_AUTO_CREATE)
                        startService(intent)
                        
                        // Servis başlatıldıktan sonra kısa bir gecikme ile onResume metodunu çağır
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
                    // Önce aktif servise stopAudio komutu gönder
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
                    
                    // Metadata güncellendikten sonra kısa bir gecikme ile tekrar güncelle
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
        
        // MediaService'den gelen bildirimler için Flutter ile iletişim kurulumu
        flutterMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLUTTER_CHANNEL)
        flutterMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initMediaService" -> {
                    // MediaService ile iletişim için Method Channel'ı kaydet
                    MediaService.methodChannel = flutterMethodChannel
                    result.success(null)
                }
                "audio_completed" -> {
                    // Ses tamamlandığında Flutter'a "next" komutunu gönder
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
                    // Ses hatası durumunda Flutter'a hata bildirimi gönder
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
                    // Şu anki ses sayfasını al
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val bookCode = prefs.getString("flutter.playing_book_code", "") ?: ""
                    val currentPage = prefs.getInt("flutter.${bookCode}_current_audio_page", 0)
                    result.success(currentPage)
                }
                "updateAudioPageState" -> {
                    // Ses sayfası durumunu güncelle
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
        
        // Quran media controls channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_QURAN_MEDIA_CONTROLS)
            .setMethodCallHandler { call, result ->
                handleQuranMediaControls(call, result)
            }
        
        // Book media controls channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BOOK_MEDIA_CONTROLS)
            .setMethodCallHandler { call, result ->
                handleBookMediaControls(call, result)
            }
        
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
    
    private val quranConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as QuranMediaService.LocalBinder
            quranMediaService = binder.getService()
            quranBound = true
            
            Log.d("MainActivity", "QuranMediaService connected successfully")
            
            // MethodChannel'ı servise ilet
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val methodChannel = MethodChannel(messenger, CHANNEL_QURAN_MEDIA_CALLBACK)
                quranMediaService?.setMethodChannel(methodChannel)
                Log.d("MainActivity", "MethodChannel set to QuranMediaService")
            }
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            quranBound = false
            quranMediaService = null
            Log.d("MainActivity", "QuranMediaService disconnected")
        }
    }
    
    private val bookConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as BookMediaService.LocalBinder
            bookMediaService = binder.getService()
            bookBound = true
            
            Log.d("MainActivity", "BookMediaService connected successfully")
            
            // MethodChannel'ı servise ilet
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val methodChannel = MethodChannel(messenger, CHANNEL_BOOK_MEDIA_CALLBACK)
                bookMediaService?.setMethodChannel(methodChannel)
                Log.d("MainActivity", "MethodChannel set to BookMediaService")
            }
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            bookBound = false
            bookMediaService = null
            Log.d("MainActivity", "BookMediaService disconnected")
        }
    }

    
    override fun onResume() {
        super.onResume()
        isActivityResumed = true
        
        // Bekleyen action'ı işle
        processPendingAction()
        
        // Uygulama ön plana geldiğinde Flutter'a bildir
        // Bu, medya kontrollerinin güncellenmesini sağlar
        handler.postDelayed({
            methodChannel?.invokeMethod("onResume", null)
        }, 300)
        
        // Servis bağlantısını kontrol et ve gerekirse yeniden bağlan
        if (mediaService == null && bound) {
            // Servis bağlantısını yeniden kur
            val intent = Intent(this, MediaService::class.java)
            bindService(intent, connection, Context.BIND_AUTO_CREATE)
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
                
                // Sayfa değişikliklerinde yeni bir Handler kullanarak Flutter'a bildir
                Handler(Looper.getMainLooper()).postDelayed({
                    when (action) {
                        "next_page" -> flutterMethodChannel?.invokeMethod("next", null)
                        "previous_page" -> flutterMethodChannel?.invokeMethod("previous", null)
                        "toggle_play" -> flutterMethodChannel?.invokeMethod("togglePlay", null)
                    }
                }, 300) // Kısa bir gecikme ile UI'ın hazır olmasını bekle
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Intent işleme hatası: ${e.message}")
        }
    }
    
    private fun processPendingAction() {
        if (pendingAction == null) {
            return
        }
        
        // İşlem zaten devam ediyorsa ve yeni bir istek geldiyse, önceki işlemi iptal et
        isProcessingAction = false
        
        try {
            isProcessingAction = true
            
            when (pendingAction) {
                "next_page" -> {
                    // Sayfa değişim komutunu hemen işle
                    methodChannel?.invokeMethod("next", null)
                    
                    // Kısa bir gecikme ekleyerek UI'ın güncellenmesini bekle
                    handler.postDelayed({
                        isProcessingAction = false
                        pendingAction = null
                    }, 300)
                }
                "previous_page" -> {
                    // Sayfa değişim komutunu hemen işle
                    methodChannel?.invokeMethod("previous", null)
                    
                    // Kısa bir gecikme ekleyerek UI'ın güncellenmesini bekle
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
        // Handler callback'lerini temizle (memory leak önleme)
        handler.removeCallbacksAndMessages(null)
        
        if (bound) {
            mediaService?.stopAudio()
            unbindService(connection)
            bound = false
        }
        val intent = Intent(this, MediaService::class.java)
        stopService(intent)
        
        if (quranBound) {
            quranMediaService?.stopAudio()
            unbindService(quranConnection)
            quranBound = false
        }
        val quranIntent = Intent(this, QuranMediaService::class.java)
        stopService(quranIntent)
        
        if (bookBound) {
            bookMediaService?.stopAudio()
            unbindService(bookConnection)
            bookBound = false
        }
        val bookIntent = Intent(this, BookMediaService::class.java)
        stopService(bookIntent)
        
        super.onDestroy()
    }
    
    // Quran media controls handler
    private fun handleQuranMediaControls(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        when (call.method) {
            "startService" -> {
                startQuranMediaService()
                result.success(true)
            }
            "stopService" -> {
                stopQuranMediaService()
                result.success(true)
            }
            "updatePlaybackState" -> {
                val state = call.argument<Int>("state") ?: 0
                updateQuranPlaybackState(state)
                result.success(true)
            }
            "updateMetadata" -> {
                val title = call.argument<String>("title") ?: ""
                val surahName = call.argument<String>("surahName") ?: ""
                val ayahNumber = call.argument<Int>("ayahNumber") ?: 0
                val duration = call.argument<Number>("duration")?.toLong() ?: 0L
                updateQuranMetadata(title, surahName, ayahNumber, duration)
                result.success(true)
            }
            "updatePosition" -> {
                val position = call.argument<Number>("position")?.toLong() ?: 0L
                updateQuranPosition(position)
                result.success(true)
            }
            "stopAudio" -> {
                stopQuranAudio()
                result.success(true)
            }
            "initMediaService" -> {
                startQuranMediaService()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
    
    // Quran Media Service Methods
    private fun startQuranMediaService() {
        try {
            Log.d("MainActivity", "Starting quran media service")
            
            // Önce Book MediaSession'ını deaktive et (eğer varsa)
            if (bound) {
                mediaService?.stopAudio()
            }
            
            val intent = Intent(this, QuranMediaService::class.java)
            bindService(intent, quranConnection, Context.BIND_AUTO_CREATE)
            startService(intent)
            
            // Quran MediaSession'ını aktive et
            Handler(Looper.getMainLooper()).postDelayed({
                if (quranBound) {
                    quranMediaService?.activateMediaSession()
                }
            }, 500)
            
            Log.d("MainActivity", "Quran media service started")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error starting quran media service: ${e.message}")
        }
    }
    
    private fun stopQuranMediaService() {
        try {
            Log.d("MainActivity", "Stopping quran media service")
            if (quranBound) {
                quranMediaService?.stopAudio()
                unbindService(quranConnection)
                quranBound = false
            }
            val intent = Intent(this, QuranMediaService::class.java)
            stopService(intent)
            Log.d("MainActivity", "Quran media service stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping quran media service: ${e.message}")
        }
    }
    
    private fun updateQuranPlaybackState(state: Int) {
        try {
            if (lastPlaybackState != state) {
                Log.d("MainActivity", "Updating quran playback state: $state")
                if (quranBound) {
                    quranMediaService?.updatePlaybackState(state)
                }
                lastPlaybackState = state
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating quran playback state: ${e.message}")
        }
    }
    
    private fun updateQuranMetadata(title: String, surahName: String, ayahNumber: Int, duration: Long) {
        try {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastMetadataUpdate > metadataDebounceDelay) {
                Log.d("MainActivity", "Updating quran metadata: $title - $surahName:$ayahNumber")
                if (quranBound) {
                    quranMediaService?.updateMetadata(title, surahName, ayahNumber, duration)
                }
                lastMetadataUpdate = currentTime
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating quran metadata: ${e.message}")
        }
    }
    
    private fun updateQuranPosition(position: Long) {
        try {
            if (kotlin.math.abs(position - lastPosition) > 1000) {
                Log.d("MainActivity", "Updating quran position: $position")
                if (quranBound) {
                    quranMediaService?.updatePosition(position)
                }
                lastPosition = position
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating quran position: ${e.message}")
        }
    }
    
    private fun stopQuranAudio() {
        try {
            Log.d("MainActivity", "Stopping quran audio")
            if (quranBound) {
                quranMediaService?.stopAudio()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping quran audio: ${e.message}")
        }
    }
    
    // Book media controls handler
    private fun handleBookMediaControls(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        when (call.method) {
            "startService" -> {
                startBookMediaService()
                result.success(true)
            }
            "stopService" -> {
                stopBookMediaService()
                result.success(true)
            }
            "updatePlaybackState" -> {
                val state = call.argument<Int>("state") ?: 0
                updateBookPlaybackState(state)
                result.success(true)
            }
            "updateMetadata" -> {
                val title = call.argument<String>("title") ?: ""
                val author = call.argument<String>("author") ?: ""
                val coverUrl = call.argument<String>("coverUrl") ?: ""
                val duration = call.argument<Number>("duration")?.toLong() ?: 0L
                updateBookMetadata(title, author, coverUrl, duration)
                result.success(true)
            }
            "updatePosition" -> {
                val position = call.argument<Number>("position")?.toLong() ?: 0L
                updateBookPosition(position)
                result.success(true)
            }
            "updateAudioPageState" -> {
                val bookCode = call.argument<String>("bookCode") ?: ""
                val currentPage = call.argument<Int>("currentPage") ?: 0
                val firstPage = call.argument<Int>("firstPage") ?: 1
                val lastPage = call.argument<Int>("lastPage") ?: 9999
                updateBookPageState(bookCode, currentPage, firstPage, lastPage)
                result.success(true)
            }
            "stopAudio" -> {
                stopBookAudio()
                result.success(true)
            }
            "initMediaService" -> {
                startBookMediaService()
                result.success(true)
            }
            "clearQuranHandler" -> {
                // Book media için Quran handler temizleme - boş bırak
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
    
    // Book Media Service Methods
    private fun startBookMediaService() {
        try {
            Log.d("MainActivity", "Starting book media service")
            
            // Önce Quran MediaSession'ını deaktive et (eğer varsa)
            if (quranBound) {
                quranMediaService?.stopAudio()
            }
            
            val intent = Intent(this, BookMediaService::class.java)
            bindService(intent, bookConnection, Context.BIND_AUTO_CREATE)
            startService(intent)
            
            // Book MediaSession'ını aktive et
            Handler(Looper.getMainLooper()).postDelayed({
                if (bookBound) {
                    bookMediaService?.activateMediaSession()
                }
            }, 500)
            
            Log.d("MainActivity", "Book media service started")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error starting book media service: ${e.message}")
        }
    }
    
    private fun stopBookMediaService() {
        try {
            Log.d("MainActivity", "Stopping book media service")
            if (bookBound) {
                bookMediaService?.stopAudio()
                unbindService(bookConnection)
                bookBound = false
            }
            val intent = Intent(this, BookMediaService::class.java)
            stopService(intent)
            Log.d("MainActivity", "Book media service stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping book media service: ${e.message}")
        }
    }
    
    private fun updateBookPlaybackState(state: Int) {
        try {
            Log.d("MainActivity", "Updating book playback state: $state")
            if (bookBound) {
                bookMediaService?.updatePlaybackState(state)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating book playback state: ${e.message}")
        }
    }
    
    private fun updateBookMetadata(title: String, author: String, coverUrl: String, duration: Long) {
        try {
            Log.d("MainActivity", "Updating book metadata: $title - $author")
            if (bookBound) {
                bookMediaService?.updateMetadata(title, author, coverUrl, duration)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating book metadata: ${e.message}")
        }
    }
    
    private fun updateBookPosition(position: Long) {
        try {
            if (bookBound) {
                bookMediaService?.updatePosition(position)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating book position: ${e.message}")
        }
    }
    
    private fun updateBookPageState(bookCode: String, currentPage: Int, firstPage: Int, lastPage: Int) {
        try {
            Log.d("MainActivity", "Updating book page state: $bookCode, page: $currentPage")
            if (bookBound) {
                bookMediaService?.updatePageState(bookCode, currentPage, firstPage, lastPage)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating book page state: ${e.message}")
        }
    }
    
    private fun stopBookAudio() {
        try {
            Log.d("MainActivity", "Stopping book audio")
            if (bookBound) {
                bookMediaService?.stopAudio()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping book audio: ${e.message}")
        }
    }
}