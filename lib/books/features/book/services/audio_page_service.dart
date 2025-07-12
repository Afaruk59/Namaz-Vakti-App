import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/media_controller.dart';

/// Sayfa değiştirme ve ses çalma işlemlerini arka planda yapan servis
class AudioPageService {
  final ApiService _apiService = ApiService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final BookTitleService _bookTitleService = BookTitleService();
  final BookProgressService _bookProgressService = BookProgressService();

  // Track if completion listener is set up
  bool _isCompletionListenerSet = false;
  StreamSubscription? _completionSubscription;

  // Singleton pattern
  static final AudioPageService _instance = AudioPageService._internal();
  factory AudioPageService() => _instance;
  AudioPageService._internal() {
    // Setup audio completion listener during initialization
    _setupAudioCompletionListener();
  }

  // Setup completion listener for automatic page navigation
  void _setupAudioCompletionListener() {
    if (_isCompletionListenerSet) return;

    _completionSubscription = _audioPlayerService.completionStream.listen((_) async {
      print('AudioPageService: Audio completion detected in background');

      // Check if a book is currently playing
      final String? currentBookCode = _audioPlayerService.playingBookCode;
      if (currentBookCode == null || currentBookCode.isEmpty) {
        print('AudioPageService: No book was playing, ignoring completion');
        return;
      }

      // Get the current page from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentPage = prefs.getInt('${currentBookCode}_current_audio_page') ??
          prefs.getInt('current_audio_book_page') ??
          0;

      if (currentPage <= 0) {
        print('AudioPageService: Invalid current page: $currentPage');
        return;
      }

      // Get maximum page for the book
      final maxPage = await _getMaxPageForBook(currentBookCode);

      // Calculate next page
      final nextPage = currentPage + 1;

      // Check if next page is valid
      if (nextPage > maxPage) {
        print(
            'AudioPageService: Reached the end of the book (page $currentPage of $maxPage). No more pages to play.');
        return;
      }

      print(
          'AudioPageService: Auto-advancing to next page: $nextPage after audio completion (current: $currentPage, max: $maxPage)');

      // Force a short delay to ensure no race conditions
      await Future.delayed(Duration(milliseconds: 500));

      // Save that we're auto-advancing to a new page - this is critical for the page to
      // know that it should start audio from the beginning of the new page
      await prefs.setBool('${currentBookCode}_auto_advanced', true);

      // Reset position when auto-advancing (we always want to start from beginning of next page)
      await prefs.setInt('${currentBookCode}_audio_position', 0);

      // Clearly log what's happening
      print(
          'AudioPageService: Marked ${currentBookCode}_auto_advanced=true and reset position to 0');

      // Navigate to the next page and play its audio
      final success = await changePageAndPlayAudio(currentBookCode, nextPage);

      if (success) {
        print('AudioPageService: Successfully advanced to page $nextPage and started playback');
      } else {
        print('AudioPageService: Failed to advance to page $nextPage. Trying another page...');
        // Try the page after next as a fallback
        if (nextPage < maxPage) {
          await changePageAndPlayAudio(currentBookCode, nextPage + 1);
        }
      }
    });

    _isCompletionListenerSet = true;
    print('AudioPageService: Audio completion listener set up');
  }

  /// Dispose of the completion listener
  void dispose() {
    _completionSubscription?.cancel();
    _isCompletionListenerSet = false;
  }

