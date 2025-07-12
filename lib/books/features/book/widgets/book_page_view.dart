import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_page_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_ui_components_manager.dart';

/// A widget that handles page view for book pages
class BookPageView extends StatelessWidget {
  final BookPageController pageController;
  final BookUIComponentsManager uiManager;
  final String bookCode;
  final Function(int) onPageChanged;
  final VoidCallback? onStateChanged;

  const BookPageView({
    Key? key,
    required this.pageController,
    required this.uiManager,
    required this.bookCode,
    required this.onPageChanged,
    this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _EdgeAwareBookPageView(
      pageController: pageController.pageController,
      bookCode: bookCode,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return uiManager.buildPageContent(index, onStateChanged: onStateChanged);
      },
    );
  }
}

class _EdgeAwareBookPageView extends StatefulWidget {
  final PageController pageController;
  final String bookCode;
  final Function(int) onPageChanged;
  final IndexedWidgetBuilder itemBuilder;
  const _EdgeAwareBookPageView({
    required this.pageController,
    required this.bookCode,
    required this.onPageChanged,
    required this.itemBuilder,
  });
  @override
  State<_EdgeAwareBookPageView> createState() => _EdgeAwareBookPageViewState();
}

class _EdgeAwareBookPageViewState extends State<_EdgeAwareBookPageView> {
  bool _blockSwipe = false;
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        final details = notification.dragDetails;
        final screenWidth = MediaQuery.of(context).size.width;
        if (details != null &&
            (details.globalPosition.dx < 24 || details.globalPosition.dx > screenWidth - 24)) {
          setState(() {
            _blockSwipe = true;
          });
        } else {
          setState(() {
            _blockSwipe = false;
          });
        }
        return false;
      },
      child: PageView.builder(
        controller: widget.pageController,
        dragStartBehavior: DragStartBehavior.start,
        physics: _blockSwipe
            ? const NeverScrollableScrollPhysics()
            : (widget.bookCode == 'quran'
                ? const AlwaysScrollableScrollPhysics()
                : const PageScrollPhysics()),
        onPageChanged: widget.onPageChanged,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
