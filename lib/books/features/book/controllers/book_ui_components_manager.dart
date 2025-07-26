import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_app_bar.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_theme_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_bookmark_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_audio_controller.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_drawer_builder.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_content_wrapper.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_bottom_controls.dart';

/// Manager for handling all UI components in the book page screen
class BookUIComponentsManager {
  final BuildContext context;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color appBarColor;
  final String bookCode;
  final Future<List<IndexItem>> indexFuture;
  String bookTitleText;
  final BookPageController pageController;
  final BookThemeController themeController;
  final BookBookmarkController bookmarkController;
  final BookAudioController audioController;
  final AudioPlayerService audioPlayerService;
  final Function(int) onPageSelected;
  final Function(String) onSearch;

  // State values maintained by the UI manager
  bool isFullScreen = false;
  bool showAudioProgress = false;
  String? searchText;
  bool isBookmarked = false;
  bool hasBookmarks = false;
  BookPageModel? currentBookPage;

  BookUIComponentsManager({
    required this.context,
    required this.scaffoldKey,
    required this.appBarColor,
    required this.bookCode,
    required this.indexFuture,
    required this.bookTitleText,
    required this.pageController,
    required this.themeController,
    required this.bookmarkController,
    required this.audioController,
    required this.audioPlayerService,
    required this.onPageSelected,
    required this.onSearch,
  });

  // Update current book page
  void updateCurrentBookPage(BookPageModel bookPage) {
    currentBookPage = bookPage;
  }

  // Toggle full screen mode
  void toggleFullScreen(bool value, [VoidCallback? onStateChanged]) {
    isFullScreen = value;
    if (onStateChanged != null) {
      onStateChanged();
    }
  }

  // Toggle audio progress visibility
  void setShowAudioProgress(bool value) {
    showAudioProgress = value;
  }

  // Set bookmark status
  void setBookmarkStatus(bool value) {
    isBookmarked = value;
  }

  // Set has bookmarks flag
  void setHasBookmarks(bool value) {
    hasBookmarks = value;
  }

  // Set search text
  void setSearchText(String? value) {
    searchText = value;
  }

  // Build the app bar
  PreferredSizeWidget? buildAppBar({VoidCallback? onBackgroundColorChanged}) {
    if (isFullScreen) {
      return null;
    }

    return BookAppBar(
      title: bookTitleText,
      appBarColor: appBarColor,
      fontSize: themeController.fontSize,
      onFontSizeChanged: (newSize) {
        themeController.saveFontSize(newSize);
      },
      backgroundColor: themeController.backgroundColor,
      onBackgroundColorChanged: (newColor) {
        themeController.setBackgroundColor(newColor);
        if (onBackgroundColorChanged != null) {
          onBackgroundColorChanged();
        }
      },
      isAutoBackground: themeController.isAutoBackground,
      onAutoBackgroundChanged: (value) {
        themeController.setAutoBackground(value);
      },
      bookCode: bookCode,
      currentPage: pageController.currentPage,
      onBookmarkToggled: (isBookmarked) {
        this.isBookmarked = isBookmarked;
      },
    );
  }

  // Build the page content
  Widget buildPageContent(int index, {VoidCallback? onStateChanged}) {
    if (currentBookPage != null && index == pageController.currentPage) {
      return BookContentWrapper(
        bookPage: currentBookPage!,
        themeController: themeController,
        bookmarkController: bookmarkController,
        bookCode: bookCode,
        pageNumber: pageController.currentPage,
        isFullScreen: isFullScreen,
        onFullScreenChanged: (value) => toggleFullScreen(value, onStateChanged),
        onSearch: onSearch,
      );
    }

    return FutureBuilder<BookPageModel>(
      future: pageController.getPageFromCacheOrLoad(index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return BookContentWrapper(
            bookPage: snapshot.data!,
            themeController: themeController,
            bookmarkController: bookmarkController,
            bookCode: bookCode,
            pageNumber: index,
            isFullScreen: isFullScreen,
            onFullScreenChanged: (value) => toggleFullScreen(value, onStateChanged),
            onSearch: onSearch,
          );
        } else {
          return const Center(child: Text('No data available.'));
        }
      },
    );
  }

  // Build the bottom bar
  Widget buildBottomBar({
    required Function() onPlayAudio,
    Function()? onPlayPauseProgress,
    required Function(double) onSeek,
    required Function() onSpeedChange,
    required Function() refreshBookmarkStatus,
    required Function(int) onPageNumberEntered,
    Function()? onNextPage,
    Function()? onPreviousPage,
  }) {
    return BookBottomControls(
      pageController: pageController,
      audioPlayerService: audioPlayerService,
      appBarColor: appBarColor,
      bookCode: bookCode,
      showAudioProgress: showAudioProgress,
      hasAudio: currentBookPage?.mp3.isNotEmpty ?? false,
      hasBookmarks: hasBookmarks,
      isFullScreen: isFullScreen,
      onPlayAudio: onPlayAudio,
      onPlayPauseProgress: onPlayPauseProgress,
      onSeek: onSeek,
      onSpeedChange: onSpeedChange,
      refreshBookmarkStatus: refreshBookmarkStatus,
      onPageNumberEntered: onPageNumberEntered,
      onNextPage: onNextPage,
      onPreviousPage: onPreviousPage,
      onMenuPressed: () {
        scaffoldKey.currentState?.openDrawer();
      },
    );
  }

  // Build the drawer
  Widget? buildDrawer({
    required Future<List<Map<String, dynamic>>> Function(String, String)? searchFunction,
    required BookPageModel? currentBookPage,
  }) {
    return BookDrawerBuilder.buildDrawer(
      context: context,
      scaffoldKey: scaffoldKey,
      isFullScreen: isFullScreen,
      showAudioProgress: showAudioProgress,
      indexFuture: indexFuture,
      bookTitleText: bookTitleText,
      bookCode: bookCode,
      appBarColor: appBarColor,
      onPageSelected: onPageSelected,
      searchFunction: searchFunction,
      searchText: searchText,
      audioPlayerService: audioPlayerService,
      currentBookPage: currentBookPage,
    );
  }
}
