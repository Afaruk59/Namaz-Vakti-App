// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:flutter/material.dart';

/// Kilit ekranında medya kontrollerini yöneten sınıf
class MediaController {
  static MediaController? _instance;
  factory MediaController.singleton(AudioPlayerService audioPlayerService) {
    return _instance ??= MediaController(audioPlayerService: audioPlayerService);
  }
  static const MethodChannel _channel =
      MethodChannel('com.afaruk59.namaz_vakti_app/book_media_controls');
  static const MethodChannel _callbackChannel =
      MethodChannel('com.afaruk59.namaz_vakti_app/book_media_callback');
  final AudioPlayerService _audioPlayerService;
  final BookProgressService _bookProgressService = BookProgressService();
  bool _isServiceRunning = false;

  // Completion controller for iOS background audio completion
  final StreamController<void> _completionController = StreamController<void>.broadcast();

  // Public getter for completion stream
  Stream<void> get completionStream => _completionController.stream;

  // Playback state sabitleri
  static const int STATE_NONE = 0;
  static const int STATE_PLAYING = 3;
  static const int STATE_PAUSED = 2;
  static const int STATE_STOPPED = 1;

  // Kitap sınırları için değişkenler
  int _firstPage = 1;
  int _lastPage = 9999;

  // Metadata cache - kitap bilgilerini korumak için
  String _cachedTitle = "";
  String _cachedAuthor = "";
  int _cachedPageNumber = 0;
  int _cachedDuration = 30000;

  MediaController({required AudioPlayerService audioPlayerService})
      : _audioPlayerService = audioPlayerService {
    _setupListeners();
    _setupMethodCallHandler();
    _setupCallbackHandler();
  }

  /// Servis başlatma
  Future<void> startService() async {
    try {
      debugPrint('🔥🔥🔥 FLUTTER MediaController.startService() CALLED 🔥🔥🔥');
      if (!_isServiceRunning) {
        debugPrint('🔥 FLUTTER: Calling iOS startService via method channel');

        // ÖNEMLİ: Kitap sistemi aktif olduğunda, Kuran sistemi handler'ını temizle
        // Bu, method channel çakışmalarını önler
        try {
          await _channel.invokeMethod('clearQuranHandler');
        } catch (e) {
          debugPrint('MediaController: clearQuranHandler hatası (normal olabilir): $e');
        }

        await _channel.invokeMethod('startService');
        _isServiceRunning = true;
        debugPrint('✅ FLUTTER: startService completed successfully');

        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(const Duration(milliseconds: 200));

        // Ek güvenlik: Method channel handler'ını yeniden kur
        _setupMethodCallHandler();
      }
    } catch (e) {
      debugPrint('MediaController startService hatası: $e');
      // Hata durumunda servis durumunu güncelle
      _isServiceRunning = false;
    }
  }

