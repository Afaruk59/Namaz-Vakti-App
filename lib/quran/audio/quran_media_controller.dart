import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namaz_vakti_app/quran/audio/quran_audio_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/quran/services/surah_localization_service.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

/// Kuran için kilit ekranında medya kontrollerini yöneten sınıf
class QuranMediaController {
  static const MethodChannel _channel =
      MethodChannel('com.afaruk59.namaz_vakti_app/quran_media_controls');
  static const MethodChannel _quranChannel =
      MethodChannel('com.afaruk59.namaz_vakti_app/quran_media');
  static const MethodChannel _callbackChannel =
      MethodChannel('com.afaruk59.namaz_vakti_app/quran_media_callback');
  final QuranAudioService _audioService;
  // final AudioPlayerService _audioPlayerService; // Not used in current implementation
  bool _isServiceRunning = false;

  // Expose service running state
  bool get isServiceRunning => _isServiceRunning;

  // Playback state sabitleri
  static const int STATE_NONE = 0;
  static const int STATE_PLAYING = 3;
  static const int STATE_PAUSED = 2;
  static const int STATE_STOPPED = 1;

  // Sayfa değişimi için callback'ler
  Function(int)? _onNextPage;
  Function(int)? _onPreviousPage;
  int _currentPage = 1;
  int _totalPages = 604; // Kuran için toplam sayfa sayısı

  QuranMediaController({
    required QuranAudioService audioService,
    required AudioPlayerService
        audioPlayerService, // Keep parameter for compatibility but don't store
  }) : _audioService = audioService {
    _setupListeners();
    setupMethodCallHandler();
    _setupQuranChannelHandler();
    _setupCallbackHandler();
  }

