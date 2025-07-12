import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';

class BookmarkWidget extends StatefulWidget {
  final String bookCode;
  final int pageNumber;
  final Color bookmarkColor;
  final Function(bool) onBookmarkToggled;

  const BookmarkWidget({
    Key? key,
    required this.bookCode,
    required this.pageNumber,
    this.bookmarkColor = Colors.red,
    required this.onBookmarkToggled,
  }) : super(key: key);

  @override
  _BookmarkWidgetState createState() => _BookmarkWidgetState();
}

class _BookmarkWidgetState extends State<BookmarkWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isBookmarked = false;
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    final isBookmarked =
        await _bookmarkService.isPageBookmarked(widget.bookCode, widget.pageNumber);
    setState(() {
      _isBookmarked = isBookmarked;
      if (_isBookmarked) {
        _controller.value = 1.0; // Eğer sayfa işaretlenmişse, ayracı uzatılmış göster
      }
    });
  }

  @override
  void didUpdateWidget(BookmarkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadBookmarkStatus();
    }
  }

  void _toggleBookmark() async {
    final newStatus = !_isBookmarked;

    if (newStatus) {
      await _bookmarkService.addBookmark(widget.bookCode, widget.pageNumber);
      _controller.forward();
    } else {
      await _bookmarkService.removeBookmark(widget.bookCode, widget.pageNumber);
      _controller.reverse();
    }

    setState(() {
      _isBookmarked = newStatus;
    });

    widget.onBookmarkToggled(_isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBookmark,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 30,
            height: 20 + _animation.value * 80, // Animasyon ile uzunluğu değişir
            decoration: BoxDecoration(
              color: widget.bookmarkColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_animation.value > 0.5) // Sadece ayraç uzadığında ikonu göster
                  Opacity(
                    opacity: (_animation.value - 0.5) * 2, // Yavaşça görünür ol
                    child: Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
