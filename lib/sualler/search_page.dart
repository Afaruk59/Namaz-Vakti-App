import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'article_detail_page.dart';
import 'search_service.dart';
import 'random_questions_widget.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class SualPage extends StatefulWidget {
  const SualPage({super.key});

  @override
  State<SualPage> createState() => _SualPageState();
}

class _SualPageState extends State<SualPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Article> _articles = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _lastSearchTerm = '';
  List<String> _searchHistory = [];
  List<String> _filteredSuggestions = [];
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _removeOverlay();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _updateSuggestions(_searchController.text);
    } else {
      _removeOverlay();
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(term); // Remove if exists to avoid duplicates
    _searchHistory.insert(0, term); // Add to beginning

    // Keep only last 20 searches
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }

    await prefs.setStringList('search_history', _searchHistory);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _filteredSuggestions = _searchHistory
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    if (_filteredSuggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top +
            kToolbarHeight +
            16 +
            56, // AppBar + padding + TextField height
        child: Card(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _filteredSuggestions[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(suggestion),
                onTap: () {
                  _searchController.text = suggestion;
                  _removeOverlay();
                  _searchArticles(suggestion);
                },
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _searchArticles(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Save search term to history
    await _saveSearchTerm(searchTerm.trim());
    _removeOverlay();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _lastSearchTerm = searchTerm;
    });

    try {
      final articles = await SearchService.searchArticles(searchTerm);
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: 'Dini ve Tarihi Sualler',
      background: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () {
            Navigator.pushNamed(context, '/favorites');
          },
        ),
        const SizedBox(width: 20),
      ],
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            // Arama çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Bir konu başlığı yazın...',
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isLoading ? null : () => _searchArticles(_searchController.text),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _removeOverlay();
                            setState(() {
                              _articles = [];
                              _errorMessage = '';
                              _lastSearchTerm = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
                  ),
                ),
                onSubmitted: (value) {
                  _debounceTimer?.cancel();
                  _searchArticles(value);
                },
                onChanged: (value) {
                  setState(() {});
                  _updateSuggestions(value);
                },
              ),
            ),
            // Sonuçlar
            Expanded(
              child: _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchArticles(_lastSearchTerm),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty && _lastSearchTerm.isNotEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '"$_lastSearchTerm" için sonuç bulunamadı',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı anahtar kelimeler deneyebilirsiniz',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return const RandomQuestionsWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          '"$_lastSearchTerm" için ${_articles.length} sonuç bulundu',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Card(
                  color: Theme.of(context).cardColor,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailPage(articleUrl: article.link),
                        ),
                      );
                      // Geri dönüldüğünde focus'u kaldır
                      _searchFocusNode.unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ListTile(
                        leading: const Icon(Icons.help_rounded),
                        subtitle: Text(article.title),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
