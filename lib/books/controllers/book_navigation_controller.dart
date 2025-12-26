import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:flutter/material.dart';

class BookNavigationController {
  // Property declarations to fix the undefined variables
  String currentBookCode = '';
  int currentPage = 1;
  int firstPage = 1;
  int lastPage = 9999;
  bool playingBook = false;
  AudioPlayerService? audioController;

  // ... existing code ...

  // Medya kontrollerinden tetiklenen sayfa değişimlerini işle
  void updateFromMediaControls(String action) {
    if (currentBookCode.isEmpty) return;

    debugPrint("BookNavigationController: Medya kontrolünden gelen aksiyon: $action");

    switch (action) {
      case 'next':
        if (currentPage < lastPage) {
          changePage(currentPage + 1);
          _updateMediaPageState(); // Medya servisine bildir
        }
        break;
      case 'previous':
        if (currentPage > firstPage) {
          changePage(currentPage - 1);
          _updateMediaPageState(); // Medya servisine bildir
        }
        break;
      case 'togglePlay':
        // Play/Pause durumunu yönet, gerekirse sesli okuma kontrolörüne bildir
        if (playingBook && audioController != null) {
          togglePlay();
        }
        break;
    }
  }

  // Audiocontroller için toggle play metodu
  void togglePlay() {
    if (audioController != null) {
      if (audioController!.isPlaying) {
        audioController!.pauseAudio();
      } else {
        audioController!.resumeAudio();
      }
    }
  }

  // Medya servisine sayfa durumunu bildir
  void _updateMediaPageState() {
    if (currentBookCode.isEmpty) return;

    const platform = MethodChannel('com.afaruk59.namaz_vakti_app/media_controls');
    try {
      platform.invokeMethod('updateAudioPageState', {
        'bookCode': currentBookCode,
        'currentPage': currentPage,
        'firstPage': firstPage,
        'lastPage': lastPage,
      });
    } catch (e) {
      debugPrint("Medya servisi sayfa durumu güncelleme hatası: $e");
    }
  }

  // Medya servisini başlat ve sayfa durumunu bildir
  void initMediaService() {
    if (currentBookCode.isEmpty) return;

    const platform = MethodChannel('com.afaruk59.namaz_vakti_app/media_controls');
    try {
      platform.invokeMethod('initMediaService');
      _updateMediaPageState();
    } catch (e) {
      debugPrint("Medya servisi başlatma hatası: $e");
    }
  }

  // ... existing code ...

  // Kitap açıldığında medya servisini başlat
  void openBook(String bookCode, int page) {
    // Add the implementation
    currentBookCode = bookCode;
    currentPage = page;
    // Medya servisini başlat
    initMediaService();
  }

  // Sayfayı değiştirdiğimizde medya servisine bildir
  void changePage(int page) {
    // Add the implementation
    currentPage = page;
    // Sayfa değiştiğinde medya servisine bildir
    _updateMediaPageState();
  }

  // ... existing code ...
}
