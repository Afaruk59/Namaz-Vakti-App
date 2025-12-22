import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:flutter/material.dart';

class BookTitleService {
  static final BookTitleService _instance = BookTitleService._internal();
  final ApiService _apiService = ApiService();
  final Map<String, String> _titleCache = {};
  final Map<String, String> _authorCache = {};

  factory BookTitleService() {
    return _instance;
  }

  BookTitleService._internal();

  Future<String> getTitle(String bookCode) async {
    if (_titleCache.containsKey(bookCode)) {
      return _titleCache[bookCode]!;
    }

    try {
      final indexItems = await _apiService.getBookIndex(bookCode);
      if (indexItems.isNotEmpty) {
        final title = indexItems[0].title;
        _titleCache[bookCode] = title;
        return title;
      }
      return 'Hakikat Kitabevi';
    } catch (e) {
      debugPrint('Error loading book title: $e');
      return 'Hakikat Kitabevi';
    }
  }

  // Kitap yazarını döndürür
  Future<String> getAuthor(String bookCode) async {
    if (_authorCache.containsKey(bookCode)) {
      return _authorCache[bookCode]!;
    }

    try {
      // Şu an için sabit bir değer döndürüyoruz, gerçek uygulamada API'den alınabilir
      const author = "Hakikat Kitabevi";
      _authorCache[bookCode] = author;
      return author;
    } catch (e) {
      debugPrint('Error loading book author: $e');
      return 'Hakikat Kitabevi';
    }
  }

  void clearCache() {
    _titleCache.clear();
    _authorCache.clear();
  }
}