  /// Servis başlatma
  Future<void> startService() async {
    try {
      if (!_isServiceRunning) {
        await _channel.invokeMethod('startService');
        _isServiceRunning = true;

        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 50));

        // Method channel handler'ı tekrar kur - bu çok önemli!
        setupMethodCallHandler();
      }
    } catch (e) {
      print('QuranMediaController startService hatası: $e');
      // Hata durumunda servis durumunu güncelle
      _isServiceRunning = false;
    }
  }

  /// Servis durdurma
  Future<void> stopService() async {
    // Bildirim player'ı kesinlikle kaldırmak için agresif şekilde çağır
    try {
      await updatePlaybackState(STATE_STOPPED);
      await Future.delayed(Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      await Future.delayed(Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      // Ekstra: tekrar playback state STOPPED gönder
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});
      await Future.delayed(Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      _isServiceRunning = false;
    } catch (e) {
      print('QuranMediaController stopService (agresif) hata: $e');
      _isServiceRunning = false;
    }
  }

  /// Oynatma durumunu güncelleme
  Future<void> updatePlaybackState(int state) async {
    try {
      if (!_isServiceRunning) {
        await startService();
        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 50));
      }

      await _channel.invokeMethod('updatePlaybackState', {'state': state.toInt()});

      // Oynatma durumu değiştiğinde pozisyonu da güncelle
      if (state == STATE_PLAYING) {
        await updatePosition(_audioService.position.inMilliseconds);
      }
    } catch (e) {
      print('QuranMediaController updatePlaybackState hatası: $e');
    }
  }

  /// Metadata güncelleme
  Future<void> updateMetadata({
    required String title,
    required String surahName,
    required int ayahNumber,
    required int durationMs,
    int pageNumber = 0,
    BuildContext? context,
  }) async {
    if (_isServiceRunning) {
      // Başlığa sayfa numarasını ekle
      String displayTitle = title;
      if (pageNumber > 0 && context != null) {
        final localizedPageNumber =
            AppLocalizations.of(context)?.pageNumber(pageNumber) ?? "Sayfa $pageNumber";
        displayTitle = "$title - $localizedPageNumber";
      } else if (pageNumber > 0) {
        displayTitle = "$title - Sayfa $pageNumber";
      }

      // Yazar kısmına sadece sure adı ekle (ayet numarası olmadan)
      String author;
      if (ayahNumber == 0) {
        // Besmele çalıyorsa - çok dilli destek
        String localizedBesmele = "Besmele"; // varsayılan
        if (context != null) {
          localizedBesmele = AppLocalizations.of(context)?.besmele ?? "Besmele";
        }

        // Sure ismini de çok dilli yap
        String localizedSurahName = surahName;
        if (context != null) {
          localizedSurahName = SurahLocalizationService.getLocalizedSurahName(surahName, context);
        }

        author = "${localizedSurahName} - ${localizedBesmele}";
      } else {
        // Normal ayet çalıyorsa - sure ismini çok dilli yap
        if (context != null) {
          author = SurahLocalizationService.getLocalizedSurahName(surahName, context);
        } else {
          author = surahName;
        }
      }

      await _channel.invokeMethod('updateMetadata', {
        'title': displayTitle,
        'surahName': author,
        'ayahNumber': ayahNumber,
        'duration': durationMs.toInt(),
      });
    }
  }

  /// Pozisyon güncelleme
  Future<void> updatePosition(int positionMs) async {
    if (_isServiceRunning) {
      await _channel.invokeMethod('updatePosition', {'position': positionMs.toInt()});
    }
  }

  /// Kuran sayfası için medya kontrollerini güncelleme
  Future<void> updateForQuranPage(int pageNumber, String surahName, int ayahNumber,
      {BuildContext? context}) async {
    try {
      // Her dinleme başlatıldığında method channel handler'ı tekrar ata
      setupMethodCallHandler();
      if (!_isServiceRunning) {
        await startService();
        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Metadata güncelle (sadece bir kez)
      String localizedTitle = "Kuran-ı Kerim"; // varsayılan
      if (context != null) {
        localizedTitle = AppLocalizations.of(context)?.holyQuran ?? "Kuran-ı Kerim";
      }

      await updateMetadata(
        title: localizedTitle,
        surahName: surahName,
        ayahNumber: ayahNumber,
        durationMs: _audioService.duration.inMilliseconds > 0
            ? _audioService.duration.inMilliseconds
            : 30000, // Eğer süre henüz belli değilse varsayılan bir değer kullan
        pageNumber: pageNumber,
        context: context,
      );

      // Oynatma durumunu güncelle - eğer ses çalınıyorsa PLAYING, değilse PAUSED olarak ayarla
      final state = _audioService.isPlaying ? STATE_PLAYING : STATE_PAUSED;
      await updatePlaybackState(state);

      // Pozisyonu güncelle
      if (_audioService.isPlaying) {
        await updatePosition(_audioService.position.inMilliseconds);
      }
    } catch (e) {
      print('QuranMediaController updateForQuranPage hatası: $e');
    }
  }

  /// Dinleyicileri ayarla
  void _setupListeners() {
    // AudioService'deki değişiklikleri dinle
    _audioService.addListener(() {
      // Oynatma durumu değiştiğinde
      if (_audioService.isPlaying) {
        updatePlaybackState(STATE_PLAYING);
      } else {
        // Zincirleme oynatmada veya otomatik geçişte STOPPED asla gönderme!
        updatePlaybackState(STATE_PAUSED);
      }
      // Pozisyon değiştiğinde
      updatePosition(_audioService.position.inMilliseconds);
    });
  }

  /// Sayfa değişimi için callback'leri ayarla
  void setPageChangeCallbacks({
    required Function(int) onNextPage,
    required Function(int) onPreviousPage,
    required int currentPage,
  }) {
    _onNextPage = onNextPage;
    _onPreviousPage = onPreviousPage;
    _currentPage = currentPage;
  }

  /// Mevcut sayfa bilgisini güncelle
  void updateCurrentPage(int currentPage) {
    _currentPage = currentPage;
  }

  /// Method call handler'ı ayarla (Flutter -> Android iletişimi için)
  void setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      try {
        // ÖNEMLİ: Önce hangi sistemin aktif olduğunu kontrol et
        final prefs = await SharedPreferences.getInstance();
        final playingBookCode = prefs.getString('playing_book_code');

        // Eğer kitap sistemi aktifse, Kuran sistemi method call'larını işleme
        if (playingBookCode != null && playingBookCode != 'quran') {
          print(
              'QuranMediaController: Kitap sistemi aktif, Kuran method call\'ı işlenmedi: ${call.method}');
          return false;
        }

        switch (call.method) {
          case 'initMediaService':
            // Servis başlatma isteği
            return true;
          default:
            return false;
        }
      } catch (e) {
        print('QuranMediaController method call hatası: $e');
        return false;
      }
    });
  }

  /// Kuran channel handler'ı ayarla (kitap sisteminden gelen çağrılar için)
  void _setupQuranChannelHandler() {
    _quranChannel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'resume':
            await _audioService.resumeAudio();
            return true;
          case 'pause':
            await _audioService.pauseAudio();
            return true;
          case 'stop':
            await _audioService.stop();
            return true;
          case 'next':
            // Sonraki sayfa işlemi
            if (_onNextPage != null && _currentPage < _totalPages) {
              try {
                _onNextPage!(_currentPage + 1);
              } catch (e) {
                print('QuranMediaController quran channel next error: $e');
              }
            }
            return true;
          case 'previous':
            // Önceki sayfa işlemi
            if (_onPreviousPage != null && _currentPage > 1) {
              try {
                _onPreviousPage!(_currentPage - 1);
              } catch (e) {
                print('QuranMediaController quran channel previous error: $e');
              }
            }
            return true;
          case 'seekTo':
            // Belirli bir konuma atlama
            final position = call.arguments['position'] as int;
            await _audioService.seekToPosition(Duration(milliseconds: position));
            return true;
          case 'getPosition':
            // Mevcut pozisyonu döndür
            return _audioService.position.inMilliseconds;
          default:
            return false;
        }
      } catch (e) {
        print('QuranMediaController quran channel error: $e');
        return false;
      }
    });
  }

  /// Callback handler'ı ayarla (Android -> Flutter çağrıları için)
  void _setupCallbackHandler() {
    _callbackChannel.setMethodCallHandler((call) async {
      try {
        // Sadece Kuran sistemi aktifse işle
        final prefs = await SharedPreferences.getInstance();
        final playingBookCode = prefs.getString('playing_book_code');

        if (playingBookCode != 'quran' || !_isServiceRunning) {
          return false; // Kitap sistemi için false döndür
        }

        switch (call.method) {
          case 'play':
            await _audioService.resumeAudio();
            return true;
          case 'pause':
            await _audioService.pauseAudio();
            return true;
          case 'stop':
            await _audioService.stop();
            return true;
          case 'next':
            // Sonraki sayfa işlemi
            if (_onNextPage != null && _currentPage < _totalPages) {
              try {
                _onNextPage!(_currentPage + 1);
              } catch (e) {
                print('QuranMediaController callback next error: $e');
              }
            }
            return true;
          case 'previous':
            // Önceki sayfa işlemi
            if (_onPreviousPage != null && _currentPage > 1) {
              try {
                _onPreviousPage!(_currentPage - 1);
              } catch (e) {
                print('QuranMediaController callback previous error: $e');
              }
            }
            return true;
          case 'seekTo':
            // Belirli bir konuma atlama
            final position = call.arguments as int;
            await _audioService.seekToPosition(Duration(milliseconds: position));
            return true;
          case 'getPosition':
            // Mevcut pozisyonu döndür
            return _audioService.position.inMilliseconds;
          default:
            return false; // Kitap sistemi için false döndür
        }
      } catch (e) {
        print('QuranMediaController callback error: $e');
        return false; // Hata durumunda kitap sistemi için false döndür
      }
    });
  }

  /// Kaynakları temizle
  void dispose() {
    stopService();
    _channel.setMethodCallHandler(null); // Method channel handler'ı sıfırla
    _quranChannel.setMethodCallHandler(null); // Kuran channel handler'ı sıfırla
    _callbackChannel.setMethodCallHandler(null); // Callback handler'ı sıfırla
  }
}
