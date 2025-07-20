import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/audio_player_controls.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_bottom_bar.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';

/// A widget that combines audio controls and bottom navigation bar
class BookBottomControls extends StatelessWidget {
  final BookPageController pageController;
  final AudioPlayerService audioPlayerService;
  final Color appBarColor;
  final String bookCode;
  final bool showAudioProgress;
  final bool hasAudio;
  final bool hasBookmarks;
  final bool isFullScreen;

  final Function() onPlayAudio;
  final Function()? onPlayPauseProgress;
  final Function(double) onSeek;
  final Function() onSpeedChange;
  final Function() refreshBookmarkStatus;
  final Function(int) onPageNumberEntered;
  final Function() onMenuPressed;

  const BookBottomControls({
    super.key,
    required this.pageController,
    required this.audioPlayerService,
    required this.appBarColor,
    required this.bookCode,
    required this.showAudioProgress,
    required this.hasAudio,
    required this.hasBookmarks,
    required this.isFullScreen,
    required this.onPlayAudio,
    this.onPlayPauseProgress,
    required this.onSeek,
    required this.onSpeedChange,
    required this.refreshBookmarkStatus,
    required this.onPageNumberEntered,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAudioProgress)
              AudioPlayerControls(
                audioPlayerService: audioPlayerService,
                onSeek: onSeek,
                onSpeedChange: onSpeedChange,
                onPlayPauseProgress: onPlayPauseProgress ?? onPlayAudio,
                appBarColor: appBarColor, // parametreyi ilet
              ),
            if (!isFullScreen)
              BookBottomBar(
                appBarColor: appBarColor,
                currentPage: pageController.currentPage,
                isFirstPage: pageController.isFirstPage,
                isLastPage: pageController.isLastPage,
                onPreviousPage: () {
                  pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                onNextPage: () {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                onMenuPressed: onMenuPressed,
                onPlayAudio: onPlayAudio,
                hasAudio: hasAudio,
                isAudioPlaying: showAudioProgress,
                isPlaying: audioPlayerService.isPlaying,
                bookCode: bookCode,
                hasBookmarks: hasBookmarks,
                onBookmarksReturn: refreshBookmarkStatus,
                onPageNumberEntered: onPageNumberEntered,
              ),
          ],
        ));
  }
}
