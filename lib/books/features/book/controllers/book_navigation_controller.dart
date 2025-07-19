import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_bookmark_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_media_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_audio_controller.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller responsible for handling navigation between book pages
class BookNavigationController {
  final String bookCode;
  final BookPageController pageController;
  final BookBookmarkController bookmarkController;
  final BookMediaController mediaController;
  final BookAudioController audioController;
  final AudioPlayerService audioPlayerService;
  final BookTitleService bookTitleService;
  final BookProgressService bookProgressService;
  final Function(bool) onAudioProgressVisibilityChanged;
  final Function(BookPageModel?) onBookPageUpdated;
  final Function() onMediaInfoUpdated;

  // Method Channel for native media service
  static const platform = MethodChannel('com.afaruk59.namaz_vakti_app/media_service');

  BookNavigationController({
    required this.bookCode,
    required this.pageController,
    required this.bookmarkController,
    required this.mediaController,
    required this.audioController,
    required this.audioPlayerService,
    required this.bookTitleService,
    required this.bookProgressService,
    required this.onAudioProgressVisibilityChanged,
    required this.onBookPageUpdated,
    required this.onMediaInfoUpdated,
  }) {
    // Medya servis method channel listener'ı kur
    _initMediaServiceListener();
  }

  // Medya servis method channel'ını dinlemeye başla
  void _initMediaServiceListener() {
    platform.setMethodCallHandler((call) async {
      debugPrint("BookNavigationController: Method channel çağrısı: ${call.method}");

      switch (call.method) {
        case 'next':
          await goToNextPage();
          break;
        case 'previous':
          await goToPreviousPage();
          break;
        case 'togglePlay':
          // Ses çalıyorsa durdur/başlat
          if (audioPlayerService.playingBookCode == bookCode) {
            if (audioPlayerService.isPlaying) {
              audioPlayerService.pauseAudio();
            } else {
              audioPlayerService.resumeAudio();
            }
          } else {
            // Ses çalmıyorsa, mevcut sayfadaki sesi başlat
            final currentPage = pageController.currentPage;
            final bookPage = await pageController.getPageFromCacheOrLoad(currentPage);
            if (bookPage.mp3.isNotEmpty) {
              final bookTitle = await bookTitleService.getTitle(bookCode);
              final bookAuthor = await bookTitleService.getAuthor(bookCode);

              await audioController.handlePlayAudio(
                currentBookPage: bookPage,
                currentPage: currentPage,
                fromBottomBar: true,
                bookTitle: bookTitle,
                bookAuthor: bookAuthor,
              );
            }
          }
          break;
      }

      // Sayfa durumunu native tarafına bildir
      _updateMediaPageState();

      return null;
    });
  }

  // Medya servisine sayfa durumunu bildir
  Future<void> _updateMediaPageState() async {
    try {
      const firstPage = 1;
      final lastPage =
          pageController.isLastPage ? pageController.currentPage : pageController.currentPage + 1;
      final currentPage = pageController.currentPage;

      debugPrint("BookNavigationController: Sayfa durumu güncelleniyor: $currentPage / $lastPage");

      await platform.invokeMethod('updateAudioPageState', {
        'bookCode': bookCode,
        'currentPage': currentPage,
        'firstPage': firstPage,
        'lastPage': lastPage,
      });
    } catch (e) {
      debugPrint("Medya servisi sayfa durumu güncelleme hatası: $e");
    }
  }

  // Medya servisini başlat
  Future<void> initMediaService() async {
    try {
      await platform.invokeMethod('initMediaService');
      await _updateMediaPageState();
      debugPrint("BookNavigationController: Medya servisi başlatıldı");
    } catch (e) {
      debugPrint("Medya servisi başlatma hatası: $e");
    }
  }

