import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_manager.dart';

class BookBookmarkController {
  final String bookCode;
  final BookmarkService bookmarkService;
  late final BookmarkManager _bookmarkManager;

  // Current state
  bool isBookmarked = false;
  bool hasBookmarks = false;

  // State change callbacks
  final Function(bool) onBookmarkStatusChanged;
  final Function(bool) onHasBookmarksChanged;

  BookBookmarkController({
    required this.bookCode,
    required this.bookmarkService,
    required this.onBookmarkStatusChanged,
    required this.onHasBookmarksChanged,
  }) {
    // Create a new BookmarkManager with our callbacks
    _bookmarkManager = BookmarkManager(
      bookmarkService: bookmarkService,
      onBookmarkStatusChanged: (value) {
        isBookmarked = value;
        onBookmarkStatusChanged(value);
      },
      onHasBookmarksChanged: (value) {
        hasBookmarks = value;
        onHasBookmarksChanged(value);
      },
    );
  }

  // Initialize bookmark status
  Future<void> initializeBookmarkStatus(int currentPage) async {
    await checkBookmarkStatus(currentPage);
    await checkHasBookmarks();
  }

  // Check if current page is bookmarked
  Future<void> checkBookmarkStatus(int pageNumber) async {
    await _bookmarkManager.checkBookmarkStatus(bookCode, pageNumber);
  }

  // Check if book has any bookmarks
  Future<void> checkHasBookmarks() async {
    await _bookmarkManager.checkHasBookmarks(bookCode);
  }

  // Toggle bookmark on current page
  Future<void> toggleBookmark(int pageNumber) async {
    await _bookmarkManager.toggleBookmark(bookCode, pageNumber, isBookmarked);
  }

  // Refresh bookmark status - called when returning from BookmarksScreen
  Future<void> refreshBookmarkStatus(int pageNumber) async {
    await _bookmarkManager.refreshBookmarkStatus(bookCode, pageNumber);
  }

  // Clear bookmark cache (for force refresh)
  void clearCache() {
    bookmarkService.clearCache();
  }
}
