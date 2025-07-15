import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexDrawer extends StatefulWidget {
  final Future<List<IndexItem>> indexFuture;
  final String bookTitle;
  final Function(int) onPageSelected;
  final String bookCode;
  final Color? appBarColor;
  final Future<List<Map<String, dynamic>>> Function(String, String)? searchFunction;
  final List<Map<String, dynamic>>? juzIndex;
  final String? initialSearchText;

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

class _IndexDrawerState extends State<IndexDrawer> with SingleTickerProviderStateMixin {
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
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
      _isSearching = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterItems(widget.initialSearchText!);
        _searchInBook(widget.initialSearchText!);
      });
    }

    // Index verilerini yükle
    widget.indexFuture.then((items) {
      setState(() {
        _indexItems = items;
        _filteredItems = items;
      });
    });

    // Tab controller'ı başlat - varsayılan olarak "Sureler" sekmesi (indeks 0) seçili olsun
    _tabController = TabController(length: widget.juzIndex != null ? 3 : 2, vsync: this);
  }

  Future<void> _loadRecentSearches() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = _prefs?.getStringList('recent_searches_${widget.bookCode}') ?? [];
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

    await _prefs?.setStringList('recent_searches_${widget.bookCode}', _recentSearches);
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
            .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
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
            : Text(widget.bookTitle),
        backgroundColor: widget.appBarColor ?? Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
        bottom: widget.juzIndex != null
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
                tabs: const [
                  Tab(text: 'Sureler'),
                  Tab(text: 'Cüzler'),
                ],
              )
            : null,
      ),
      body: widget.juzIndex != null
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
      return Center(child: Text('Cüz listesi bulunamadı'));
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
              juz['juz'],
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
          if (result['shortdesc'] != null && result['shortdesc'].toString().trim().isNotEmpty) {
            displayText = result['shortdesc'].toString();
          } else if (result['text'] != null && result['text'].toString().trim().isNotEmpty) {
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
        spans.add(TextSpan(text: text.substring(start, indexOfQuery), style: style));
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
                    _prefs?.setStringList('recent_searches_${widget.bookCode}', _recentSearches);
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
    _searchController.dispose();
    _tabController.dispose();
    _suresScrollController.dispose();
    _juzScrollController.dispose();
    _searchScrollController.dispose();
    super.dispose();
  }
}
