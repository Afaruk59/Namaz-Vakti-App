import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'keyword_search_page.dart';

class ArticleDetail {
  final String question;
  final String answer;
  final List<String> relatedTopics;

  ArticleDetail({
    required this.question,
    required this.answer,
    this.relatedTopics = const [],
  });
}

class ArticleDetailPage extends StatefulWidget {
  final String articleUrl;

  const ArticleDetailPage({super.key, required this.articleUrl});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  ArticleDetail? _articleDetail;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchArticleDetail();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favorites.contains(widget.articleUrl);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    List<String> favoriteQuestions = prefs.getStringList('favoriteQuestions') ?? [];

    if (_isFavorite) {
      final index = favorites.indexOf(widget.articleUrl);
      if (index != -1) {
        favorites.removeAt(index);
        if (index < favoriteQuestions.length) {
          favoriteQuestions.removeAt(index);
        }
      }
    } else {
      favorites.add(widget.articleUrl);
      favoriteQuestions.add(_articleDetail?.question ?? 'Favori Sual');
    }

    await prefs.setStringList('favorites', favorites);
    await prefs.setStringList('favoriteQuestions', favoriteQuestions);
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _shareContent() async {
    if (_articleDetail != null) {
      final shareText = '''${_articleDetail!.question}

Cevap:
${_articleDetail!.answer}

Kaynak: ${widget.articleUrl}''';
      // ignore: deprecated_member_use
      await Share.share(
        shareText,
        subject: 'Dini Sual ve Cevap',
      );
    }
  }

  // HTML parsing işlemini isolate'te çalıştırmak için yardımcı fonksiyon
  static ArticleDetail _parseHtmlInIsolate(String htmlContent) {
    final document = html.parse(htmlContent);

    // Sual ve cevap bilgilerini al
    final questionElement = document.querySelector('.question');
    final answerElement = document.querySelector('.answer');

    String question = '';
    String answer = '';

    if (questionElement != null) {
      // 'Sual Gönder' butonunu içeren elementleri kaldır
      questionElement.querySelectorAll('button').forEach((button) {
        if (button.text.contains('Sual Gönder')) {
          button.remove();
        }
      });

      // Sadece sual başlığını al, cevap kısmını çıkar
      final questionTitle = questionElement.querySelector('h2');
      if (questionTitle != null) {
        question = questionTitle.text.trim();
      } else {
        // Tüm metni al ve 'Cevap' kelimesinden sonrasını çıkar
        String fullText = questionElement.text.trim();
        // 'Cevap' kelimesini ve sonrasını kaldır
        fullText = fullText.replaceAll(RegExp(r'\s*Cevap[\s\S]*'), '');
        // 'Sual Gönder' bölümünü kaldır
        fullText =
            fullText.replaceAll(RegExp(r'\s*Sual Gönder[\s\S]*?(?=\n|$)', multiLine: true), '');
        question = fullText.trim();
      }

      // Sual metnindeki gereksiz boş satırları ve "Sual" kelimesini temizle
      question = question.replaceAll(RegExp(r'^\s*Sual\s*'), '').trim();
      question = question.replaceAll(RegExp(r'\n\s*\n'), '\n').trim();
      question = question.replaceAll(RegExp(r'^\s*\n+'), '').trim();
      question = question.replaceAll(RegExp(r'\n+\s*$'), '').trim();
    }

    if (answerElement != null) {
      // 'Sual Gönder' butonunu içeren elementleri kaldır
      answerElement.querySelectorAll('button').forEach((button) {
        if (button.text.contains('Sual Gönder')) {
          button.remove();
        }
      });

      String answerText = answerElement.text.trim();
      // 'Sual Gönder' bölümünü cevaptan da kaldır
      answerText =
          answerText.replaceAll(RegExp(r'\s*Sual Gönder[\s\S]*?(?=\n|$)', multiLine: true), '');
      // Cevap metnindeki gereksiz boş satırları temizle
      answerText = answerText.replaceAll(RegExp(r'\n\s*\n'), '\n').trim();
      answerText = answerText.replaceAll(RegExp(r'^\s*\n+'), '').trim();
      answerText = answerText.replaceAll(RegExp(r'\n+\s*$'), '').trim();
      answer = answerText.trim();
    }

    // Alakalı konuları al
    List<String> relatedTopics = [];
    final relatedElements = document.querySelectorAll('.relevant-keywords .keyword a');
    for (var element in relatedElements) {
      String linkText = element.text.trim();
      if (linkText.isNotEmpty && !relatedTopics.contains(linkText)) {
        relatedTopics.add(linkText);
      }
    }

    return ArticleDetail(
      question: question,
      answer: answer,
      relatedTopics: relatedTopics,
    );
  }

  Future<void> _fetchArticleDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse(widget.articleUrl),
        headers: {
          'Accept-Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        // HTML parsing işlemini isolate'te çalıştır
        final htmlContent = utf8.decode(response.bodyBytes);
        final articleDetail = await compute(_parseHtmlInIsolate, htmlContent);

        setState(() {
          _articleDetail = articleDetail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Makale yüklenirken hata oluştu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      actions: [
        IconButton(
          onPressed: () {
            _toggleFavorite();
          },
          icon: _isFavorite ? const Icon(Icons.favorite) : const Icon(Icons.favorite_border),
        ),
        IconButton(
          onPressed: () {
            _shareContent();
          },
          icon: const Icon(Icons.share),
        ),
        const SizedBox(width: 20),
      ],
      title: 'Sual Detayı',
      background: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
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
                        _error!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchArticleDetail,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _articleDetail != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sual bölümü
                          Card(
                            color: Theme.of(context).cardColor,
                            child: ListTile(
                              leading: Icon(
                                Icons.help_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Sual',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                _articleDetail!.question,
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ),
                          // Cevap bölümü
                          Card(
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_rounded,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      Text(
                                        'Cevap',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _articleDetail!.answer,
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Alakalı konular bölümü
                          if (_articleDetail!.relatedTopics.isNotEmpty) ...[
                            Card(
                              color: Theme.of(context).cardColor,
                              child: ListTile(
                                leading: Icon(
                                  Icons.topic_rounded,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                title: Text(
                                  'İlgili Konular',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ..._articleDetail!.relatedTopics.map(
                                      (topic) => InkWell(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  KeywordSearchPage(keyword: topic),
                                            ),
                                          );
                                        },
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.label_important_outline_rounded,
                                            color: Theme.of(context).colorScheme.secondary,
                                            size: 20,
                                          ),
                                          title: Text(
                                            topic,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // Kaynak linki butonu
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  final Uri url = Uri.parse(widget.articleUrl);
                                  await launchUrl(url);
                                },
                                icon: const Icon(Icons.open_in_browser),
                                label: const Text('Sual ve Cevabın Kaynağını Görüntüleyin'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('Makale bulunamadı'),
                    ),
    );
  }
}
