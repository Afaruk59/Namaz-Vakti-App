import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/screens/bookmarks_screen.dart';
import 'package:namaz_vakti_app/books/screens/book_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookBookmarkIndicator extends StatefulWidget {
  final String bookCode;
  final Color color;
  final Key? refreshKey;

  const BookBookmarkIndicator({
    Key? key,
    required this.bookCode,
    this.color = Colors.red,
    this.refreshKey,
  }) : super(key: key);

  @override
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

      // Eğer widget hala monte edilmişse ve sayı değiştiyse güncelle
      if (mounted && count != _bookmarkCount) {
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
      print('Yer işareti sayısı yüklenirken hata: $e');
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
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        bool showMeal = true;
        if (widget.bookCode == 'quran') {
          final prefs = await SharedPreferences.getInstance();
          showMeal = prefs.getBool('quran_show_meal') ?? false;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookmarksScreen(
              initialBookCode: widget.bookCode,
              showMeal: showMeal,
            ),
          ),
        ).then((_) {
          // Geri döndüğünde yer işareti sayısını güncelle
          _loadBookmarkCount();

          // Ana ekrandaki tüm bookmark göstergelerini yenilemek için
          // HomeScreen'deki refreshBookmarkIndicators metodunu çağır
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
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(7),
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
            Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 14,
            ),
            SizedBox(height: 1),
            Text(
              '$_bookmarkCount',
              style: TextStyle(
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
