// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';

// Controllers
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_audio_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_bookmark_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_theme_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_media_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_navigation_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_ui_components_manager.dart';

// Widgets
import 'package:namaz_vakti_app/books/features/book/widgets/book_page_view.dart';

// Legacy managers - will be removed eventually
import 'package:namaz_vakti_app/books/features/book/services/audio_manager.dart';
import 'package:namaz_vakti_app/books/features/book/services/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// A screen for displaying and interacting with book content
class BookPageScreen extends StatefulWidget {
  final String bookCode;
  final int initialPage;
  final Color appBarColor;
  final bool forceRefresh;
  final bool autoNavigateBack;
  final bool autoPlayOnReturn;

  const BookPageScreen({
    super.key,
    required this.bookCode,
    this.initialPage = 1,
    this.appBarColor = Colors.blue,
    this.forceRefresh = false,
    this.autoNavigateBack = false,
    this.autoPlayOnReturn = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BookPageScreenState createState() => _BookPageScreenState();
}

class _BookPageScreenState extends State<BookPageScreen> with WidgetsBindingObserver {
  // Services
  final ApiService _apiService = ApiService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final BookTitleService _bookTitleService = BookTitleService();
  final BookProgressService _bookProgressService = BookProgressService();
  final BookmarkService _bookmarkService = BookmarkService();

  // Controllers
  late BookPageController _pageController;
  late BookAudioController _audioController;
  late BookBookmarkController _bookmarkController;
  late BookThemeController _themeController;
  late BookMediaController _mediaController;
  late BookNavigationController _navigationController;
  late BookUIComponentsManager _uiManager;

  // Legacy managers
  late AudioManager _audioManager;
  late ThemeManager _themeManager;

  // Scaffold GlobalKey
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  late Future<List<IndexItem>> _indexFuture;
  final bool _autoPlayNextPage = true;
  String _bookTitleText = 'Hakikat Kitabevi';
  BookPageModel? _currentBookPage;

  // --- EKLENDİ: Çıkış sırasında tekrar audio başlatmayı engelleyen flag ---
  bool _isExiting = false;

  // --- EKLENDİ: Başlık güncelleme fonksiyonu ---
  Future<void> _updateBookTitle() async {
    final title = await _bookTitleService.getTitle(widget.bookCode);
    if (mounted) {
      setState(() {
        _bookTitleText = title;
        _uiManager.bookTitleText = title;
        _audioManager.updateBookInfo(title, "Hakikat Kitabevi");
      });
    }
  }

  // Periodic timer to check for page changes in the background
  Timer? _backgroundCheckTimer;
  int _lastCheckedPage = 0;

  // Lock screen event channel
  MethodChannel? _lockScreenChannel;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addObserver(this);

    try {
      // Initialize the app
      _setupInitialData();
      _initializeManagers();
      _initializeControllers();
      _initializeUIManager();
      _themeManager.loadThemeSettings(null);
      _setupMediaControllerCallbacks();

      // Setup initial page and load content
      _checkAndUpdateInitialPage().then((initialPage) {
        _setupInitialPage(initialPage).then((_) {
          _loadInitialData().then((_) {
            _initializeAudioAfterPageLoad();

            // Check if page was changed from mini player and handle accordingly
            _checkMiniPlayerPageChangeFlag();
          });
        });
      });

      // Start the background page change listener
      _startBackgroundPageChangeListener();

      // --- YENİ: Lock screen event channel dinleyici ---
      _lockScreenChannel = const MethodChannel('lock_screen_events');
      _lockScreenChannel!.setMethodCallHandler((call) async {
        if (call.method == 'pageChanged') {
          debugPrint('BookPageScreen: lock_screen_events.pageChanged event alındı');
          await _checkAndSyncCurrentAudioPage();
        }
        return null;
      });
      // --- YENİ SONU ---
    } catch (e) {
      debugPrint('BookPageScreen initState error: $e');
    }
  }

  void _setupInitialData() {
    if (widget.forceRefresh) {
      _bookmarkService.clearCache();
    }
    _indexFuture = _apiService.getBookIndex(widget.bookCode);
  }

  Future<void> _setupInitialPage(int initialPage) async {
    if (initialPage > 1) {
      _bookProgressService.setCurrentPage(widget.bookCode, initialPage);
      await _pageController.loadPage(initialPage, isForward: initialPage > widget.initialPage);
    }
    await _bookmarkController.checkBookmarkStatus(_pageController.currentPage);
  }

  void _initializeUIManager() {
    _uiManager = BookUIComponentsManager(
      context: context,
      scaffoldKey: _scaffoldKey,
      appBarColor: widget.appBarColor,
      bookCode: widget.bookCode,
      indexFuture: _indexFuture,
      bookTitleText: _bookTitleText,
      pageController: _pageController,
      themeController: _themeController,
      bookmarkController: _bookmarkController,
      audioController: _audioController,
      audioPlayerService: _audioPlayerService,
      onPageSelected: (page) => _navigationController.goToPage(page),
      onSearch: _handleSearch,
    );
  }

  void _initializeAudioAfterPageLoad() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted && _currentBookPage != null) {
        _updateMediaControllerPageInfo();

        // Check if audio is already playing for this book
        bool isPlaying = _audioPlayerService.isPlaying;
        bool isPaused = !isPlaying && _audioPlayerService.position.inSeconds > 0;

        final prefs = await SharedPreferences.getInstance();
        final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;

        // Get the saved audio position for this book if available
        final savedPosition = prefs.getInt('${widget.bookCode}_audio_position') ?? 0;

        debugPrint(
            'BookPageScreen: Initializing audio with saved position: $savedPosition ms, isPlaying=$isPlaying, isPaused=$isPaused, miniPlayerChangedPage=$miniPlayerChangedPage');

        // Only check if audio is playing for this book if it's not coming from an auto-navigate back
        if (!widget.autoNavigateBack) {
          await _audioController.checkIfAudioIsPlayingForThisBook();

          debugPrint(
              'BookPageScreen _initializeAudioAfterPageLoad: miniPlayerChangedPage=$miniPlayerChangedPage, isPlaying=$isPlaying, isPaused=$isPaused');

          // If mini player changed page and audio is playing/paused, don't restart audio
          if (miniPlayerChangedPage && (isPlaying || isPaused)) {
            // Reset the flag
            await prefs.setBool('mini_player_changed_page', false);
            debugPrint(
                'BookPageScreen: Mini player changed page flag was true, reset and not restarting audio');

            // Make sure we're showing audio progress if needed
            if (_audioPlayerService.playingBookCode == widget.bookCode &&
                !_uiManager.showAudioProgress) {
              _uiManager.setShowAudioProgress(true);
            }

            return; // Don't auto navigate back
          }

          // If we have a saved position and audio was playing, restore it
          if (savedPosition > 0 && _audioPlayerService.playingBookCode == widget.bookCode) {
            debugPrint('BookPageScreen: Restoring saved audio position: $savedPosition ms');

            // If the book is already playing but at beginning, seek to saved position
            if ((isPlaying || isPaused) && _audioPlayerService.position.inMilliseconds < 100) {
              await _audioPlayerService.seekTo(Duration(milliseconds: savedPosition));
              debugPrint('BookPageScreen: Sought to saved position: $savedPosition ms');
            }
            // If not playing but we have position, start playback from saved position
            else if (!isPlaying &&
                !isPaused &&
                _currentBookPage != null &&
                _currentBookPage!.mp3.isNotEmpty) {
              debugPrint('BookPageScreen: Starting playback from saved position');
              await _audioController.handlePlayAudio(
                  currentBookPage: _currentBookPage!,
                  currentPage: _pageController.currentPage,
                  fromBottomBar: false,
                  startPosition: savedPosition,
                  autoResume: true,
                  bookTitle: _bookTitleText,
                  bookAuthor: "Hakikat Kitabevi");
            }
          }
        }

        if (widget.autoNavigateBack) {
          _handleAutoNavigateBack();
        }
      }
    });
  }

  void _handleAutoNavigateBack() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        try {
          await _audioPlayerService.setPlayingBookCode(widget.bookCode);
          if (_currentBookPage != null && _currentBookPage!.mp3.isNotEmpty) {
            await _audioPlayerService.playAudio(_currentBookPage!.mp3[0]);
            await _audioController.saveAudioBookPreferencesWithPlayingState(
                _pageController.currentPage, true, _bookTitleText, "Hakikat Kitabevi");
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) Navigator.of(context).pop();
          } else {
            debugPrint('No audio file found, returning to home screen');
            if (mounted) Navigator.of(context).pop();
          }
        } catch (e) {
          debugPrint('Error starting audio: $e');
          if (mounted) Navigator.of(context).pop();
        }
      }
    });
  }

  void _initializeControllers() {
    // Page Controller
    _pageController = BookPageController(
      bookCode: widget.bookCode,
      apiService: _apiService,
      bookProgressService: _bookProgressService,
      onPageChanged: (pageNumber) => _updateMediaControllerPageInfo(),
      onPageLoaded: (bookPage) async {
        if (mounted) {
          setState(() {
            _currentBookPage = bookPage;
            _uiManager.updateCurrentBookPage(bookPage);
          });
          await _updateBookTitle(); // --- EKLENDİ: Her sayfa yüklendiğinde başlığı güncelle ---
        }
      },
    );

    // Audio Controller
    _audioController = BookAudioController(
      bookCode: widget.bookCode,
      audioPlayerService: _audioPlayerService,
      audioManager: _audioManager,
      onShowAudioProgressChanged: (showProgress) {
        if (mounted) setState(() => _uiManager.setShowAudioProgress(showProgress));
      },
    );

    // Bookmark Controller
    _bookmarkController = BookBookmarkController(
      bookCode: widget.bookCode,
      bookmarkService: _bookmarkService,
      onBookmarkStatusChanged: (isBookmarked) {
        if (mounted) setState(() => _uiManager.setBookmarkStatus(isBookmarked));
      },
      onHasBookmarksChanged: (hasBookmarks) {
        if (mounted) setState(() => _uiManager.setHasBookmarks(hasBookmarks));
      },
    );

    // Theme Controller
    _themeController = BookThemeController(
      onFontSizeChanged: (fontSize) {
        if (mounted) setState(() {});
      },
    );

    // Media Controller
    _mediaController = BookMediaController(
      audioManager: _audioManager,
      bookCode: widget.bookCode,
    );

    // Navigation Controller
    _navigationController = BookNavigationController(
      bookCode: widget.bookCode,
      pageController: _pageController,
      bookmarkController: _bookmarkController,
      mediaController: _mediaController,
      audioController: _audioController,
      audioPlayerService: _audioPlayerService,
      bookTitleService: _bookTitleService,
      bookProgressService: _bookProgressService,
      onAudioProgressVisibilityChanged: (showProgress) {
        if (mounted) setState(() => _uiManager.setShowAudioProgress(showProgress));
      },
      onBookPageUpdated: (bookPage) async {
        if (mounted && bookPage != null) {
          setState(() {
            _currentBookPage = bookPage;
            _uiManager.updateCurrentBookPage(bookPage);
          });
          await _updateBookTitle(); // --- EKLENDİ: Sayfa güncellendiğinde başlığı güncelle ---
        }
      },
      onMediaInfoUpdated: _updateMediaControllerPageInfo,
    );

    // Audio Listeners
    _audioController.setupAudioListeners(context, (fromAudioCompletion) {
      if (mounted && _autoPlayNextPage) {
        _navigationController.goToNextPage(fromAudioCompletion: fromAudioCompletion);
      }
    });

    // MediaChannel listener'lar kur
    _setupMediaChannelListeners();
  }

  void _setupMediaChannelListeners() {
    // com.afaruk59.namaz_vakti_app/media_service kanalı üzerinden gelen bildirimler
    const mediaServiceChannel = MethodChannel('com.afaruk59.namaz_vakti_app/media_service');

    mediaServiceChannel.setMethodCallHandler((call) async {
      debugPrint("BookPageScreen: Method channel çağrısı: ${call.method}");

      if (!mounted) return null;

      switch (call.method) {
        case 'next':
          await _navigationController.goToNextPage();
          break;
        case 'previous':
          await _navigationController.goToPreviousPage();
          break;
        case 'togglePlay':
          if (_currentBookPage != null && _currentBookPage!.mp3.isNotEmpty) {
            final bookTitle = await _bookTitleService.getTitle(widget.bookCode);
            final bookAuthor = await _bookTitleService.getAuthor(widget.bookCode);

            await _audioController.handlePlayAudio(
              currentBookPage: _currentBookPage!,
              currentPage: _pageController.currentPage,
              fromBottomBar: true,
              bookTitle: bookTitle,
              bookAuthor: bookAuthor,
            );
          }
          break;
      }

      return null;
    });

    // Başlatma sırasında method channel servisini native tarafa bildir
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await mediaServiceChannel.invokeMethod('initMediaService');
        debugPrint("BookPageScreen: Method channel servisi başlatıldı");

        // Sayfa durumunu bildir
        await _updateMediaPageState();
      } catch (e) {
        debugPrint("Method channel servis başlatma hatası: $e");
      }
    });
  }

  Future<void> _updateMediaPageState() async {
    try {
      const mediaServiceChannel = MethodChannel('com.afaruk59.namaz_vakti_app/media_service');

      final currentPage = _pageController.currentPage;
      final lastPage = _pageController.isLastPage ? currentPage : currentPage + 1;
      const firstPage = 1;

      await mediaServiceChannel.invokeMethod('updateAudioPageState', {
        'bookCode': widget.bookCode,
        'currentPage': currentPage,
        'firstPage': firstPage,
        'lastPage': lastPage,
      });

      debugPrint("BookPageScreen: Sayfa durumu güncellendi: $currentPage / $lastPage");
    } catch (e) {
      debugPrint("Sayfa durumu güncelleme hatası: $e");
    }
  }

  void _initializeManagers() {
    // Audio Manager
    _audioManager = AudioManager(
      audioPlayerService: _audioPlayerService,
      onShowAudioProgressChanged: (showProgress) {
        if (mounted) setState(() => _uiManager.setShowAudioProgress(showProgress));
      },
      bookTitle: _bookTitleText,
      bookAuthor: "Hakikat Kitabevi",
    );

    // Theme Manager
    _themeManager = ThemeManager(
      onBackgroundColorChanged: (color) {
        if (mounted) setState(() {});
      },
      onAutoBackgroundChanged: (isAuto) {
        if (mounted) setState(() {});
      },
    );
  }

  void _setupMediaControllerCallbacks() {
    _apiService.getBookIndex(widget.bookCode).then((indexItems) {
      int totalPages = indexItems.isNotEmpty ? indexItems.last.pageNumber : 1;
      _audioManager.setupMediaControllerCallbacks(
        onNextPage: (currentPage, totalPages) {
          if (mounted) _navigationController.goToNextPage(fromAudioCompletion: false);
        },
        onPreviousPage: (currentPage) {
          if (mounted) _navigationController.goToPreviousPage();
        },
        currentPage: _pageController.currentPage,
        totalPages: totalPages,
      );
    });
  }

  void _updateMediaControllerPageInfo() {
    _apiService.getBookIndex(widget.bookCode).then((indexItems) {
      int totalPages = indexItems.isNotEmpty ? indexItems.last.pageNumber : 1;
      _mediaController.updateCurrentPage(_pageController.currentPage, totalPages);

      if (_currentBookPage != null && _currentBookPage!.mp3.isNotEmpty) {
        try {
          _mediaController.updateMetadata(
            _currentBookPage!,
            _bookTitleText,
            "Hakikat Kitabevi",
            _pageController.currentPage,
          );
        } catch (e) {
          debugPrint('Error updating media metadata: $e');
        }
      }
    }).catchError((error) {
      debugPrint('Error updating media controller: $error');
    });
  }

  Future<void> _loadInitialData() async {
    await _pageController.initializeFirstPage();
    await _loadBookTitle();
    await _bookmarkController.initializeBookmarkStatus(_pageController.currentPage);

    if (_themeController.isAutoBackground && mounted) {
      _themeController.updateAutoBackground(context);
    }
  }

  Future<void> _loadBookTitle() async {
    final title = await _bookTitleService.getTitle(widget.bookCode);
    setState(() {
      _bookTitleText = title;
      _audioManager.updateBookInfo(title, "Hakikat Kitabevi");
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_themeController.isAutoBackground) {
      _themeController.updateAutoBackground(context);
    }
  }

  void _handlePlayAudio({bool fromBottomBar = false, bool afterPageChange = false}) async {
    if (_isExiting) return;
    try {
      // Log to help troubleshoot audio issues
      debugPrint(
          '_handlePlayAudio called: fromBottomBar= [38;5;2m$fromBottomBar [0m, afterPageChange=$afterPageChange');
      debugPrint(
          'Audio state: isPlaying=${_audioPlayerService.isPlaying}, position=${_audioPlayerService.position.inSeconds}s');

      // Uygulama yeniden açıldığında veya kullanıcı manuel başlattığında, startPosition her zaman 0 olmalı
      int? startPosition = 0;

      await _audioController.handlePlayAudio(
        currentBookPage: _currentBookPage,
        currentPage: _pageController.currentPage,
        fromBottomBar: fromBottomBar,
        afterPageChange: afterPageChange,
        startPosition: startPosition,
        autoResume: true,
        bookTitle: _bookTitleText,
        bookAuthor: "Hakikat Kitabevi",
      );

      // Immediately after starting audio playback, update the mini player with book info
      // if (_audioPlayerService.isPlaying &&
      //     _currentBookPage != null &&
      //     _currentBookPage!.mp3.isNotEmpty) {
      //   await _audioController.updateHomeScreenWithCurrentBook(
      //     _pageController.currentPage,
      //     _bookTitleText,
      //     "Hakikat Kitabevi",
      //   );
      //   print(
      //       'Mini player updated with book info: $_bookTitleText, page: ${_pageController.currentPage}');
      // }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) setState(() => _uiManager.setShowAudioProgress(false));

      // Show a brief error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses oynatılırken bir hata oluştu'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Add new method for handling play/pause from audio progress bar
  void _handlePlayPauseFromProgressBar() async {
    try {
      debugPrint('_handlePlayPauseFromProgressBar called');
      debugPrint(
          'Current state: isPlaying=${_audioPlayerService.isPlaying}, showProgress=${_uiManager.showAudioProgress}');

      // Use the specialized method that keeps progress bar visible
      await _audioController.togglePlayPauseFromProgressBar(
        currentBookPage: _currentBookPage,
        currentPage: _pageController.currentPage,
        bookTitle: _bookTitleText,
        bookAuthor: "Hakikat Kitabevi",
      );
    } catch (e) {
      debugPrint('Error in play/pause toggle: $e');

      // Show error but don't close progress bar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses oynatma/duraklatma sırasında bir hata oluştu'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSeek(double value) async {
    await _audioController.handleSeek(value);
  }

  void _handleSpeedChange() {
    _audioController.handleSpeedChange();
    HapticFeedback.lightImpact();
  }

  void _handleBookmarkToggled(bool isBookmarked) {
    setState(() => _uiManager.setBookmarkStatus(isBookmarked));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked ? 'Bookmark added' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ignore: unused_element
  Future<void> _toggleBookmark() async {
    await _bookmarkController.toggleBookmark(_pageController.currentPage);
    _handleBookmarkToggled(_uiManager.isBookmarked);
  }

  Future<void> _refreshBookmarkStatus() async {
    await _bookmarkController.refreshBookmarkStatus(_pageController.currentPage);

    if (_audioPlayerService.isPlaying || _uiManager.showAudioProgress) {
      debugPrint('Highlights not reloaded during audio playback');
      return;
    }

    if (_currentBookPage != null) {
      setState(() {
        _currentBookPage = BookPageModel(
          audio: _currentBookPage!.audio,
          mp3: _currentBookPage!.mp3,
          pageText: _currentBookPage!.pageText,
        );
        _uiManager.updateCurrentBookPage(_currentBookPage!);
      });
    }
  }

  void _handleSearch(String searchText) {
    setState(() => _uiManager.setSearchText(searchText));
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onPageChanged(int pageNumber) {
    if (_isExiting) return;

    // Since we no longer use PageView, this method is mainly for manual navigation
    // triggered by navigation buttons or external page changes
    try {
      Future.microtask(() async {
        try {
          if (_isExiting) return;
          await _audioController.checkIfAudioIsPlayingForThisBook();

          if (pageNumber != _pageController.currentPage) {
            if (_isExiting) return;
            await _navigationController.goToPage(pageNumber);
          }
        } catch (e) {
          debugPrint('Error handling page change: $e');
        }
      });
    } catch (e) {
      debugPrint('Page change error: $e');
    }
  }

  // Orientation tracking için state variables
  Orientation? _lastOrientation;
  bool _isRestoringAfterOrientationChange = false;

  @override
  Widget build(BuildContext context) {
    // Orientation change detection ve state preservation
    final currentOrientation = MediaQuery.of(context).orientation;

    // İlk build veya orientation değişikliği kontrolü
    if (_lastOrientation == null) {
      _lastOrientation = currentOrientation;
    } else if (_lastOrientation != currentOrientation && !_isRestoringAfterOrientationChange) {
      debugPrint(
          'BookPageScreen: Orientation changed from $_lastOrientation to $currentOrientation');
      _handleOrientationChange(currentOrientation);
      _lastOrientation = currentOrientation;
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _isExiting = true;
        // Geri tuşuna basınca notification ve audio kesinlikle kapatılsın
        await _audioManager.stopAllAudioAndNotification();
        return true;
      },
      child: OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
            extendBody: true,
            key: _scaffoldKey,
            drawer: _uiManager.buildDrawer(
              searchFunction: _apiService.searchBook,
              currentBookPage: _currentBookPage,
            ),
            appBar: _uiManager.buildAppBar(onBackgroundColorChanged: () {
              if (mounted) setState(() {});
            }),
            body: Stack(
              children: [
                BookPageView(
                  pageController: _pageController,
                  uiManager: _uiManager,
                  bookCode: widget.bookCode,
                  onPageChanged: _onPageChanged,
                  onStateChanged: () => setState(() {}),
                  backgroundColor: _themeController.backgroundColor,
                ),
                // BookControlsOverlay widget'ı kaldırıldı
              ],
            ),
            bottomNavigationBar: _uiManager.buildBottomBar(
              onPlayAudio: () => _handlePlayAudio(fromBottomBar: true),
              onPlayPauseProgress: _handlePlayPauseFromProgressBar,
              onSeek: _handleSeek,
              onSpeedChange: _handleSpeedChange,
              refreshBookmarkStatus: _refreshBookmarkStatus,
              onPageNumberEntered: (pageNumber) => _navigationController.goToPage(pageNumber),
              onNextPage: () => _navigationController.goToNextPage(),
              onPreviousPage: () => _navigationController.goToPreviousPage(),
            ),
            drawerEnableOpenDragGesture: false,
          );
        },
      ),
    );
  }

  void _handleOrientationChange(Orientation newOrientation) async {
    debugPrint('BookPageScreen: Handling orientation change to $newOrientation');

    _isRestoringAfterOrientationChange = true;

    // Mevcut audio state'i kaydet
    final wasShowingProgress = _uiManager.showAudioProgress;
    final currentPlayingBookCode = await _audioPlayerService.getPlayingBookCode();
    final isPlaying = _audioPlayerService.isPlaying;

    debugPrint(
        'BookPageScreen: Pre-orientation state - showProgress: $wasShowingProgress, isPlaying: $isPlaying, bookCode: $currentPlayingBookCode');

    // Orientation change sonrası state'i restore et
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      debugPrint('BookPageScreen: Restoring state after orientation change');

      // Audio service full recovery
      _audioPlayerService.recoverAfterOrientationChange();

      // Progress bar state restore
      if (wasShowingProgress && currentPlayingBookCode == widget.bookCode) {
        _uiManager.setShowAudioProgress(true);
        _audioController.showAudioProgress = true;

        debugPrint('BookPageScreen: Restored audio progress bar after orientation change');
      }

      // Force UI update
      if (mounted) {
        setState(() {});
      }

      // Kısa bir gecikme sonra daha da güçlendir
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        if (isPlaying && currentPlayingBookCode == widget.bookCode) {
          _audioPlayerService.recoverAfterOrientationChange();
          _uiManager.setShowAudioProgress(true);
          _audioController.showAudioProgress = true;

          debugPrint('BookPageScreen: Double-confirmed audio state after orientation change');

          if (mounted) setState(() {});
        }

        _isRestoringAfterOrientationChange = false;
      });
    });
  }

  Future<int> _checkAndUpdateInitialPage() async {
    try {
      String? savedBookCode = await _audioPlayerService.getPlayingBookCode();
      if (savedBookCode != null && savedBookCode == widget.bookCode) {
        return await _pageController.checkAndUpdateInitialPage(widget.initialPage);
      }
    } catch (e) {
      debugPrint('Error updating initial page: $e');
    }
    return widget.initialPage;
  }

  @override
  void dispose() {
    // dispose'u asenkron hale getir
    _disposeAsync();
    super.dispose();
  }

  Future<void> _disposeAsync() async {
    _isExiting = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.removeObserver(this);

    // Dispose background check timer
    _backgroundCheckTimer?.cancel();

    // Always stop audio playback and notification when leaving the book screen
    debugPrint('Stopping audio playback and notification when leaving book screen');
    await _audioManager.stopAllAudioAndNotification();

    try {
      _pageController.dispose();
      _audioManager.disposeWithoutStoppingAudio();
    } catch (e) {
      debugPrint('BookPageScreen dispose error: $e');
    }

    // --- YENİ: Lock screen channel temizle ---
    _lockScreenChannel = null;
  }

  @override
  void didUpdateWidget(BookPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_pageController.currentPage != 0) {
      _bookmarkController.checkBookmarkStatus(_pageController.currentPage);
    }

    if (_uiManager.searchText != null) {
      setState(() => _uiManager.setSearchText(null));
    }

    Future.microtask(() async {
      await _audioController.checkIfAudioIsPlayingForThisBook();
    });
  }

  // Check if the page was changed from mini player and handle it
  Future<void> _checkMiniPlayerPageChangeFlag() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final prefs = await SharedPreferences.getInstance();
      final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;
      final currentAudioPage = prefs.getInt('${widget.bookCode}_current_audio_page') ??
          prefs.getInt('current_audio_book_page') ??
          0;
      // --- DÖNGÜ KIRICI ---
      if (!miniPlayerChangedPage || _audioPlayerService.isPlaying) {
        // Eğer flag zaten false ise veya audio oynuyorsa hiçbir şey yapma
        return;
      }
      if (miniPlayerChangedPage &&
          currentAudioPage > 0 &&
          currentAudioPage != _pageController.currentPage) {
        debugPrint(
            'BookPageScreen: Detected page change from mini player, navigating to page $currentAudioPage (current: ${_pageController.currentPage})');
        await prefs.setBool('mini_player_changed_page', false);
        debugPrint('BookPageScreen: Reset mini_player_changed_page flag before navigation');
        await _navigationController.goToPage(currentAudioPage);
        if (_audioPlayerService.isPlaying || _audioPlayerService.position.inSeconds > 0) {
          debugPrint('BookPageScreen: Audio is already playing or paused, not restarting');
        }
      } else if (miniPlayerChangedPage) {
        await prefs.setBool('mini_player_changed_page', false);
        debugPrint('BookPageScreen: Reset mini_player_changed_page flag (already on correct page)');
      }
    } catch (e) {
      debugPrint('BookPageScreen: Error checking mini player page change flag: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('BookPageScreen: App lifecycle state changed to $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - force state sync and restore media player
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        // App paused - preserve state for background audio
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App inactive (orientation change, etc.) - preserve state
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        // App detached - clean up if needed
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        // App hidden - maintain state
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() async {
    debugPrint('BookPageScreen: App resumed - syncing media player state');

    // Force audio service state sync
    _audioPlayerService.forceStateSync();

    // Sync UI with current audio state
    _syncAudioProgressWithPlayer();

    // Check for page changes from background controls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAndSyncCurrentAudioPage();
      }
    });

    // Ensure media controller metadata is updated
    if (_audioPlayerService.isPlaying) {
      _updateMediaControllerPageInfo();
    }
  }

  void _handleAppPaused() {
    debugPrint('BookPageScreen: App paused - preserving media player state');

    // Preserve audio playback for background
    if (_audioPlayerService.isPlaying) {
      _audioController.updateMetadataOnLockScreen(currentPage: _pageController.currentPage);
    }

    // Update media controller for background state
    if (_audioPlayerService.isPlaying) {
      _updateMediaControllerPageInfo();
    }
  }

  void _handleAppInactive() {
    debugPrint('BookPageScreen: App inactive (orientation change) - maintaining state');

    // During orientation changes, maintain the media player state
    // Force state preservation
    if (_uiManager.showAudioProgress) {
      // Ensure progress bar doesn't disappear during orientation change
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _audioPlayerService.playingBookCode == widget.bookCode) {
          _uiManager.setShowAudioProgress(true);
          _audioPlayerService.forceStateSync();
        }
      });
    }
  }

  void _handleAppDetached() {
    debugPrint('BookPageScreen: App detached');
    // App is being destroyed, but we don't want to stop audio
    // Just ensure cleanup if needed
  }

  void _handleAppHidden() {
    debugPrint('BookPageScreen: App hidden');
    // Similar to paused, maintain state
    _handleAppPaused();
  }

  // App resume olduğunda audio progress bar'ı ve pozisyonu güncelle
  void _syncAudioProgressWithPlayer() async {
    try {
      bool isPlaying = _audioPlayerService.isPlaying;
      bool isPaused = !isPlaying && _audioPlayerService.position.inSeconds > 0;
      String? playingBookCode = await _audioPlayerService.getPlayingBookCode();

      debugPrint(
          '_syncAudioProgressWithPlayer: isPlaying=$isPlaying, isPaused=$isPaused, playingBookCode=$playingBookCode, currentBookCode=${widget.bookCode}');

      // Force state sync to ensure UI reflects actual audio service state
      _audioPlayerService.forceStateSync();

      if ((isPlaying || isPaused) && playingBookCode == widget.bookCode) {
        if (!_uiManager.showAudioProgress) {
          _uiManager.setShowAudioProgress(true);
          debugPrint('_syncAudioProgressWithPlayer: Showing audio progress bar');
        }

        // Update audio controller state
        _audioController.showAudioProgress = true;

        // Force position update
        _audioPlayerService.forcePositionUpdate();

        // Update media controller if needed
        _updateMediaControllerPageInfo();
      } else if (playingBookCode != null && playingBookCode != widget.bookCode) {
        // Different book is playing, hide progress bar
        if (_uiManager.showAudioProgress) {
          _uiManager.setShowAudioProgress(false);
          _audioController.showAudioProgress = false;
        }
      }

      // Ensure UI updates
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error in _syncAudioProgressWithPlayer: $e');
    }
  }

  // Check and sync the current audio page from SharedPreferences
  // but don't change audio playback
  Future<void> _checkAndSyncCurrentAudioPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAudioPage = prefs.getInt('${widget.bookCode}_current_audio_page') ??
          prefs.getInt('current_audio_book_page') ??
          0;

      // Get current audio position for restoration later
      final currentPosition = _audioPlayerService.position.inMilliseconds;
      debugPrint('Current audio position before sync: $currentPosition ms');

      // If audio is playing and the stored page is different from our current page,
      // this likely means the page was changed via media controls while the app was in background
      if (_audioPlayerService.isPlaying || _audioPlayerService.position.inSeconds > 0) {
        if (currentAudioPage > 0 && currentAudioPage != _pageController.currentPage) {
          debugPrint('BookPageScreen: Detected page change while app was in background. '
              'Stored page: $currentAudioPage, Current page: ${_pageController.currentPage}');

          // Instead of navigating with the navigation controller,
          // we'll update the UI directly without changing audio

          // Set flag to true to indicate this is from mini player/media controls
          await prefs.setBool('mini_player_changed_page', true);

          // Save current audio position so it's not lost during page change
          await prefs.setInt('${widget.bookCode}_audio_position', currentPosition);

          // Only update the page in the UI, without changing audio
          debugPrint('BookPageScreen: Updating page display without changing audio');

          // Jump to page and load content
          await _pageController.jumpToPage(currentAudioPage);
          await _pageController.loadPage(currentAudioPage,
              isForward: currentAudioPage > _pageController.currentPage);

          // Update bookmark status for the new page
          await _bookmarkController.checkBookmarkStatus(currentAudioPage);

          // Get page content and update UI
          BookPageModel? bookPage = await _pageController.getPageFromCacheOrLoad(currentAudioPage);
          setState(() {
            _currentBookPage = bookPage;
            _uiManager.updateCurrentBookPage(bookPage);
          });

          // Reset the flag
          await prefs.setBool('mini_player_changed_page', false);

          debugPrint(
              'BookPageScreen: Synced page UI to match audio page after resume (without changing audio)');

          // Restore the exact audio position if needed
          if (_audioPlayerService.position.inMilliseconds != currentPosition) {
            await _audioPlayerService.seekTo(Duration(milliseconds: currentPosition));
            debugPrint('Restored audio position after page sync: $currentPosition ms');
          }
        }
      }
    } catch (e) {
      debugPrint('BookPageScreen: Error checking current audio page: $e');
    }
  }

  // Start background page change listener
  void _startBackgroundPageChangeListener() {
    // Check every 2 seconds for page changes
    _backgroundCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkForBackgroundPageChanges();
      } else {
        // Dispose timer if widget is no longer mounted
        timer.cancel();
      }
    });
  }

  // Check for page changes that happened in the background
  Future<void> _checkForBackgroundPageChanges() async {
    try {
      if (!mounted) return;
      if (!_audioPlayerService.isPlaying && _audioPlayerService.position.inSeconds <= 0) return;
      final prefs = await SharedPreferences.getInstance();
      final currentAudioPage = prefs.getInt('${widget.bookCode}_current_audio_page') ??
          prefs.getInt('current_audio_book_page') ??
          0;
      final miniPlayerChangedPage = prefs.getBool('mini_player_changed_page') ?? false;
      // --- DÖNGÜ KIRICI ---
      if (miniPlayerChangedPage || _audioPlayerService.isPlaying) {
        // Eğer flag zaten true ise veya audio oynuyorsa hiçbir şey yapma
        return;
      }
      if (currentAudioPage > 0 &&
          currentAudioPage != _lastCheckedPage &&
          currentAudioPage != _pageController.currentPage) {
        debugPrint(
            'BookPageScreen: Detected background page change: $currentAudioPage (current: ${_pageController.currentPage})');
        _lastCheckedPage = currentAudioPage;
        await prefs.setBool('mini_player_changed_page', true);
        debugPrint(
            'BookPageScreen: Updating page display without changing audio (background check)');
        if (mounted) {
          await _pageController.jumpToPage(currentAudioPage);
          await _pageController.loadPage(currentAudioPage,
              isForward: currentAudioPage > _pageController.currentPage);
          await _bookmarkController.checkBookmarkStatus(currentAudioPage);
          BookPageModel? bookPage = await _pageController.getPageFromCacheOrLoad(currentAudioPage);
          if (mounted) {
            setState(() {
              _currentBookPage = bookPage;
              _uiManager.updateCurrentBookPage(bookPage);
            });
          }
        }
        await prefs.setBool('mini_player_changed_page', false);
        debugPrint(
            'BookPageScreen: Synced page UI to match audio page in background (without changing audio)');
      } else if (currentAudioPage > 0) {
        _lastCheckedPage = currentAudioPage;
      }
    } catch (e) {
      debugPrint('BookPageScreen: Error checking for background page changes: $e');
    }
  }
}