  /// Navigate to the next page
  Future<void> goToNextPage({bool fromAudioCompletion = false}) async {
    final currentPage = pageController.currentPage;
    final lastPage = await bookProgressService.getLastPage(bookCode);

    if (currentPage < lastPage) {
      final nextPage = currentPage + 1;
      final prefs = await SharedPreferences.getInstance();
      // --- AUTO ADVANCED KONTROLÜ ---
      bool autoAdvanced = prefs.getBool('${bookCode}_auto_advanced') ?? false;
      if (autoAdvanced) {
        // Flag'i hemen sıfırla ve ses başlatmayı atla
        await prefs.setBool('${bookCode}_auto_advanced', false);
        debugPrint('goToNextPage: auto_advanced flag true, audio başlatılmayacak.');
      }
      // Store audio playback state
      final wasPlaying = audioPlayerService.isPlaying;
      final wasPaused = !audioPlayerService.isPlaying && audioPlayerService.position.inSeconds > 0;
      final shouldPlayAudio = wasPlaying || wasPaused;

      debugPrint(
          'goToNextPage: wasPlaying=$wasPlaying, wasPaused=$wasPaused, shouldPlayAudio=$shouldPlayAudio, fromAudioCompletion=$fromAudioCompletion');

      // Save current audio position for restoring if needed
      final currentPosition = audioPlayerService.position.inMilliseconds;
      debugPrint('Current audio position: $currentPosition ms');

      // Mark this as auto-advanced only if it came from audio completion
      // which will make it start from the beginning of the next page
      if (fromAudioCompletion) {
        await prefs.setBool('${bookCode}_auto_advanced', true);
        // Reset position to 0 for auto-advance
        await prefs.setInt('${bookCode}_audio_position', 0);
        debugPrint('Auto-advanced flag set to true - will start from beginning of new page');
      } else {
        // This is manual navigation, so we'll keep the position within the page
        await prefs.setBool('${bookCode}_auto_advanced', false);
      }

      // Get book title and author first
      final bookTitle = await bookTitleService.getTitle(bookCode);
      final bookAuthor = await bookTitleService.getAuthor(bookCode);

      // If audio is playing or paused, STOP it before changing page
      if (audioPlayerService.isPlaying || wasPaused) {
        debugPrint('Stopping audio before changing to next page');
        await audioPlayerService.stopAudio();
      }

      // Navigate to the next page
      pageController.jumpToPage(nextPage);

      // Load the next page
      await pageController.loadPage(nextPage, isForward: true);

      // Check bookmark status for the new page
      await bookmarkController.checkBookmarkStatus(nextPage);

      // Update media controller with new page info
      onMediaInfoUpdated();

      // Medya servisine sayfa değişimini bildir
      _updateMediaPageState();

      // Get the book page content
      BookPageModel? bookPage = await pageController.getPageFromCacheOrLoad(nextPage);
      onBookPageUpdated(bookPage);

      // If the page has audio and was playing/paused before, start playing audio
      if (bookPage.mp3.isNotEmpty && shouldPlayAudio && !autoAdvanced) {
        // Add delay to ensure page is fully loaded
        await Future.delayed(const Duration(milliseconds: 300));

        // If from audio completion, keep audio progress visible
        if (fromAudioCompletion) {
          onAudioProgressVisibilityChanged(true);
        }

        debugPrint('Playing audio for next page');

        // Play audio for the new page
        await audioController.handlePlayAudio(
          currentBookPage: bookPage,
          currentPage: nextPage,
          fromBottomBar: false,
          afterPageChange: true,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
        );
      }
    }
  }

  /// Navigate to the previous page
  Future<void> goToPreviousPage() async {
    final currentPage = pageController.currentPage;

    if (currentPage > 1) {
      final previousPage = currentPage - 1;
      final prefs = await SharedPreferences.getInstance();
      // --- AUTO ADVANCED KONTROLÜ ---
      bool autoAdvanced = prefs.getBool('${bookCode}_auto_advanced') ?? false;
      if (autoAdvanced) {
        await prefs.setBool('${bookCode}_auto_advanced', false);
        debugPrint('goToPreviousPage: auto_advanced flag true, audio başlatılmayacak.');
      }
      // Store audio playback state
      final wasPlaying = audioPlayerService.isPlaying;
      final wasPaused = !audioPlayerService.isPlaying && audioPlayerService.position.inSeconds > 0;
      final shouldPlayAudio = wasPlaying || wasPaused;

      debugPrint(
          'goToPreviousPage: wasPlaying=$wasPlaying, wasPaused=$wasPaused, shouldPlayAudio=$shouldPlayAudio');

      // Get book title and author first
      final bookTitle = await bookTitleService.getTitle(bookCode);
      final bookAuthor = await bookTitleService.getAuthor(bookCode);

      // Save current audio position for restoring if needed
      final currentPosition = audioPlayerService.position.inMilliseconds;
      debugPrint('Current audio position: $currentPosition ms');

      // Mark this as manual navigation (not auto-advanced)
      await prefs.setBool('${bookCode}_auto_advanced', false);

      // If audio is playing, stop it before changing page
      if (audioPlayerService.isPlaying || wasPaused) {
        debugPrint('Stopping audio before changing to previous page');
        await audioPlayerService.stopAudio();
      }

      // Navigate to the previous page
      pageController.jumpToPage(previousPage);

      // Load the previous page
      await pageController.loadPage(previousPage, isForward: false);

      // Check bookmark status for the new page
      await bookmarkController.checkBookmarkStatus(previousPage);

      // Update media controller with new page info
      onMediaInfoUpdated();

      // Medya servisine sayfa değişimini bildir
      _updateMediaPageState();

      // Get the book page content
      BookPageModel? bookPage = await pageController.getPageFromCacheOrLoad(previousPage);
      onBookPageUpdated(bookPage);

      // If audio was playing/paused and the new page has audio, play it
      if (shouldPlayAudio && bookPage.mp3.isNotEmpty && !autoAdvanced) {
        // Add delay to ensure page is fully loaded
        await Future.delayed(const Duration(milliseconds: 300));

        debugPrint('Playing audio for previous page');

        // Play audio for the new page
        await audioController.handlePlayAudio(
          currentBookPage: bookPage,
          currentPage: previousPage,
          fromBottomBar: false,
          afterPageChange: true,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
        );
      }
    }
  }

