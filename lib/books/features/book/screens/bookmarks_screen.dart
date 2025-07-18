// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:namaz_vakti_app/books/features/book/screens/book_page_screen.dart';
import 'package:namaz_vakti_app/books/features/book/ui/color_extractor.dart';
import 'package:namaz_vakti_app/books/shared/models/book_model.dart';
import 'package:namaz_vakti_app/books/screens/book_screen.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class BookmarksScreen extends StatefulWidget {
  final String? initialBookCode;
  final bool showMeal;

  const BookmarksScreen({super.key, this.initialBookCode, this.showMeal = true});

  @override
  // ignore: library_private_types_in_public_api
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  final BookmarkService _bookmarkService = BookmarkService();
  final BookTitleService _bookTitleService = BookTitleService();

  TabController? _tabController;
  Map<String, List<Bookmark>> _allBookmarks = {};
  List<String> _bookCodes = [];
  Map<String, String> _bookTitles = {};
  Map<String, Color> _bookColors = {}; // Kitap renklerini saklamak için
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // TabController'ı başlangıçta boş bir liste ile başlat
    _tabController = TabController(
      length: 1,
      vsync: this,
    );
    _loadBookmarks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TabController hazır olduğunda listener ekle
    if (!_isLoading && _bookCodes.isNotEmpty) {
      _tabController!.addListener(_handleTabChange);
    }
  }

  // Tab değişikliğini dinle
  void _handleTabChange() {
    // Tab animasyonu tamamlandığında veya kullanıcı manuel olarak tab değiştirdiğinde
    if (_tabController!.indexIsChanging == false && mounted) {
      setState(() {
        // AppBar rengini güncellemek için setState çağır
        debugPrint('Tab değişti: ${_tabController!.index}');
      });
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mevcut seçili kitap kodunu kaydet (eğer varsa)
      String? previousSelectedBookCode;
      if (_tabController != null &&
          _bookCodes.isNotEmpty &&
          _tabController!.index >= 0 &&
          _tabController!.index < _bookCodes.length) {
        previousSelectedBookCode = _bookCodes[_tabController!.index];
      }

      // Tüm yer işaretlerini yükle
      final bookmarks = await _bookmarkService.getAllBookmarks();

      // Boş yer işaretlerine sahip kitapları filtrele
      bookmarks.removeWhere((key, value) => value.isEmpty);

      // Kitap kodlarını al
      final bookCodes = bookmarks.keys.toList();

      // Başlangıçta varsayılan renkleri kullan
      Map<String, Color> bookColors = {};
      Map<String, String> bookTitles = {};

      // Mevcut TabController'ı temizle
      if (_tabController != null) {
        _tabController!.removeListener(_handleTabChange);
        _tabController!.dispose();
      }

      // Yeni TabController oluştur
      _tabController = TabController(
        length: bookCodes.isEmpty ? 1 : bookCodes.length,
        vsync: this,
      );

      // Durum değişkenlerini güncelle
      setState(() {
        _allBookmarks = bookmarks;
        _bookCodes = bookCodes;
        _bookColors = bookColors;
        _bookTitles = bookTitles; // Kitap isimlerini tamamen sıfırla
        _isLoading = false;
      });

      // Tab değişikliklerini dinle
      if (bookCodes.isNotEmpty) {
        _tabController!.addListener(_handleTabChange);
      }

      // Tab seçimini belirle
      if (bookCodes.isNotEmpty) {
        int initialTabIndex = 0;

        // Öncelik sırası:
        // 1. Önceki seçili kitap (hala varsa)
        // 2. initialBookCode (constructor'da belirtilen)
        // 3. İlk kitap (varsayılan)

        if (previousSelectedBookCode != null && bookCodes.contains(previousSelectedBookCode)) {
          // Önceki seçili kitap hala varsa, onu seç
          initialTabIndex = bookCodes.indexOf(previousSelectedBookCode);
        } else if (widget.initialBookCode != null && bookCodes.contains(widget.initialBookCode)) {
          // Önceki seçili kitap yoksa ama initialBookCode varsa, onu seç
          initialTabIndex = bookCodes.indexOf(widget.initialBookCode!);
        }

        // Tab'ı seçili kitaba ayarla
        _tabController!.animateTo(initialTabIndex);
      }

      // Sadece mevcut kitapların başlıklarını ve renklerini yükle
      if (bookCodes.isNotEmpty) {
        List<Future<void>> futures = [];

        for (var bookCode in bookCodes) {
          // Başlık yükleme
          futures.add(_bookTitleService.getTitle(bookCode).then((title) {
            bookTitles[bookCode] = title;
          }));

          // Her kitap için renk yükleme
          futures.add(_getBookColor(bookCode).then((color) {
            bookColors[bookCode] = color;
          }));
        }

        // Tüm yükleme işlemlerinin tamamlanmasını bekle
        await Future.wait(futures);

        // Durum değişkenlerini güncelle
        if (mounted) {
          setState(() {
            _bookTitles = bookTitles;
            _bookColors = bookColors;
          });
        }
      }
    } catch (e) {
      debugPrint('Yer işaretleri yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Kitap rengini al
  Future<Color> _getBookColor(String bookCode) async {
    try {
      // Kitap modelini bul
      final books = Book.samples();
      final book = books.firstWhere(
        (b) => b.code == bookCode,
        orElse: () => Book(
          code: bookCode,
        ),
      );

      // Yeni ColorExtractor.getBookColor metodunu kullan
      ImageProvider? coverImage;
      if (book.coverImageUrl.isNotEmpty) {
        coverImage = AssetImage(book.coverImageUrl);
      }

      return await ColorExtractor.getBookColor(
        bookCode,
        coverImage,
        defaultColor: Provider.of<ChangeSettings>(context).color,
      );
    } catch (e) {
      debugPrint('Kitap rengi alınırken hata: $e');
      return Provider.of<ChangeSettings>(context).color;
    }
  }

  // Silme onay dialogu göster
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yer İşaretini Sil'),
          content: const Text('Bu yer işaretini silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      if (_tabController != null) {
        _tabController!.removeListener(_handleTabChange);
        _tabController!.dispose();
      }
    } catch (e) {
      debugPrint('TabController dispose hatası: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seçili kitabın rengini al
    Color selectedTabColor = Colors.transparent; // Varsayılan renk olarak koyu mavi kullan

    // TabController ve kitap kodları hazır olduğunda seçili kitabın rengini al
    if (!_isLoading &&
        _bookCodes.isNotEmpty &&
        _tabController != null &&
        _tabController!.length > 0) {
      try {
        int currentIndex = _tabController!.index;
        if (currentIndex >= 0 && currentIndex < _bookCodes.length) {
          final selectedBookCode = _bookCodes[currentIndex];
          selectedTabColor = _bookColors[selectedBookCode] ?? Colors.transparent;
        }
      } catch (e) {
        debugPrint('Tab rengi alınırken hata: $e');
      }
    }
    return WillPopScope(
      onWillPop: () async {
        final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
        if (homeScreenState != null) {
          homeScreenState.refreshBookmarkIndicators();
        }
        return true;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Provider.of<ChangeSettings>(context).color,
                BlendMode.color,
              ),
              child: Image.asset(
                Provider.of<ChangeSettings>(context).isDark
                    ? 'assets/img/wallpaperdark.png'
                    : 'assets/img/wallpaper.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Scaffold(
            appBar: AppBar(
              backgroundColor: selectedTabColor,
              title: const Text('Yer İşaretleri'),
              bottom: _isLoading || _bookCodes.isEmpty || _tabController == null
                  ? null
                  : TabBar(
                      controller: _tabController!,
                      isScrollable: true, // Seçili olmayan tab yazılarını yarı saydam beyaz yap
                      tabs: _bookCodes.map((bookCode) {
                        return Tab(
                          text: _bookTitles[bookCode] ?? bookCode,
                        );
                      }).toList(),
                    ),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookCodes.isEmpty || _tabController == null
                    ? _buildEmptyBookmarksView()
                    : TabBarView(
                        controller: _tabController!,
                        children: _bookCodes.map((bookCode) {
                          final bookmarks = _allBookmarks[bookCode] ?? [];
                          return _buildBookmarksList(bookCode, bookmarks);
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  // Boş yer işaretleri görünümü
  Widget _buildEmptyBookmarksView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz yer işareti eklenmemiş',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () {
              // Ana ekrana dönmeden önce tüm bookmark göstergelerini yenile
              final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
              if (homeScreenState != null) {
                homeScreenState.refreshBookmarkIndicators();
              }
              Navigator.pop(context);
            },
            child: const Text('Kitaplara Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(String bookCode, List<Bookmark> bookmarks) {
    // Eğer kitabın yer işaretleri boşsa, bu durumu göster ve yeniden yükleme yap
    if (bookmarks.isEmpty) {
      // Kitabı listelerden kaldır ve yeniden yükle
      Future.microtask(() async {
        // Tüm yer işaretlerini yeniden yükle
        await _loadBookmarks();

        // Eğer hiç kitap kalmadıysa, boş ekranı göster
        if (_bookCodes.isEmpty && mounted) {
          // Hiç yer işareti kalmadı, boş ekranı göster
          setState(() {
            // TabController'ı güncelle
            if (_tabController != null) {
              _tabController!.removeListener(_handleTabChange);
              _tabController!.dispose();
              _tabController = TabController(length: 1, vsync: this);
            }
          });
        } else if (mounted && _bookCodes.isNotEmpty) {
          // Başka kitaplarda yer işareti var, ilk kitabı seç
          setState(() {
            if (_tabController != null && _tabController!.length > 0) {
              _tabController!.animateTo(0); // İlk kitaba git
            }
          });
        }
      });

      // Geçici olarak yükleniyor göster
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Kitabın rengini al (varsayılan olarak tema rengini kullan)
    final bookColor = _bookColors[bookCode] ?? Theme.of(context).primaryColor;

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    bookmark.pageNumber.toString(),
                  ),
                ),
                title: Text('Sayfa ${bookmark.pageNumber}'),
                subtitle: Text(_bookTitles[bookCode] ?? bookCode),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final shouldDelete = await _showDeleteConfirmationDialog(context);
                    if (shouldDelete == true) {
                      await _bookmarkService.removeBookmark(
                        bookCode,
                        bookmark.pageNumber,
                        selectedText: bookmark.selectedText,
                        startIndex: bookmark.startIndex,
                        endIndex: bookmark.endIndex,
                      );
                      _loadBookmarks();
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookPageScreen(
                        bookCode: bookCode,
                        initialPage: bookmark.pageNumber,
                        appBarColor: bookColor, // Kitabın kendi rengini kullan
                        forceRefresh: true, // Vurgulamaları yeniden yükle
                      ),
                    ),
                  ).then((_) {
                    _loadBookmarks();
                  });
                },
              ),
              if (bookmark.selectedText != null && bookmark.selectedText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        children: [
                          const Text(
                            'Seçilen Metin:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Vurgulama rengi göstergesi
                          if (bookmark.highlightColor != null)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: bookmark.highlightColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookPageScreen(
                                bookCode: bookCode,
                                initialPage: bookmark.pageNumber,
                                appBarColor: bookColor,
                                forceRefresh: true,
                              ),
                            ),
                          ).then((_) {
                            _loadBookmarks();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bookmark.highlightColor?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bookmark.selectedText!,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              backgroundColor: bookmark.highlightColor?.withOpacity(0.2),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