  /// Sayfa değiştirme ve ses çalma işlemini arka planda yapar
  Future<bool> changePageAndPlayAudio(String bookCode, int pageNumber,
      {int maxAttempts = 5}) async {
    try {
      print('Arka planda sayfa değiştiriliyor: $bookCode, sayfa $pageNumber');

      final prefs = await SharedPreferences.getInstance();
      final bool isAutoAdvanced = prefs.getBool('${bookCode}_auto_advanced') ?? false;

      // Get saved position if not auto-advanced
      int? startPosition;
      if (!isAutoAdvanced) {
        startPosition = prefs.getInt('${bookCode}_audio_position') ?? 0;
        print('Resuming from saved position: $startPosition ms (not auto-advanced)');
      } else {
        // Clear auto-advanced flag since we're handling it now
        await prefs.setBool('${bookCode}_auto_advanced', false);
        print(
            'Auto-advanced=true detected! Starting from beginning of new page and resetting flag');

        // Double check that position is indeed 0 for auto-advancement
        final currentSavedPosition = prefs.getInt('${bookCode}_audio_position') ?? 0;
        if (currentSavedPosition > 0) {
          print(
              'Warning: Found non-zero position ($currentSavedPosition) with auto-advanced flag, resetting to 0');
          await prefs.setInt('${bookCode}_audio_position', 0);
        }
      }

      // --- SADECE SAYFA BİLGİSİNİ GÜNCELLE ---
      // API'den sayfa verilerini al
      final BookPageModel bookPage = await _apiService.getBookPage(bookCode, pageNumber);

      // Ses dosyası var mı kontrol et
      if (bookPage.mp3.isEmpty) {
        print('Sayfa $pageNumber için ses dosyası bulunamadı');
        if (maxAttempts > 0) {
          print('Sonraki sayfa ($pageNumber + 1) için ses dosyası kontrol ediliyor...');
          return await changePageAndPlayAudio(bookCode, pageNumber + 1,
              maxAttempts: maxAttempts - 1);
        }
        return false;
      }

      // --- SADECE SAYFA BİLGİSİNİ GÜNCELLE ---
      // Şu anki sayfa bilgisini kaydet
      await prefs.setInt('${bookCode}_current_audio_page', pageNumber);
      print('Sayfa $pageNumber arka planda güncellendi (audio başlatılmadı)');

      // Ses başlatma kodu kaldırıldı!
      // await _audioPlayerService.playAudio(bookPage.mp3[0]);
      // if (startPosition != null && startPosition > 0) {
      //   await Future.delayed(Duration(milliseconds: 100));
      //   await _audioPlayerService.seekTo(Duration(milliseconds: startPosition));
      //   print('Sought to saved position: $startPosition ms');
      // } else {
      //   print('Starting from beginning of page (position: 0)');
      // }
      // await _saveAudioBookPreferences(bookCode, pageNumber, true);
      // await _updateHomeScreen(bookCode, pageNumber);
      // print('Sayfa $pageNumber için ses dosyası başarıyla çalınıyor');
      return true;
    } catch (e) {
      print('Sayfa değiştirme ve ses çalma hatası: $e');
      if (maxAttempts > 0) {
        print(
            'Sonraki sayfa ($pageNumber + 1) için ses dosyası kontrol ediliyor (hata sonrası)...');
        return await changePageAndPlayAudio(bookCode, pageNumber + 1, maxAttempts: maxAttempts - 1);
      }
      return false;
    }
  }

  /// HomeScreen'i güncelle
  Future<void> _updateHomeScreen(String bookCode, int pageNumber) async {
    try {
      // Kitap başlığı ve yazarını al
      final bookTitle = await _bookTitleService.getTitle(bookCode);
      final bookAuthor = await _bookTitleService.getAuthor(bookCode);

      // HomeScreen'i güncelle
      // HomeScreen.updateCurrentAudioBook(
      //   bookCode: bookCode,
      //   bookTitle: bookTitle,
      //   bookAuthor: bookAuthor,
      //   currentPage: pageNumber,
      //   isPlaying: _audioPlayerService.isPlaying,
      // );

      print('HomeScreen güncellendi: $bookTitle, sayfa $pageNumber');
    } catch (e) {
      print('HomeScreen güncelleme hatası: $e');
    }
  }

  /// Save current audio position
  Future<void> saveCurrentAudioPosition(String bookCode) async {
    try {
      final audioPlayerService = AudioPlayerService();
      final prefs = await SharedPreferences.getInstance();

      // Only save position if the same book is playing
      if (audioPlayerService.playingBookCode == bookCode) {
        final currentPosition = audioPlayerService.position.inMilliseconds;

        print('AudioPageService: Saving current position for $bookCode: $currentPosition ms');
        await prefs.setInt('${bookCode}_audio_position', currentPosition);

        // Also save that this was not an auto-advance
        await prefs.setBool('${bookCode}_auto_advanced', false);
      }
    } catch (e) {
      print('AudioPageService: Error saving current audio position: $e');
    }
  }

  /// Ses çalma tercihlerini kaydet
  Future<void> _saveAudioBookPreferences(String bookCode, int page, bool isPlaying) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kitap başlığı ve yazarını al
      final bookTitle = await _bookTitleService.getTitle(bookCode);
      final bookAuthor = await _bookTitleService.getAuthor(bookCode);

      // Kitap bilgilerini kaydet
      await prefs.setString('current_audio_book_code', bookCode);
      await prefs.setString('current_audio_book_title', bookTitle);
      await prefs.setString('current_audio_book_author', bookAuthor);

      // Save page number with both global and book-specific keys
      await prefs.setInt('current_audio_book_page', page);
      await prefs.setInt('${bookCode}_current_audio_page', page);

