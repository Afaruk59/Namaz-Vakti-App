import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index_item_model.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/quran/services/surah_localization_service.dart';

class IndexDrawer extends StatefulWidget {
  final Future<List<IndexItem>> indexFuture;
  final String bookTitle;
  final Function(int) onPageSelected;
  final String bookCode;
  final Color? appBarColor;
  final Future<List<Map<String, dynamic>>> Function(String, String)?
      searchFunction;
  final List<Map<String, dynamic>>? juzIndex;
  final String? initialSearchText;

  // Kuran için sure listesi - static olarak sınıf seviyesinde tanımlandı
  static final List<Map<String, dynamic>> quranIndex = [
    {"title": "1. Fatiha Suresi", "page": 0},
    {"title": "2. Bakara Suresi", "page": 1},
    {"title": "3. Al-i İmran Suresi", "page": 49},
    {"title": "4. Nisa Suresi", "page": 76},
    {"title": "5. Maide Suresi", "page": 105},
    {"title": "6. Enam Suresi", "page": 127},
    {"title": "7. Araf Suresi", "page": 150},
    {"title": "8. Enfal Suresi", "page": 176},
    {"title": "9. Tevbe Suresi", "page": 186},
    {"title": "10. Yunus Suresi", "page": 207},
    {"title": "11. Hud Suresi", "page": 220},
    {"title": "12. Yusuf Suresi", "page": 234},
    {"title": "13. Rad Suresi", "page": 248},
    {"title": "14. İbrahim Suresi", "page": 254},
    {"title": "15. Hicr Suresi", "page": 261},
    {"title": "16. Nahl Suresi", "page": 266},
    {"title": "17. İsra Suresi", "page": 281},
    {"title": "18. Kehf Suresi", "page": 292},
    {"title": "19. Meryem Suresi", "page": 304},
    {"title": "20. Taha Suresi", "page": 311},
    {"title": "21. Enbiya Suresi", "page": 321},
    {"title": "22. Hac Suresi", "page": 331},
    {"title": "23. Müminun Suresi", "page": 341},
    {"title": "24. Nur Suresi", "page": 349},
    {"title": "25. Furkan Suresi", "page": 358},
    {"title": "26. Şuara Suresi", "page": 366},
    {"title": "27. Neml Suresi", "page": 376},
    {"title": "28. Kasas Suresi", "page": 384},
    {"title": "29. Ankebut Suresi", "page": 395},
    {"title": "30. Rum Suresi", "page": 403},
    {"title": "31. Lokman Suresi", "page": 410},
    {"title": "32. Secde Suresi", "page": 414},
    {"title": "33. Ahzab Suresi", "page": 417},
    {"title": "34. Sebe Suresi", "page": 427},
    {"title": "35. Fatır Suresi", "page": 433},
    {"title": "36. Yasin Suresi", "page": 439},
    {"title": "37. Saffat Suresi", "page": 445},
    {"title": "38. Sad Suresi", "page": 452},
    {"title": "39. Zümer Suresi", "page": 457},
    {"title": "40. Mümin Suresi", "page": 466},
    {"title": "41. Fussilet Suresi", "page": 476},
    {"title": "42. Şura Suresi", "page": 482},
    {"title": "43. Zuhruf Suresi", "page": 488},
    {"title": "44. Duhan Suresi", "page": 495},
    {"title": "45. Casiye Suresi", "page": 498},
    {"title": "46. Ahkaf Suresi", "page": 501},
    {"title": "47. Muhammed Suresi", "page": 506},
    {"title": "48. Fetih Suresi", "page": 510},
    {"title": "49. Hucurat Suresi", "page": 514},
    {"title": "50. Kaf Suresi", "page": 517},
    {"title": "51. Zariyat Suresi", "page": 519},
    {"title": "52. Tur Suresi", "page": 522},
    {"title": "53. Necm Suresi", "page": 525},
    {"title": "54. Kamer Suresi", "page": 527},
    {"title": "55. Rahman Suresi", "page": 530},
    {"title": "56. Vakıa Suresi", "page": 533},
    {"title": "57. Hadid Suresi", "page": 536},
    {"title": "58. Mücadele Suresi", "page": 541},
    {"title": "59. Haşr Suresi", "page": 544},
    {"title": "60. Mümtehine Suresi", "page": 548},
    {"title": "61. Saf Suresi", "page": 550},
    {"title": "62. Cuma Suresi", "page": 552},
    {"title": "63. Münafikun Suresi", "page": 553},
    {"title": "64. Tegabün Suresi", "page": 555},
    {"title": "65. Talak Suresi", "page": 557},
    {"title": "66. Tahrim Suresi", "page": 559},
    {"title": "67. Mülk Suresi", "page": 561},
    {"title": "68. Kalem Suresi", "page": 563},
    {"title": "69. Hakka Suresi", "page": 565},
    {"title": "70. Mearic Suresi", "page": 567},
    {"title": "71. Nuh Suresi", "page": 569},
    {"title": "72. Cin Suresi", "page": 571},
    {"title": "73. Müzzemmil Suresi", "page": 573},
    {"title": "74. Müddessir Suresi", "page": 574},
    {"title": "75. Kıyame Suresi", "page": 576},
    {"title": "76. İnsan Suresi", "page": 577},
    {"title": "77. Mürselat Suresi", "page": 579},
    {"title": "78. Nebe Suresi", "page": 581},
    {"title": "79. Naziat Suresi", "page": 582},
    {"title": "80. Abese Suresi", "page": 584},
    {"title": "81. Tekvir Suresi", "page": 585},
    {"title": "82. İnfitar Suresi", "page": 586},
    {"title": "83. Mutaffifin Suresi", "page": 586},
    {"title": "84. İnşikak Suresi", "page": 588},
    {"title": "85. Büruc Suresi", "page": 589},
    {"title": "86. Tarık Suresi", "page": 590},
    {"title": "87. Ala Suresi", "page": 591},
    {"title": "88. Gaşiye Suresi", "page": 591},
    {"title": "89. Fecr Suresi", "page": 592},
    {"title": "90. Beled Suresi", "page": 593},
    {"title": "91. Şems Suresi", "page": 594},
    {"title": "92. Leyl Suresi", "page": 595},
    {"title": "93. Duha Suresi", "page": 595},
    {"title": "94. İnşirah Suresi", "page": 596},
    {"title": "95. Tin Suresi", "page": 596},
    {"title": "96. Alak Suresi", "page": 597},
    {"title": "97. Kadir Suresi", "page": 598},
    {"title": "98. Beyyine Suresi", "page": 598},
    {"title": "99. Zilzal Suresi", "page": 599},
    {"title": "100. Adiyat Suresi", "page": 599},
    {"title": "101. Karia Suresi", "page": 600},
    {"title": "102. Tekasür Suresi", "page": 600},
    {"title": "103. Asr Suresi", "page": 601},
    {"title": "104. Hümeze Suresi", "page": 601},
    {"title": "105. Fil Suresi", "page": 601},
    {"title": "106. Kureyş Suresi", "page": 602},
    {"title": "107. Maun Suresi", "page": 602},
    {"title": "108. Kevser Suresi", "page": 602},
    {"title": "109. Kafirun Suresi", "page": 603},
    {"title": "110. Nasr Suresi", "page": 603},
    {"title": "111. Tebbet Suresi", "page": 603},
    {"title": "112. İhlas Suresi", "page": 604},
    {"title": "113. Felak Suresi", "page": 604},
    {"title": "114. Nas Suresi", "page": 604}
  ];

