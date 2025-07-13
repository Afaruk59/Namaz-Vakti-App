import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Kuran ses çalma işlemlerini yöneten sınıf
class QuranAudioPlayer extends ChangeNotifier {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDisposed = false;

  // Getters
  bool get isPlaying => _isPlaying;
  double get playbackRate => _playbackRate;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isDisposed => _isDisposed;

  QuranAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer?.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer?.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _audioPlayer?.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer?.setPlaybackRate(_playbackRate);
  }

  /// Ses dosyasını çalar
  Future<void> play(String url) async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    }

    await _audioPlayer?.play(UrlSource(url));
    _isPlaying = true;
    notifyListeners();
  }

  /// Sesi duraklatır
  Future<void> pause() async {
    try {
      if (_audioPlayer == null || _isDisposed) return;

      await _audioPlayer?.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('AudioPlayer pause hatası: $e');
      // Hata durumunda state'i güvenli bir şekilde güncelle
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Duraklatılmış sesi devam ettirir
  Future<void> resume() async {
    try {
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        _initAudioPlayer();
      }

      if (_isDisposed) return;

      await _audioPlayer?.resume();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('AudioPlayer resume hatası: $e');
      // Hata durumunda tekrar çalmayı dene
      try {
        if (_position.inMilliseconds > 0 && _duration.inMilliseconds > 0) {
          // Mevcut konumdan devam et
          await _audioPlayer?.seek(_position);
          await _audioPlayer?.resume();
          _isPlaying = true;
          notifyListeners();
        }
      } catch (innerError) {
        print('AudioPlayer resume tekrar deneme hatası: $innerError');
      }
    }
  }

  /// Sesi durdurur
  Future<void> stop() async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        try {
          await _audioPlayer!.stop();
        } catch (e) {
          print('AudioPlayer stop hatası: $e');
          // Hata durumunda sessizce devam et, state'i güncelle
        } finally {
          // Hata olsa bile state'i güvenli bir şekilde güncelle
          _isPlaying = false;
          _position = Duration.zero;
          notifyListeners();
        }
      } else {
        // AudioPlayer null veya dispose edilmiş, sadece state'i güncelle
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();
      }
    } catch (e) {
      print('AudioPlayer stop genel hatası: $e');
      // Genel hata durumunda state'i güvenli bir şekilde güncelle
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    }
  }

  /// Belirli bir konuma atlar
  Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        await _audioPlayer!.seek(position);
        _position = position;
        notifyListeners();
      }
    } catch (e) {
      print('AudioPlayer seekTo hatası: $e');
    }
  }

  /// Oynatma hızını ayarlar
  Future<void> setPlaybackRate(double rate) async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        await _audioPlayer!.setPlaybackRate(rate);
        _playbackRate = rate;
        notifyListeners();
      }
    } catch (e) {
      print('AudioPlayer setPlaybackRate hatası: $e');
    }
  }

  /// Ses seviyesini ayarlar
  Future<void> setVolume(double volume) async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        await _audioPlayer!.setVolume(volume);
        notifyListeners();
      }
    } catch (e) {
      print('AudioPlayer setVolume hatası: $e');
    }
  }

  /// Tamamlanma olayı için dinleyici ekler
  void addCompletionListener(VoidCallback onComplete) {
    _audioPlayer?.onPlayerComplete.listen((_) {
      onComplete();
    });
  }

  /// Kaynakları temizler
  @override
  Future<void> dispose() async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        if (_isPlaying) {
          try {
            await _audioPlayer!.stop();
          } catch (e) {
            print('AudioPlayer stop hatası (dispose): $e');
          }
        }
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      _isDisposed = true;
      super.dispose();
    } catch (e) {
      print('AudioPlayer dispose hatası: $e');
      _isDisposed = true;
      super.dispose();
    }
  }

  /// Kaynakları temizler ancak dispose çağırmaz
  Future<void> cleanup() async {
    try {
      if (_audioPlayer != null && !_isDisposed) {
        if (_isPlaying) {
          try {
            await _audioPlayer!.stop();
          } catch (e) {
            print('AudioPlayer stop hatası (cleanup): $e');
          }
        }
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
    } catch (e) {
      print('AudioPlayer cleanup hatası: $e');
      // Hata durumunda state'i güvenli bir şekilde güncelle
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
    }
  }
}
