import 'package:flutter/material.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_ui_components_manager.dart';

/// A widget that displays a single book page instead of PageView
class BookPageView extends StatelessWidget {
  final BookPageController pageController;
  final BookUIComponentsManager uiManager;
  final String bookCode;
  final Function(int) onPageChanged;
  final VoidCallback? onStateChanged;
  final Color backgroundColor;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  const BookPageView({
    super.key,
    required this.pageController,
    required this.uiManager,
    required this.bookCode,
    required this.onPageChanged,
    this.onStateChanged,
    required this.backgroundColor,
    this.onNextPage,
    this.onPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleGestureDetector(
      onHorizontalSwipe: (direction) {
        if (direction == SwipeDirection.right && !pageController.isFirstPage) {
          // Sağa kaydırma = önceki sayfa (ilk sayfada değilse)
          onPreviousPage?.call();
        } else if (direction == SwipeDirection.left && !pageController.isLastPage) {
          // Sola kaydırma = sonraki sayfa (son sayfada değilse)
          onNextPage?.call();
        }
      },
      swipeConfig: const SimpleSwipeConfig(
        verticalThreshold: 40.0,
        horizontalThreshold: 40.0,
        swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
      ),
      child: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: uiManager.buildPageContent(pageController.currentPage,
              onStateChanged: onStateChanged),
        ),
      ),
    );
  }
}
