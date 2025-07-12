import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/shared/widgets/index_drawer.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import '../audio/quran_audio_service.dart';
import '../controllers/quran_page_controller.dart';
import '../ui/quran_app_bar.dart';
import '../audio/quran_audio_repository.dart';
import '../ui/quran_settings_drawer.dart';
import '../ui/quran_audio_progress_bar.dart';
import '../ui/quran_navigation_bar.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_navigation_controller.dart';
import '../ui/quran_body_builder.dart';
import '../services/quran_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/screens/bookmarks_screen.dart';

/// Kuran sayfası ekranı
class ModularQuranPageScreen extends StatefulWidget {
  final int initialPage;
  final String initialFormat;

  const ModularQuranPageScreen({
    Key? key,
    this.initialPage = 0,
    this.initialFormat = 'Mukabele',
  }) : super(key: key);

  // Static fields to preserve audio state between navigations
  static QuranAudioService? _sharedAudioService;
  static bool _wasAudioPlaying = false;
  static int _lastPlayingPage = 0;
  static int _lastPlayingSurah = 0;
  static int _lastPlayingAyah = 0;

  @override
  _ModularQuranPageScreenState createState() => _ModularQuranPageScreenState();
}

/// FloatingActionButton'un bottom bar ile bütünleşmesi için özel konum sınıfı
class QuranFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation location;
  final double offsetY;

  const QuranFloatingActionButtonLocation(this.location, {this.offsetY = 0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy + offsetY);
  }
}

class _ModularQuranPageScreenState extends State<ModularQuranPageScreen> {
  late QuranPageController _pageController;
  late QuranAudioService _audioService;
  late QuranAudioController _audioController;
  late QuranNavigationController _navigationController;
  late Future<List<IndexItem>> _indexFuture;
  late QuranAudioRepository _audioRepository;
  final QuranProgressService _progressService = QuranProgressService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _useExistingAudioService = false;
  bool _showMeal = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadShowMealPref();
    _pageController = QuranPageController(
      initialPage: widget.initialPage,
      initialFormat: widget.initialFormat,
    );
    // Controller'ı başlat
    _initController();

    _audioRepository = QuranAudioRepository();
    _indexFuture = Future.value([]);

    // Check if we have an existing audio service
    if (ModularQuranPageScreen._sharedAudioService != null &&
        ModularQuranPageScreen._wasAudioPlaying &&
        !ModularQuranPageScreen._sharedAudioService!.isDisposed) {
      print('Restoring previous audio service');
      _useExistingAudioService = true;
      _audioService = ModularQuranPageScreen._sharedAudioService!;
    } else {
      print('Creating new audio service');
      _audioService = QuranAudioService();
      ModularQuranPageScreen._sharedAudioService = _audioService;
    }

    // Always create a new audio controller with either existing or new service
    _audioController = QuranAudioController(
      audioService: _audioService,
      pageController: _pageController,
      context: context,
      audioPlayerService: AudioPlayerService(),
    );

    // Navigation controller'ı oluştur
    _navigationController = QuranNavigationController(
      pageController: _pageController,
      audioController: _audioController,
      context: context,
    );

