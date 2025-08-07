import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class Article {
  final String title;
  final String link;
  final String description;
  final String date;
  final String category;

  Article({
    required this.title,
    required this.link,
    required this.description,
    required this.date,
    required this.category,
  });
}

class SearchService {
  static final Map<String, List<Article>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  static Future<List<Article>> searchArticles(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return [];

    final normalizedTerm = searchTerm.trim().toLowerCase();

    // Cache kontrolü
    if (_cache.containsKey(normalizedTerm)) {
      final timestamp = _cacheTimestamps[normalizedTerm];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[normalizedTerm]!;
      }
    }

    try {
      final encodedTerm = Uri.encodeComponent(searchTerm);
      final url = 'https://www.ekrembugraekinci.com/search-results/?srch=$encodedTerm&type=makale';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding': 'gzip, deflate, br',
        'Referer': 'https://www.ekrembugraekinci.com/',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin'
      };

      final response = await http.get(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Arama isteği zaman aşımına uğradı', const Duration(seconds: 10));
        },
      );

      debugPrint('DEBUG: Response status: ${response.statusCode}');
      debugPrint('DEBUG: Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final articles = _parseSearchResults(response.bodyBytes);

        // Cache'e kaydet
        _cache[normalizedTerm] = articles;
        _cacheTimestamps[normalizedTerm] = DateTime.now();

        // Cache boyutunu sınırla (son 50 arama)
        if (_cache.length > 50) {
          final oldestKey =
              _cacheTimestamps.entries.reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
          _cache.remove(oldestKey);
          _cacheTimestamps.remove(oldestKey);
        }

        return articles;
      } else {
        throw Exception('Web sitesine erişim hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hata oluştu: $e');
    }
  }

  static List<Article> _parseSearchResults(List<int> responseBytes) {
    final document = html.parse(utf8.decode(responseBytes));
    final articles = <Article>[];

    // Yazışmalar bölümünü ara
    final yazismalarUl = document.querySelector('ul.tab-wrapper#yazismalar');

    List<dynamic> resultItems = [];
    if (yazismalarUl != null) {
      resultItems = yazismalarUl.querySelectorAll('li.results-list-item');
    }

    // Eğer yazışmalar bulunamazsa, genel sonuçları ara
    if (resultItems.isEmpty) {
      resultItems = document.querySelectorAll('li.results-list-item');
    }

    for (final item in resultItems) {
      final linkElem = item.querySelector('a[href]');
      if (linkElem == null) continue;

      final href = linkElem.attributes['href'] ?? '';
      final link = href.startsWith('/') ? 'https://www.ekrembugraekinci.com$href' : href;

      final titleElem = linkElem.querySelector('div.result-title');
      final title = titleElem?.text.trim() ?? '';

      final categoryElem = linkElem.querySelector('div.result-type');
      final category = categoryElem?.text.trim() ?? '';

      final dateElem = linkElem.querySelector('div.result-date');
      final date = dateElem?.text.trim() ?? '';

      final descriptionElem = linkElem.querySelector('div.spot');
      final description = descriptionElem?.text.trim() ?? '';

      if (title.isNotEmpty) {
        articles.add(Article(
          title: title,
          link: link,
          description: description.isNotEmpty && description != '...' ? description : '',
          date: date,
          category: category,
        ));
      }
    }

    return articles;
  }

  static Future<List<Article>> getRandomQuestions() async {
    try {
      // Önce kaç sayfa olduğunu öğrenmek için ilk sayfayı kontrol et
      final totalPages = await _getTotalPages();

      // Rastgele bir sayfa seç (1 ile totalPages arasında)
      final random = Random();
      final randomPage = random.nextInt(totalPages) + 1;

      // Seçilen sayfadan soruları al
      final url = randomPage == 1
          ? 'https://www.ekrembugraekinci.com/questions'
          : 'https://www.ekrembugraekinci.com/questions/?pg=$randomPage&id=';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding': 'gzip, deflate, br',
        'Referer': 'https://www.ekrembugraekinci.com/',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin'
      };

      final response = await http.get(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('İstek zaman aşımına uğradı', const Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        final allQuestions = _parseQuestionsFromMainPage(response.bodyBytes);

        // Sayfadaki sorulardan rastgele 10 tane seç
        if (allQuestions.length <= 10) {
          return allQuestions;
        }

        final selectedQuestions = <Article>[];
        final usedIndices = <int>{};

        while (selectedQuestions.length < 10 && usedIndices.length < allQuestions.length) {
          final index = random.nextInt(allQuestions.length);
          if (!usedIndices.contains(index)) {
            usedIndices.add(index);
            selectedQuestions.add(allQuestions[index]);
          }
        }

        return selectedQuestions;
      } else {
        throw Exception('Web sitesine erişim hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hata oluştu: $e');
    }
  }

  static Future<int> _getTotalPages() async {
    try {
      const url = 'https://www.ekrembugraekinci.com/questions';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding': 'gzip, deflate, br',
        'Referer': 'https://www.ekrembugraekinci.com/',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin'
      };

      final response = await http.get(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('İstek zaman aşımına uğradı', const Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        final document = html.parse(utf8.decode(response.bodyBytes));

        // Pagination linklerini ara
        final paginationLinks = document.querySelectorAll('a[href*="pg="]');
        int maxPage = 1;

        for (final link in paginationLinks) {
          final href = link.attributes['href'] ?? '';
          final pageMatch = RegExp(r'pg=(\d+)').firstMatch(href);
          if (pageMatch != null) {
            final pageNum = int.tryParse(pageMatch.group(1) ?? '1') ?? 1;
            if (pageNum > maxPage) {
              maxPage = pageNum;
            }
          }
        }

        // Eğer pagination bulunamazsa, en azından 168 sayfa olduğunu biliyoruz (web sitesinden)
        return maxPage > 1 ? maxPage : 168;
      } else {
        // Hata durumunda varsayılan olarak 168 sayfa döndür
        return 168;
      }
    } catch (e) {
      // Hata durumunda varsayılan olarak 168 sayfa döndür
      return 168;
    }
  }

  static List<Article> _parseQuestionsFromMainPage(List<int> responseBytes) {
    final document = html.parse(utf8.decode(responseBytes));
    final articles = <Article>[];

    // Questions sayfası için doğru selektör
    final questionItems = document.querySelectorAll('li.questions-list-item');

    for (final item in questionItems) {
      try {
        final linkElement = item.querySelector('a');
        final titleElement = item.querySelector('.question-title');

        if (linkElement != null && titleElement != null) {
          String title = titleElement.text.trim();
          String link = linkElement.attributes['href'] ?? '';

          if (title.isNotEmpty && link.isNotEmpty) {
            // Relative URL'leri absolute yap
            if (link.startsWith('/')) {
              link = 'https://www.ekrembugraekinci.com$link';
            }

            articles.add(Article(
              title: title,
              link: link,
              description: '',
              date: '',
              category: 'Yazışma',
            ));
          }
        }
      } catch (e) {
        continue;
      }
    }

    return articles;
  }
}
