import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';

/// Kilit ekranında medya kontrollerini yöneten sınıf
class MediaController {
  static MediaController? _instance;
  factory MediaController.singleton(AudioPlayerService audioPlayerService) {
    return _instance ??= MediaController(audioPlayerService: audioPlayerService);
  }
  static const MethodChannel _channel =
      MethodChannel('com.afaruk59.namaz_vakti_app/media_controls');
  final AudioPlayerService _audioPlayerService;
  final BookProgressService _bookProgressService = BookProgressService();
  bool _isServiceRunning = false;

  // Playback state sabitleri
  static const int STATE_NONE = 0;
  static const int STATE_PLAYING = 3;
  static const int STATE_PAUSED = 2;
  static const int STATE_STOPPED = 1;

  // Kitap sınırları için değişkenler
  int _firstPage = 1;
  int _lastPage = 9999;

  MediaController({required AudioPlayerService audioPlayerService})
      : _audioPlayerService = audioPlayerService {
    _setupListeners();
    _setupMethodCallHandler();
  }

  /// Servis başlatma
  Future<void> startService() async {
    try {
      if (!_isServiceRunning) {
        await _channel.invokeMethod('startService');
        _isServiceRunning = true;

        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 200));
      }
    } catch (e) {
      print('MediaController startService hatası: $e');
      // Hata durumunda servis durumunu güncelle
      _isServiceRunning = false;
    }
  }

  /// Servis durdurma
  Future<void> stopService() async {
    // Bildirim player'ı kesinlikle kaldırmak için agresif şekilde çağır
    try {
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});
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
      print('MediaController stopService (agresif) hata: $e');
      _isServiceRunning = false;
    }
  }

  /// Oynatma durumunu güncelleme
  Future<void> updatePlaybackState(int state) async {
    try {
      // Sadece ses çalarken veya state PLAYING ise native'e gönder
      if (!_audioPlayerService.isPlaying && state != STATE_PLAYING) {
        // Eğer ses çalmıyorsa ve state PLAYING değilse, hiçbir şey yapma
        return;
      }
      if (!_isServiceRunning) {
        await startService();
        await Future.delayed(Duration(milliseconds: 100));
      }
      await _channel.invokeMethod('updatePlaybackState', {'state': state.toInt()});
      if (state == STATE_PLAYING) {
        await updatePosition(_audioPlayerService.position.inMilliseconds);
      }
    } catch (e) {
      print('MediaController updatePlaybackState hatası: $e');
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
    try {
      // Sadece ses çalarken notification başlat
      if (_audioPlayerService.isPlaying) {
        if (!_isServiceRunning) {
          await startService();
          await Future.delayed(Duration(milliseconds: 200));
        }

        // Başlığa sayfa numarasını ekle
        String displayTitle = pageNumber > 0 ? "$title - Sayfa $pageNumber" : title;

        // Metadata'yı güncelle
        await _channel.invokeMethod('updateMetadata', {
          'title': displayTitle,
          'author': author,
          'coverUrl': coverUrl,
          'duration': durationMs.toInt(),
        });

        // Kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 300));

        // Metadata'yı tekrar güncelle
        await _channel.invokeMethod('updateMetadata', {
          'title': displayTitle,
          'author': author,
          'coverUrl': coverUrl,
          'duration': durationMs.toInt(),
        });

        // Son bir kez daha güncelle
        await Future.delayed(Duration(milliseconds: 300));
        await _channel.invokeMethod('updateMetadata', {
          'title': displayTitle,
          'author': author,
          'coverUrl': coverUrl,
          'duration': durationMs.toInt(),
        });
      }
    } catch (e) {
      print('MediaController updateMetadata hatası: $e');
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
      // Her dinleme başlatıldığında method channel handler'ı tekrar ata
      _setupMethodCallHandler();
      // Sadece ses çalarken notification başlat
      if (_audioPlayerService.isPlaying) {
        if (!_isServiceRunning) {
          await startService();
          await Future.delayed(Duration(milliseconds: 200));
        }

        // Metadata güncelle
        await updateMetadata(
          title: bookTitle,
          author: bookAuthor,
          coverUrl: '',
          durationMs: _audioPlayerService.duration.inMilliseconds > 0
              ? _audioPlayerService.duration.inMilliseconds
              : 30000,
          pageNumber: pageNumber,
        );

        // Oynatma durumunu güncelle
        final state = _audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED;
        await updatePlaybackState(state);

        // Pozisyonu güncelle
        if (_audioPlayerService.isPlaying) {
          await updatePosition(_audioPlayerService.position.inMilliseconds);
        }

        // Kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 300));

        // Metadata'yı tekrar güncelle
        await updateMetadata(
          title: bookTitle,
          author: bookAuthor,
          coverUrl: '',
          durationMs: _audioPlayerService.duration.inMilliseconds > 0
              ? _audioPlayerService.duration.inMilliseconds
              : 30000,
          pageNumber: pageNumber,
        );
      }
    } catch (e) {
      print('MediaController updateForBookPage hatası: $e');
    }
  }

  /// Dinleyicileri ayarla
  void _setupListeners() {
    // Oynatma durumu değişikliklerini dinle
    _audioPlayerService.playingStateStream.listen((isPlaying) {
      final state = isPlaying ? STATE_PLAYING : STATE_PAUSED;
      updatePlaybackState(state);
    });

    // Pozisyon değişikliklerini dinle
    _audioPlayerService.positionStream.listen((position) {
      updatePosition(position.inMilliseconds);
    });

    // Süre değişikliklerini dinle
    _audioPlayerService.durationStream.listen((duration) {
      // Süre değiştiğinde metadata'yı güncelle
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

        print(
            'MediaController: Kitap sınırları yüklendi - İlk sayfa: $_firstPage, Son sayfa: $_lastPage');
      }
    } catch (e) {
      print('MediaController: Kitap sınırları yüklenirken hata: $e');
    }
  }

  /// Method call handler'ı ayarla
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'play':
            await _audioPlayerService.resumeAudio();
            return true;
          case 'pause':
            await _audioPlayerService.pauseAudio();
            // Pause durumunda bildirim kontrollerinin kaybolmaması için
            // playback state'i duraklatılmış olarak güncelle
            await updatePlaybackState(STATE_PAUSED);
            return true;
          case 'stop':
            await _audioPlayerService.stopAudio();
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
                  print('Sonraki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                print('MediaController: Son sayfadayız, sonraki sayfaya geçilemez');
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
                  print('Önceki sayfa işlemi hatası: $e');
                  // Hata durumunda playback state'i güncelle
                  updatePlaybackState(STATE_PAUSED);
                }
              } else {
                print('MediaController: İlk sayfadayız, önceki sayfaya geçilemez');
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
            print('MediaController: Audio error received, updating playback state');
            updatePlaybackState(STATE_PAUSED);
            return true;
          default:
            return null;
        }
      } catch (e) {
        print('MediaController method call hatası: $e');
        return false;
      }
    });
  }

  // Ana ekranda iken de medya kontrollerinin çalışmasını sağlayacak yardımcı metod
  void _checkApplicationStateAndExecute(Function callback) {
    try {
      // Önce şu anki durumu kaydet (callback çağrılmadan önce)
      Future.delayed(Duration(milliseconds: 50), () async {
        try {
          // Mevcut kitap kodunu ve sayfa bilgisini kontrol et
          String? bookCode = await _audioPlayerService.getPlayingBookCode();
          if (bookCode != null && bookCode.isNotEmpty) {
            // Direkt SharedPreferences'ı kullanarak mevcut sayfa bilgisini kaydet
            var prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_audio_book_page', _currentPage);
            print(
                'MediaController: Mevcut sayfa bilgisi kaydedildi: $_currentPage (callback öncesi)');
          }
        } catch (e) {
          print('MediaController: Sayfa bilgisi kaydedilemedi (callback öncesi): $e');
        }
      });

      // Callback'i çağır
      callback();

      // --- YENİ: Callback'ten sonra metadata güncelle ---
      Future.delayed(Duration(milliseconds: 100), () async {
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
              await updateForBookPage(
                bookPage,
                bookTitle,
                bookAuthor,
                pageNumber: _currentPage,
              );
              print('MediaController: Metadata güncellendi (lock screen sayfa değişimi sonrası)');

              // --- YENİ: Flutter tarafına event gönder ---
              const MethodChannel lockScreenChannel = MethodChannel('lock_screen_events');
              try {
                await lockScreenChannel.invokeMethod('pageChanged', {
                  'bookCode': bookCode,
                  'pageNumber': _currentPage,
                });
                print('MediaController: Flutter tarafına pageChanged event gönderildi');
              } catch (e) {
                print('MediaController: Flutter event gönderilemedi: $e');
              }
              // --- YENİ SONU ---
            } catch (e) {
              print('MediaController: Metadata güncellenemedi (lock screen): $e');
            }
          }
        } catch (e) {
          print('MediaController: Metadata güncellenemedi (lock screen): $e');
        }
      });
      // --- YENİ SONU ---

      // Kilit ekranında yapılan sayfa değişikliklerini kaydetmek için
      // örneğin SharedPreferences'a kaydet
      Future.delayed(Duration(milliseconds: 200), () async {
        try {
          // Sayfa değişikliklerini AudioPlayerService üzerinden
          // SharedPreferences'a kaydetmeyi dene
          String? bookCode = await _audioPlayerService.getPlayingBookCode();
          if (bookCode != null && bookCode.isNotEmpty) {
            print(
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

            print(
                'MediaController: Sayfa değişikliği ve mini_player_changed_page bayrağı SharedPreferences\'a kaydedildi: $_currentPage');

            // Arka planda otomatik sayfa güncelleme için broadcast channel ile mesaj gönder
            try {
              await _channel.invokeMethod('notifyPageChange', {
                'bookCode': bookCode,
                'pageNumber': _currentPage,
              });
              print('MediaController: Sayfa değişikliği bildirimi gönderildi');
            } catch (e) {
              print('MediaController: Sayfa değişikliği bildirimi gönderilemedi: $e');
            }

            // Playback durumunu güncelle
            updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
          }
        } catch (e) {
          print('MediaController: Sayfa değişikliği kaydedilemedi: $e');
          // Hata oluşsa bile playback durumunu güncelle
          updatePlaybackState(_audioPlayerService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
        }
      });
    } catch (e) {
      print('MediaController: _checkApplicationStateAndExecute hatası: $e');
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
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Flutter -> Native köprüsü üzerinden sayfa durumunu güncelle
      await _channel.invokeMethod('updateAudioPageState', {
        'bookCode': bookCode,
        'currentPage': currentPage,
        'firstPage': firstPage,
        'lastPage': lastPage,
      });

      print(
          'Sent audio page state to native. Book: $bookCode, Page: $currentPage, Boundaries: $firstPage-$lastPage');
    } catch (e) {
      print('MediaController updateAudioPageState hatası: $e');
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
          await Future.delayed(Duration(milliseconds: 500));
          if (!_audioPlayerService.isPlaying && _audioPlayerService.playingBookCode != null) {
            print('MediaController: Audio stopped unexpectedly in background, updating state');
            await updatePlaybackState(STATE_PAUSED);
          }
        } else if (_audioPlayerService.playingBookCode != null) {
          // Eğer ses çalmıyorsa ama duraklatılmışsa ve bir kitap kodu varsa, servisi başlat ve durumu güncelle
          await startService();
          await updatePlaybackState(STATE_PAUSED);
        } else {
          // Eğer ses çalmıyorsa ve kitap kodu yoksa (stop durumu), servisi durdur
          print(
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
          print(
              'MediaController: Uygulama ön planda ve ses durdurulmuş, bildirim kontrollerini kaldırıyorum');
          await updatePlaybackState(STATE_STOPPED);
          await stopService();
        }
      }
    } catch (e) {
      print('MediaController handleAppStateChange hatası: $e');
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
        print('MediaController: Playback state update error in handleAppStateChange: $updateError');
      }
    }
  }

  /// Kaynakları temizle
  Future<void> dispose() async {
    try {
      // Önce playback state'i durdurulmuş olarak işaretle
      await _channel.invokeMethod('updatePlaybackState', {'state': STATE_STOPPED});

      // Kısa bir gecikme ekle
      await Future.delayed(Duration(milliseconds: 100));

      // Servisi durdur
      await stopService();

      // Tüm dinleyicileri temizle
      _audioPlayerService.playingStateStream.drain();
      _audioPlayerService.positionStream.drain();
      _audioPlayerService.durationStream.drain();
    } catch (e) {
      print('MediaController dispose hatası: $e');
    }
  }
}
