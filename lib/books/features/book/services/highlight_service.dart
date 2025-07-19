import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';

/// Metin vurgulama işlemlerini yöneten servis sınıfı
class HighlightService {
  final BookmarkService _bookmarkService = BookmarkService();

  /// Vurgulanmış metinleri yükler
  Future<List<HighlightInfo>> loadHighlightedTexts(String bookCode, int pageNumber) async {
    try {
      final bookmarks = await _bookmarkService.getPageBookmarks(bookCode, pageNumber);

      List<HighlightInfo> highlights = [];

      for (var bookmark in bookmarks) {
        if (bookmark.selectedText != null &&
            bookmark.highlightColor != null &&
            bookmark.startIndex != null &&
            bookmark.endIndex != null) {
          highlights.add(HighlightInfo(
            text: bookmark.selectedText!,
            color: bookmark.highlightColor!,
            startIndex: bookmark.startIndex!,
            endIndex: bookmark.endIndex!,
          ));
        }
      }

      return highlights;
    } catch (e) {
      debugPrint('Vurgulanmış metinleri yükleme hatası: $e');
      return []; // Hata durumunda boş liste döndür
    }
  }

  /// Vurgulanmış metni yer işareti olarak ekler
  Future<bool> addHighlightedBookmark(String bookCode, int pageNumber, String selectedText,
      Color color, int startIndex, int endIndex) async {
    if (selectedText.isEmpty || startIndex < 0 || endIndex < startIndex) {
      debugPrint(
          'Geçersiz vurgulama parametreleri: metin=$selectedText, başlangıç=$startIndex, bitiş=$endIndex');
      return false;
    }

    try {
      debugPrint(
          'Vurgulama ekleniyor: metin=$selectedText, başlangıç=$startIndex, bitiş=$endIndex');

      // Yer işaretini ekle
      await _bookmarkService.addBookmark(
        bookCode,
        pageNumber,
        selectedText: selectedText,
        highlightColor: color,
        startIndex: startIndex,
        endIndex: endIndex,
      );

      return true;
    } catch (e) {
      debugPrint('Vurgulu yer işareti ekleme hatası: $e');
      return false;
    }
  }

  /// Vurgulamayı kaldırır
  Future<bool> removeHighlight(String bookCode, int pageNumber, HighlightInfo highlight) async {
    try {
      // Yer işaretini kaldır
      await _bookmarkService.removeBookmark(
        bookCode,
        pageNumber,
        selectedText: highlight.text,
        startIndex: highlight.startIndex,
        endIndex: highlight.endIndex,
      );

      // BookmarkService önbelleğini temizle
      _bookmarkService.clearCache();

      return true;
    } catch (e) {
      debugPrint('Vurgulama kaldırılırken hata: $e');
      return false;
    }
  }

  /// Sayfada başka vurgulama veya yer işareti olup olmadığını kontrol eder
  Future<bool> hasPageBookmarks(String bookCode, int pageNumber) async {
    return await _bookmarkService.isPageBookmarked(bookCode, pageNumber);
  }
}