      // Ses çalma durumunu kaydet
      await prefs.setBool('is_audio_playing', isPlaying);

      // Save current position
      final currentPosition = _audioPlayerService.position.inMilliseconds;
      await prefs.setInt('${bookCode}_audio_position', currentPosition);

      // Ana ekranda mini player göstergesi üzerinde sayfa değişimi yapıldığından işaretleyelim
      await prefs.setBool('mini_player_changed_page', true);

      print(
          'Ses çalma tercihleri kaydedildi: $bookTitle, sayfa: $page, çalıyor: $isPlaying, pozisyon: $currentPosition ms');
    } catch (e) {
      print('Ses çalma tercihlerini kaydetme hatası: $e');
    }
  }

  /// Stop audio and clear the player state
  Future<void> stopAudioAndClearPlayer() async {
    try {
      final audioPlayerService = AudioPlayerService();

      print(
          'AudioPageService: Stopping audio and clearing player. Current position: ${audioPlayerService.position.inSeconds}s');

      // Stop audio playback
      await audioPlayerService.stopAudio();

      // MediaController'ın servisini durdurmadan önce playback state'i kesin olarak STOPPED yap (singleton üzerinden)
      final mediaController = MediaController.singleton(audioPlayerService);
      await mediaController.updatePlaybackState(MediaController.STATE_STOPPED);
      await mediaController.stopService();

      // Clear playing book code
      await audioPlayerService.setPlayingBookCode(null);

      // Reset SharedPreferences
      await _clearAudioPreferences();

      // Update HomeScreen - clear mini player
      // HomeScreen.updateCurrentAudioBook(
      //   bookCode: '',
      //   bookTitle: '',
      //   bookAuthor: '',
      //   currentPage: 0,
      //   isPlaying: false,
      // );

      print('AudioPageService: Audio stopped and player cleared successfully');
    } catch (e) {
      print('AudioPageService: Error stopping audio and clearing player: $e');
    }
  }

  /// Save audio preferences to SharedPreferences
  Future<void> _saveAudioPreferences({
    String? bookCode,
    String? bookTitle,
    String? bookAuthor,
    int? pageNumber,
    bool? isPlaying,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print(
          'AudioPageService: Saving audio preferences: book: $bookCode, title: $bookTitle, page: $pageNumber, isPlaying: $isPlaying');

      if (bookCode != null) {
        await prefs.setString('current_audio_book_code', bookCode);
      }

      if (bookTitle != null) {
        await prefs.setString('current_audio_book_title', bookTitle);
      }

      if (bookAuthor != null) {
        await prefs.setString('current_audio_book_author', bookAuthor);
      }

      if (pageNumber != null) {
        await prefs.setInt('current_audio_book_page', pageNumber);

        // Also save book-specific page number
        if (bookCode != null) {
          await prefs.setInt('${bookCode}_current_audio_page', pageNumber);
        }
      }

      if (isPlaying != null) {
        await prefs.setBool('is_audio_playing', isPlaying);
      }

      print('AudioPageService: Successfully saved audio preferences');
    } catch (e) {
      print('AudioPageService: Error saving audio preferences: $e');
    }
  }

  /// Clear audio preferences from SharedPreferences
  Future<void> _clearAudioPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioPlayerService = AudioPlayerService();

      // Get current book code before clearing
      String? bookCode = audioPlayerService.playingBookCode;
      print('AudioPageService: Clearing audio preferences for book: $bookCode');

      // Clear all audio-related preferences
      await prefs.remove('current_audio_book_code');
      await prefs.remove('current_audio_book_title');
      await prefs.remove('current_audio_book_author');
      await prefs.remove('current_audio_book_page');
      await prefs.remove('is_audio_playing');

      // Also clear book-specific preferences if bookCode is available
      if (bookCode != null) {
        await prefs.remove('${bookCode}_current_audio_page');
        print('AudioPageService: Cleared book-specific preferences for $bookCode');
      }

      print('AudioPageService: Successfully cleared all audio preferences');
    } catch (e) {
      print('AudioPageService: Error clearing audio preferences: $e');
    }
  }

  // Get the maximum page number for a book
  Future<int> _getMaxPageForBook(String bookCode) async {
    try {
      // Get the book's page count from the book progress service
      final lastPage = await _bookProgressService.getLastPage(bookCode);
      if (lastPage > 0) {
        return lastPage;
      }

      // Fallback to a reasonable default if we couldn't get the last page
      return 1000; // Use a high number as fallback
    } catch (e) {
      print('AudioPageService: Error getting max page for book: $e');
      return 1000; // Use a high number as fallback on error
    }
  }
}
