import 'package:namaz_vakti_app/books/features/book/services/audio_manager.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';

class BookMediaController {
  final AudioManager audioManager;
  final String bookCode;

  BookMediaController({
    required this.audioManager,
    required this.bookCode,
  });

  // Update current page info in media controller
  void updateCurrentPage(int currentPage, int totalPages) {
    audioManager.updateCurrentPage(currentPage, totalPages);
  }

  // Update metadata for current page
  void updateMetadata(
      BookPageModel bookPage, String bookTitle, String bookAuthor, int currentPage) {
    try {
      audioManager.updateMetadata(
        bookPage,
        bookTitle,
        bookAuthor,
        currentPage,
      );
    } catch (e) {
      print('Error updating media metadata: $e');
    }
  }

  // Update media controller position
  void updatePosition(int positionMs) {
    audioManager.updatePosition(positionMs);
  }
}
