import 'package:flutter/material.dart';
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

  const BookPageView({
    super.key,
    required this.pageController,
    required this.uiManager,
    required this.bookCode,
    required this.onPageChanged,
    this.onStateChanged,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child:
            uiManager.buildPageContent(pageController.currentPage, onStateChanged: onStateChanged),
      ),
    );
  }
}
