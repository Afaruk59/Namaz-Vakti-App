import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_bookmark_controller.dart';
import 'package:namaz_vakti_app/books/features/book/controllers/book_theme_controller.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/page_content_view.dart';

/// A wrapper widget for PageContentView that adds additional functionality
class BookContentWrapper extends StatelessWidget {
  final BookPageModel bookPage;
  final BookThemeController themeController;
  final BookBookmarkController bookmarkController;
  final String bookCode;
  final int pageNumber;
  final bool isFullScreen;
  final Function(bool) onFullScreenChanged;
  final Function(String) onSearch;

  const BookContentWrapper({
    Key? key,
    required this.bookPage,
    required this.themeController,
    required this.bookmarkController,
    required this.bookCode,
    required this.pageNumber,
    required this.isFullScreen,
    required this.onFullScreenChanged,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageContentView(
      bookPage: bookPage,
      backgroundColor: themeController.backgroundColor,
      fontSize: themeController.fontSize,
      isFullScreen: isFullScreen,
      onFullScreenChanged: onFullScreenChanged,
      bookCode: bookCode,
      pageNumber: pageNumber,
      onBookmarkAdded: () {
        bookmarkController.checkHasBookmarks();
      },
      onBookmarkRemoved: () async {
        await bookmarkController.checkBookmarkStatus(pageNumber);
        await bookmarkController.checkHasBookmarks();
      },
      onSearch: onSearch,
    );
  }
}
