// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_title_service.dart';
import 'package:namaz_vakti_app/books/features/book/screens/book_page_screen.dart';
import 'package:namaz_vakti_app/books/screens/book_screen.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/quran/screens/modular_quran_page_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/quran/services/surah_localization_service.dart';
import 'package:html_unescape/html_unescape.dart';

class BookmarksScreen extends StatefulWidget {
  final String? initialBookCode;

  const BookmarksScreen({super.key, this.initialBookCode});

  @override
  // ignore: library_private_types_in_public_api
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

/// HTML kodlarını temizleyen yardımcı sınıf
class _BookmarkTextCleaner {
  static final HtmlUnescape _htmlUnescape = HtmlUnescape();
  
  /// HTML entity'leri ve taglarını temizler
  static String cleanText(String text) {
    if (text.isEmpty) return text;
    
    // HTML entity'leri decode et
    String cleanedText = _htmlUnescape.convert(text);

    // HTML taglarını ve footnote referanslarını temizle
    cleanedText = cleanedText
        .replaceAll(RegExp(r'<sup[^>]*foot_note=\d+[^>]*>.*?</sup>'), '') // Superscript footnote taglarını kaldır
        .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>'), '') // Diğer superscript taglarını kaldır
        .replaceAll(RegExp(r'<[^>]*>'), '') // Kalan tüm HTML taglarını kaldır
        .replaceAll(RegExp(r'foot_note=\d+'), '') // Kalan footnote referanslarını kaldır
        .replaceAll(RegExp(r'[<>]'), '') // Kalan < > karakterlerini kaldır
        .replaceAll(RegExp(r'\s+'), ' ') // Birden fazla boşluğu tek boşluğa çevir
        .replaceAll(RegExp(r'\s*,\s*'), ', ') // Virgül etrafındaki boşlukları düzenle
        .replaceAll(RegExp(r'\s*\.\s*'), '. ') // Nokta etrafındaki boşlukları düzenle
        .replaceAll(RegExp(r"\s*'\s*"), "'") // Tek tırnak etrafındaki boşlukları düzenle
        .trim(); // Başta ve sonda boşlukları temizle

    return cleanedText;
  }
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  final BookmarkService _bookmarkService = BookmarkService();
  final BookTitleService _bookTitleService = BookTitleService();

  TabController? _tabController;
  Map<String, List<Bookmark>> _allBookmarks = {};
  List<String> _bookCodes = [];
  Map<String, String> _bookTitles = {};

  bool _isLoading = true;
  bool _showMeal = false; // SharedPreferences'dan alınacak

  @override
  void initState() {
    super.initState();
    // TabController'ı başlangıçta boş bir liste ile başlat
    _tabController = TabController(
      length: 1,
      vsync: this,
    );
    _loadShowMealPreference();
    _loadBookmarks();
  }

