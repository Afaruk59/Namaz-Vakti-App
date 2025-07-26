import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_page_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookPageController {
  final String bookCode;
  final ApiService apiService;
  final BookProgressService bookProgressService;
  late BookPageManager pageManager;
  BookPageModel? currentBookPage;

  // Callback when the current page changes
  final Function(int) onPageChanged;

  // Callback when a page is loaded
  final Function(BookPageModel) onPageLoaded;

  BookPageController({
    required this.bookCode,
    required this.apiService,
    required this.bookProgressService,
    required this.onPageChanged,
    required this.onPageLoaded,
    int initialPage = 1,
  }) {
    // Initialize the page manager
    pageManager = BookPageManager(
      bookCode: bookCode,
      apiService: apiService,
      bookProgressService: bookProgressService,
      onPageLoaded: (bookPage) {
        currentBookPage = bookPage as BookPageModel?;
        onPageLoaded(bookPage);
      },
      onPageChanged: onPageChanged,
    );
  }

  // Check if audio is playing and navigate to the correct page
  Future<int> checkAndUpdateInitialPage(int initialPage) async {
    try {
      // Get saved page number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      int savedPage = prefs.getInt('${bookCode}_current_audio_page') ??
          prefs.getInt('current_audio_book_page') ??
          0;

      if (savedPage > 0 && savedPage != initialPage) {
        // Update the progress service
        bookProgressService.setCurrentPage(bookCode, savedPage);

        // Load the saved page
        await pageManager.loadPage(savedPage, isForward: savedPage > initialPage);

        // Return the updated page number
        return savedPage;
      }
    } catch (e) {
      debugPrint('Error updating initial page: $e');
    }

    // Return the original page if no change
    return initialPage;
  }

  // Initialize the first page
  Future<void> initializeFirstPage() async {
    await pageManager.initializeFirstPage();
  }

  // Load a specific page
  Future<void> loadPage(int pageNumber, {bool isForward = true}) async {
    await pageManager.loadPage(pageNumber, isForward: isForward);
  }

  // Navigate to the next page
  Future<void> goToNextPage() async {
    final currentPage = pageManager.currentPage;
    final totalPages = bookProgressService.getTotalPages(bookCode);

    if (currentPage < totalPages) {
      final nextPage = currentPage + 1;
      await pageManager.loadPage(nextPage, isForward: true);
    }
  }

  // Navigate to the previous page
  Future<void> goToPreviousPage() async {
    final currentPage = pageManager.currentPage;

    if (currentPage > 1) {
      final previousPage = currentPage - 1;
      await pageManager.loadPage(previousPage, isForward: false);
    }
  }

  // Navigate to a specific page
  Future<void> goToPage(int pageNumber) async {
    return pageManager.goToPage(pageNumber);
  }

  // Get a page from cache or load it
  Future<BookPageModel> getPageFromCacheOrLoad(int pageNumber) {
    return pageManager.getPageFromCacheOrLoad(pageNumber);
  }

  // Jump to a specific page (for compatibility with existing code)
  Future<void> jumpToPage(int page) async {
    // Simply load the page since we don't have PageController anymore
    await pageManager.loadPage(page, isForward: page > pageManager.currentPage);
  }

  // Check if there are clients (for compatibility with existing code)
  bool get hasClients => true; // Always true since we don't use PageController

  // Dispose resources
  void dispose() {
    // No need to dispose PageController anymore
  }

  // Called when page is changed externally
  void handleExternalPageChange(int pageNumber) {
    // This method can be used to handle page changes from external sources
    if (pageNumber != pageManager.currentPage) {
      loadPage(pageNumber, isForward: pageNumber > pageManager.currentPage);
    }
  }

  // Helper properties
  bool get isFirstPage => pageManager.isFirstPage;
  bool get isLastPage => pageManager.isLastPage;
  int get currentPage => pageManager.currentPage;
}