  /// Servis durdurma
  Future<void> stopService() async {
    // Bildirim player'ı kesinlikle kaldırmak için agresif şekilde çağır
    try {
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});
      await Future.delayed(const Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      await Future.delayed(const Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      // Ekstra: tekrar playback state STOPPED gönder
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});
      await Future.delayed(const Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      _isServiceRunning = false;

      // ÖNEMLİ: Kitap sistemi durdurulduğunda playing_book_code'u temizle
      // Bu, Kuran sistemi handler'larının aktif olmasını sağlar
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('playing_book_code');
        debugPrint(
            'MediaController: playing_book_code temizlendi, Kuran sistemi handler\'ları aktif olabilir');
      } catch (e) {
        debugPrint('MediaController: playing_book_code temizlenemedi: $e');
      }
    } catch (e) {
      debugPrint('MediaController stopService (agresif) hata: $e');
      _isServiceRunning = false;
    }
  }

  /// Oynatma durumunu güncelleme
  Future<void> updatePlaybackState(int state) async {
    try {
      debugPrint(
          'MediaController: updatePlaybackState called with state: $state, isPlaying: ${_audioPlayerService.isPlaying}');

      if (!_isServiceRunning) {
        await startService();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // iOS'a playback state'i gönder
      await _channel.invokeMethod('updatePlaybackState', {'state': state.toInt()});

      // Pozisyonu güncelle (eğer çalıyorsa)
      if (state == STATE_PLAYING) {
        await updatePosition(_audioPlayerService.position.inMilliseconds);
      }

      debugPrint('MediaController: updatePlaybackState completed successfully');
    } catch (e) {
      debugPrint('MediaController updatePlaybackState hatası: $e');
    }
  }

  /// Metadata güncelleme
  Future<void> updateMetadata({
    required String title,
    required String author,
    required String coverUrl,
    required int durationMs,
    int pageNumber = 0,
  }) async {
    debugPrint('🔥🔥🔥 FLUTTER MediaController.updateMetadata() CALLED 🔥🔥🔥');
    debugPrint(
        '🔥 FLUTTER: Title: $title, Author: $author, Duration: $durationMs, Page: $pageNumber');
    try {
      // iOS için her zaman servis başlat ve metadata güncelle
      if (!_isServiceRunning) {
        await startService();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Başlığa sayfa numarasını ekle ve boş değerleri kontrol et
      String cleanTitle = title.isNotEmpty ? title : "Hakikat Kitabevi";
      String cleanAuthor = author.isNotEmpty ? author : "Hakikat Kitabevi";
      String displayTitle = pageNumber > 0 ? "$cleanTitle - Sayfa $pageNumber" : cleanTitle;

      // Süre kontrolü (eğer 0 ise varsayılan değer kullan)
      int safeDuration = durationMs > 0 ? durationMs : 30000; // 30 saniye varsayılan

      // Cache'i güncelle - bu bilgiler play/pause sırasında korunacak
      _cachedTitle = cleanTitle;
      _cachedAuthor = cleanAuthor;
      _cachedPageNumber = pageNumber;
      _cachedDuration = safeDuration;

      debugPrint(
          'MediaController: Updating metadata - Title: $displayTitle, Author: $cleanAuthor, Duration: ${safeDuration}ms');
      debugPrint(
          'MediaController: Cached values - Title: $_cachedTitle, Author: $_cachedAuthor, Page: $_cachedPageNumber');

      // Metadata'yı güncelle
      await _channel.invokeMethod('updateMetadata', {
        'title': displayTitle,
        'author': cleanAuthor,
        'coverUrl': coverUrl,
        'duration': safeDuration,
      });

      // Kısa bir gecikme sonra playback state'i güncelle
      await Future.delayed(const Duration(milliseconds: 100));

      // Playback state'i güncelle
      if (_audioPlayerService.isPlaying) {
        await updatePlaybackState(STATE_PLAYING);
      } else {
        await updatePlaybackState(STATE_PAUSED);
      }

      debugPrint('MediaController: Metadata and playback state updated successfully');
    } catch (e) {
      debugPrint('MediaController updateMetadata hatası: $e');
    }
  }

  /// Cache'den metadata'yı restore et (play/pause sırasında kullan)
  Future<void> _restoreMetadataFromCache() async {
    if (_cachedTitle.isNotEmpty && _isServiceRunning) {
      try {
        String displayTitle =
            _cachedPageNumber > 0 ? "$_cachedTitle - Sayfa $_cachedPageNumber" : _cachedTitle;

        debugPrint(
            'MediaController: Restoring metadata from cache - Title: $displayTitle, Author: $_cachedAuthor');

        await _channel.invokeMethod('updateMetadata', {
          'title': displayTitle,
          'author': _cachedAuthor,
          'coverUrl': '',
          'duration': _cachedDuration,
        });

        debugPrint('MediaController: Metadata restored from cache successfully');
      } catch (e) {
        debugPrint('MediaController: Error restoring metadata from cache: $e');
      }
    }
  }

  /// Pozisyon güncelleme
  Future<void> updatePosition(int positionMs) async {
    if (_isServiceRunning) {
      await _channel.invokeMethod('updatePosition', {'position': positionMs.toInt()});
    }
  }

  /// Kitap sayfası için medya kontrollerini güncelleme
  Future<void> updateForBookPage(BookPageModel bookPage, String bookTitle, String bookAuthor,
      {int pageNumber = 0}) async {
    try {
      debugPrint(
          'MediaController: updateForBookPage called - Title: $bookTitle, Page: $pageNumber, isPlaying: ${_audioPlayerService.isPlaying}');

      // ÖNEMLİ: Kitap sistemi başlatıldığında playing_book_code'u ayarla
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('playing_book_code', _audioPlayerService.playingBookCode ?? '');

      // Her dinleme başlatıldığında method channel handler'ı tekrar ata
      _setupMethodCallHandler();

      // iOS için her zaman servis başlat ve metadata güncelle
      if (!_isServiceRunning) {
        await startService();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Kitap bilgilerini güvenli hale getir
      String safeTitle = bookTitle.isNotEmpty ? bookTitle : "Hakikat Kitabevi";
      String safeAuthor = bookAuthor.isNotEmpty ? bookAuthor : "Hakikat Kitabevi";

      // Süre bilgisini güvenli şekilde al
      int safeDuration = _audioPlayerService.duration.inMilliseconds > 0
          ? _audioPlayerService.duration.inMilliseconds
          : 30000;

      // Metadata güncelle
      await updateMetadata(
        title: safeTitle,
        author: safeAuthor,
        coverUrl: '',
        durationMs: safeDuration,
        pageNumber: pageNumber,
      );

      debugPrint('MediaController: updateForBookPage completed successfully');
    } catch (e) {
      debugPrint('MediaController updateForBookPage hatası: $e');
    }
  }

  /// Dinleyicileri ayarla
  void _setupListeners() {
    // Oynatma durumu değişikliklerini dinle
    _audioPlayerService.playingStateStream.listen((isPlaying) async {
      debugPrint('MediaController: Playing state changed to $isPlaying');

      // Sadece playback state güncellemesi yap, metadata'yı korumaya çalış
      final state = isPlaying ? STATE_PLAYING : STATE_PAUSED;

      try {
        // Önce cache'den metadata restore et (eğer cache doluysa)
        if (_cachedTitle.isNotEmpty) {
          await _restoreMetadataFromCache();
          // Kısa bir gecikme sonra playback state güncelle
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Playback state'i güncelle
        if (_isServiceRunning) {
          await _channel.invokeMethod('updatePlaybackState', {'state': state});

          // Pozisyonu güncelle
          if (isPlaying) {
            await updatePosition(_audioPlayerService.position.inMilliseconds);
          }
        }

        debugPrint('MediaController: Playback state updated to $state with metadata preserved');
      } catch (e) {
        debugPrint('MediaController: Error updating playback state in listener: $e');
      }
    });

    // Pozisyon değişikliklerini dinle
    _audioPlayerService.positionStream.listen((position) {
      updatePosition(position.inMilliseconds);
    });

    // Süre değişikliklerini dinle
    _audioPlayerService.durationStream.listen((duration) {
      // Süre değiştiğinde sadece süre bilgisini güncelle, diğer metadata'ları koruma
      if (_isServiceRunning) {
        _channel.invokeMethod('updateMetadata', {
          'duration': duration.inMilliseconds.toInt(),
        });
      }
    });
  }

  // Sayfa değişimi için callback'ler
  Function(int, int)? _onNextPage;
  Function(int)? _onPreviousPage;
  int _currentPage = 1;
  int _totalPages = 1;

  /// Sayfa değişimi için callback'leri ayarla
  void setPageChangeCallbacks({
    required Function(int, int) onNextPage,
    required Function(int) onPreviousPage,
    required int currentPage,
    required int totalPages,
  }) {
    _onNextPage = onNextPage;
    _onPreviousPage = onPreviousPage;
    _currentPage = currentPage;
    _totalPages = totalPages;

    // Sayfa değişiminin sınırları için kitabın ilk ve son sayfalarını al
    _loadBookBoundaries();
  }

  /// Mevcut sayfa bilgisini güncelle
  void updateCurrentPage(int currentPage, int totalPages) {
    _currentPage = currentPage;
    _totalPages = totalPages;

    // Cache'deki sayfa numarasını da güncelle
    if (_cachedTitle.isNotEmpty) {
      _cachedPageNumber = currentPage;
      debugPrint('MediaController: Cache sayfa numarası güncellendi: $currentPage');
    }
  }

  /// Kitabın ilk ve son sayfa bilgilerini yükle
  Future<void> _loadBookBoundaries() async {
    try {
      // Çalan kitap kodunu al
      String? bookCode = await _audioPlayerService.getPlayingBookCode();
      if (bookCode != null && bookCode.isNotEmpty) {
        // Kitabın ilk sayfasını al
        int firstPage = await _bookProgressService.getFirstPage(bookCode);

        // Kitabın son sayfasını al
        int lastPage = await _bookProgressService.getLastPage(bookCode);

        // Değerleri kaydet
        _firstPage = firstPage;
        _lastPage = lastPage;

        debugPrint(
            'MediaController: Kitap sınırları yüklendi - İlk sayfa: $_firstPage, Son sayfa: $_lastPage');
      }
    } catch (e) {
      debugPrint('MediaController: Kitap sınırları yüklenirken hata: $e');
    }
  }

  /// Callback handler'ı ayarla (iOS -> Flutter çağrıları için)
  void _setupCallbackHandler() {
    _callbackChannel.setMethodCallHandler((call) async {
      try {
        debugPrint('MediaController callback received: ${call.method}');

        // Hangi ses sisteminin aktif olduğunu kontrol et
        final prefs = await SharedPreferences.getInstance();
        final playingBookCode = prefs.getString('playing_book_code');

        debugPrint(
            'MediaController: playing_book_code = $playingBookCode, method = ${call.method}');

        // Kuran sistemi aktifse, callback'i işleme
        if (playingBookCode == 'quran') {
          debugPrint('MediaController: Quran system active, ignoring callback');
          return false; // Kuran sistemi için false döndür
        }

        // Kitap sistemi için normal callback'ler
        switch (call.method) {
          case 'play':
            await _audioPlayerService.resumeAudio();
            // Play durumunda metadata'yı cache'den restore et
            await _restoreMetadataFromCache();
            return true;
          case 'pause':
            await _audioPlayerService.pauseAudio();
            // Pause durumunda metadata'yı cache'den restore et
            await _restoreMetadataFromCache();
            // Pause durumunda bildirim kontrollerinin kaybolmaması için
            // playback state'i duraklatılmış olarak güncelle
            await updatePlaybackState(STATE_PAUSED);
            return true;
          case 'stop':
            // iOS için ek güvenlik: stop işlemini güvenli bir şekilde gerçekleştir
            try {
              await _audioPlayerService.stopAudio();
              // Stop işleminden sonra servisi de durdur
              await Future.delayed(const Duration(milliseconds: 100));
              await stopService();
            } catch (e) {
              debugPrint('MediaController callback stop error: $e');
              // Hata durumunda da servisi durdur
              await stopService();
            }
            return true;
          case 'next':
            // Sonraki sayfa işlemi - hemen sayfa değişimi yap
            if (_onNextPage != null) {
              // Önce cache'deki sayfa numarasını güncelle ve hemen metadata'yı restore et
              if (_cachedTitle.isNotEmpty && _currentPage < _lastPage) {
                _cachedPageNumber = _currentPage + 1;
                await _restoreMetadataFromCache();
              }

              // Playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Kitabın son sayfası kontrolü
              await _loadBookBoundaries(); // Sınırları güncel tut

              // Son sayfada değilsek sayfa değişimini gerçekleştir
              if (_currentPage < _lastPage) {
                // Sayfa değişimini gerçekleştir
                try {
                  // Flutter uygulama durumunu kontrol et ve ona göre işlem yap
                  _checkApplicationStateAndExecute(() {
                    _onNextPage!(_currentPage, _totalPages);
                  });

                  // Sayfa değişiminden sonra playback state'i tekrar güncelle
                  updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
                } catch (e) {
                  debugPrint('Sonraki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                debugPrint('MediaController: Son sayfadayız, sonraki sayfaya geçilemez');
                // Kullanıcıya geri bildirim ver (sayfa değişmeyecek)
                updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              }
            }
            return true;
          case 'previous':
            // Önceki sayfa işlemi - hemen sayfa değişimi yap
            if (_onPreviousPage != null) {
              // Önce cache'deki sayfa numarasını güncelle ve hemen metadata'yı restore et
              if (_cachedTitle.isNotEmpty && _currentPage > _firstPage) {
                _cachedPageNumber = _currentPage - 1;
                await _restoreMetadataFromCache();
              }

              // Playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Kitabın ilk sayfası kontrolü
              await _loadBookBoundaries(); // Sınırları güncel tut

              // İlk sayfada değilsek sayfa değişimini gerçekleştir
              if (_currentPage > _firstPage) {
                // Sayfa değişimini gerçekleştir
                try {
                  // Flutter uygulama durumunu kontrol et ve ona göre işlem yap
                  _checkApplicationStateAndExecute(() {
                    _onPreviousPage!(_currentPage);
                  });

                  // Sayfa değişiminden sonra playback state'i tekrar güncelle
                  updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
                } catch (e) {
                  debugPrint('Önceki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                debugPrint('MediaController: İlk sayfadayız, önceki sayfaya geçilemez');
                // Kullanıcıya geri bildirim ver (sayfa değişmeyecek)
                updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              }
            }
            return true;
          case 'seekTo':
            final position = call.arguments as int;
            await _audioPlayerService.seekTo(Duration(milliseconds: position));
            return true;
          case 'audio_completed':
            // iOS'tan gelen audio completion event'i
            debugPrint('MediaController callback: Audio completion received from iOS');
            // AudioPageService'e completion event'ini ilet
            if (!_completionController.isClosed) {
              _completionController.add(null);
            }
            return true;
          default:
            return null;
        }
      } catch (e) {
        debugPrint('MediaController callback method call hatası: $e');
        return false;
      }
    });
  }

  /// Method call handler'ı ayarla
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      try {
        // ÖNEMLİ: Önce hangi sistemin aktif olduğunu kontrol et
        final prefs = await SharedPreferences.getInstance();
        final playingBookCode = prefs.getString('playing_book_code');

        // Eğer Kuran sistemi aktifse, kitap sistemi method call'larını işleme
        if (playingBookCode == 'quran') {
          debugPrint(
              'MediaController: Kuran sistemi aktif, kitap method call\'ı işlenmedi: ${call.method}');
          return false;
        }

        switch (call.method) {
          case 'play':
            await _audioPlayerService.resumeAudio();
            // Play durumunda metadata'yı cache'den restore et
            await _restoreMetadataFromCache();
            return true;
          case 'pause':
            await _audioPlayerService.pauseAudio();
            // Pause durumunda metadata'yı cache'den restore et
            await _restoreMetadataFromCache();
            // Pause durumunda bildirim kontrollerinin kaybolmaması için
            // playback state'i duraklatılmış olarak güncelle
            await updatePlaybackState(STATE_PAUSED);
            return true;
          case 'stop':
            // iOS için ek güvenlik: stop işlemini güvenli bir şekilde gerçekleştir
            try {
              await _audioPlayerService.stopAudio();
              // Stop işleminden sonra servisi de durdur
              await Future.delayed(const Duration(milliseconds: 100));
              await stopService();
            } catch (e) {
              debugPrint('MediaController stop error: $e');
              // Hata durumunda da servisi durdur
              await stopService();
            }
            return true;
          case 'next':
            // Sonraki sayfa işlemi - hemen sayfa değişimi yap
            if (_onNextPage != null) {
              // Önce playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Kitabın son sayfası kontrolü
              await _loadBookBoundaries(); // Sınırları güncel tut

              // Son sayfada değilsek sayfa değişimini gerçekleştir
              if (_currentPage < _lastPage) {
                // Sayfa değişimini gerçekleştir
                try {
                  // Flutter uygulama durumunu kontrol et ve ona göre işlem yap
                  _checkApplicationStateAndExecute(() {
                    _onNextPage!(_currentPage, _totalPages);
                  });

                  // Sayfa değişiminden sonra playback state'i tekrar güncelle
                  updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
                } catch (e) {
                  debugPrint('Sonraki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                debugPrint('MediaController: Son sayfadayız, sonraki sayfaya geçilemez');
                // Kullanıcıya geri bildirim ver (sayfa değişmeyecek)
                updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              }
            }
            return true;
          case 'previous':
            // Önceki sayfa işlemi - hemen sayfa değişimi yap
            if (_onPreviousPage != null) {
              // Önce playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Kitabın ilk sayfası kontrolü
              await _loadBookBoundaries(); // Sınırları güncel tut

              // İlk sayfada değilsek sayfa değişimini gerçekleştir
              if (_currentPage > _firstPage) {
                // Sayfa değişimini gerçekleştir
                try {
                  // Flutter uygulama durumunu kontrol et ve ona göre işlem yap
                  _checkApplicationStateAndExecute(() {
                    _onPreviousPage!(_currentPage);
                  });

                  // Sayfa değişiminden sonra playback state'i tekrar güncelle
                  updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
                } catch (e) {
                  debugPrint('Önceki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                debugPrint('MediaController: İlk sayfadayız, önceki sayfaya geçilemez');
                // Kullanıcıya geri bildirim ver (sayfa değişmeyecek)
                updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              }
            }
            return true;
          case 'seekTo':
            final position = call.arguments as int;
            await _audioPlayerService.seekTo(Duration(milliseconds: position));
            return true;
          case 'getPosition':
            return _audioPlayerService.position.inMilliseconds;
          case 'onResume':
            // Uygulama ön plana geldiğinde medya kontrollerini güncelle
            if (_isServiceRunning && _audioPlayerService.isPlaying) {
              // Eğer ses çalınıyorsa, playback state'i güncelle
              updatePlaybackState(STATE_PLAYING);
            } else if (_isServiceRunning) {
              // Eğer ses çalmıyorsa ama servis çalışıyorsa, playback state'i güncelle
              updatePlaybackState(STATE_PAUSED);
            }
            return true;
          case 'audio_error':
            // Audio error durumunda güvenli bir şekilde durumu güncelle
            debugPrint('MediaController: Audio error received, updating playback state');
            updatePlaybackState(STATE_PAUSED);
            return true;
          default:
            return null;
        }
      } catch (e) {
        debugPrint('MediaController method call hatası: $e');
        return false;
      }
    });
  }

  // Ana ekranda iken de medya kontrollerinin çalışmasını sağlayacak yardımcı metod
  void _checkApplicationStateAndExecute(Function callback) {
    try {
      // Önce şu anki durumu kaydet (callback çağrılmadan önce)
      Future.delayed(const Duration(milliseconds: 50), () async {
        try {
          // Mevcut kitap kodunu ve sayfa bilgisini kontrol et
          String? bookCode = await _audioPlayerService.getPlayingBookCode();
          if (bookCode != null && bookCode.isNotEmpty) {
            // Direkt SharedPreferences'ı kullanarak mevcut sayfa bilgisini kaydet
            var prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_audio_book_page', _currentPage);
            debugPrint(
                'MediaController: Mevcut sayfa bilgisi kaydedildi: $_currentPage (callback öncesi)');
          }
        } catch (e) {
          debugPrint('MediaController: Sayfa bilgisi kaydedilemedi (callback öncesi): $e');
        }
      });

      // Callback'i çağır
      callback();

      // --- YENİ: Callback'ten sonra metadata güncelle ---
      Future.delayed(const Duration(milliseconds: 100), () async {
        try {
          String? bookCode = await _audioPlayerService.getPlayingBookCode();
          if (bookCode != null && bookCode.isNotEmpty) {
            // BookPageModel ve başlık/author'u servislerden al
            try {
              final apiService = ApiService();
              final bookTitleService = BookTitleService();
              final bookPage = await apiService.getBookPage(bookCode, _currentPage);
              final bookTitle = await bookTitleService.getTitle(bookCode);
              final bookAuthor = await bookTitleService.getAuthor(bookCode);

              // Cache'i güncelle ve metadata'yı restore et
              _cachedTitle = bookTitle.isNotEmpty ? bookTitle : "Hakikat Kitabevi";
              _cachedAuthor = bookAuthor.isNotEmpty ? bookAuthor : "Hakikat Kitabevi";
              _cachedPageNumber = _currentPage;

              await updateForBookPage(
                bookPage,
                bookTitle,
                bookAuthor,
                pageNumber: _currentPage,
              );
              debugPrint(
                  'MediaController: Metadata güncellendi (lock screen sayfa değişimi sonrası) - $_cachedTitle, Sayfa $_currentPage');

              // --- YENİ: Flutter tarafına event gönder ---
              const MethodChannel lockScreenChannel = MethodChannel('lock_screen_events');
              try {
                await lockScreenChannel.invokeMethod('pageChanged', {
                  'bookCode': bookCode,
                  'pageNumber': _currentPage,
                });
                debugPrint('MediaController: Flutter tarafına pageChanged event gönderildi');
              } catch (e) {
                debugPrint('MediaController: Flutter event gönderilemedi: $e');
              }
              // --- YENİ SONU ---
            } catch (e) {
              debugPrint('MediaController: Metadata güncellenemedi (lock screen): $e');
              // Hata durumunda cache'den restore et
              await _restoreMetadataFromCache();
            }
          } else {
            // BookCode yoksa cache'den restore et
            await _restoreMetadataFromCache();
          }
        } catch (e) {
          debugPrint('MediaController: Metadata güncellenemedi (lock screen): $e');
          // Her durumda cache'den restore et
          await _restoreMetadataFromCache();
        }
      });
      // --- YENİ SONU ---

      // Kilit ekranında yapılan sayfa değişikliklerini kaydetmek için
      // örneğin SharedPreferences'a kaydet
      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          // Sayfa değişikliklerini AudioPlayerService üzerinden
          // SharedPreferences'a kaydetmeyi dene
          String? bookCode = await _audioPlayerService.getPlayingBookCode();
          if (bookCode != null && bookCode.isNotEmpty) {
            debugPrint(
                'MediaController: Sayfa değişikliği, yeni sayfa: $_currentPage, bookCode: $bookCode');
            // Direkt SharedPreferences'ı kullanarak sayfa değişikliğini kaydet
            var prefs = await SharedPreferences.getInstance();
            // Use a book-specific key to store the current page
            await prefs.setInt('${bookCode}_current_audio_page', _currentPage);
            // Also keep the global key for backward compatibility
            await prefs.setInt('current_audio_book_page', _currentPage);

            // ÖNEMLİ: Kilit ekranından sayfa değişikliği yapıldığını belirtmek için bayrağı ayarla
            // Bu, arka plandayken de sayfa değişikliğinin algılanmasını sağlar
            await prefs.setBool('mini_player_changed_page', true);

            // Native player'dan gelen sayfa değişikliği flag'ini ayarla
            await prefs.setBool('${bookCode}_native_page_change', true);

            // Sayfa atlama bilgisini kontrol et
            final lastRequestedPage = prefs.getInt('${bookCode}_last_requested_page') ?? 0;
            final actualLoadedPage = prefs.getInt('${bookCode}_actual_loaded_page') ?? 0;
            if (lastRequestedPage > 0 &&
                actualLoadedPage > 0 &&
                lastRequestedPage != actualLoadedPage) {
              debugPrint(
                  'MediaController: Sayfa atlama tespit edildi: $lastRequestedPage -> $actualLoadedPage');
              // Gerçek yüklenen sayfayı kullan
              _currentPage = actualLoadedPage;
              await prefs.setInt('${bookCode}_current_audio_page', actualLoadedPage);
              await prefs.setInt('current_audio_book_page', actualLoadedPage);
            }

            debugPrint(
                'MediaController: Sayfa değişikliği ve native_page_change bayrağı SharedPreferences\'a kaydedildi: $_currentPage');

            // Arka planda otomatik sayfa güncelleme için broadcast channel ile mesaj gönder
            try {
              await _channel.invokeMethod('notifyPageChange', {
                'bookCode': bookCode,
                'pageNumber': _currentPage,
              });
              debugPrint('MediaController: Sayfa değişikliği bildirimi gönderildi');
            } catch (e) {
              debugPrint('MediaController: Sayfa değişikliği bildirimi gönderilemedi: $e');
            }

            // Playback durumunu güncelle
            updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
          }
        } catch (e) {
          debugPrint('MediaController: Sayfa değişikliği kaydedilemedi: $e');
          // Hata oluşsa bile playback durumunu güncelle
          updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
        }
      });
    } catch (e) {
      debugPrint('MediaController: _checkApplicationStateAndExecute hatası: $e');
    }
  }

  /// Kitap sayfa durumunu güncelle
  Future<void> updateAudioPageState({
    required String bookCode,
    required int currentPage,
    required int firstPage,
    required int lastPage,
  }) async {
    try {
      if (!_isServiceRunning) {
        await startService();
        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Flutter -> Native köprüsü üzerinden sayfa durumunu güncelle
      await _channel.invokeMethod('updateAudioPageState', {
        'bookCode': bookCode,
        'currentPage': currentPage,
        'firstPage': firstPage,
        'lastPage': lastPage,
      });

      debugPrint(
          'Sent audio page state to native. Book: $bookCode, Page: $currentPage, Boundaries: $firstPage-$lastPage');
    } catch (e) {
      debugPrint('MediaController updateAudioPageState hatası: $e');
    }
  }

  /// Uygulama durumu değişikliğini işle
  Future<void> handleAppStateChange(bool isActive) async {
    try {
      if (!isActive) {
        // Uygulama arka plana geçtiğinde
        if (_audioPlayerService.isPlaying) {
          // Eğer ses çalıyorsa servisi başlat ve durumu güncelle
          await startService();
          await updatePlaybackState(STATE_PLAYING);

          // Ek güvenlik: Arka plana geçerken ses durumunu tekrar kontrol et
          await Future.delayed(const Duration(milliseconds: 500));
          if (!_audioPlayerService.isPlaying && _audioPlayerService.playingBookCode != null) {
            debugPrint('MediaController: Audio stopped unexpectedly in background, updating state');
            await updatePlaybackState(STATE_PAUSED);
          }
        } else if (_audioPlayerService.playingBookCode != null) {
          // Eğer ses çalmıyorsa ama duraklatılmışsa ve bir kitap kodu varsa, servisi başlat ve durumu güncelle
          await startService();
          await updatePlaybackState(STATE_PAUSED);
        } else {
          // Eğer ses çalmıyorsa ve kitap kodu yoksa (stop durumu), servisi durdur
          debugPrint(
              'MediaController: Uygulama arka planda ve ses durdurulmuş, bildirim kontrollerini kaldırıyorum');
          await updatePlaybackState(STATE_STOPPED);
          await stopService();
        }
      } else {
        // Uygulama ön plana geldiğinde
        if (_audioPlayerService.isPlaying) {
          // Eğer ses çalıyorsa servisi başlat ve durumu güncelle
          await startService();
          await updatePlaybackState(STATE_PLAYING);
        } else if (_audioPlayerService.playingBookCode != null) {
          // Eğer ses çalmıyorsa ama duraklatılmışsa ve bir kitap kodu varsa, servisi başlat ve durumu güncelle
          await startService();
          await updatePlaybackState(STATE_PAUSED);
        } else {
          // Eğer ses çalmıyorsa ve kitap kodu yoksa (stop durumu), servisi durdur
          debugPrint(
              'MediaController: Uygulama ön planda ve ses durdurulmuş, bildirim kontrollerini kaldırıyorum');
          await updatePlaybackState(STATE_STOPPED);
          await stopService();
        }
      }
    } catch (e) {
      debugPrint('MediaController handleAppStateChange hatası: $e');
      // Hata durumunda güvenli bir şekilde durumu güncelle
      try {
        if (_audioPlayerService.isPlaying) {
          await updatePlaybackState(STATE_PLAYING);
        } else if (_audioPlayerService.playingBookCode != null) {
          await updatePlaybackState(STATE_PAUSED);
        } else {
          await updatePlaybackState(STATE_STOPPED);
        }
      } catch (updateError) {
        debugPrint(
            'MediaController: Playback state update error in handleAppStateChange: $updateError');
      }
    }
  }

  /// Kaynakları temizle
  Future<void> dispose() async {
    try {
      // Önce playback state'i durdurulmuş olarak işaretle
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});

      // Kısa bir gecikme ekle
      await Future.delayed(const Duration(milliseconds: 100));

      // Servisi durdur
      await stopService();

      // Tüm dinleyicileri temizle
      _audioPlayerService.playingStateStream.drain();
      _audioPlayerService.positionStream.drain();
      _audioPlayerService.durationStream.drain();
    } catch (e) {
      debugPrint('MediaController dispose hatası: $e');
    }
  }
}