  // SharedPreferences'dan showMeal değerini yükle
  Future<void> _loadShowMealPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMeal = prefs.getBool('quran_show_meal') ?? false;
    });
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

      // Kitap başlıklarını al
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

      // Sadece mevcut kitapların başlıklarını yükle
      if (bookCodes.isNotEmpty) {
        List<Future<void>> futures = [];

        for (var bookCode in bookCodes) {
          // Başlık yükleme
          futures.add(_bookTitleService.getTitle(bookCode, context: context).then((title) {
            bookTitles[bookCode] = title;
          }));
        }

        // Tüm yükleme işlemlerinin tamamlanmasını bekle
        await Future.wait(futures);

        // Durum değişkenlerini güncelle
        if (mounted) {
          setState(() {
            _bookTitles = bookTitles;
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

  // Silme onay dialogu göster
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.deleteBookmark ?? 'Yer İşaretini Sil'),
          content: Text(AppLocalizations.of(context)?.deleteBookmarkConfirmation ?? 'Bu yer işaretini silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(AppLocalizations.of(context)?.delete ?? 'Sil'),
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          debugPrint('BookmarksScreen: PopScope triggered, clearing cache and refreshing badges');
          
          // BookmarkService cache'ini temizle
          _bookmarkService.clearCache();
          
          final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
          if (homeScreenState != null) {
            debugPrint('BookmarksScreen: Found BookScreenState, calling refreshBookmarkIndicators');
            homeScreenState.refreshBookmarkIndicators();
          } else {
            debugPrint('BookmarksScreen: BookScreenState not found in widget tree');
          }
        }
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
              title: Text(AppLocalizations.of(context)?.bookmarksTitle ?? 'Yer İşaretleri'),
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
          Text(
            AppLocalizations.of(context)?.noBookmarksYet ?? 'Henüz yer işareti eklenmemiş',
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () {
              // BookmarkService cache'ini temizle
              _bookmarkService.clearCache();
              
              // Ana ekrana dönmeden önce tüm bookmark göstergelerini yenile
              final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
              if (homeScreenState != null) {
                homeScreenState.refreshBookmarkIndicators();
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)?.returnToBooks ?? 'Kitaplara Dön'),
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

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        final isQuran = bookCode == 'quran';
        String? sureName;
        String? ayetNumber;
        if (isQuran) {
          sureName = bookmark.surahName != null 
              ? SurahLocalizationService.getLocalizedSurahName(bookmark.surahName!, context)
              : null;
          ayetNumber = bookmark.ayahNumber;
        }
        
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: isQuran
                      ? const Icon(Icons.menu_book, color: Colors.white)
                      : Text(
                          bookmark.pageNumber.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                title: isQuran
                    ? Text(AppLocalizations.of(context)?.quranHolyQuran ?? 'Kuran-ı Kerim')
                    : Text(AppLocalizations.of(context)?.pageNumber(bookmark.pageNumber) ?? 'Sayfa ${bookmark.pageNumber}'),
                subtitle: isQuran
                    ? Text(
                        '${AppLocalizations.of(context)?.pageNumber(bookmark.pageNumber) ?? 'Sayfa ${bookmark.pageNumber}'}${sureName != null ? ' | $sureName' : ''}${ayetNumber != null ? ' | $ayetNumber. ${AppLocalizations.of(context)?.verse ?? 'Ayet'}' : ''}',
                        style: const TextStyle(fontSize: 13),
                      )
                    : Text(_bookTitles[bookCode] ?? bookCode),
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
                      
                      // BookmarkService cache'ini temizle
                      _bookmarkService.clearCache();
                      
                      // Bookmark'ları yeniden yükle
                      _loadBookmarks();
                      
                      // Ana ekrandaki badge'leri güncelle
                      final homeScreenState = context.findAncestorStateOfType<BookScreenState>();
                      if (homeScreenState != null) {
                        homeScreenState.refreshBookmarkIndicators();
                      }
                    }
                  },
                ),
                onTap: () {
                  if (bookCode == 'quran') {
                    // Quran için ModularQuranPageScreen kullan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModularQuranPageScreen(
                          initialPage: bookmark.pageNumber,
                        ),
                      ),
                    ).then((_) {
                      _loadBookmarks();
                    });
                  } else {
                    // Diğer kitaplar için BookPageScreen kullan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookPageScreen(
                          bookCode: bookCode,
                          initialPage: bookmark.pageNumber,
                          forceRefresh: true, // Vurgulamaları yeniden yükle
                        ),
                      ),
                    ).then((_) {
                      _loadBookmarks();
                    });
                  }
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
                          Text(
                            AppLocalizations.of(context)?.selectedText ?? 'Seçilen Metin:',
                            style: const TextStyle(
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
                          if (bookCode == 'quran') {
                            // Quran için ModularQuranPageScreen kullan
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModularQuranPageScreen(
                                  initialPage: bookmark.pageNumber,
                                ),
                              ),
                            ).then((_) {
                              _loadBookmarks();
                            });
                          } else {
                            // Diğer kitaplar için BookPageScreen kullan
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookPageScreen(
                                  bookCode: bookCode,
                                  initialPage: bookmark.pageNumber,
                                  forceRefresh: true,
                                ),
                              ),
                            ).then((_) {
                              _loadBookmarks();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bookmark.highlightColor?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isQuran &&
                                  bookmark.selectedText != null &&
                                  bookmark.selectedText!.contains('[Terceme]:')
                              ? _QuranBookmarkExpandable(
                                  arabicText: _BookmarkTextCleaner.cleanText(
                                    bookmark.selectedText!
                                        .split('[Terceme]:')[0]
                                        .trim()
                                  ),
                                  mealText: bookmark.selectedText!
                                              .split('[Terceme]:')
                                              .length >
                                          1
                                      ? _BookmarkTextCleaner.cleanText(
                                          bookmark.selectedText!
                                              .split('[Terceme]:')[1]
                                              .trim()
                                        )
                                      : null,
                                  showMeal: _showMeal,
                                  highlightColor: bookmark.highlightColor,
                                )
                              : Text(
                                  _BookmarkTextCleaner.cleanText(bookmark.selectedText!),
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

class _QuranBookmarkExpandable extends StatefulWidget {
  final String arabicText;
  final String? mealText;
  final bool showMeal;
  final Color? highlightColor;
  
  const _QuranBookmarkExpandable({
    required this.arabicText,
    this.mealText,
    required this.showMeal,
    this.highlightColor,
  });

  @override
  State<_QuranBookmarkExpandable> createState() => _QuranBookmarkExpandableState();
}

class _QuranBookmarkExpandableState extends State<_QuranBookmarkExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMeal = widget.mealText != null && widget.mealText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _BookmarkTextCleaner.cleanText(widget.arabicText),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  backgroundColor: widget.highlightColor?.withOpacity(0.2),
                ),
              ),
            ),
            if (widget.showMeal && hasMeal)
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
          ],
        ),
        if (_expanded && widget.showMeal && hasMeal)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _BookmarkTextCleaner.cleanText(widget.mealText!),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                backgroundColor: widget.highlightColor?.withOpacity(0.1),
              ),
            ),
          ),
      ],
    );
  }
}
