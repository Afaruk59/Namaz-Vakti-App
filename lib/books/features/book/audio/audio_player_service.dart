import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerService {
  // Context-based instances
  static final Map<String, AudioPlayerService> _instances = {};

  // Method channel for Android communication - context-specific
  final MethodChannel _platform;

  // AudioPlayer instance
  AudioPlayer? _audioPlayer;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? _playingBookCode; // Çalınan kitap kodu
  DateTime? _lastPositionUpdateTime; // Son pozisyon güncelleme zamanı
  bool _isHandlingCompletion = false; // Tamamlanma işlemi zaten yürütülüyor mu
  bool _isStoppingIntentionally = false; // Kasıtlı olarak durduruldu mu

  // Convenience getter for playingBookCode
  String? get playingBookCode => _playingBookCode;

  // Ses konumu için getter
  Duration get audioPosition => position;

  // Stream controllers
  StreamController<bool>? _playingStateController;
  StreamController<Duration>? _positionController;
  StreamController<Duration>? _durationController;
  StreamController<double>? _playbackRateController;
  StreamController<void>? _completionController;

  // Seeking debounce
  Timer? _seekDebounceTimer;
  Duration? _pendingSeekPosition;

  // Streams
  Stream<bool> get playingStateStream => _playingStateController!.stream;
  Stream<Duration> get positionStream => _positionController!.stream;
  Stream<Duration> get durationStream => _durationController!.stream;
  Stream<double> get playbackRateStream => _playbackRateController!.stream;
  Stream<void> get completionStream => _completionController!.stream;

  // Context identifier
  final String _contextId;

  // Factory constructor to return context-specific instance
  factory AudioPlayerService.forContext(String contextId) {
    _instances[contextId] ??= AudioPlayerService._internal(contextId);
    return _instances[contextId]!;
  }

  // Legacy factory constructor for backward compatibility (defaults to 'book')
  factory AudioPlayerService() {
    return AudioPlayerService.forContext('book');
  }

  // Private constructor
  AudioPlayerService._internal(this._contextId) : _platform = MethodChannel('com.afaruk59.namaz_vakti_app/${_contextId}_media_controls') {
    _initialize();
  }

  void _initialize() {
    try {
      // Initialize AudioPlayer
      _audioPlayer = AudioPlayer();

      // Initialize stream controllers
      _playingStateController = StreamController<bool>.broadcast();
      _positionController = StreamController<Duration>.broadcast();
      _durationController = StreamController<Duration>.broadcast();
      _playbackRateController = StreamController<double>.broadcast();
      _completionController = StreamController<void>.broadcast();

      // Setup listeners
      _setupListeners();
    } catch (e) {
      debugPrint('AudioPlayerService initialization error: $e');
    }
  }

  void _setupListeners() {
    if (_audioPlayer == null) return;

    _audioPlayer!.onPlayerStateChanged.listen((state) {
      debugPrint(
          'AudioPlayerService: Player state changed to: $state, isStoppingIntentionally: $_isStoppingIntentionally');

      // Hata durumlarını kontrol et - sadece kasıtlı olmayan durmalarda hata ver
      if (state == PlayerState.stopped && isPlaying && !_isStoppingIntentionally) {
        debugPrint('AudioPlayerService: Player stopped unexpectedly, treating as error');
        // Beklenmeyen durma durumunu hata olarak değerlendir
        isPlaying = false;
        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        // Hata durumunda completion handling'i sıfırla
        _isHandlingCompletion = false;

        // Android servisine hata durumunu bildir (sadece Android'de)
        try {
          // Platform kontrolü yaparak sadece Android'de çağır
          if (defaultTargetPlatform == TargetPlatform.android) {
            _platform.invokeMethod('audio_error', {'error': 'Player stopped unexpectedly'});
          }
        } catch (e) {
          debugPrint('AudioPlayerService: Failed to notify service about error: $e');
        }
        return;
      }

      // Kasıtlı durdurma işlemi tamamlandıysa flag'i sıfırla
      if (state == PlayerState.stopped && _isStoppingIntentionally) {
        debugPrint('AudioPlayerService: Player stopped intentionally');
        _isStoppingIntentionally = false;
      }

      isPlaying = state == PlayerState.playing;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
    });

    // Pozisyon güncellemelerini optimize et
    _audioPlayer!.onPositionChanged.listen((newPosition) {
      // Geçerli bir pozisyon güncellemesi mi kontrol et
      if (newPosition.inMilliseconds < 0) {
        return;
      }

      // Throttling için zaman kontrolü
      final now = DateTime.now();
      if (_lastPositionUpdateTime != null) {
        final elapsed = now.difference(_lastPositionUpdateTime!).inMilliseconds;
        // Normal hızda 500ms, yüksek hızda 250ms throttling
        final throttleInterval = playbackSpeed > 1.0 ? 250 : 500;
        if (elapsed < throttleInterval) {
          return;
        }
      }

      // Pozisyon farkı çok küçükse güncelleme yapma (50ms'den az)
      if ((newPosition - position).inMilliseconds.abs() < 50) {
        return;
      }

      _lastPositionUpdateTime = now;
      position = newPosition;
      if (!_positionController!.isClosed) {
        _positionController!.add(position);
      }
    });

    _audioPlayer!.onDurationChanged.listen((newDuration) {
      duration = newDuration;
      if (!_durationController!.isClosed) {
        _durationController!.add(duration);
      }
    });

    _audioPlayer!.onPlayerComplete.listen((_) async {
      isPlaying = false;

      // Always notify Android service about audio completion, regardless of bookCode
      if (!_isHandlingCompletion) {
        debugPrint(
            'AudioPlayerService: Audio completed, triggering completion handler for book: $_playingBookCode');
        _isHandlingCompletion = true;

        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        if (!_completionController!.isClosed) {
          _completionController!.add(null); // Broadcast completion event
        }

        // Notify native service about audio completion for background handling
        // This should work even when bookCode is null (app in background)
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _platform.invokeMethod('audio_completed');
            debugPrint('AudioPlayerService: Audio completion notification sent to Android service');
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            // iOS için ana method channel üzerinden bildir (daha güvenilir)
            await _platform.invokeMethod('audio_completed');
            debugPrint(
                'AudioPlayerService: Audio completion notification sent to iOS via main channel');
          }
        } catch (e) {
          debugPrint(
              'AudioPlayerService: Failed to notify native service about audio completion: $e');
        }

        // Reset the completion handling flag after a short delay
        // This prevents multiple completion events from being processed simultaneously
        await Future.delayed(const Duration(seconds: 1));
        _isHandlingCompletion = false;
      } else {
        debugPrint(
            'AudioPlayerService: Audio completed but completion handling was suppressed. isHandlingCompletion: $_isHandlingCompletion, bookCode: $_playingBookCode');

        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }
      }
    });
  }

  Future<void> playAudio(String audioUrl) async {
    try {
      if (_audioPlayer == null) {
        _initialize();
      }

      // URL'yi kontrol et ve düzelt
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        audioUrl = 'https://www.hakikatkitabevi.net$audioUrl';
      }

      debugPrint('Playing audio from URL: $audioUrl');

      // Önce mevcut sesi durdur
      await stopAudio();

      // Yeni ses başlatılacağı için flag'leri sıfırla
      _isStoppingIntentionally = false;
      _isHandlingCompletion = false;

      // Kısa bir bekleme ekleyerek önceki ses dosyasının tamamen durmasını sağla
      await Future.delayed(const Duration(milliseconds: 100));

      // Yeni ses dosyasını çal
      await _audioPlayer!.play(UrlSource(audioUrl));

      // Oynatma hızını ayarla
      await _audioPlayer!.setPlaybackRate(playbackSpeed);

      // Durumu güncelle
      isPlaying = true;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }

      // Çalma başarılı olduğunu doğrula
      debugPrint('Audio playback started successfully for URL: $audioUrl');

      // Kısa bir gecikme sonra çalma durumunu tekrar kontrol et
      await Future.delayed(const Duration(milliseconds: 100));
      if (_audioPlayer!.state != PlayerState.playing) {
        debugPrint(
            'Warning: Audio player state is not playing after 300ms. Current state: ${_audioPlayer!.state}');
        // Tekrar çalmayı dene
        await _audioPlayer!.play(UrlSource(audioUrl));

        // Ek bir 'resume' işlemi ile çalmasını zorla
        await Future.delayed(const Duration(milliseconds: 100));
        await resumeAudio();
      }

      // Ek güvenlik: Ekran kilitleme durumlarında daha güvenli olması için
      // bir süre sonra durumu tekrar kontrol et
      await Future.delayed(const Duration(milliseconds: 500));
      if (_audioPlayer != null && _audioPlayer!.state == PlayerState.stopped && isPlaying) {
        debugPrint(
            'AudioPlayerService: Player stopped unexpectedly after 500ms, attempting recovery');
        // Beklenmeyen durma durumunda recovery dene
        try {
          await _audioPlayer!.resume();
          if (_audioPlayer!.state != PlayerState.playing) {
            // Resume başarısızsa tekrar play dene
            await _audioPlayer!.play(UrlSource(audioUrl));
          }
        } catch (recoveryError) {
          debugPrint('AudioPlayerService: Recovery attempt failed: $recoveryError');
          // Recovery başarısızsa durumu güncelle
          isPlaying = false;
          if (!_playingStateController!.isClosed) {
            _playingStateController!.add(isPlaying);
          }
        }
      }
    } catch (error) {
      debugPrint('Error playing audio: $error');
      // Hata durumunda durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }

      // Hata durumunda completion handling'i sıfırla
      _isHandlingCompletion = false;

      rethrow; // Hatayı yukarıya ilet
    }
  }

  Future<void> pauseAudio() async {
    try {
      if (_audioPlayer != null) {
        debugPrint(
            'AudioPlayerService.pauseAudio called, current position: ${position.inSeconds}s');

        // iOS için ek güvenlik: completion handling'i geçici olarak devre dışı bırak
        bool wasHandlingCompletion = _isHandlingCompletion;
        _isHandlingCompletion = true;

        // Mevcut pozisyonu kaydet
        position = await _audioPlayer!.getCurrentPosition() ?? position;

        // Sesi durdur ama pozisyonu sıfırlama
        await _audioPlayer!.pause();
        isPlaying = false;

        debugPrint(
            'AudioPlayerService.pauseAudio completed, position preserved: ${position.inSeconds}s');

        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        // Bildirim kontrollerinin kaybolmaması için kısa bir gecikme ekle
        await Future.delayed(const Duration(milliseconds: 100));

        // Completion handling'i eski durumuna geri getir
        _isHandlingCompletion = wasHandlingCompletion;
      }
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      // Hata durumunda güvenli bir şekilde durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
      // Hata durumunda completion handling'i sıfırla
      _isHandlingCompletion = false;
    }
  }

  /// Resume audio playback
  Future<void> resumeAudio() async {
    try {
      debugPrint('AudioPlayerService.resumeAudio called');

      if (_audioPlayer != null) {
        await _audioPlayer!.resume();

        // Make sure it's actually playing
        await Future.delayed(const Duration(milliseconds: 50));
        if (_audioPlayer!.state != PlayerState.playing) {
          debugPrint('Resume didn\'t work on first attempt, trying play() instead');
          // Get current source and play it again
          if (_audioPlayer!.source != null) {
            await _audioPlayer!.play(_audioPlayer!.source!);
          }
        }

        isPlaying = true;
        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }
        debugPrint('AudioPlayerService.resumeAudio completed successfully');
      } else {
        debugPrint('Warning: AudioPlayer was null when trying to resume');
      }
    } catch (e) {
      debugPrint('Error resuming audio: $e');
      // Hata durumunda güvenli bir şekilde durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
    }
  }

  Future<void> stopAudio() async {
    try {
      if (_audioPlayer != null) {
        debugPrint('AudioPlayerService.stopAudio called from Flutter.');

        // Kasıtlı durdurma işlemi başladığını belirt
        _isStoppingIntentionally = true;

        // iOS için ek güvenlik: completion handling'i devre dışı bırak
        _isHandlingCompletion = true;

        // Önce pozisyonu sıfırla
        position = Duration.zero;
        if (!_positionController!.isClosed) {
          _positionController!.add(position);
        }

        // Sesi durdur
        await _audioPlayer!.stop();

        // Durumu güncelle
        isPlaying = false;
        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        // Çalınan kitap kodunu temizle - bu bildirim kontrollerinin kaldırılmasına yardımcı olur
        await setPlayingBookCode(null);
        
        // ÖNEMLİ: SharedPreferences'tan da playing_book_code'u temizle
        // Bu, method channel handler'larının düzgün çalışmasını sağlar
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('playing_book_code');
          debugPrint('AudioPlayerService: playing_book_code SharedPreferences\'tan temizlendi');
        } catch (e) {
          debugPrint('AudioPlayerService: playing_book_code SharedPreferences\'tan temizlenemedi: $e');
        }

        // iOS için ek güvenlik: kısa bir gecikme sonra completion handling'i tekrar aktif et
        await Future.delayed(const Duration(milliseconds: 500));
        _isHandlingCompletion = false;

        debugPrint(
            'AudioPlayerService.stopAudio completed - bildirim kontrollerini kaldırma tamamlandı');
      }
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      // Hata olsa bile durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
      // Hata durumunda flag'leri sıfırla
      _isHandlingCompletion = false;
      _isStoppingIntentionally = false;
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null) {
        // Debounce seeking işlemi
        _pendingSeekPosition = position;
        _seekDebounceTimer?.cancel();
        _seekDebounceTimer = Timer(Duration(milliseconds: 20), () async {
          if (_pendingSeekPosition != null) {
            await _performSeek(_pendingSeekPosition!);
            _pendingSeekPosition = null;
          }
        });
      }
    } catch (e) {
      debugPrint('AudioPlayerService seek error: $e');
    }
  }

  /// Gerçek seek işlemini gerçekleştirir
  Future<void> _performSeek(Duration position) async {
    try {
      if (_audioPlayer != null) {
        debugPrint('AudioPlayerService: Seeking to position ${position.inSeconds}s');

        // Geçerli pozisyon aralığında mı kontrol et
        if (position.inMilliseconds < 0 ||
            (duration.inMilliseconds > 0 && position.inMilliseconds > duration.inMilliseconds)) {
          debugPrint('AudioPlayerService: Invalid seek position, ignoring');
          return;
        }

        // Seek işlemini gerçekleştir
        await _audioPlayer!.seek(position);

        // Pozisyonu güncelle
        this.position = position;
        if (!_positionController!.isClosed) {
          _positionController!.add(position);
        }

        debugPrint('AudioPlayerService: Seek completed to ${this.position.inSeconds}s');
      }
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      debugPrint('AudioPlayerService: Setting playback speed to ${speed}x');

      // Önce yerel değişkeni güncelle ve stream'e gönder
      // Böylece UI hemen tepki verebilir
      playbackSpeed = speed;

      // UI güncellemesi için küçük bir gecikme ekle
      // Bu, art arda çoklu güncelleme durumunda UI'ın stabilize olmasına yardımcı olur
      await Future.delayed(const Duration(milliseconds: 50));

      if (!_playbackRateController!.isClosed) {
        _playbackRateController!.add(playbackSpeed);
      }

      // Sonra gerçek hız değişikliğini yap
      if (_audioPlayer != null) {
        await _audioPlayer!.setPlaybackRate(speed);
      }

      // Pozisyon güncelleme zaman damgasını sıfırla
      _lastPositionUpdateTime = null;

      debugPrint('AudioPlayerService: Playback speed set to ${speed}x');
    } catch (e) {
      debugPrint('Error setting playback speed: $e');
    }
  }

  List<double> getSpeedLevels() {
    return [1.0, 1.25, 1.5];
  }

  double getNextSpeed() {
    final speedLevels = getSpeedLevels();
    int currentIndex = speedLevels.indexOf(playbackSpeed);
    if (currentIndex == -1) {
      return 1.0; // Eğer mevcut hız listede yoksa, varsayılan 1.0'a dön
    }
    int nextIndex = (currentIndex + 1) % speedLevels.length;
    return speedLevels[nextIndex];
  }

  void reset() {
    try {
      // Stop audio if playing
      if (isPlaying) {
        stopAudio();
      }

      // Reset state
      isPlaying = false;
      position = Duration.zero;
      duration = Duration.zero;
      _isHandlingCompletion = false;
      _isStoppingIntentionally = false;

      // Notify listeners
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
      if (!_positionController!.isClosed) {
        _positionController!.add(position);
      }
      if (!_durationController!.isClosed) {
        _durationController!.add(duration);
      }
    } catch (e) {
      debugPrint('Error resetting audio player: $e');
    }
  }

  void dispose() {
    try {
      // Timer'ı temizle
      _seekDebounceTimer?.cancel();
      _seekDebounceTimer = null;
      _pendingSeekPosition = null;

      // Önce ses oynatıcıyı durdur
      try {
        if (_audioPlayer != null) {
          _audioPlayer!.stop();
          _audioPlayer!.dispose();
          _audioPlayer = null;
        }
      } catch (e) {
        debugPrint('AudioPlayer stop/dispose hatası: $e');
      }

      // Stream controller'ları güvenli bir şekilde kapat
      try {
        if (_playingStateController != null && !_playingStateController!.isClosed) {
          _playingStateController!.close();
          _playingStateController = null;
        }
      } catch (e) {
        debugPrint('_playingStateController kapatma hatası: $e');
      }

      try {
        if (_positionController != null && !_positionController!.isClosed) {
          _positionController!.close();
          _positionController = null;
        }
      } catch (e) {
        debugPrint('_positionController kapatma hatası: $e');
      }

      try {
        if (_durationController != null && !_durationController!.isClosed) {
          _durationController!.close();
          _durationController = null;
        }
      } catch (e) {
        debugPrint('_durationController kapatma hatası: $e');
      }

      try {
        if (_playbackRateController != null && !_playbackRateController!.isClosed) {
          _playbackRateController!.close();
          _playbackRateController = null;
        }
      } catch (e) {
        debugPrint('_playbackRateController kapatma hatası: $e');
      }

      try {
        if (_completionController != null && !_completionController!.isClosed) {
          _completionController!.close();
          _completionController = null;
        }
      } catch (e) {
        debugPrint('_completionController kapatma hatası: $e');
      }

      // Context-specific instance'ı sıfırla
      _instances.remove(_contextId);
    } catch (e) {
      debugPrint('AudioPlayerService dispose genel hatası: $e');
    }
  }

  // Çalınan kitap kodunu ayarla
  Future<void> setPlayingBookCode(String? bookCode) async {
    _playingBookCode = bookCode;
    debugPrint('AudioPlayerService: Playing book code set to: $bookCode');

    // SharedPreferences'a da kaydet
    try {
      final prefs = await SharedPreferences.getInstance();
      if (bookCode != null) {
        await prefs.setString('playing_book_code', bookCode);
        debugPrint('AudioPlayerService: playing_book_code saved to SharedPreferences: $bookCode');
      } else {
        await prefs.remove('playing_book_code');
        debugPrint('AudioPlayerService: playing_book_code removed from SharedPreferences');
      }
    } catch (e) {
      debugPrint('AudioPlayerService: Error saving playing_book_code to SharedPreferences: $e');
    }

    if (bookCode == null) {
      _isHandlingCompletion = false; // Reset completion handling if book code is cleared
    }
  }

  // Çalınan kitap kodunu al
  Future<String?> getPlayingBookCode() async {
    return _playingBookCode;
  }

  /// Prepare next audio file for seamless transition
  Future<void> prepareNextAudio(String audioUrl) async {
    try {
      debugPrint('AudioPlayerService: Preparing next audio file: $audioUrl');

      // URL'yi kontrol et ve düzelt
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        audioUrl = 'https://www.hakikatkitabevi.net$audioUrl';
      }

      // Create a new audio player for the next audio
      AudioPlayer nextPlayer = AudioPlayer();

      // Set up the source but don't play yet
      await nextPlayer.setSourceUrl(audioUrl);

      // Remove any previous completion listeners to avoid multiple triggers
      StreamSubscription? completionSubscription;
      completionSubscription = _audioPlayer?.onPlayerComplete.listen((_) async {
        debugPrint('AudioPlayerService: Current audio finished, switching to next audio');

        // Cancel this subscription to prevent memory leaks
        completionSubscription?.cancel();

        // Stop and dispose current player
        await _audioPlayer?.dispose();

        // Switch to the new player
        _audioPlayer = nextPlayer;

        // Set up listeners for the new player
        _setupListeners();

        // Start playing the new audio
        await _audioPlayer?.resume();

        debugPrint('AudioPlayerService: Switched to next audio successfully');
      });
    } catch (e) {
      debugPrint('Error preparing next audio: $e');
    }
  }

  // Add a method to directly update the playing state
  void forceUpdatePlayingState(bool playing) {
    isPlaying = playing;
    if (_playingStateController != null && !_playingStateController!.isClosed) {
      _playingStateController!.add(playing);
      debugPrint('Manually forced playing state to: $playing');
    }
  }

  // Pozisyonu manuel olarak güncelleyen fonksiyon
  void forcePositionUpdate() {
    if (_positionController != null && !_positionController!.isClosed) {
      _positionController!.add(position);
    }
  }

  // Seek işleminden sonra pozisyonu senkronize eden fonksiyon
  Future<void> forcePositionSync() async {
    if (_audioPlayer != null) {
      try {
        final currentPosition = await _audioPlayer!.getCurrentPosition();
        if (currentPosition != null) {
          position = currentPosition;
          if (_positionController != null && !_positionController!.isClosed) {
            _positionController!.add(currentPosition);
          }
          debugPrint('AudioPlayerService: Position synced to ${currentPosition.inSeconds}s');
        }
      } catch (e) {
        debugPrint('AudioPlayerService: Error syncing position: $e');
      }
    }
  }

  // State'i zorla güncelle - UI senkronizasyonu için
  void forceStateSync() {
    if (_playingStateController != null && !_playingStateController!.isClosed) {
      _playingStateController!.add(isPlaying);
    }
    if (_positionController != null && !_positionController!.isClosed) {
      _positionController!.add(position);
    }
    if (_durationController != null && !_durationController!.isClosed) {
      _durationController!.add(duration);
    }
    if (_playbackRateController != null && !_playbackRateController!.isClosed) {
      _playbackRateController!.add(playbackSpeed);
    }
  }

  // Orientation change sonrası tam recovery için
  void recoverAfterOrientationChange() {
    debugPrint('AudioPlayerService: Recovering state after orientation change');

    // Mevcut pozisyonu al ve force update
    if (_audioPlayer != null) {
      _audioPlayer!.getCurrentPosition().then((currentPos) {
        if (currentPos != null) {
          position = currentPos;
          forcePositionUpdate();
        }
      }).catchError((e) {
        debugPrint('Error getting current position during recovery: $e');
      });
    }

    // Tüm state'i sync et
    forceStateSync();

    debugPrint('AudioPlayerService: Recovery completed');
  }
}
