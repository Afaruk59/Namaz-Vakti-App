import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/media_controller.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';

/// Ses oynatma işlemlerini yöneten servis sınıfı
class AudioManager {
  final AudioPlayerService _audioPlayerService;
  final MediaController _mediaController;
  final Function(bool) onShowAudioProgressChanged;
  String _currentBookTitle = "";
  String _currentBookAuthor = "";

  AudioManager({
    required AudioPlayerService audioPlayerService,
    required this.onShowAudioProgressChanged,
    required String bookTitle,
    required String bookAuthor,
  })  : _audioPlayerService = audioPlayerService,
        _mediaController = MediaController(audioPlayerService: audioPlayerService),
        _currentBookTitle = bookTitle,
        _currentBookAuthor = bookAuthor;

  /// Ses oynatma/durdurma işlemini yönetir
  Future<void> toggleAudio(BookPageModel? currentBookPage, {int pageNumber = 0}) async {
    try {
      if (_audioPlayerService.isPlaying) {
        // Ses çalıyorsa durdur
        await _audioPlayerService.stopAudio();
        onShowAudioProgressChanged(false);
      } else {
        // Ses çalmıyorsa başlat
        if (currentBookPage != null && currentBookPage.mp3.isNotEmpty) {
          onShowAudioProgressChanged(true);

          // Ses dosyasını çalmaya başla
          try {
            await _audioPlayerService.playAudio(currentBookPage.mp3[0]);

            // Kilit ekranı kontrollerini güncelle
            await _mediaController.updateForBookPage(
              currentBookPage,
              _currentBookTitle,
              _currentBookAuthor,
              pageNumber: pageNumber,
            );
          } catch (e) {
            print('Ses oynatma hatası: $e');
            // Hata durumunda progress bar'ı gizle
            onShowAudioProgressChanged(false);
          }
        }
      }
    } catch (e) {
      print('Ses oynatma/durdurma hatası: $e');
    }
  }

  /// Ses oynatma/duraklatma işlemini yönetir
  Future<void> handlePlayPause({int pageNumber = 0}) async {
    try {
      if (_audioPlayerService.isPlaying) {
        await _audioPlayerService.pauseAudio();
        // Pause durumunda _showAudioProgress'i true olarak tut
        onShowAudioProgressChanged(true);

        // Kilit ekranı kontrollerini güncelle - duraklatıldı
        await _mediaController.updatePlaybackState(MediaController.STATE_PAUSED);

        // Pozisyonu güncelle
        await _mediaController.updatePosition(_audioPlayerService.position.inMilliseconds);
      } else {
        await _audioPlayerService.resumeAudio();
        onShowAudioProgressChanged(true);

        // Kilit ekranı kontrollerini güncelle - çalıyor
        await _mediaController.updatePlaybackState(MediaController.STATE_PLAYING);

        // Pozisyonu güncelle
        await _mediaController.updatePosition(_audioPlayerService.position.inMilliseconds);

        // Kısa bir gecikme sonra tekrar güncelle
        await Future.delayed(Duration(milliseconds: 200));
        if (_audioPlayerService.isPlaying) {
          await _mediaController.updatePlaybackState(MediaController.STATE_PLAYING);
          await _mediaController.updatePosition(_audioPlayerService.position.inMilliseconds);
        }
      }
    } catch (e) {
      print('Ses oynatma/duraklatma hatası: $e');
    }
  }

  /// Ses dosyasını çalar
  Future<void> playAudio(BookPageModel? currentBookPage, {int pageNumber = 0}) async {
    try {
      // Eğer ses çalınıyorsa, önce mevcut sesi durdur
      if (_audioPlayerService.isPlaying) {
        await _audioPlayerService.stopAudio();
        // Kısa bir gecikme ekleyerek ses dosyasının tamamen durmasını sağla
        await Future.delayed(Duration(milliseconds: 100));
      }

      if (currentBookPage != null && currentBookPage.mp3.isNotEmpty) {
        // Önce kilit ekranı kontrollerini güncelle - ses çalmadan önce
        await _mediaController.updateForBookPage(
          currentBookPage,
          _currentBookTitle,
          _currentBookAuthor,
          pageNumber: pageNumber,
        );

        // Yeni bir ses dosyası çal
        await _audioPlayerService.playAudio(currentBookPage.mp3[0]);
        onShowAudioProgressChanged(true);

        // Ses çalmaya başladıktan sonra tekrar güncelle - durumu PLAYING olarak ayarla
        await _mediaController.updatePlaybackState(MediaController.STATE_PLAYING);

        // Kısa bir gecikme sonra metadata'yı tekrar güncelle
        await Future.delayed(Duration(milliseconds: 300));

        // Ses çalma durumunu tekrar kontrol et ve güncelle
        if (_audioPlayerService.isPlaying) {
          await updateMetadata(
            currentBookPage,
            _currentBookTitle,
            _currentBookAuthor,
            pageNumber,
          );

          // Pozisyonu güncelle
          await _mediaController.updatePosition(_audioPlayerService.position.inMilliseconds);
        }
      } else if (_audioPlayerService.isPlaying) {
        // Eğer ses çalınıyorsa ve yeni sayfada ses dosyası yoksa, sesi durdur
        await _audioPlayerService.stopAudio();
        onShowAudioProgressChanged(false);
      }
    } catch (e) {
      print('Ses çalma hatası: $e');
      // Hata durumunda ses çalmayı durdur ve UI'ı güncelle
      try {
        await _audioPlayerService.stopAudio();
      } catch (stopError) {
        print('Hata sonrası ses durdurma hatası: $stopError');
      }
      onShowAudioProgressChanged(false);
    }
  }

