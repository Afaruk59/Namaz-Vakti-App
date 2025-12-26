import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/screens/bookmarks_screen.dart';
import 'package:namaz_vakti_app/books/screens/book_screen.dart';

class BookBookmarkIndicator extends StatefulWidget {
  final String bookCode;
  final Color color;
  final Key? refreshKey;

  const BookBookmarkIndicator({
    super.key,
    required this.bookCode,
    this.color = Colors.red,
    this.refreshKey,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BookBookmarkIndicatorState createState() => _BookBookmarkIndicatorState();
}

class _BookBookmarkIndicatorState extends State<BookBookmarkIndicator> {
  final BookmarkService _bookmarkService = BookmarkService();
  int _bookmarkCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkCount();
  }

  @override
  void didUpdateWidget(BookBookmarkIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookCode != widget.bookCode || oldWidget.key != widget.key) {
      _loadBookmarkCount();
    }
  }

  Future<void> _loadBookmarkCount() async {
    try {
      // Yükleme durumunu güncelle
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Yer işareti sayısını al
      final count = await _bookmarkService.getBookmarkCount(widget.bookCode);
      debugPrint('BookBookmarkIndicator: Loading bookmark count for ${widget.bookCode}: $count (previous: $_bookmarkCount)');

      // Eğer widget hala monte edilmişse ve sayı değiştiyse güncelle
      if (mounted && count != _bookmarkCount) {
        debugPrint('BookBookmarkIndicator: Updating bookmark count for ${widget.bookCode}: $_bookmarkCount -> $count');
        setState(() {
          _bookmarkCount = count;
          _isLoading = false;
        });
      } else if (mounted) {
        // Sadece yükleme durumunu güncelle
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Yer işareti sayısı yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _bookmarkCount = 0; // Hata durumunda yer işareti sayısını sıfırla
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer yer işareti yoksa veya yükleme devam ediyorsa gösterme
    if (_isLoading || _bookmarkCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookmarksScreen(
              initialBookCode: widget.bookCode,
            ),
          ),
        ).then((_) {
          // BookmarkService cache'ini temizle
          BookmarkService().clearCache();
          
          // Geri döndüğünde yer işareti sayısını güncelle
          _loadBookmarkCount();

          // Ana ekrandaki tüm bookmark göstergelerini yenilemek için
          // HomeScreen'deki refreshBookmarkIndicators metodunu çağır
          // ignore: use_build_context_synchronously
          final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
          if (homeScreenState != null) {
            homeScreenState.refreshBookmarkIndicators();
          }
        });
      },
      child: Container(
        width: 24,
        height: 32,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(7),
          ),
          boxShadow: const [
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
            const Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(height: 1),
            Text(
              '$_bookmarkCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
