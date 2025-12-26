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
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class BookMediaService : Service() {
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
        private const val CHANNEL_ID = "book_media_playback_channel"
        private const val MEDIA_SESSION_TAG = "prayertimes_book_media_session"
    }

    inner class LocalBinder : Binder() {
        fun getService(): BookMediaService = this@BookMediaService
    }

    override fun onCreate() {
        super.onCreate()
        
        println("BookMediaService: Service created")
        
        // Önce packageManager'ı başlat
        packageManager = getPackageManager()
        
        // Bildirim kanalı oluştur
        createNotificationChannel()
        println("BookMediaService: Notification channel created")
        
        // MediaSession oluştur
        mediaSession = MediaSessionCompat(this, MEDIA_SESSION_TAG).apply {
            // MediaSession'ı aktif et
            isActive = true
            
            // Ana aktiviteye dönüş için PendingIntent oluştur
            val activityIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
                intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                PendingIntent.getActivity(this@BookMediaService, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            
            // MediaSession'a aktivite intent'ini ayarla
            setSessionActivity(activityIntent)
            
            // MediaButtonReceiver için PendingIntent oluştur
            val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
            val pendingIntent = PendingIntent.getBroadcast(
                this@BookMediaService, 0, mediaButtonIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setMediaButtonReceiver(pendingIntent)
        }
        
        // MediaSession callback'leri ayarla
        setupMediaSessionCallbacks()

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
        
        println("BookMediaService: Service initialization completed successfully")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val playbackState = mediaSession.controller.playbackState?.state
            if (isPlaying || playbackState == PlaybackStateCompat.STATE_PAUSED) {
                updateNotification()
            } else {
                stopForeground(true)
                notificationManager.cancel(NOTIFICATION_ID)
            }
        } catch (e: Exception) {
            println("Servis başlatma hatası: ${e.message}")
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
        
        println("BookMediaService: updatePlaybackState called with state=$state, isPlaying=$isPlaying")
        
        stateBuilder.setState(state, position, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        if (state == PlaybackStateCompat.STATE_STOPPED) {
            println("BookMediaService: State is STOPPED, removing notification")
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
        } else {
            println("BookMediaService: Updating notification for state=$state")
            updateNotification()
            Handler(Looper.getMainLooper()).postDelayed({
                if (stateBuilder.build().state == state) {
                    updateNotification()
                }
            }, 300)
        }
    }

    fun stopAudio() {
        println("BookMediaService: stopAudio called. isPlaying: $isPlaying")
        isPlaying = false
        stopPositionUpdates()
        
        val stateBuilder = PlaybackStateCompat.Builder()
            .setState(PlaybackStateCompat.STATE_STOPPED, 0, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        stopForeground(true)
        notificationManager.cancel(NOTIFICATION_ID)
    }

    fun updateMetadata(title: String, author: String, coverUrl: String, durationMs: Long) {
        bookTitle = title
        bookAuthor = author
        bookCoverUrl = coverUrl
        duration = durationMs
        
        println("BookMediaService: updateMetadata called - title=$title, author=$author, duration=$durationMs")
        
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, author)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Prayer Times Books")
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
        
        val bitmap = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, bitmap)
        
        mediaSession.setMetadata(metadataBuilder.build())
        
        println("BookMediaService: Calling updateNotification after metadata update")
        updateNotification()
        
        Handler(Looper.getMainLooper()).postDelayed({
            updateNotification()
        }, 500)
    }

    fun updatePosition(positionMs: Long) {
        position = positionMs
        
        stateBuilder.setState(
            if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED, 
            position, 
            1.0f
        )
        mediaSession.setPlaybackState(stateBuilder.build())
        
        updateNotification()
    }
    
    fun updatePageState(bookCode: String, currentPage: Int, firstPage: Int, lastPage: Int) {
        println("BookMediaService: updatePageState - Book: $bookCode, Page: $currentPage/$lastPage")
        // Bu bilgileri MediaSession'a ekleyebiliriz veya başka bir yerde kullanabiliriz
        // Şimdilik sadece log'layalım
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
                }

                override fun notImplemented() {
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
                "Prayer Times Kitap Oynatma",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Prayer Times uygulaması için kitap oynatma bildirimleri"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun updateNotification() {
        println("BookMediaService: updateNotification called. isPlaying=$isPlaying")
        
        val controller = mediaSession.controller
        val mediaMetadata = controller.metadata
        val playbackState = controller.playbackState
        
        println("BookMediaService: playbackState=${playbackState?.state}, title=${mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_TITLE)}")

        if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
            println("BookMediaService: State is STOPPED or NONE, not showing notification")
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
            return
        }

        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_TITLE) ?: bookTitle)
            setContentText(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_ARTIST) ?: bookAuthor)
            setSubText("Prayer Times Kitap")
            setLargeIcon(mediaMetadata?.getBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART))
            setSmallIcon(R.mipmap.ic_launcher)
            setContentIntent(contentIntent ?: controller.sessionActivity)
            setDeleteIntent(createMediaButtonPendingIntent(PlaybackStateCompat.ACTION_STOP))
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            setOngoing(true)
            
            setStyle(androidx.media.app.NotificationCompat.MediaStyle()
                .setMediaSession(mediaSession.sessionToken)
                .setShowActionsInCompactView(0, 1, 2)
                .setShowCancelButton(true)
                .setCancelButtonIntent(createMediaButtonPendingIntent(PlaybackStateCompat.ACTION_STOP)))
            
            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_previous,
                    "Önceki",
                    createMediaButtonPendingIntent(PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS)
                )
            )
            
            val playPauseIcon = if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING)
                android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            val playPauseAction = if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING)
                PlaybackStateCompat.ACTION_PAUSE else PlaybackStateCompat.ACTION_PLAY
            addAction(
                NotificationCompat.Action(
                    playPauseIcon,
                    if (playbackState?.state == PlaybackStateCompat.STATE_PLAYING) "Duraklat" else "Oynat",
                    createMediaButtonPendingIntent(playPauseAction)
                )
            )
            
            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_next,
                    "Sonraki",
                    createMediaButtonPendingIntent(PlaybackStateCompat.ACTION_SKIP_TO_NEXT)
                )
            )
        }

        val notification = builder.build()
        
        println("BookMediaService: Notification built. isPlaying=$isPlaying, playbackState=${playbackState?.state}")
        
        try {
            if (isPlaying || playbackState?.state == PlaybackStateCompat.STATE_PAUSED) {
                println("BookMediaService: Starting foreground service with notification")
                startForeground(NOTIFICATION_ID, notification)
                println("BookMediaService: Foreground service started successfully")
            } else if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
                println("BookMediaService: Stopping foreground and canceling notification")
                stopForeground(true)
                notificationManager.cancel(NOTIFICATION_ID)
            } else {
                println("BookMediaService: Showing notification (not foreground)")
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            println("BookMediaService: Bildirim gösterme hatası: ${e.message}")
            e.printStackTrace()
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun getMediaSession(): MediaSessionCompat {
        return mediaSession
    }
    
    fun activateMediaSession() {
        println("BookMediaService: Activating MediaSession")
        setupMediaSessionCallbacks()
        mediaSession.isActive = true
        println("BookMediaService: MediaSession activated. isActive=${mediaSession.isActive}")
    }
    
    private fun setupMediaSessionCallbacks() {
        mediaSession.setCallback(object : MediaSessionCompat.Callback() {
            override fun onPlay() {
                try {
                    println("🔥🔥🔥 BookMediaService: onPlay called 🔥🔥🔥")
                    val currentState = mediaSession.controller.playbackState?.state
                    println("BookMediaService: Current state before onPlay: $currentState")
                    
                    methodChannel?.invokeMethod("play", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
                } catch (e: Exception) {
                    println("BookMediaService onPlay error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }

            override fun onPause() {
                try {
                    println("🔥🔥🔥 BookMediaService: onPause called 🔥🔥🔥")
                    val currentState = mediaSession.controller.playbackState?.state
                    println("BookMediaService: Current state before onPause: $currentState")
                    
                    methodChannel?.invokeMethod("pause", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                } catch (e: Exception) {
                    println("BookMediaService onPause error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }


            override fun onStop() {
                try {
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                } catch (e: Exception) {
                    println("BookMediaService onStop error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                }
            }

            override fun onSkipToNext() {
                try {
                    println("🔥🔥🔥 BookMediaService: onSkipToNext called 🔥🔥🔥")
                    methodChannel?.invokeMethod("next", null)
                    println("🔥🔥🔥 BookMediaService: next method called via methodChannel 🔥🔥🔥")
                } catch (e: Exception) {
                    println("Sonraki sayfa kontrol hatası: ${e.message}")
                    methodChannel?.invokeMethod("next", null)
                }
            }

            override fun onSkipToPrevious() {
                try {
                    println("BookMediaService: onSkipToPrevious called")
                    methodChannel?.invokeMethod("previous", null)
                    println("BookMediaService: previous method called via methodChannel")
                } catch (e: Exception) {
                    println("Önceki sayfa kontrol hatası: ${e.message}")
                    methodChannel?.invokeMethod("previous", null)
                }
            }

            override fun onSeekTo(pos: Long) {
                methodChannel?.invokeMethod("seekTo", pos.toInt())
                position = pos
                updatePlaybackState(if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED)
            }
        })
    }
    
    fun deactivateMediaSession() {
        println("BookMediaService: Deactivating MediaSession")
        mediaSession.isActive = false
        mediaSession.setCallback(null)
    }
    
    private fun createMediaButtonPendingIntent(action: Long): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
        intent.putExtra(Intent.EXTRA_KEY_EVENT, action)
        return PendingIntent.getBroadcast(
            this, action.toInt(), intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}