  /// Seek to position in milliseconds
  Future<void> seekTo(double milliseconds) async {
    try {
      print('AudioManager: Seeking to $milliseconds ms');

      // Ensure value is within valid range
      final Duration position = Duration(milliseconds: milliseconds.toInt());
      final Duration maxDuration = _audioPlayerService.duration;

      // Use a safe duration
      Duration safeDuration = position;
      if (maxDuration.inMilliseconds > 0 && position.inMilliseconds >= maxDuration.inMilliseconds) {
        // If seeking beyond max duration, go to a slightly earlier position
        safeDuration = maxDuration - Duration(milliseconds: 500);
        print(
            'AudioManager: Adjusted seek position to ${safeDuration.inMilliseconds} ms (before end)');
      }

      // Perform the seek operation
      await _audioPlayerService.seekTo(safeDuration);

      // Update the media controller position
      if (_mediaController != null) {
        _mediaController.updatePosition(safeDuration.inMilliseconds);
      }

      print(
          'AudioManager: Seek successful to ${safeDuration.inSeconds}.${safeDuration.inMilliseconds % 1000} seconds');
      return;
    } catch (e) {
      print('AudioManager: Error during seek: $e');
    }
  }

  /// Oynatma hızını değiştirir
  void changeSpeed() {
    final nextSpeed = _audioPlayerService.getNextSpeed();
    _audioPlayerService.setPlaybackSpeed(nextSpeed);
  }

  /// Sonraki sayfaya geçiş yapar ve ses dosyasını çalar
  Future<void> goToNextPageAndPlayAudio(
    int currentPage,
    int totalPages,
    Function(int) onPageChanged,
    BookPageModel? currentBookPage,
  ) async {
    try {
      if (!isPlaying) return;

      if (currentPage < totalPages) {
        // Eğer otomatik sayfa geçişi yapılacaksa
        int nextPage = currentPage + 1;

        // Ses çalma durumunu koru
        onShowAudioProgressChanged(true);

        // Önce ses oynatıcıyı durdur
        await _audioPlayerService.stopAudio();

        // Sayfa geçişini yap
        onPageChanged(nextPage);

        // Kısa bir gecikme ekleyerek sayfa yüklenmesinin tamamlanmasını bekle
        await Future.delayed(Duration(milliseconds: 500));

        if (currentBookPage != null && currentBookPage.mp3.isNotEmpty) {
          // Ses dosyasını çalmadan önce durumu güncelle
          onShowAudioProgressChanged(true);

          // Ses dosyasını çal
          try {
            await _audioPlayerService.playAudio(currentBookPage.mp3[0]);

            // Kilit ekranı kontrollerini güncelle
            await _mediaController.updateForBookPage(
              currentBookPage,
              _currentBookTitle,
              _currentBookAuthor,
              pageNumber: nextPage,
            );
          } catch (error) {
            print('Otomatik sayfa geçişinde ses dosyası çalma hatası: $error');
            // Hata durumunda _showAudioProgress'i false yap
            onShowAudioProgressChanged(false);
          }
        } else {
          // Eğer ses dosyası yoksa _showAudioProgress'i false yap
          onShowAudioProgressChanged(false);
        }
      } else {
        // Son sayfadaysak ses çalma durumunu kapat
        onShowAudioProgressChanged(false);
      }
    } catch (e) {
      print('Sonraki sayfaya geçiş hatası: $e');
      // Hata durumunda ses çalmayı durdur ve UI'ı güncelle
      try {
        await _audioPlayerService.stopAudio();
      } catch (stopError) {
        print('Hata sonrası ses durdurma hatası: $stopError');
      }
      onShowAudioProgressChanged(false);
    }
  }

