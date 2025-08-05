import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'dart:convert';
import 'article_detail_page.dart';

class Question {
  final String title;
  final String link;
  final String answer;
  final String date;

  Question({
    required this.title,
    required this.link,
    required this.answer,
    required this.date,
  });
}

class KeywordSearchPage extends StatefulWidget {
  final String keyword;

  const KeywordSearchPage({super.key, required this.keyword});

  @override
  State<KeywordSearchPage> createState() => _KeywordSearchPageState();
}

class _KeywordSearchPageState extends State<KeywordSearchPage> {
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _questions.clear();
      _currentPage = 1;
      _hasMoreData = true;
    });

    await _loadQuestions();
  }

  Future<void> _loadMoreQuestions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final encodedKeyword = Uri.encodeComponent(widget.keyword);
      final url =
          'https://www.ekrembugraekinci.com/keywordsearch/?text=$encodedKeyword&page=$_currentPage';

      print('DEBUG: Fetching URL: $url');
      print('DEBUG: Keyword: ${widget.keyword}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'tr-TR,tr;q=0.8,en-US;q=0.5,en;q=0.3',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        // UTF-8 olarak decode et
        final decodedBody = utf8.decode(response.bodyBytes);
        final document = html.parse(decodedBody);
        final List<Question> questions = [];

        // Tüm div.col-12.col-lg-8 elementlerini bul
        final resultContainers = document.querySelectorAll('div.col-12.col-lg-8');
        print('DEBUG: Results containers found: ${resultContainers.length}');

        final List<dom.Element> allListItems = [];

        for (final container in resultContainers) {
          final resultsList = container.querySelector('ul.results-list');
          if (resultsList != null) {
            final listItems = resultsList.querySelectorAll('li.results-list-item');
            allListItems.addAll(listItems);
          }
        }

        print('DEBUG: Total list items found: ${allListItems.length}');

        if (allListItems.isNotEmpty) {
          print('DEBUG: Processing ${allListItems.length} list items');

          for (final item in allListItems) {
            final linkElem = item.querySelector('a[href]');
            if (linkElem == null) continue;

            final href = linkElem.attributes['href'] ?? '';
            final link = href.startsWith('/') ? 'https://www.ekrembugraekinci.com$href' : href;

            final titleElem = linkElem.querySelector('div.result-title');
            String title = titleElem?.text.trim() ?? '';

            // "Sual:" kısmını kaldır
            if (title.startsWith('Sual:')) {
              title = title.substring(5).trim();
            }

            // div.spot'tan cevap çıkarma
            final spotElem = linkElem.querySelector('div.spot');
            String answer = spotElem?.text.trim() ?? '';

            // Eğer spot'ta cevap yoksa title'dan çıkarmaya çalış
            if (answer.isEmpty && title.contains('Cevap:')) {
              final parts = title.split('Cevap:');
              if (parts.length > 1) {
                answer = parts[1].trim();
              }
            }

            final dateElem = linkElem.querySelector('div.result-date');
            final date = dateElem?.text.trim() ?? '';

            if (title.isNotEmpty) {
              questions.add(Question(
                title: title,
                link: link,
                answer: answer,
                date: date,
              ));
            }
          }
        }

        print('DEBUG: Total questions parsed: ${questions.length}');

        if (mounted) {
          setState(() {
            if (_currentPage == 1) {
              _questions = questions;
            } else {
              _questions.addAll(questions);
            }
            _isLoading = false;
            _isLoadingMore = false;
            _hasMoreData = questions.isNotEmpty;
          });
        }
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: '"${widget.keyword}" Arama Sonuçları',
      background: true,
      actions: const [],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(
                  child: Text(
                    'Bu anahtar kelime için sonuç bulunamadı.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '"${widget.keyword}" için ${_questions.length} sonuç bulundu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _questions.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _questions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final question = _questions[index];
                          return Card(
                            color: Theme.of(context).cardColor,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ArticleDetailPage(articleUrl: question.link),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: ListTile(
                                  leading: const Icon(Icons.help_rounded),
                                  subtitle: Text(question.title),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
