package com.afaruk59.namaz_vakti_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.session.MediaButtonReceiver
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class MediaService : Service() {
    private val binder = LocalBinder()
    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var stateBuilder: PlaybackStateCompat.Builder
    private lateinit var notificationManager: NotificationManager
    private var executor: ScheduledExecutorService? = null
    private var methodChannel: MethodChannel? = null
    private var isPlaying = false
    private var bookTitle = ""
    private var bookAuthor = ""
    private var bookCoverUrl = ""
    private var duration: Long = 0
    private var position: Long = 0
    private lateinit var packageManager: PackageManager

    companion object {
        private const val NOTIFICATION_ID = 2
        private const val CHANNEL_ID = "media_playback_channel"
        private const val MEDIA_SESSION_TAG = "kitap_oku_media_session"
        var methodChannel: MethodChannel? = null
    }

    inner class LocalBinder : Binder() {
        fun getService(): MediaService = this@MediaService
    }

    override fun onCreate() {
        super.onCreate()
        
        // Önce packageManager'ı başlat
        packageManager = getPackageManager()
        
        // Bildirim kanalı oluştur
        createNotificationChannel()
        
        // MediaSession oluştur
        mediaSession = MediaSessionCompat(this, MEDIA_SESSION_TAG).apply {
            // MediaSession'ı aktif et
            isActive = true
            
            // Ana aktiviteye dönüş için PendingIntent oluştur
            val activityIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
                intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                PendingIntent.getActivity(this@MediaService, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            
            // MediaSession'a aktivite intent'ini ayarla
            setSessionActivity(activityIntent)
            
            // MediaButtonReceiver için PendingIntent oluştur
            val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
            mediaButtonIntent.setClass(this@MediaService, MediaButtonReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this@MediaService, 0, mediaButtonIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setMediaButtonReceiver(pendingIntent)
        }
        
        // MediaSession callback'leri ayarla
        mediaSession.setCallback(object : MediaSessionCompat.Callback() {
            override fun onPlay() {
                try {
                    methodChannel?.invokeMethod("play", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
                } catch (e: Exception) {
                    android.util.Log.e("MediaService", "onPlay error: ${e.message}")
                    // Hata durumunda güvenli bir şekilde durumu güncelle
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }

            override fun onPause() {
                try {
                    methodChannel?.invokeMethod("pause", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                } catch (e: Exception) {
                    android.util.Log.e("MediaService", "onPause error: ${e.message}")
                    // Hata durumunda güvenli bir şekilde durumu güncelle
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }

            override fun onStop() {
                try {
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                } catch (e: Exception) {
                    android.util.Log.e("MediaService", "onStop error: ${e.message}")
                    // Hata durumunda güvenli bir şekilde durumu güncelle
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                }
            }

            override fun onSkipToNext() {
                try {
                    // Sayfa sınırlarını SharedPreferences'tan kontrol et
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val bookCode = prefs.getString("flutter.playing_book_code", "") ?: ""
                    val currentPage = prefs.getInt("flutter.${bookCode}_current_audio_page", 0)
                    val lastPage = prefs.getInt("flutter.${bookCode}_last_page", 9999)
                    
                    // Son sayfada olup olmadığımızı kontrol et
                    if (currentPage >= lastPage) {
                        android.util.Log.d("MediaService", "Son sayfadayız, sonraki sayfaya geçilemez")
                        // Kullanıcıya geri bildirim ver - durumu güncelle ama sayfa değiştirme
                        updatePlaybackState(if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED)
                        return
                    }
                    
                    // Sayfa değişim komutunu işle ve Flutter uygulamasını ön plana getir
                    val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("action", "next_page")
                    }
                    
                    // Kullanıcıya hemen geri bildirim vermek için playback state'i güncelle
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                    
                    // Uygulamayı ön plana getir, komutu MainActivity'de işle
                    if (intent != null) {
                        try {
                            startActivity(intent)
                        } catch (e: Exception) {
                            android.util.Log.e("MediaService", "Uygulamayı ön plana getirme hatası: ${e.message}")
                            // Uygulama ön plana getirilemezse doğrudan method channel üzerinden çağır
                            methodChannel?.invokeMethod("next", null)
                        }
                    } else {
                        // Intent oluşturulamadıysa doğrudan method channel üzerinden çağır
                        methodChannel?.invokeMethod("next", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MediaService", "Sonraki sayfa kontrol hatası: ${e.message}")
                    // Hata durumunda normal işleme devam et
                    methodChannel?.invokeMethod("next", null)
                }
            }

            override fun onSkipToPrevious() {
                try {
                    // Sayfa sınırlarını SharedPreferences'tan kontrol et
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val bookCode = prefs.getString("flutter.playing_book_code", "") ?: ""
                    val currentPage = prefs.getInt("flutter.${bookCode}_current_audio_page", 0)
                    val firstPage = prefs.getInt("flutter.${bookCode}_first_page", 1)
                    
                    // İlk sayfada olup olmadığımızı kontrol et
                    if (currentPage <= firstPage) {
                        android.util.Log.d("MediaService", "İlk sayfadayız, önceki sayfaya geçilemez")
                        // Kullanıcıya geri bildirim ver - durumu güncelle ama sayfa değiştirme
                        updatePlaybackState(if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED)
                        return
                    }
                    
                    // Sayfa değişim komutunu işle ve Flutter uygulamasını ön plana getir
                    val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("action", "previous_page")
                    }
                    
                    // Kullanıcıya hemen geri bildirim vermek için playback state'i güncelle
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                    
                    // Uygulamayı ön plana getir, komutu MainActivity'de işle
                    if (intent != null) {
                        try {
                            startActivity(intent)
                        } catch (e: Exception) {
                            android.util.Log.e("MediaService", "Uygulamayı ön plana getirme hatası (previous): ${e.message}")
                            // Uygulama ön plana getirilemezse doğrudan method channel üzerinden çağır
                            methodChannel?.invokeMethod("previous", null)
                        }
                    } else {
                        // Intent oluşturulamadıysa doğrudan method channel üzerinden çağır
                        methodChannel?.invokeMethod("previous", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MediaService", "Önceki sayfa kontrol hatası: ${e.message}")
                    // Hata durumunda normal işleme devam et
                    methodChannel?.invokeMethod("previous", null)
                }
            }

            override fun onSeekTo(pos: Long) {
                methodChannel?.invokeMethod("seekTo", pos.toInt())
                position = pos
                updatePlaybackState(if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED)
            }
        })

        // Playback state builder oluştur
        stateBuilder = PlaybackStateCompat.Builder()
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_PLAY_PAUSE or
                PlaybackStateCompat.ACTION_STOP or
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                PlaybackStateCompat.ACTION_SEEK_TO
            )
        
        mediaSession.setPlaybackState(stateBuilder.build())
        
        // Bildirim yöneticisini al
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        MediaButtonReceiver.handleIntent(mediaSession, intent)

        // Sadece ses çalarken veya duraklatılmışken bildirim göster
        try {
            val playbackState = mediaSession.controller.playbackState?.state
            if (isPlaying || playbackState == PlaybackStateCompat.STATE_PAUSED) {
                updateNotification()
            } else {
                // Bildirimi kaldır
                stopForeground(true)
                notificationManager.cancel(NOTIFICATION_ID)
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaService", "Servis başlatma hatası: ${e.message}")
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onDestroy() {
        stopForeground(true)
        mediaSession.release()
        executor?.shutdown()
        // Handler callback'lerini temizle
        Handler(Looper.getMainLooper()).removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopAudio()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    fun setMethodChannel(channel: MethodChannel) {
        methodChannel = channel
    }

    fun updatePlaybackState(state: Int) {
        isPlaying = state == PlaybackStateCompat.STATE_PLAYING
        
        // Yeni durumu ayarla
        stateBuilder.setState(state, position, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        // Bildirim güncelle veya kaldır
        if (state == PlaybackStateCompat.STATE_STOPPED) {
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
        } else {
            updateNotification()
            // Kısa bir gecikme ile tekrar güncelle
            Handler(Looper.getMainLooper()).postDelayed({
                if (stateBuilder.build().state == state) {
                    updateNotification()
                }
            }, 300)
        }
    }

    fun stopAudio() {
        android.util.Log.d("MediaService", "stopAudio called. isPlaying: $isPlaying")
        isPlaying = false
        stopPositionUpdates()
        
        // Önce bildirimi güncelle
        val stateBuilder = PlaybackStateCompat.Builder()
            .setState(PlaybackStateCompat.STATE_STOPPED, 0, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        // Sonra bildirimi kaldır
        stopForeground(true)
        notificationManager.cancel(NOTIFICATION_ID)
    }

    fun updateMetadata(title: String, author: String, coverUrl: String, durationMs: Long) {
        bookTitle = title
        bookAuthor = author
        bookCoverUrl = coverUrl
        duration = durationMs
        
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, author)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Kitap Oku")
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
        
        // Varsayılan bir bitmap kullan
        val bitmap = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, bitmap)
        
        mediaSession.setMetadata(metadataBuilder.build())
        
        // Bildirim hemen güncelle
        updateNotification()
        
        // Bildirim içeriğinin doğru görünmesi için kısa bir gecikme ile tekrar güncelle
        Handler(Looper.getMainLooper()).postDelayed({
            updateNotification()
        }, 500)
    }

    fun updatePosition(positionMs: Long) {
        position = positionMs
        
        // Playback state'i güncelle - pozisyon bilgisini içerecek şekilde
        stateBuilder.setState(
            if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED, 
            position, 
            1.0f
        )
        mediaSession.setPlaybackState(stateBuilder.build())
        
        // Bildirim güncelle
        updateNotification()
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        executor = Executors.newSingleThreadScheduledExecutor()
        executor?.scheduleAtFixedRate({
            methodChannel?.invokeMethod("getPosition", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (result is Number) {
                        position = result.toLong()
                        stateBuilder.setState(PlaybackStateCompat.STATE_PLAYING, position, 1.0f)
                        mediaSession.setPlaybackState(stateBuilder.build())
                    }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    // Hata durumunda yapılacak işlemler
                }

                override fun notImplemented() {
                    // Metod uygulanmamışsa yapılacak işlemler
                }
            })
        }, 0, 1, TimeUnit.SECONDS)
    }

    private fun stopPositionUpdates() {
        executor?.shutdown()
        executor = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kitap Oku Medya Oynatma",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Kitap Oku uygulaması için medya oynatma bildirimleri"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun updateNotification() {
        val controller = mediaSession.controller
        val mediaMetadata = controller.metadata
        val playbackState = controller.playbackState

        // Eğer durdurulmuşsa veya hiç çalma durumu yoksa bildirim gösterme
        if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
            return
        }

        // Ana aktiviteye dönüş için PendingIntent
        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            // Medya kontrollerini ekle
            setContentTitle(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_TITLE) ?: bookTitle)
            setContentText(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_ARTIST) ?: bookAuthor)
            setSubText("Kitap Oku")
            setLargeIcon(mediaMetadata?.getBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART))
            setSmallIcon(R.mipmap.ic_launcher)
            setContentIntent(contentIntent ?: controller.sessionActivity)
            setDeleteIntent(MediaButtonReceiver.buildMediaButtonPendingIntent(this@MediaService, PlaybackStateCompat.ACTION_STOP))
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            setOngoing(true) // Bildirimi kalıcı yap
            
            // Medya stil
            setStyle(androidx.media.app.NotificationCompat.MediaStyle()
                .setMediaSession(mediaSession.sessionToken)
                .setShowActionsInCompactView(0, 1, 2)
                .setShowCancelButton(true)
                .setCancelButtonIntent(MediaButtonReceiver.buildMediaButtonPendingIntent(this@MediaService, PlaybackStateCompat.ACTION_STOP)))
            
            // Önceki düğmesi
            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_previous,
                    "Önceki",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(this@MediaService, PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS)
                )
            )
            
            // Oynat/Duraklat düğmesi
            val playPauseIcon = if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING)
                android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            val playPauseAction = if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING)
                PlaybackStateCompat.ACTION_PAUSE else PlaybackStateCompat.ACTION_PLAY
            addAction(
                NotificationCompat.Action(
                    playPauseIcon,
                    if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING) "Duraklat" else "Oynat",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(this@MediaService, playPauseAction)
                )
            )
            
            // Sonraki düğmesi
            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_next,
                    "Sonraki",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(this@MediaService, PlaybackStateCompat.ACTION_SKIP_TO_NEXT)
                )
            )
        }

        val notification = builder.build()
        
        // Bildirim içeriğini göster
        try {
            if (isPlaying || playbackState?.state == PlaybackStateCompat.STATE_PAUSED) {
                startForeground(NOTIFICATION_ID, notification)
            } else if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
                stopForeground(true) // Remove notification and detach service from foreground
                notificationManager.cancel(NOTIFICATION_ID) // Explicitly cancel the notification
            } else {
                // For other states like BUFFERING, ERROR, etc., keep the notification but don't start foreground if not playing/paused
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaService", "Bildirim gösterme hatası: ${e.message}")
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun getMediaSession(): MediaSessionCompat {
        return mediaSession
    }
}