  /// Navigate to a specific page
  Future<void> goToPage(int pageNumber) async {
    final currentPage = pageController.currentPage;

    // Don't reload if we're already on the requested page
    if (pageNumber == currentPage) {
      return;
    }

    // Validate page number
    if (pageNumber < 1) {
      pageNumber = 1;
    }

    // Determine if we're moving forward or backward
    final isForward = pageNumber > currentPage;

    // Store audio playback state
    final wasPlaying = audioPlayerService.isPlaying;
    final wasPaused = !audioPlayerService.isPlaying && audioPlayerService.position.inSeconds > 0;
    final shouldPlayAudio = wasPlaying || wasPaused;

    // Get book title and author first
    final bookTitle = await bookTitleService.getTitle(bookCode);
    final bookAuthor = await bookTitleService.getAuthor(bookCode);

    // Check if page was changed from mini player
    final prefs = await SharedPreferences.getInstance();
    final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;

    debugPrint(
        'BookNavigationController.goToPage: pageNumber=$pageNumber, currentPage=$currentPage, wasPlaying=$wasPlaying, wasPaused=$wasPaused, shouldPlayAudio=$shouldPlayAudio, miniPlayerChangedPage=$miniPlayerChangedPage');

    try {
      // If audio is playing or paused, STOP it before changing page
      if (audioPlayerService.playingBookCode == bookCode && (wasPlaying || wasPaused)) {
        debugPrint('Stopping audio before changing page');
        await audioPlayerService.stopAudio();
      }

      // Navigate to the specified page
      pageController.jumpToPage(pageNumber);

      // Load the page content
      await pageController.loadPage(pageNumber, isForward: isForward);

      // Check bookmark status for the new page
      await bookmarkController.checkBookmarkStatus(pageNumber);

      // Update media controller with new page info
      onMediaInfoUpdated();

      // Medya servisine sayfa değişimini bildir
      _updateMediaPageState();

      // Get the new page content
      BookPageModel? bookPage = await pageController.getPageFromCacheOrLoad(pageNumber);
      onBookPageUpdated(bookPage);

      // If the new page has audio, start playing it immediately if previous page was playing
      if (bookPage.mp3.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // --- AUTO ADVANCED KONTROLÜ ---
        bool autoAdvanced = prefs.getBool('${bookCode}_auto_advanced') ?? false;
        if (autoAdvanced) {
          await prefs.setBool('${bookCode}_auto_advanced', false);
          debugPrint('goToPage: auto_advanced flag true, audio başlatılmayacak.');
        }
        // If previous audio was playing/paused, play this page's audio
        if (shouldPlayAudio && !autoAdvanced) {
          debugPrint('Starting fresh audio for new page after navigation');

          // Add delay to ensure page is fully loaded
          await Future.delayed(const Duration(milliseconds: 300));

          // Play audio for the new page from beginning
          await audioController.handlePlayAudio(
            currentBookPage: bookPage,
            currentPage: pageNumber,
            fromBottomBar: false,
            afterPageChange: true,
            bookTitle: bookTitle,
            bookAuthor: bookAuthor,
          );
        }
      }
    } catch (error) {
      debugPrint('Error navigating to page: $error');
    }
  }
}
