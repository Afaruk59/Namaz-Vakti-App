import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/bookmark_painter.dart';

/// A button widget for toggling bookmarks
class BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final Color appBarColor;
  final Function() onToggle;
  final bool visible;

  const BookmarkButton({
    Key? key,
    required this.isBookmarked,
    required this.appBarColor,
    required this.onToggle,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return SizedBox();
    }

    return Positioned(
      top: 0,
      right: 20,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 30,
          height: isBookmarked ? 50 : 40, // Make longer when bookmarked
          child: CustomPaint(
            painter: BookmarkPainter(
              color: appBarColor.withOpacity(0.3),
              isBookmarked: isBookmarked,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
