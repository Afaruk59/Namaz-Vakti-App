import 'dart:async';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/audio_manager.dart';
import 'package:namaz_vakti_app/books/features/book/services/audio_page_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookAudioController {
  final String bookCode;
  final AudioPlayerService audioPlayerService = AudioPlayerService.forContext('book');
  final AudioManager audioManager;

  // Callback when audio progress visibility changes
  final Function(bool) onShowAudioProgressChanged;

  // Current state
  bool _showAudioProgress = false;
  DateTime _lastPositionUpdate = DateTime.now();

  BookAudioController({
    required this.bookCode,
    required this.audioManager,
    required this.onShowAudioProgressChanged,
  });

  // Setup audio listeners
  void setupAudioListeners(BuildContext context, Function(bool) goToNextPage) {
    try {
      // Playing state listener
      audioPlayerService.playingStateStream.listen((isPlaying) async {
        debugPrint(
            'Audio playing state changed: $isPlaying, current showAudioProgress: $_showAudioProgress');

        // Do not hide progress bar just because audio is paused
        // Only update UI if necessary
        if (!isPlaying && !_showAudioProgress) {
          // Do nothing - we don't want to show progress bar if it was previously hidden
        } else if (isPlaying && !_showAudioProgress) {
          // Audio started playing but progress bar was hidden
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);

          // Sadece gerçekten bir ses çalarken servisi başlat
          String? playingBookCode = await audioPlayerService.getPlayingBookCode();
          if (playingBookCode != null && playingBookCode.isNotEmpty) {
            audioManager.startService();
          }
        } else {
          // Just notify about current state without changing visibility
          onShowAudioProgressChanged(_showAudioProgress);
        }
      });

      // Position listener - throttled to reduce UI updates
      audioPlayerService.positionStream.listen((position) {
        final now = DateTime.now();
        if (now.difference(_lastPositionUpdate).inMilliseconds >= 1000) {
          _lastPositionUpdate = now;

          // Update position on lock screen if playing
          if (audioPlayerService.isPlaying) {
            try {
              audioManager.updatePosition(position.inMilliseconds);
            } catch (e) {
              debugPrint('Error updating position: $e');
            }
          }
        }
      });

      // Duration listener
      audioPlayerService.durationStream.listen((duration) {
        // This will trigger a UI update through the state
      });

      // Completion listener
      audioPlayerService.completionStream.listen((_) {
        goToNextPage(true);
      });

      // Kitap sınırlarını MediaController'a bildir
      _updateBookBoundaries();
    } catch (e) {
      debugPrint('Error setting up audio listeners: $e');
    }
  }

  // Kitap sınırlarını güncelleme
  Future<void> _updateBookBoundaries() async {
    try {
      // Kitabın ilk ve son sayfalarını belirle
      const firstPage = 1; // veya bookCode'a göre dinamik hesapla
      const lastPage = 999; // veya bookCode'a göre dinamik hesapla

      // Kilit ekranında kullanmak üzere MediaController'a bildir
      await audioManager.updateAudioPageState(
        bookCode: bookCode,
        currentPage: 1, // Varsayılan değer, güncellenecek
        firstPage: firstPage,
        lastPage: lastPage,
      );
    } catch (e) {
      debugPrint('Error updating book boundaries: $e');
    }
  }

  // Handle play/pause audio
  Future<void> handlePlayAudio({
    required BookPageModel? currentBookPage,
    required int currentPage,
    bool fromBottomBar = false,
    bool afterPageChange = false,
    String? bookTitle,
    String? bookAuthor,
    int? startPosition,
    bool autoResume = false,
  }) async {
    try {
      if (currentBookPage == null || currentBookPage.mp3.isEmpty) {
        debugPrint('No audio file found');
        return;
      }

      debugPrint(
          'handlePlayAudio called: fromBottomBar=$fromBottomBar, afterPageChange=$afterPageChange, _showAudioProgress=$_showAudioProgress, isPlaying=${audioPlayerService.isPlaying}, startPosition=$startPosition, autoResume=$autoResume');

      // If called from bottom bar and audio is playing/paused, stop audio completely
      if (fromBottomBar &&
          (_showAudioProgress ||
              audioPlayerService.isPlaying ||
              audioPlayerService.position.inSeconds > 0)) {
        await AudioPageService().stopAudioAndClearPlayer();
        _showAudioProgress = false;
        onShowAudioProgressChanged(_showAudioProgress);
        debugPrint('Audio completely stopped and mini player cleared (bottom bar)');
        return;
      }

      // When called after page change or starting a new audio
      if (afterPageChange || (!_showAudioProgress)) {
        debugPrint(
            'handlePlayAudio called: afterPageChange=$afterPageChange, hasStartPosition=${startPosition != null}, startPosition=${startPosition ?? 0}, autoResume=$autoResume');

        // Check current book code
        String? playingBookCode = await audioPlayerService.getPlayingBookCode();

        // If different book is playing, stop it first
        if (playingBookCode != null && playingBookCode != bookCode) {
          debugPrint('Different book is playing, stopping it first: $playingBookCode');
          await audioPlayerService.stopAudio();
        }

        // Set book code
        await audioPlayerService.setPlayingBookCode(bookCode);

        // Show audio progress if not already visible
        if (!_showAudioProgress) {
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);
        }

        // If this is return from home screen with a saved position
        if (!afterPageChange && !fromBottomBar && startPosition != null && startPosition > 0) {
          debugPrint('RESUMING from saved position: $startPosition ms, autoResume: $autoResume');

          try {
            final prefs = await SharedPreferences.getInstance();

            // Start playing audio from saved position
            await audioPlayerService.playAudio(currentBookPage.mp3[0]);

            // Seek to saved position after a short delay to ensure audio is loaded
            await Future.delayed(const Duration(milliseconds: 100));
            await audioPlayerService.seekTo(Duration(milliseconds: startPosition));

            // ALWAYS auto-resume when coming back from home screen with saved position
            debugPrint('Auto-resuming playback - FORCING PLAYBACK after home screen return');

            // Force three resume attempts to ensure audio actually starts
            for (int i = 0; i < 3; i++) {
              await audioPlayerService.resumeAudio();
              await Future.delayed(const Duration(milliseconds: 100));
              if (audioPlayerService.isPlaying) {
                debugPrint('Audio resume successful on attempt ${i + 1}');
                break;
              } else if (i == 2) {
                debugPrint('Warning: All resume attempts failed, trying one more time');
                // One final attempt with a longer delay
                await Future.delayed(const Duration(milliseconds: 300));
                await audioPlayerService.resumeAudio();
              }
            }

            // Ensure the state is properly saved everywhere
            await prefs.setBool('is_audio_playing', true);
            await prefs.setBool('${bookCode}_was_playing', true);

            debugPrint('Audio resumed from saved position $startPosition ms and auto-resumed');
          } catch (e) {
            debugPrint('Error resuming audio: $e');
          }
        }
        // If this is a normal page change within the book
        else if (afterPageChange) {
          debugPrint('Starting fresh audio for new page after page change');

          // Start playing audio from beginning
          await audioPlayerService.playAudio(currentBookPage.mp3[0]);

          // --- ESKİ KOMİTTEKİ GİBİ: Metadata güncelle ---
          await audioManager.updateMetadata(
            currentBookPage,
            bookTitle ?? '',
            bookAuthor ?? '',
            currentPage,
          );
          // --- SONU ---

          // Immediately force play to ensure audio actually starts
          if (!audioPlayerService.isPlaying) {
            debugPrint('Initial play didn\'t start audio, forcing resume...');
            await Future.delayed(const Duration(milliseconds: 100));
            await audioPlayerService.resumeAudio();

            // Make a second attempt if needed
            if (!audioPlayerService.isPlaying) {
              debugPrint('First resume attempt failed, trying one more time...');
              await Future.delayed(const Duration(milliseconds: 200));
              await audioPlayerService.resumeAudio();
            }
          }

          // Force the isPlaying state to true to ensure UI updates correctly
          if (!audioPlayerService.isPlaying) {
            debugPrint(
                'WARNING: Audio still not playing after multiple attempts, forcing state update');
            audioPlayerService.forceUpdatePlayingState(true);
          }

          debugPrint(
              'Started playing audio for the new page: isPlaying=${audioPlayerService.isPlaying}');
        }
        // Initial playback or other cases
        else {
          debugPrint('Starting normal audio playback from beginning');

          // Start playing audio
          await audioPlayerService.playAudio(currentBookPage.mp3[0]);

          // --- ESKİ KOMİTTEKİ GİBİ: Metadata güncelle ---
          await audioManager.updateMetadata(
            currentBookPage,
            bookTitle ?? '',
            bookAuthor ?? '',
            currentPage,
          );
          // --- SONU ---

          // If a start position was provided, seek to it
          if (startPosition != null && startPosition > 0) {
            await audioPlayerService.seekTo(Duration(milliseconds: startPosition));
            debugPrint('Seeking to position: $startPosition ms');

            // If autoResume is true, resume playback automatically
            if (autoResume) {
              debugPrint('Auto-resuming playback after seeking');
              await audioPlayerService.resumeAudio();
            }
          }
        }

        // Save audio state with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);

        debugPrint('Audio playback handled successfully');
        return;
      }

      // When called from AudioProgressBar and audio is playing, pause audio
      if (!fromBottomBar && audioPlayerService.isPlaying) {
        debugPrint('Pausing audio via handlePlayAudio, showAudioProgress=$_showAudioProgress');
        await audioPlayerService.pauseAudio();

        // Ensure the progress bar stays visible
        if (!_showAudioProgress) {
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);
        }

        debugPrint(
            'Audio paused, progress bar should remain visible: _showAudioProgress=$_showAudioProgress');

        // Save paused state to preferences with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);
        return;
      }

      // If audio is paused and called from AudioProgressBar, resume audio
      if (!fromBottomBar &&
          !audioPlayerService.isPlaying &&
          audioPlayerService.position.inSeconds > 0 &&
          _showAudioProgress) {
        await audioPlayerService.resumeAudio();
        debugPrint('Audio resumed (audio progress bar)');

        // Save playing state to preferences with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);
        return;
      }

      // If we reach here, start new audio playback
      debugPrint('Starting new audio playback: ${currentBookPage.mp3}');

      // Check current book code
      String? playingBookCode = await audioPlayerService.getPlayingBookCode();

      // If different book is playing, stop it first
      if (playingBookCode != null && playingBookCode != bookCode) {
        debugPrint('Different book is playing, stopping it first: $playingBookCode');
        await audioPlayerService.stopAudio();
      }

      // Set book code
      await audioPlayerService.setPlayingBookCode(bookCode);

      _showAudioProgress = true;
      onShowAudioProgressChanged(_showAudioProgress);

      // Start playing audio
      try {
        await audioPlayerService.playAudio(currentBookPage.mp3[0]);

        // --- ESKİ KOMİTTEKİ GİBİ: Metadata güncelle ---
        await audioManager.updateMetadata(
          currentBookPage,
          bookTitle ?? '',
          bookAuthor ?? '',
          currentPage,
        );
        // --- SONU ---

        // Save audio state with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);

        debugPrint('Audio playback started');
      } catch (e) {
        debugPrint('Error playing audio: $e');
        _showAudioProgress = false;
        onShowAudioProgressChanged(_showAudioProgress);
      }
    } catch (e) {
      debugPrint('Error in handlePlayAudio: $e');
      _showAudioProgress = false;
      onShowAudioProgressChanged(_showAudioProgress);
    }
  }

  // Handle audio seek
  Future<void> handleSeek(double value) async {
    try {
      debugPrint(
          'BookAudioController: handleSeek called with value: $value ms (${value / 1000} seconds)');

      // Convert milliseconds to Duration
      final position = Duration(milliseconds: value.toInt());

      // Make sure we don't seek beyond the duration
      final safeDuration = position.inMilliseconds <= audioPlayerService.duration.inMilliseconds
          ? position
          : audioPlayerService.duration - const Duration(milliseconds: 100);

      debugPrint(
          'BookAudioController: Seeking to position ${safeDuration.inSeconds}.${safeDuration.inMilliseconds % 1000}s');

      // Seek using the audio manager
      await audioManager.seekTo(safeDuration.inMilliseconds.toDouble());

      // Seek tamamlandıktan sonra pozisyonu senkronize et
      await Future.delayed(const Duration(milliseconds: 100));
      await audioPlayerService.forcePositionSync();

      debugPrint('BookAudioController: Seek completed and position synced');
    } catch (e) {
      debugPrint('BookAudioController: Error in handleSeek: $e');
    }
  }

  // Handle speed change
  void handleSpeedChange() {
    audioManager.changeSpeed();
  }

  // Save audio preferences
  Future<void> saveAudioBookPreferences(int currentPage,
      [String? bookTitle, String? bookAuthor]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save book info
      await prefs.setString('current_audio_book_code', bookCode);
      if (bookTitle != null) {
        await prefs.setString('current_audio_book_title', bookTitle);
      }
      if (bookAuthor != null) {
        await prefs.setString('current_audio_book_author', bookAuthor);
      }

      // Save page number with both global and book-specific keys
      await prefs.setInt('current_audio_book_page', currentPage);
      await prefs.setInt('${bookCode}_current_audio_page', currentPage);

      // Save playing state
      await prefs.setBool('is_audio_playing', audioPlayerService.isPlaying);

      debugPrint('Audio preferences saved: page: $currentPage');
    } catch (e) {
      debugPrint('Error saving audio preferences: $e');
    }
  }

  // Save audio preferences with specific playing state
  Future<void> saveAudioBookPreferencesWithPlayingState(int currentPage, bool isPlaying,
      [String? bookTitle, String? bookAuthor]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save book info
      await prefs.setString('current_audio_book_code', bookCode);
      if (bookTitle != null) {
        await prefs.setString('current_audio_book_title', bookTitle);
      }
      if (bookAuthor != null) {
        await prefs.setString('current_audio_book_author', bookAuthor);
      }

      // Save page number with both global and book-specific keys
      await prefs.setInt('current_audio_book_page', currentPage);
      await prefs.setInt('${bookCode}_current_audio_page', currentPage);

      // Save playing state
      await prefs.setBool('is_audio_playing', isPlaying);

      debugPrint('Audio preferences saved: page: $currentPage, playing: $isPlaying');
    } catch (e) {
      debugPrint('Error saving audio preferences: $e');
    }
  }

  // Check if audio is playing for this book
  Future<bool> checkIfAudioIsPlayingForThisBook() async {
    try {
      // Get playing book code
      String? playingBookCode = await audioPlayerService.getPlayingBookCode();

      // Check if audio is playing
      bool isAudioActuallyPlaying = audioPlayerService.isPlaying;

      // Check if audio is paused (position > 0 but not playing)
      bool isAudioPaused = !isAudioActuallyPlaying && audioPlayerService.position.inSeconds > 0;

      // Check if mini player changed the page (which means we don't want to restart audio)
      final prefs = await SharedPreferences.getInstance();
      final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;

      debugPrint(
          'BookAudioController.checkIfAudioIsPlayingForThisBook: playingBookCode=$playingBookCode, currentBookCode=$bookCode, isPlaying=$isAudioActuallyPlaying, isPaused=$isAudioPaused, miniPlayerChangedPage=$miniPlayerChangedPage');

      // If playing book code matches this book AND audio is playing or paused, show progress bar
      if (playingBookCode != null &&
          playingBookCode == bookCode &&
          (isAudioActuallyPlaying || isAudioPaused)) {
        if (!_showAudioProgress) {
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);
        }
        debugPrint('Audio is playing or paused for this book, showing progress bar');
        return true;
      } else {
        // Special case: if mini player changed the page, we want to keep the audio state as is
        if (miniPlayerChangedPage && playingBookCode == bookCode) {
          debugPrint('Mini player changed page, keeping audio state as is');
          // Keep current _showAudioProgress state (don't change visibility)
          return _showAudioProgress;
        }

        // If playing for a different book or not playing at all, hide progress bar
        if (_showAudioProgress) {
          _showAudioProgress = false;
          onShowAudioProgressChanged(_showAudioProgress);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error in checkIfAudioIsPlayingForThisBook: $e');
      // Hide progress bar on error
      if (_showAudioProgress) {
        _showAudioProgress = false;
        onShowAudioProgressChanged(_showAudioProgress);
      }
      return false;
    }
  }

  // Check current audio page and update if needed
  Future<void> checkCurrentAudioPageAndUpdate(
      int currentPage, Function(int) onPageUpdated, Function() onPageAlreadyCurrent) async {
    try {
      // Check playing book
      String? playingBookCode = audioPlayerService.playingBookCode;

      // If playing book matches this book, check current page
      if (playingBookCode != null && playingBookCode == bookCode) {
        final prefs = await SharedPreferences.getInstance();

        debugPrint(
            'BookAudioController: Checking current audio page. Current app page: $currentPage');

        // Use book-specific page number key - check this first
        final currentAudioPage = prefs.getInt('${bookCode}_current_audio_page') ??
            prefs.getInt('current_audio_book_page') ??
            0;

        final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;

        // If page changed, update UI
        if (currentAudioPage > 0 && (currentAudioPage != currentPage || miniPlayerChangedPage)) {
          debugPrint(
              'Page change detected: SharedPreferences: $currentAudioPage, App: $currentPage, MiniPlayerChangedPage: $miniPlayerChangedPage');

          // Reset mini player changed flag
          await prefs.setBool('mini_player_changed_page', false);

          // Call the callback to update the page
          onPageUpdated(currentAudioPage);

          debugPrint('UI updated, page: $currentAudioPage');
        } else {
          debugPrint('Page already current: $currentPage');
          onPageAlreadyCurrent();
        }
      }
    } catch (e) {
      debugPrint('Error checking and updating page: $e');
    }
  }

  // Get current audio progress state
  bool get showAudioProgress => _showAudioProgress;

  // Set audio progress state
  set showAudioProgress(bool value) {
    _showAudioProgress = value;
    onShowAudioProgressChanged(_showAudioProgress);
  }

  // Add a new method specifically for handling play/pause from the audio progress bar
  Future<void> togglePlayPauseFromProgressBar({
    required BookPageModel? currentBookPage,
    required int currentPage,
    String? bookTitle,
    String? bookAuthor,
  }) async {
    try {
      debugPrint(
          'togglePlayPauseFromProgressBar called, isPlaying=${audioPlayerService.isPlaying}');

      if (currentBookPage == null || currentBookPage.mp3.isEmpty) {
        debugPrint('No audio file found for play/pause toggle');
        return;
      }

      // If currently playing, pause the audio
      if (audioPlayerService.isPlaying) {
        debugPrint('Audio is playing, pausing it while keeping progress bar visible');
        await audioPlayerService.pauseAudio();

        // Make sure progress bar stays visible
        if (!_showAudioProgress) {
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);
        }

        // Save paused state to preferences with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);
      }
      // If paused, resume audio
      else if (audioPlayerService.position.inSeconds > 0) {
        debugPrint('Audio is paused, resuming playback');
        await audioPlayerService.resumeAudio();

        // Make sure progress bar stays visible
        if (!_showAudioProgress) {
          _showAudioProgress = true;
          onShowAudioProgressChanged(_showAudioProgress);
        }

        // Save playing state to preferences with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);
      }
      // If not started yet, start playing
      else {
        debugPrint('Audio not started yet, starting playback');
        await audioPlayerService.playAudio(currentBookPage.mp3[0]);

        _showAudioProgress = true;
        onShowAudioProgressChanged(_showAudioProgress);

        // Save playing state to preferences with book info
        await saveAudioBookPreferences(currentPage, bookTitle, bookAuthor);
      }
    } catch (e) {
      debugPrint('Error in togglePlayPauseFromProgressBar: $e');
      // Don't hide progress bar on error
    }
  }

  /// Kilit ekranında metadata ve medya kontrollerini güncelle
  Future<void> updateMetadataOnLockScreen({required int currentPage}) async {
    try {
      // Eğer medya kontrollerinin güncellenmesi gerekiyorsa
      if (_showAudioProgress && audioPlayerService.isPlaying) {
        await audioManager.startService();

        // Medya metadatasını güncelleme - kitap başlığı, yazarı vb.
        await Future.delayed(
            const Duration(milliseconds: 300)); // UI güncellemesi için kısa bekleme

        // Kitap bilgilerini MediaController'a ilet
        // Bu sayede kilit ekranında bu bilgiler görünecek
        await audioManager.updateForLockScreen(currentPage);
      }
    } catch (e) {
      debugPrint('Error updating lock screen metadata: $e');
    }
  }
}
