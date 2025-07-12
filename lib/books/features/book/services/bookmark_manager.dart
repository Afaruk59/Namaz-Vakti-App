import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';

/// Yer işareti işlemlerini yöneten servis sınıfı
class BookmarkManager {
  final BookmarkService _bookmarkService;
  final Function(bool) onBookmarkStatusChanged;
  final Function(bool) onHasBookmarksChanged;

  BookmarkManager({
    required BookmarkService bookmarkService,
    required this.onBookmarkStatusChanged,
    required this.onHasBookmarksChanged,
  }) : _bookmarkService = bookmarkService;

  /// Yer işareti durumunu kontrol eder
  Future<void> checkBookmarkStatus(String bookCode, int pageNumber) async {
    try {
      // Sadece sayfa yer işaretini kontrol et, metin vurgulamalarını değil
      final isBookmarked = await _bookmarkService.isPageBookmarked(bookCode, pageNumber);

      onBookmarkStatusChanged(isBookmarked);
    } catch (e) {
      print('Yer işareti durumu kontrol edilirken hata: $e');
    }
  }

  /// Kitapta herhangi bir yer işareti olup olmadığını kontrol eder
  Future<void> checkHasBookmarks(String bookCode) async {
    try {
      final bookmarks = await _bookmarkService.getBookmarks(bookCode);
      onHasBookmarksChanged(bookmarks.isNotEmpty);
    } catch (e) {
      print('Kitap yer işaretleri kontrol edilirken hata: $e');
    }
  }

  /// Yer işareti durumunu yeniler
  Future<void> refreshBookmarkStatus(String bookCode, int pageNumber) async {
    await checkBookmarkStatus(bookCode, pageNumber);
    await checkHasBookmarks(bookCode);

    // BookmarkService önbelleğini temizle
    _bookmarkService.clearCache();
  }

  /// Yer işaretini ekler/kaldırır
  Future<void> toggleBookmark(String bookCode, int pageNumber, bool isBookmarked) async {
    final newStatus = !isBookmarked;

    if (newStatus) {
      // Sadece sayfa yer işaretini ekle, metin vurgulamalarına dokunma
      await _bookmarkService.addPageBookmark(bookCode, pageNumber);

      onBookmarkStatusChanged(newStatus);
      onHasBookmarksChanged(true); // En az bir yer işareti var
    } else {
      // Sadece sayfa yer işaretini kaldır, metin vurgulamalarına dokunma
      await _bookmarkService.removePageBookmark(bookCode, pageNumber);

      // Kitapta hala yer işareti veya vurgulanmış metin var mı kontrol et
      final bookmarks = await _bookmarkService.getBookmarks(bookCode);

      onBookmarkStatusChanged(newStatus);
      onHasBookmarksChanged(
          bookmarks.isNotEmpty); // Kitapta hala yer işareti varsa true, yoksa false
    }

    // BookmarkService önbelleğini temizle
    _bookmarkService.clearCache();
  }
}