  /// Önceki sayfaya geçiş yapar ve ses dosyasını çalar
  Future<void> goToPreviousPageAndPlayAudio(
    int currentPage,
    Function(int) onPageChanged,
    BookPageModel? currentBookPage,
  ) async {
    try {
      if (currentPage > 1) {
        // Eğer otomatik sayfa geçişi yapılacaksa
        int previousPage = currentPage - 1;

        // Ses çalma durumunu koru
        onShowAudioProgressChanged(true);

        // Önce ses oynatıcıyı durdur
        await _audioPlayerService.stopAudio();

        // Sayfa geçişini yap
        onPageChanged(previousPage);

        // Kısa bir gecikme ekleyerek sayfa yüklenmesinin tamamlanmasını bekle
        await Future.delayed(Duration(milliseconds: 500));

        if (currentBookPage != null && currentBookPage.mp3.isNotEmpty) {
          // Ses dosyasını çalmadan önce durumu güncelle
          onShowAudioProgressChanged(true);

          // Ses dosyasını çal
          try {
            await _audioPlayerService.playAudio(currentBookPage.mp3[0]);

            // Kilit ekranı kontrollerini güncelle
            await _mediaController.updateForBookPage(
              currentBookPage,
              _currentBookTitle,
              _currentBookAuthor,
              pageNumber: previousPage,
            );
          } catch (error) {
            print('Otomatik sayfa geçişinde ses dosyası çalma hatası: $error');
            // Hata durumunda _showAudioProgress'i false yap
            onShowAudioProgressChanged(false);
          }
        } else {
          // Eğer ses dosyası yoksa _showAudioProgress'i false yap
          onShowAudioProgressChanged(false);
        }
      }
    } catch (e) {
      print('Önceki sayfaya geçiş hatası: $e');
      // Hata durumunda ses çalmayı durdur ve UI'ı güncelle
      try {
        await _audioPlayerService.stopAudio();
      } catch (stopError) {
        print('Hata sonrası ses durdurma hatası: $stopError');
      }
      onShowAudioProgressChanged(false);
    }
  }

  /// Kitap bilgilerini günceller
  void updateBookInfo(String title, String author) {
    _currentBookTitle = title;
    _currentBookAuthor = author;
  }

  /// Mevcut sayfa bilgisini güncelle
  void updateCurrentPage(int currentPage, int totalPages) {
    _mediaController.updateCurrentPage(currentPage, totalPages);
  }

  /// Medya kontrolcüsünün metadata bilgilerini güncelle
  Future<void> updateMetadata(
    BookPageModel bookPage,
    String bookTitle,
    String bookAuthor,
    int pageNumber,
  ) async {
    try {
      await _mediaController.updateForBookPage(
        bookPage,
        bookTitle,
        bookAuthor,
        pageNumber: pageNumber,
      );
    } catch (e) {
      print('Medya metadata güncelleme hatası: $e');
    }
  }

  /// Medya kontrolcüsünün pozisyon bilgisini güncelle
  Future<void> updatePosition(int positionMs) async {
    try {
      await _mediaController.updatePosition(positionMs);
    } catch (e) {
      print('Medya pozisyon güncelleme hatası: $e');
    }
  }

  /// Kilit ekranında kullanmak üzere kitap sayfa durumunu güncelle
  Future<void> updateAudioPageState({
    required String bookCode,
    required int currentPage,
    required int firstPage,
    required int lastPage,
  }) async {
    try {
      // Flutter -> Native köprüsü üzerinden sayfa durumunu güncelle
      // Bu, kilit ekranında ileri/geri tuşları için sınırları belirler
      await _mediaController.updateAudioPageState(
        bookCode: bookCode,
        currentPage: currentPage,
        firstPage: firstPage,
        lastPage: lastPage,
      );
      print(
          'Updated audio page state in native. Book: $bookCode, Page: $currentPage, Boundaries: $firstPage-$lastPage');
    } catch (e) {
      print('Error updating audio page state: $e');
    }
  }

