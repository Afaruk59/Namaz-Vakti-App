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
  late PageController pageController;
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
        onPageLoaded(bookPage as BookPageModel);
      },
      onPageChanged: onPageChanged,
    );

    // Initialize the page controller with the current page from page manager
    pageController = PageController(initialPage: pageManager.currentPage);
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

        // Return the updated page number
        return savedPage;
      }
    } catch (e) {
      print('Error updating initial page: $e');
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
  void goToNextPage(Function() beforeNavigation, Function(bool) afterNavigation) {
    final currentPage = pageManager.currentPage;
    final totalPages = bookProgressService.getTotalPages(bookCode);

    if (currentPage < totalPages) {
      final nextPage = currentPage + 1;

      // Run before navigation callback
      beforeNavigation();

      // Update page controller
      pageController.jumpToPage(nextPage);

      // Update page manager
      pageManager.loadPage(nextPage, isForward: true).then((_) {
        // Run after navigation callback
        afterNavigation(true);
      });
    }
  }

  // Navigate to the previous page
  void goToPreviousPage(Function() beforeNavigation, Function(bool) afterNavigation) {
    final currentPage = pageManager.currentPage;

    if (currentPage > 1) {
      final previousPage = currentPage - 1;

      // Run before navigation callback
      beforeNavigation();

      // Update page controller
      pageController.jumpToPage(previousPage);

      // Update page manager
      pageManager.loadPage(previousPage, isForward: false).then((_) {
        // Run after navigation callback
        afterNavigation(false);
      });
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

  // PageView navigation methods (forwarding to the internal pageController)
  Future<void> previousPage({required Duration duration, required Curve curve}) {
    return pageController.previousPage(duration: duration, curve: curve);
  }

  Future<void> nextPage({required Duration duration, required Curve curve}) {
    return pageController.nextPage(duration: duration, curve: curve);
  }

  void jumpToPage(int page) {
    pageController.jumpToPage(page);
  }

  // Expose PageController properties
  bool get hasClients => pageController.hasClients;

  // Dispose resources
  void dispose() {
    pageController.dispose();
  }

  // Helper properties
  bool get isFirstPage => pageManager.isFirstPage;
  bool get isLastPage => pageManager.isLastPage;
  int get currentPage => pageManager.currentPage;
}
