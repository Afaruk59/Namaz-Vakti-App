import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/bookmark_button.dart';

/// A widget that contains all the overlay controls for a book page
class BookControlsOverlay extends StatelessWidget {
  final bool isBookmarked;
  final Color appBarColor;
  final Function() onBookmarkToggle;
  final bool isFullScreen;
  final List<Widget> additionalControls;

  const BookControlsOverlay({
    Key? key,
    required this.isBookmarked,
    required this.appBarColor,
    required this.onBookmarkToggle,
    this.isFullScreen = false,
    this.additionalControls = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bookmark button
        BookmarkButton(
          isBookmarked: isBookmarked,
          appBarColor: appBarColor,
          onToggle: onBookmarkToggle,
          visible: !isFullScreen,
        ),

        // Add any additional controls
        ...additionalControls,
      ],
    );
  }
}