  /// Kilit ekranı medya kontrolleri için callback'leri ayarla
  void setupMediaControllerCallbacks({
    required Function(int, int) onNextPage,
    required Function(int) onPreviousPage,
    required int currentPage,
    required int totalPages,
  }) {
    // Önce mevcut sayfa bilgisini güncelle
    _mediaController.updateCurrentPage(currentPage, totalPages);

    // Sonra callback'leri ayarla
    _mediaController.setPageChangeCallbacks(
      onNextPage: (currentPage, totalPages) {
        // Hemen sayfa değişimini gerçekleştir
        try {
          onNextPage(currentPage, totalPages);
        } catch (e) {
          print('Sonraki sayfa callback hatası: $e');
        }
      },
      onPreviousPage: (currentPage) {
        // Hemen sayfa değişimini gerçekleştir
        try {
          onPreviousPage(currentPage);
        } catch (e) {
          print('Önceki sayfa callback hatası: $e');
        }
      },
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  /// Ses oynatıcıyı sıfırlar
  void reset() {
    try {
      // Ses oynatıcıyı güvenli bir şekilde durdur ve sıfırla
      if (_audioPlayerService.isPlaying) {
        try {
          _audioPlayerService.stopAudio();
          // Burada stopAudio kullanıyoruz çünkü ekrandan çıkıldığında
          // ses tamamen durdurulmalı
        } catch (e) {
          print('Ses durdurma hatası: $e');
        }
      }

      try {
        // AudioPlayerService'i dispose etmek yerine reset et
        _audioPlayerService.reset();

        // MediaController'ı durdur
        _mediaController.stopService();
      } catch (e) {
        print('AudioPlayerService reset hatası: $e');
      }
    } catch (e) {
      print('AudioManager reset hatası: $e');
    }
  }

  /// Kaynakları temizle
  void dispose() {
    reset();
    _mediaController.dispose();
  }

  /// Ses oynatıcıyı durdurmadan kaynakları temizle
  void disposeWithoutStoppingAudio() {
    try {
      // MediaController'ı durdurma, ana ekranda devam etmesi için
      // _mediaController.stopService();

      // Sadece MediaController'ı dispose et
      _mediaController.dispose();
    } catch (e) {
      print('AudioManager disposeWithoutStoppingAudio hatası: $e');
    }
  }

  /// Kitap sesli dinlemeyi tamamen durdurur ve notification'ı kapatır
  Future<void> stopAllAudioAndNotification() async {
    try {
      await _mediaController.updatePlaybackState(MediaController.STATE_STOPPED);
      await Future.delayed(Duration(milliseconds: 100));
      await _mediaController.stopService();
      await Future.delayed(Duration(milliseconds: 100));
      await _mediaController.stopService();
      await _audioPlayerService.stopAudio();
      onShowAudioProgressChanged(false);
    } catch (e) {
      print('stopAllAudioAndNotification hata: $e');
    }
  }

  /// Ses çalınıyor mu
  bool get isPlaying => _audioPlayerService.isPlaying;

  /// Ses ilerleme çubuğu gösteriliyor mu
  bool get isShowingAudioProgress => _audioPlayerService.isPlaying;

  /// Ses konumu
  Duration get position => _audioPlayerService.position;

  /// Ses süresi
  Duration get duration => _audioPlayerService.duration;

  /// Oynatma hızı
  double get playbackSpeed => _audioPlayerService.playbackSpeed;

  /// Medya servisini başlat
  Future<void> startService() async {
    try {
      // MediaController aracılığıyla native medya servisini başlat
      await _mediaController.startService();
      print('MediaController service started');
    } catch (e) {
      print('Error starting media service: $e');
    }
  }

  /// Kilit ekranında medya kontrollerini güncelle
  Future<void> updateForLockScreen(int currentPage) async {
    try {
      // Eğer ses çalınıyorsa veya duraklatılmışsa
      if (_audioPlayerService.isPlaying || _audioPlayerService.position.inSeconds > 0) {
        // Medya servisini başlat
        await _mediaController.startService();

        // Kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 200));

        // Metadata'yı güncelle (her zaman başlığa sayfa numarasını ekle)
        await _mediaController.updateMetadata(
          title: '$_currentBookTitle - Sayfa $currentPage',
          author: _currentBookAuthor,
          coverUrl: '',
          durationMs: _audioPlayerService.duration.inMilliseconds > 0
              ? _audioPlayerService.duration.inMilliseconds
              : 30000,
        );

        // Oynatma durumunu güncelle
        final state = _audioPlayerService.isPlaying
            ? MediaController.STATE_PLAYING
            : MediaController.STATE_PAUSED;
        await _mediaController.updatePlaybackState(state);

        // Pozisyonu güncelle
        await _mediaController.updatePosition(_audioPlayerService.position.inMilliseconds);
      }
    } catch (e) {
      print('Error updating lock screen: $e');
    }
  }
}
