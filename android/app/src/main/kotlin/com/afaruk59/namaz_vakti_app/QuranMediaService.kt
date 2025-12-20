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

class QuranMediaService : Service() {
    private val binder = LocalBinder()
    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var stateBuilder: PlaybackStateCompat.Builder
    private lateinit var notificationManager: NotificationManager
    private var executor: ScheduledExecutorService? = null
    private var methodChannel: MethodChannel? = null
    private var isPlaying = false
    private var quranTitle = ""
    private var surahName = ""
    private var ayahNumber = 0
    private var duration: Long = 0
    private var position: Long = 0
    private lateinit var packageManager: PackageManager

    companion object {
        private const val NOTIFICATION_ID = 3
        private const val CHANNEL_ID = "quran_media_playback_channel"
        private const val MEDIA_SESSION_TAG = "prayertimes_quran_media_session"
        var methodChannel: MethodChannel? = null
    }

    inner class LocalBinder : Binder() {
        fun getService(): QuranMediaService = this@QuranMediaService
    }

    override fun onCreate() {
        super.onCreate()
        
        packageManager = getPackageManager()
        createNotificationChannel()
        
        mediaSession = MediaSessionCompat(this, MEDIA_SESSION_TAG).apply {
            isActive = true
            
            val activityIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
                intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                PendingIntent.getActivity(this@QuranMediaService, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            
            setSessionActivity(activityIntent)
            
            val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
            val pendingIntent = PendingIntent.getBroadcast(
                this@QuranMediaService, 0, mediaButtonIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setMediaButtonReceiver(pendingIntent)
        }
        
        setupMediaSessionCallbacks()

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
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
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
        
        stateBuilder.setState(state, position, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        if (state == PlaybackStateCompat.STATE_STOPPED) {
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
        } else {
            updateNotification()
            Handler(Looper.getMainLooper()).postDelayed({
                if (stateBuilder.build().state == state) {
                    updateNotification()
                }
            }, 300)
        }
    }

    fun stopAudio() {
        println("QuranMediaService: stopAudio called. isPlaying: $isPlaying")
        isPlaying = false
        stopPositionUpdates()
        
        val stateBuilder = PlaybackStateCompat.Builder()
            .setState(PlaybackStateCompat.STATE_STOPPED, 0, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
        
        stopForeground(true)
        notificationManager.cancel(NOTIFICATION_ID)
    }

    fun updateMetadata(title: String, surahName: String, ayahNumber: Int, durationMs: Long) {
        quranTitle = title
        this.surahName = surahName
        this.ayahNumber = ayahNumber
        duration = durationMs
        
        // Ayet numarasını artist alanına ekle
        val artistText = if (ayahNumber > 0) {
            "$surahName:$ayahNumber"
        } else {
            "$surahName - Besmele"
        }
        
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artistText)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Kuran-ı Kerim")
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
        
        val bitmap = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, bitmap)
        
        mediaSession.setMetadata(metadataBuilder.build())
        
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
                "Prayer Times Kuran Oynatma",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Prayer Times uygulaması için Kuran oynatma bildirimleri"
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

        if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
            stopForeground(true)
            notificationManager.cancel(NOTIFICATION_ID)
            return
        }

        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        // Bildirimde gösterilecek artist text'i oluştur
        val notificationArtistText = if (ayahNumber > 0) {
            "$surahName:$ayahNumber"
        } else {
            "$surahName - Besmele"
        }
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_TITLE) ?: quranTitle)
            setContentText(mediaMetadata?.getString(MediaMetadataCompat.METADATA_KEY_ARTIST) ?: notificationArtistText)
            setSubText("Kuran-ı Kerim")
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
        
        try {
            if (isPlaying || playbackState?.state == PlaybackStateCompat.STATE_PAUSED) {
                startForeground(NOTIFICATION_ID, notification)
            } else if (playbackState?.state == PlaybackStateCompat.STATE_STOPPED || playbackState?.state == PlaybackStateCompat.STATE_NONE) {
                stopForeground(true)
                notificationManager.cancel(NOTIFICATION_ID)
            } else {
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            println("Bildirim gösterme hatası: ${e.message}")
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    fun getMediaSession(): MediaSessionCompat {
        return mediaSession
    }
    
    fun activateMediaSession() {
        println("QuranMediaService: Activating MediaSession")
        setupMediaSessionCallbacks()
        mediaSession.isActive = true
    }
    
    private fun setupMediaSessionCallbacks() {
        mediaSession.setCallback(object : MediaSessionCompat.Callback() {
            override fun onPlay() {
                try {
                    println("QuranMediaService: onPlay called")
                    methodChannel?.invokeMethod("play", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
                } catch (e: Exception) {
                    println("QuranMediaService onPlay error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }

            override fun onPause() {
                try {
                    println("QuranMediaService: onPause called")
                    methodChannel?.invokeMethod("pause", null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                } catch (e: Exception) {
                    println("QuranMediaService onPause error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }
            }

            override fun onStop() {
                try {
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                } catch (e: Exception) {
                    println("QuranMediaService onStop error: ${e.message}")
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                }
            }

            override fun onSkipToNext() {
                try {
                    println("QuranMediaService: onSkipToNext called")
                    methodChannel?.invokeMethod("next", null)
                    println("QuranMediaService: next method called via methodChannel")
                } catch (e: Exception) {
                    println("Sonraki sayfa kontrol hatası: ${e.message}")
                    methodChannel?.invokeMethod("next", null)
                }
            }

            override fun onSkipToPrevious() {
                try {
                    println("QuranMediaService: onSkipToPrevious called")
                    methodChannel?.invokeMethod("previous", null)
                    println("QuranMediaService: previous method called via methodChannel")
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
        println("QuranMediaService: Deactivating MediaSession")
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

