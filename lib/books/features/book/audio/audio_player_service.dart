import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class AudioPlayerService {
  // Singleton instance
  static AudioPlayerService? _instance;

  // AudioPlayer instance
  AudioPlayer? _audioPlayer;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? _playingBookCode; // Çalınan kitap kodu
  DateTime? _lastPositionUpdateTime; // Son pozisyon güncelleme zamanı
  bool _isHandlingCompletion = false; // Tamamlanma işlemi zaten yürütülüyor mu
  int _seekSessionId = 0;

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

  // Streams
  Stream<bool> get playingStateStream => _playingStateController!.stream;
  Stream<Duration> get positionStream => _positionController!.stream;
  Stream<Duration> get durationStream => _durationController!.stream;
  Stream<double> get playbackRateStream => _playbackRateController!.stream;
  Stream<void> get completionStream => _completionController!.stream;

  // Factory constructor to return the same instance
  factory AudioPlayerService() {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }

  // Private constructor
  AudioPlayerService._internal() {
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
      print('AudioPlayerService initialization error: $e');
    }
  }

  void _setupListeners() {
    if (_audioPlayer == null) return;

    _audioPlayer!.onPlayerStateChanged.listen((state) {
      print('AudioPlayerService: Player state changed to: $state');

      // Hata durumlarını kontrol et
      if (state == PlayerState.stopped && isPlaying) {
        print('AudioPlayerService: Player stopped unexpectedly, treating as error');
        // Beklenmeyen durma durumunu hata olarak değerlendir
        isPlaying = false;
        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        // Hata durumunda completion handling'i sıfırla
        _isHandlingCompletion = false;

        return;
      }

      isPlaying = state == PlayerState.playing;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
    });

    // Pozisyon güncellemelerini daha az sıklıkta yap
    // Her 500ms'de bir pozisyon güncellemesi yeterli olacaktır
    _audioPlayer!.onPositionChanged.listen((newPosition) {
      // Pozisyon değişikliği çok küçükse (100ms'den az) güncelleme yapma
      if ((newPosition - position).inMilliseconds.abs() < 100) {
        return;
      }

      // Yüksek hızda oynama durumunda daha az güncelleme yap (throttling)
      if (playbackSpeed > 1.0) {
        // Yüksek hızda daha az güncelleme yapalım
        final now = DateTime.now();
        if (_lastPositionUpdateTime != null) {
          final elapsed = now.difference(_lastPositionUpdateTime!).inMilliseconds;
          // Yüksek hızda daha fazla throttling uygula
          final throttleInterval = (200 * playbackSpeed).round();
          if (elapsed < throttleInterval) {
            return;
          }
        }
        _lastPositionUpdateTime = now;
      }

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
        print(
            'AudioPlayerService: Audio completed, triggering completion handler for book: $_playingBookCode');
        _isHandlingCompletion = true;

        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        if (!_completionController!.isClosed) {
          _completionController!.add(null); // Broadcast completion event
        }

        // Reset the completion handling flag after a short delay
        // This prevents multiple completion events from being processed simultaneously
        await Future.delayed(Duration(seconds: 1));
        _isHandlingCompletion = false;
      } else {
        print(
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
        audioUrl = 'https://www.hakikatkitabevi.net' + audioUrl;
      }

      print('Playing audio from URL: $audioUrl');

      // Önce mevcut sesi durdur
      await stopAudio();

      // Kısa bir bekleme ekleyerek önceki ses dosyasının tamamen durmasını sağla
      await Future.delayed(Duration(milliseconds: 100));

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
      print('Audio playback started successfully for URL: $audioUrl');

      // Kısa bir gecikme sonra çalma durumunu tekrar kontrol et
      await Future.delayed(Duration(milliseconds: 300));
      if (_audioPlayer!.state != PlayerState.playing) {
        print(
            'Warning: Audio player state is not playing after 300ms. Current state: ${_audioPlayer!.state}');
        // Tekrar çalmayı dene
        await _audioPlayer!.play(UrlSource(audioUrl));

        // Ek bir 'resume' işlemi ile çalmasını zorla
        await Future.delayed(Duration(milliseconds: 100));
        await resumeAudio();
      }

      // Ek güvenlik: Ekran kilitleme durumlarında daha güvenli olması için
      // bir süre sonra durumu tekrar kontrol et
      await Future.delayed(Duration(seconds: 2));
      if (_audioPlayer != null && _audioPlayer!.state == PlayerState.stopped && isPlaying) {
        print(
            'AudioPlayerService: Player stopped unexpectedly after 2 seconds, attempting recovery');
        // Beklenmeyen durma durumunda recovery dene
        try {
          await _audioPlayer!.resume();
          if (_audioPlayer!.state != PlayerState.playing) {
            // Resume başarısızsa tekrar play dene
            await _audioPlayer!.play(UrlSource(audioUrl));
          }
        } catch (recoveryError) {
          print('AudioPlayerService: Recovery attempt failed: $recoveryError');
          // Recovery başarısızsa durumu güncelle
          isPlaying = false;
          if (!_playingStateController!.isClosed) {
            _playingStateController!.add(isPlaying);
          }
        }
      }
    } catch (error) {
      print('Error playing audio: $error');
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
        print('AudioPlayerService.pauseAudio called, current position: ${position.inSeconds}s');

        // Mevcut pozisyonu kaydet
        position = await _audioPlayer!.getCurrentPosition() ?? position;

        // Sesi durdur ama pozisyonu sıfırlama
        await _audioPlayer!.pause();
        isPlaying = false;

        print(
            'AudioPlayerService.pauseAudio completed, position preserved: ${position.inSeconds}s');

        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }

        // Bildirim kontrollerinin kaybolmaması için kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 100));
      }
    } catch (e) {
      print('Error pausing audio: $e');
      // Hata durumunda güvenli bir şekilde durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
    }
  }

  /// Resume audio playback
  Future<void> resumeAudio() async {
    try {
      print('AudioPlayerService.resumeAudio called');

      if (_audioPlayer != null) {
        await _audioPlayer!.resume();

        // Make sure it's actually playing
        await Future.delayed(Duration(milliseconds: 50));
        if (_audioPlayer!.state != PlayerState.playing) {
          print('Resume didn\'t work on first attempt, trying play() instead');
          // Get current source and play it again
          if (_audioPlayer!.source != null) {
            await _audioPlayer!.play(_audioPlayer!.source!);
          }
        }

        isPlaying = true;
        if (!_playingStateController!.isClosed) {
          _playingStateController!.add(isPlaying);
        }
        print('AudioPlayerService.resumeAudio completed successfully');
      } else {
        print('Warning: AudioPlayer was null when trying to resume');
      }
    } catch (e) {
      print('Error resuming audio: $e');
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
        print('AudioPlayerService.stopAudio called from Flutter.');

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

        print(
            'AudioPlayerService.stopAudio completed - bildirim kontrollerini kaldırma tamamlandı');
      }
    } catch (e) {
      print('Error stopping audio: $e');
      // Hata olsa bile durumu güncelle
      isPlaying = false;
      if (!_playingStateController!.isClosed) {
        _playingStateController!.add(isPlaying);
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null) {
        _seekSessionId++;
        final currentSession = _seekSessionId;
        // print('AudioPlayerService: Seeking to position  [38;5;2m${position.inSeconds}s [0m');

        // Önce yerel pozisyonu güncelle, böylece UI hemen tepki verir
        this.position = position;
        if (!_positionController!.isClosed) {
          _positionController!.add(position);
        }

        // Sonra gerçek seek işlemini yap
        await _audioPlayer!.seek(position);
        // Seek sonrası pozisyonu tekrar güncelle ve stream'e zorla gönder
        this.position = await _audioPlayer!.getCurrentPosition() ?? position;
        forcePositionUpdate();

        // --- SEEK SONRASI POLLING ---
        for (int i = 0; i < 5; i++) {
          await Future.delayed(Duration(milliseconds: 200));
          if (currentSession != _seekSessionId) break;
          final current = await _audioPlayer!.getCurrentPosition();
          if (current != null) {
            this.position = current;
            forcePositionUpdate();
          }
        }
      }
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      print('AudioPlayerService: Setting playback speed to ${speed}x');

      // Önce yerel değişkeni güncelle ve stream'e gönder
      // Böylece UI hemen tepki verebilir
      playbackSpeed = speed;

      // UI güncellemesi için küçük bir gecikme ekle
      // Bu, art arda çoklu güncelleme durumunda UI'ın stabilize olmasına yardımcı olur
      await Future.delayed(Duration(milliseconds: 50));

      if (!_playbackRateController!.isClosed) {
        _playbackRateController!.add(playbackSpeed);
      }

      // Sonra gerçek hız değişikliğini yap
      if (_audioPlayer != null) {
        await _audioPlayer!.setPlaybackRate(speed);
      }

      // Pozisyon güncelleme zaman damgasını sıfırla
      _lastPositionUpdateTime = null;

      print('AudioPlayerService: Playback speed set to ${speed}x');
    } catch (e) {
      print('Error setting playback speed: $e');
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
      print('Error resetting audio player: $e');
    }
  }

  void dispose() {
    try {
      // Önce ses oynatıcıyı durdur
      try {
        if (_audioPlayer != null) {
          _audioPlayer!.stop();
          _audioPlayer!.dispose();
          _audioPlayer = null;
        }
      } catch (e) {
        print('AudioPlayer stop/dispose hatası: $e');
      }

      // Stream controller'ları güvenli bir şekilde kapat
      try {
        if (_playingStateController != null && !_playingStateController!.isClosed) {
          _playingStateController!.close();
          _playingStateController = null;
        }
      } catch (e) {
        print('_playingStateController kapatma hatası: $e');
      }

      try {
        if (_positionController != null && !_positionController!.isClosed) {
          _positionController!.close();
          _positionController = null;
        }
      } catch (e) {
        print('_positionController kapatma hatası: $e');
      }

      try {
        if (_durationController != null && !_durationController!.isClosed) {
          _durationController!.close();
          _durationController = null;
        }
      } catch (e) {
        print('_durationController kapatma hatası: $e');
      }

      try {
        if (_playbackRateController != null && !_playbackRateController!.isClosed) {
          _playbackRateController!.close();
          _playbackRateController = null;
        }
      } catch (e) {
        print('_playbackRateController kapatma hatası: $e');
      }

      try {
        if (_completionController != null && !_completionController!.isClosed) {
          _completionController!.close();
          _completionController = null;
        }
      } catch (e) {
        print('_completionController kapatma hatası: $e');
      }

      // Singleton instance'ı sıfırla
      _instance = null;
    } catch (e) {
      print('AudioPlayerService dispose genel hatası: $e');
    }
  }

  // Çalınan kitap kodunu ayarla
  Future<void> setPlayingBookCode(String? bookCode) async {
    _playingBookCode = bookCode;
    print('AudioPlayerService: Playing book code set to: $bookCode');

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
      print('AudioPlayerService: Preparing next audio file: $audioUrl');

      // URL'yi kontrol et ve düzelt
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        audioUrl = 'https://www.hakikatkitabevi.net' + audioUrl;
      }

      // Create a new audio player for the next audio
      AudioPlayer nextPlayer = AudioPlayer();

      // Set up the source but don't play yet
      await nextPlayer.setSourceUrl(audioUrl);

      // Remove any previous completion listeners to avoid multiple triggers
      StreamSubscription? completionSubscription;
      completionSubscription = _audioPlayer?.onPlayerComplete.listen((_) async {
        print('AudioPlayerService: Current audio finished, switching to next audio');

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

        print('AudioPlayerService: Switched to next audio successfully');
      });
    } catch (e) {
      print('Error preparing next audio: $e');
    }
  }

  // Add a method to directly update the playing state
  void forceUpdatePlayingState(bool playing) {
    isPlaying = playing;
    if (_playingStateController != null && !_playingStateController!.isClosed) {
      _playingStateController!.add(playing);
      print('Manually forced playing state to: $playing');
    }
  }

  // Pozisyonu manuel olarak güncelleyen fonksiyon
  void forcePositionUpdate() {
    if (_positionController != null && !_positionController!.isClosed) {
      _positionController!.add(position);
      print(
          'AudioPlayerService: forcePositionUpdate called, position=${position.inMilliseconds}ms');
    }
  }
}