  const IndexDrawer({
    Key? key,
    required this.indexFuture,
    required this.bookTitle,
    required this.onPageSelected,
    required this.bookCode,
    this.appBarColor,
    this.searchFunction,
    this.juzIndex,
    this.initialSearchText,
  }) : super(key: key);

  @override
  _IndexDrawerState createState() => _IndexDrawerState();
}

class _IndexDrawerState extends State<IndexDrawer>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<IndexItem> _indexItems = [];
  List<IndexItem> _filteredItems = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchText = '';
  bool _showSearchResults = false;
  SharedPreferences? _prefs;
  List<String> _recentSearches = [];
  final int _maxRecentSearches = 5;

  // Tab controller için değişkenler
  late TabController _tabController;

  // Scroll controller'lar
  final ScrollController _suresScrollController = ScrollController();
  final ScrollController _juzScrollController = ScrollController();
  final ScrollController _searchScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    // Eğer başlangıç arama metni verilmişse, arama kutusunu doldur ve aramayı başlat
    if (widget.initialSearchText != null &&
        widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
      _isSearching = true;

      // Arama işlemini başlatmak için bir miktar gecikme ekle
      Future.delayed(Duration(milliseconds: 300), () {
        _filterItems(widget.initialSearchText!);
        _searchInBook(widget.initialSearchText!);
      });
    }

    // Tab controller'ı başlat - varsayılan olarak "Sureler" sekmesi (indeks 0) seçili olsun
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    
    // Kuran olmayan kitaplar için normal yükleme
    if (widget.bookCode != 'quran') {
      // Diğer kitaplar için normal yükleme - 0. sayfayı filtrele
      widget.indexFuture.then((items) {
        // 0. sayfayı filtrele (kitaplar için)
        final filteredItems = items.where((item) => item.pageNumber != 0).toList();
        setState(() {
          _indexItems = filteredItems;
          _filteredItems = filteredItems;
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Kuran için özel durum - context'e bağımlı işlemler burada yapılır
    if (widget.bookCode == 'quran' && _indexItems.isEmpty) {
      // Kuran surelerini IndexItem listesine dönüştür - çok dilli
      final items = _buildLocalizedQuranIndex(context);

      setState(() {
        _indexItems = items;
        _filteredItems = items;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches =
          _prefs?.getStringList('recent_searches_${widget.bookCode}') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    if (_recentSearches.contains(query)) {
      _recentSearches.remove(query);
    }

    _recentSearches.insert(0, query);

    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }

    await _prefs?.setStringList(
        'recent_searches_${widget.bookCode}', _recentSearches);
  }

  void _clearRecentSearches() async {
    setState(() {
      _recentSearches = [];
    });
    await _prefs?.setStringList('recent_searches_${widget.bookCode}', []);
  }

  void _filterItems(String query) {
    setState(() {
      _searchText = query;
      if (query.isEmpty) {
        _filteredItems = _indexItems;
        _showSearchResults = false;
      } else {
        _filteredItems = _indexItems
            .where((item) =>
                item.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _searchInBook(String query) async {
    if (query.trim().isEmpty || widget.searchFunction == null) return;

    setState(() {
      _isLoading = true;
      _showSearchResults = true;
    });

    try {
      final results = await widget.searchFunction!(widget.bookCode, query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      await _saveRecentSearch(query);
    } catch (e) {
      print('Error searching book: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: widget.initialSearchText == null,
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _filterItems,
                onSubmitted: _searchInBook,
              )
            : Text(
                widget.bookTitle,
                style: TextStyle(color: Colors.white),
              ),
        backgroundColor: widget.appBarColor ?? Colors.blue,
        titleTextStyle: TextStyle(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterItems('');
                  _showSearchResults = false;
                }
              });
            },
          ),
        ],
        bottom: widget.bookCode == 'quran' && widget.juzIndex != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.white70,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: AppLocalizations.of(context)?.quranSurahs ?? 'Sureler'),
                  Tab(text: AppLocalizations.of(context)?.quranJuz ?? 'Cüzler'),
                ],
              )
            : null,
      ),
      body: widget.bookCode == 'quran' && widget.juzIndex != null
          ? TabBarView(
              controller: _tabController,
              children: [
                // Sureler tab'ı
                _buildMainContent(),
                // Cüzler tab'ı
                _buildJuzList(),
              ],
            )
          : _buildMainContent(),
    );
  }

  Widget _buildJuzList() {
    if (widget.juzIndex == null || widget.juzIndex!.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)?.quranJuzListNotFound ?? 'Cüz listesi bulunamadı'));
    }

    return Scrollbar(
      controller: _juzScrollController,
      thickness: 6.0,
      radius: Radius.circular(3.0),
      child: ListView.builder(
        controller: _juzScrollController,
        itemCount: widget.juzIndex!.length,
        itemBuilder: (context, index) {
          final juz = widget.juzIndex![index];
          return ListTile(
            title: Text(
              _getLocalizedJuzName(context, juz['juz']),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${juz['page']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            onTap: () {
              // Sayfa değişimini gerçekleştir, drawer'ı kapatma
              // Drawer'ı kapatma işlemi BookPageScreen'de yapılacak
              widget.onPageSelected(juz['page']);
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_showSearchResults) {
      return _buildSearchResults();
    }

    if (_searchText.isNotEmpty && _filteredItems.isEmpty) {
      return Center(child: Text('Sonuç bulunamadı'));
    }

    return Column(
      children: [
        if (_recentSearches.isNotEmpty && _isSearching) _buildRecentSearches(),
        Expanded(
          child: Scrollbar(
            controller: _suresScrollController,
            thickness: 6.0,
            radius: Radius.circular(3.0),
            child: ListView.builder(
              controller: _suresScrollController,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                // Kuran için özel görünüm
                if (widget.bookCode == 'quran') {
                  return ListTile(
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.pageNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    onTap: () {
                      // Sayfa değişimini gerçekleştir, drawer'ı kapatma
                      // Drawer'ı kapatma işlemi BookPageScreen'de yapılacak
                      widget.onPageSelected(item.pageNumber);
                    },
                  );
                } else {
                  // Diğer kitaplar için normal görünüm
                  return ListTile(
                    title: Text(item.title),
                    trailing: Text('${item.pageNumber}'),
                    onTap: () {
                      // Sayfa değişimini gerçekleştir, drawer'ı kapatma
                      // Drawer'ı kapatma işlemi BookPageScreen'de yapılacak
                      widget.onPageSelected(item.pageNumber);
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text('Sonuç bulunamadı'),
      );
    }

    return Scrollbar(
      controller: _searchScrollController,
      thickness: 6.0,
      radius: Radius.circular(3.0),
      child: ListView.builder(
        controller: _searchScrollController,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final pageNumber = result['page'] as int;

          // Öncelikle shortdesc alanını kontrol et, yoksa text alanını kullan
          final String displayText;
          if (result['shortdesc'] != null &&
              result['shortdesc'].toString().trim().isNotEmpty) {
            displayText = result['shortdesc'].toString();
          } else if (result['text'] != null &&
              result['text'].toString().trim().isNotEmpty) {
            displayText = result['text'].toString();
          } else {
            displayText = 'Sayfa ...';
          }

          return ListTile(
            title: _buildHighlightedText(
              displayText,
              _searchText,
              TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            onTap: () {
              // Sayfa değişimini gerçekleştir, drawer'ı kapatma
              // Drawer'ı kapatma işlemi BookPageScreen'de yapılacak
              widget.onPageSelected(pageNumber);
            },
          );
        },
      ),
    );
  }

  // Alternatif highlight metodu (eski koddan alındı)
  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    List<TextSpan> spans = [];
    // Case insensitive search
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();

    int start = 0;
    int indexOfQuery;

    // Find all occurrences of the search query in the text
    while (true) {
      indexOfQuery = lowercaseText.indexOf(lowercaseQuery, start);
      if (indexOfQuery == -1) {
        // No more occurrences, add the rest of the text
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }

      // Add the text before the match
      if (indexOfQuery > start) {
        spans.add(
            TextSpan(text: text.substring(start, indexOfQuery), style: style));
      }

      // Add the matched text with bold style only (no highlight)
      spans.add(TextSpan(
        text: text.substring(indexOfQuery, indexOfQuery + query.length),
        style: style.copyWith(
          fontWeight: FontWeight.bold,
          // Sarı arka planı kaldırdık
        ),
      ));

      // Move past this occurrence
      start = indexOfQuery + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildRecentSearches() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Aramalar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text('Temizle'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _searchText = search;
                  _searchInBook(search);
                },
                child: Chip(
                  label: Text(search),
                  onDeleted: () {
                    setState(() {
                      _recentSearches.remove(search);
                    });
                    _prefs?.setStringList(
                        'recent_searches_${widget.bookCode}', _recentSearches);
                  },
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(fontSize: 12),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _suresScrollController.dispose();
    _juzScrollController.dispose();
    _searchScrollController.dispose();
    super.dispose();
  }

  // Çok dilli Kuran sure listesi oluştur
  List<IndexItem> _buildLocalizedQuranIndex(BuildContext context) {
    
    // Temel sure isimleri (Türkçe)
    final baseSurahNames = [
      'Fatiha', 'Bakara', 'Al-i İmran', 'Nisa', 'Maide', 'Enam', 'Araf', 'Enfal', 'Tevbe', 'Yunus',
      'Hud', 'Yusuf', 'Rad', 'İbrahim', 'Hicr', 'Nahl', 'İsra', 'Kehf', 'Meryem', 'Taha',
      'Enbiya', 'Hac', 'Müminun', 'Nur', 'Furkan', 'Şuara', 'Neml', 'Kasas', 'Ankebut', 'Rum',
      'Lokman', 'Secde', 'Ahzab', 'Sebe', 'Fatır', 'Yasin', 'Saffat', 'Sad', 'Zümer', 'Mümin',
      'Fussilet', 'Şura', 'Zuhruf', 'Duhan', 'Casiye', 'Ahkaf', 'Muhammed', 'Fetih', 'Hucurat', 'Kaf',
      'Zariyat', 'Tur', 'Necm', 'Kamer', 'Rahman', 'Vakıa', 'Hadid', 'Mücadele', 'Haşr', 'Mümtehine',
      'Saf', 'Cuma', 'Münafikun', 'Tegabün', 'Talak', 'Tahrim', 'Mülk', 'Kalem', 'Hakka', 'Mearic',
      'Nuh', 'Cin', 'Müzzemmil', 'Müddessir', 'Kıyame', 'İnsan', 'Mürselat', 'Nebe', 'Naziat', 'Abese',
      'Tekvir', 'İnfitar', 'Mutaffifin', 'İnşikak', 'Buruc', 'Tarık', 'Ala', 'Gaşiye', 'Fecr', 'Beled',
      'Şems', 'Leyl', 'Duha', 'İnşirah', 'Tin', 'Alak', 'Kadir', 'Beyyine', 'Zilzal', 'Adiyat',
      'Karia', 'Tekasür', 'Asr', 'Hümeze', 'Fil', 'Kureyş', 'Maun', 'Kevser', 'Kafirun', 'Nasr',
      'Mesed', 'İhlas', 'Felak', 'Nas'
    ];

    List<IndexItem> items = [];
    
    for (int i = 0; i < IndexDrawer.quranIndex.length && i < baseSurahNames.length; i++) {
      final item = IndexDrawer.quranIndex[i];
      final baseName = baseSurahNames[i];
      
      // Dile göre sure ismini al
      String localizedName = SurahLocalizationService.getLocalizedSurahName(baseName, context);
      
      items.add(IndexItem(
        pageNumber: item['page'] as int,
        title: '${i + 1}. $localizedName',
      ));
    }
    
    return items;
  }

  // Cüz ismini çok dilli hale getir
  String _getLocalizedJuzName(BuildContext context, String originalJuzName) {
    // "1. Cüz" formatından sayıyı çıkar
    final match = RegExp(r'(\d+)\.?\s*Cüz').firstMatch(originalJuzName);
    if (match != null) {
      final number = match.group(1)!;
      return AppLocalizations.of(context)?.juzNumber(int.parse(number)) ?? originalJuzName;
    }
    return originalJuzName;
  }
}