    // State değişikliklerini dinle
    _audioController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // PageController'ın değişikliklerini dinle
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          // Tam ekran modu değiştiğinde UI'ı güncelle
          print(
              'PageController değişikliği algılandı: Tam ekran modu: ${_pageController.isFullScreen}');
        });
      }
    });

    // If we're coming back and audio was playing, restore audio state
    if (_useExistingAudioService && ModularQuranPageScreen._wasAudioPlaying) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          print('Restoring audio playback state');

          // First ensure correct page is shown
          if (ModularQuranPageScreen._lastPlayingPage > 0 &&
              _pageController.currentPage != ModularQuranPageScreen._lastPlayingPage) {
            _pageController.changePage(ModularQuranPageScreen._lastPlayingPage);
          }

          // Then restore audio UI state
          setState(() {
            _audioController.showAudioProgress = true;
          });

          // If audio is not playing but should be, restart it
          if (!_audioService.isPlaying && !_audioService.isBesmelePlaying) {
            _restoreAudioPlayback();
          }
        }
      });
    }
  }

  // Controller'ı başlatan metot
  Future<void> _initController() async {
    await _pageController.init();

    // Sayfa değiştiğinde MediaController'ı güncelle
    _pageController.addListener(() {
      if (_audioController.showAudioProgress) {
        _audioController.updateMediaController();
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageController.preloadAdjacentPages(context);
  }

  void _openSettingsDrawer() {
    // Drawer açılmadan önce controller'ın güncel değerlerini kullan
    setState(() {
      // Bu, endDrawer'ın güncel değerleri kullanmasını sağlar
    });

    if (_scaffoldKey.currentState != null) {
      _scaffoldKey.currentState!.openEndDrawer();
    }
  }

  void _openDrawer() {
    if (_scaffoldKey.currentState != null) {
      // Drawer'ı aç
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Çıkarken ses ve bildirim temizliği yap
        await _cleanupAndDispose();
        final homeScreenState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeScreenState != null) {
          homeScreenState.refreshBookmarkIndicators();
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _pageController.backgroundColor,
        drawer: _buildDrawer(),
        endDrawer: _buildEndDrawer(),
        appBar: _buildAppBar(),
        body: QuranBodyBuilder(
          pageController: _pageController,
          audioController: _audioController,
          context: context,
          showMeal: _showMeal,
          onHighlightChanged: _refreshBookmarkButton, // yeni parametre
        ).build(),
        bottomNavigationBar: _buildBottomBar(),
        extendBody: true, // Body'nin bottom bar'ın altına kadar uzanmasını sağlar
        drawerEnableOpenDragGesture: false, // Sadece buton ile açılır
        endDrawerEnableOpenDragGesture: false, // Sadece buton ile açılır
      ),
    );
  }

  Widget? _buildDrawer() {
    if (_pageController.isFullScreen) return null;

    return SizedBox(
      width: 280,
      height: MediaQuery.of(context).size.height -
          AppBar().preferredSize.height -
          MediaQuery.of(context).padding.top -
          60,
      child: Drawer(
        child: IndexDrawer(
          indexFuture: _indexFuture,
          bookTitle: 'Kuran-ı Kerim',
          onPageSelected: (page) async {
            // Ses çalıyor mu kontrol et
            final wasPlaying = _audioController.showAudioProgress ||
                _audioService.isPlaying ||
                _audioService.isBesmelePlaying;

            // Önce ses çalmayı tamamen durdur
            if (_audioService.isPlaying || _audioService.isBesmelePlaying) {
              print('Drawer sayfa seçimi öncesi ses durduruldu');
              await _audioService.stop();

              // UI'ı güncelle
              if (mounted) {
                _audioController.showAudioProgress = false;
              }
            }

            // Sayfa değişimini gerçekleştir
            print('Drawer ile sayfa değişimi yapılıyor: ${_pageController.currentPage} -> $page');
            _pageController.changePage(page);

            // Drawer'ı güvenli bir şekilde kapat
            try {
              if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              print('Drawer kapatma hatası: $e');
              // Hata durumunda drawer'ı kapatmayı tekrar dene
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }

            // Eğer önceden ses çalıyorsa veya besmele çalıyorsa, yeni sayfanın sesini otomatik başlat
            if (wasPlaying) {
              // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
              // Daha uzun bir bekleme süresi ekleyerek sayfa değişiminin tamamlanmasını bekle
              Future.delayed(Duration(milliseconds: 1500), () {
                if (mounted) {
                  print('Drawer sayfa değişimi sonrası ses çalma başlatılıyor: $page');
                  // Yeni sayfanın verilerini yükle ve sesi çal
                  _audioController.loadAndPlayCurrentPage();
                }
              });
            }
          },
          bookCode: 'quran',
          appBarColor: Colors.green.shade700,
          searchFunction: _navigationController.searchInQuran,
          juzIndex: _audioController.audioRepository.getQuranJuzIndex(),
        ),
      ),
    );
  }

  Widget? _buildEndDrawer() {
    if (_pageController.isFullScreen || _pageController.quranBook.selectedFormat != 'Mukabele') {
      return null;
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height -
          AppBar().preferredSize.height -
          MediaQuery.of(context).padding.top -
          60,
      child: QuranSettingsDrawer(
        fontSize: _pageController.fontSize,
        onFontSizeChanged: (newSize) {
          _pageController.setFontSize(newSize);
          setState(() {});
        },
        isAutoBackground: _pageController.isAutoBackground,
        onAutoBackgroundChanged: (value) {
          _pageController.setAutoBackground(value, context);
          setState(() {});
        },
        backgroundColor: _pageController.backgroundColor,
        onBackgroundColorChanged: (color) async {
          await _pageController.setBackgroundColor(color);
          setState(() {});
        },
        selectedFont: _pageController.selectedFont,
        availableFonts: _pageController.availableFonts,
        onFontChanged: (newFont) {
          _pageController.setFont(newFont);
          setState(() {});
        },
        isAutoScroll: _pageController.isAutoScroll,
        onAutoScrollChanged: (value) {
          _pageController.setAutoScroll(value);
          setState(() {});
        },
        onResetSettings: () async {
          // Ayarları sıfırla
          await _pageController.resetSettings(context);

          // Sayfayı yeniden yükle
          _audioController.clearCache();

          // UI'ı güncelle
          setState(() {});
        },
        showMeal: _showMeal,
        onShowMealChanged: (value) {
          setState(() {
            _showMeal = value;
          });
          _setShowMealPref(value);
        },
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_pageController.isFullScreen) return null;

    return QuranAppBar(
      selectedFormat: _pageController.quranBook.selectedFormat,
      availableFormats: _pageController.quranBook.getAvailableFormats(),
      onFormatChanged: (newFormat) {
        _pageController.changeFormat(newFormat);
        setState(() {});
      },
      onBackPressed: () async {
        await _cleanupAndDispose();
        Navigator.of(context).pop();
      },
      onSettingsPressed:
          _pageController.quranBook.selectedFormat == 'Mukabele' ? _openSettingsDrawer : null,
      actions: [], // Eski bookmark butonu kaldırıldı
    );
  }

  Widget _buildBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_audioController.showAudioProgress && !_pageController.isFullScreen)
          _buildAudioProgressBar(),
        if (!_pageController.isFullScreen) _buildNavigationBar(),
      ],
    );
  }

  Widget _buildAudioProgressBar() {
    // Ses çalma başladığında MediaController'ı güncelle
    if (_audioController.showAudioProgress) {
      _audioController.updateMediaController();
    }

    return QuranAudioProgressBar(
      position: _audioService.position,
      duration: _audioService.duration,
      isPlaying: _audioService.isPlaying,
      playbackRate: _audioService.playbackRate,
      onSeek: (position) {
        _audioService.seekTo(position);
      },
      onPlayPause: () {
        if (_audioService.isPlaying || _audioService.isBesmelePlaying) {
          _audioController.pauseAudio();
        } else {
          _audioController.resumeAudio();
        }
      },
      onPlaybackRateChanged: (rate) {
        _audioService.setPlaybackRate(rate);
      },
      // Önceki ayet butonu için callback
      onPreviousAyah: () {
        _audioService.playPreviousAyah();
      },
      // Sonraki ayet butonu için callback
      onNextAyah: () {
        _audioService.playNextAyah();
      },
      // Mevcut sure ve ayet bilgisi
      currentSurahAndAyah: _audioService.getCurrentSurahAndAyah(),
      // İlk ayet kontrolü
      isFirstAyah: _audioService.isFirstAyahOfCurrentPage(),
      // Son ayet kontrolü
      isLastAyah: _audioService.isLastAyahOfCurrentPage(),
      appBarColor: Colors.green.shade700, // overlay rengi
    );
  }

  Widget _buildNavigationBar() {
    final displayPageNumber = _pageController.currentPage;

    return FutureBuilder<int>(
      future: BookmarkService().getBookmarkCount('quran'),
      builder: (context, snapshot) {
        final hasBookmarks = (snapshot.hasData && snapshot.data != null && snapshot.data! > 0);
        return QuranNavigationBar(
          currentPage: displayPageNumber,
          onMenuPressed: _openDrawer,
          onPreviousPage: _navigationController.goToPreviousPage,
          onNextPage: _navigationController.goToNextPage,
          onPageNumberTap: _navigationController.showPageInputDialog,
          onPlayAudio: () {
            _audioController.resetMediaNotificationClosed();
            _audioController.playAudio();
          },
          isPlaying: _audioController.showAudioProgress,
          leadingWidgets: [
            if (hasBookmarks)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: Icon(Icons.bookmarks_outlined, color: Colors.white, size: 24),
                  onPressed: () async {
                    BookmarkService().clearCache();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookmarksScreen(initialBookCode: 'quran', showMeal: _showMeal),
                      ),
                    );
                    setState(() {}); // Dönüşte güncelle
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _cleanupAndDispose() async {
    try {
      print(
          'Stopping Quran audio playback but saving page position: ${_pageController.currentPage}');

      // Save the current page position
      await _progressService.setCurrentPage(_pageController.currentPage);

      // If page changed, update progress
      if (_pageController.currentPage > 0) {
        await _progressService.setProgress(_pageController.currentPage / 604);
      }

      // Always stop audio and cleanup when leaving the screen
      try {
        if (!_audioService.isDisposed) {
          await _audioService.stop();
          await _audioController.cleanup(); // <-- her durumda çağrılacak
          await _audioService.cleanup();

          // Reset the audio-related flags
          ModularQuranPageScreen._wasAudioPlaying = false;
          ModularQuranPageScreen._lastPlayingSurah = 0;
          ModularQuranPageScreen._lastPlayingAyah = 0;

          // Clear shared audio service reference
          ModularQuranPageScreen._sharedAudioService = null;

          // But don't reset the last page - we want to remember it!
          // We're keeping this commented out to show what we're NOT doing:
          // ModularQuranPageScreen._lastPlayingPage = 0;
        }
      } catch (e) {
        print('AudioService cleanup hatası: $e');
      }

      // Always dispose controllers
      try {
        _audioController.dispose();
        _pageController.dispose();
      } catch (e) {
        print('Controller dispose hatası: $e');
      }
    } catch (e) {
      print('_cleanupAndDispose genel hatası: $e');
    }
  }

  // New method to restore audio playback
  void _restoreAudioPlayback() async {
    try {
      // Make sure we have saved state
      if (ModularQuranPageScreen._lastPlayingSurah > 0 &&
          ModularQuranPageScreen._lastPlayingAyah > 0) {
        print(
            'Attempting to restore audio playback: Sure ${ModularQuranPageScreen._lastPlayingSurah}, Ayet ${ModularQuranPageScreen._lastPlayingAyah}');

        // Show audio progress bar immediately
        setState(() {
          _audioController.showAudioProgress = true;
        });

        // Get audio URLs for the last played ayah
        final audioUrl = _audioRepository.getAudioUrl(
            ModularQuranPageScreen._lastPlayingSurah, ModularQuranPageScreen._lastPlayingAyah);
        final xmlUrl = _audioRepository.getXmlUrl(
            ModularQuranPageScreen._lastPlayingSurah, ModularQuranPageScreen._lastPlayingAyah);

        // Restart playback
        await _audioService.playAyah(
          surahNo: ModularQuranPageScreen._lastPlayingSurah,
          ayahNo: ModularQuranPageScreen._lastPlayingAyah,
          audioUrl: audioUrl,
          xmlUrl: xmlUrl,
          shouldPlayBesmele: false, // Don't play besmele when restoring
          isUserInitiated: false,
        );

        // Update media controller
        final surahName = _audioRepository.getSurahName(ModularQuranPageScreen._lastPlayingSurah);
        _audioController.mediaController.updateForQuranPage(
          ModularQuranPageScreen._lastPlayingPage,
          surahName,
          ModularQuranPageScreen._lastPlayingAyah,
        );

        // Update UI
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error restoring audio playback: $e');
      // If restoration fails, reset flags
      ModularQuranPageScreen._wasAudioPlaying = false;
      if (mounted) {
        setState(() {
          _audioController.showAudioProgress = false;
        });
      }
    }
  }

  // 1. State'e bir fonksiyon ekle
  void _refreshBookmarkButton() {
    if (mounted) setState(() {});
  }

  Future<void> _loadShowMealPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMeal = prefs.getBool('quran_show_meal') ?? false;
    });
  }

  Future<void> _setShowMealPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quran_show_meal', value);
  }
}
