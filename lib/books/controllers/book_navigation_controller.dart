import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';

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

    print("BookNavigationController: Medya kontrolünden gelen aksiyon: $action");

    switch (action) {
      case 'next':
        if (currentPage < lastPage) {
          changePage(currentPage + 1);
        }
        break;
      case 'previous':
        if (currentPage > firstPage) {
          changePage(currentPage - 1);
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

  // ... existing code ...

  // Kitap açıldığında medya servisini başlat
  void openBook(String bookCode, int page) {
    // Add the implementation
    currentBookCode = bookCode;
    currentPage = page;
  }

  // Sayfayı değiştirdiğimizde medya servisine bildir
  void changePage(int page) {
    // Add the implementation
    currentPage = page;
  }

  // ... existing code ...
}
