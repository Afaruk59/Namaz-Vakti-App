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

class MainActivity : FlutterActivity() {
    companion object {
        private const val WIDGET_CHANNEL = "com.afaruk59.namaz_vakti_app/widget"
        private const val NOTIFICATION_CHANNEL = "com.afaruk59.namaz_vakti_app/notifications"
        
    }
    private val CHANNEL = "com.afaruk59.namaz_vakti_app/media_controls"
    private val FLUTTER_CHANNEL = "com.afaruk59.namaz_vakti_app/media_service"
    private var mediaService: MediaService? = null
    private var methodChannel: MethodChannel? = null
    private var flutterMethodChannel: MethodChannel? = null
    private var bound = false
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
                        
                        if (isNotificationsEnabled) {
                            PrayerNotificationService.startService(context)
                            result.success(true)
                        } else {
                            PrayerNotificationService.stopService(context)
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
                        println("Servis başlatma hatası: ${e.message}")
                        result.error("SERVICE_START_ERROR", e.message, null)
                    }
                }
                "stopService" -> {
                    // Önce aktif servise stopAudio komutu gönder
                    if (bound && mediaService != null) {
                        try {
                            mediaService?.stopAudio()
                        } catch (e: Exception) {
                            println("stopAudio çağrısı hatası: ${e.message}")
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
                    println("MainActivity: Audio completed, sending next command to Flutter")
                    try {
                        flutterMethodChannel?.invokeMethod("next", null)
                        result.success(null)
                    } catch (e: Exception) {
                        println("MainActivity: Audio completed error: ${e.message}")
                        result.error("AUDIO_COMPLETED_ERROR", e.message, null)
                    }
                }
                "audio_error" -> {
                    // Ses hatası durumunda Flutter'a hata bildirimi gönder
                    println("MainActivity: Audio error received")
                    try {
                        flutterMethodChannel?.invokeMethod("audio_error", null)
                        result.success(null)
                    } catch (e: Exception) {
                        println("MainActivity: Audio error notification error: ${e.message}")
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
        
        // Intent'ten gelen action'ı işle
        intent?.let { handleIntent(it) }
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
                println("MainActivity: Alınan intent action: $action")
                
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
            println("Intent işleme hatası: ${e.message}")
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
            println("Sayfa değişim komutu işleme hatası: ${e.message}")
            isProcessingAction = false
            pendingAction = null
        }
    }

    override fun onDestroy() {
        if (bound) {
            mediaService?.stopAudio()
            unbindService(connection)
            bound = false
        }
        val intent = Intent(this, MediaService::class.java)
        stopService(intent)
        super.onDestroy()
    }

}