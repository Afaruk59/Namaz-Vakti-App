import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class BookTitleService {
  static final BookTitleService _instance = BookTitleService._internal();
  final ApiService _apiService = ApiService();
  final Map<String, String> _titleCache = {};
  final Map<String, String> _authorCache = {};

  factory BookTitleService() {
    return _instance;
  }

  BookTitleService._internal();

  Future<String> getTitle(String bookCode, {BuildContext? context}) async {
    // Quran için özel başlık
    if (bookCode == 'quran') {
      final quranTitle = context != null 
          ? (AppLocalizations.of(context)?.quranHolyQuran ?? 'Kuran-ı Kerim')
          : 'Kuran-ı Kerim';
      _titleCache[bookCode] = quranTitle;
      debugPrint('BookTitleService: Quran title set: $quranTitle');
      return quranTitle;
    }

    // Cache kontrolü
    if (_titleCache.containsKey(bookCode)) {
      final cachedTitle = _titleCache[bookCode]!;
      debugPrint('BookTitleService: Title from cache for $bookCode: $cachedTitle');
      return cachedTitle;
    }

    try {
      final indexItems = await _apiService.getBookIndex(bookCode);
      if (indexItems.isNotEmpty) {
        final title = indexItems[0].title;
        // Boş title kontrolü
        final safeTitle = title.isNotEmpty ? title : 'Hakikat Kitabevi';
        _titleCache[bookCode] = safeTitle;
        debugPrint('BookTitleService: Title set for $bookCode: $safeTitle');
        return safeTitle;
      }
      // IndexItems boşsa varsayılan değer
      const fallbackTitle = 'Hakikat Kitabevi';
      _titleCache[bookCode] = fallbackTitle;
      debugPrint('BookTitleService: No index items, using fallback for $bookCode: $fallbackTitle');
      return fallbackTitle;
    } catch (e) {
      debugPrint('Error loading book title for $bookCode: $e');
      // Hata durumunda da güvenli değer döndür
      const errorFallback = 'Hakikat Kitabevi';
      _titleCache[bookCode] = errorFallback;
      return errorFallback;
    }
  }

  // Kitap yazarını döndürür
  Future<String> getAuthor(String bookCode) async {
    // Quran için özel yazar
    if (bookCode == 'quran') {
      const quranAuthor = 'Allah (c.c.)';
      _authorCache[bookCode] = quranAuthor;
      debugPrint('BookTitleService: Quran author set: $quranAuthor');
      return quranAuthor;
    }
    
    // Cache kontrolü
    if (_authorCache.containsKey(bookCode)) {
      return _authorCache[bookCode]!;
    }

    try {
      // Tüm kitaplar için sabit yazar değeri - Hakikat Kitabevi
      const author = "Hakikat Kitabevi";
      _authorCache[bookCode] = author;
      debugPrint('BookTitleService: Author set for $bookCode: $author');
      return author;
    } catch (e) {
      debugPrint('Error loading book author: $e');
      // Hata durumunda da aynı değeri döndür
      const fallbackAuthor = 'Hakikat Kitabevi';
      _authorCache[bookCode] = fallbackAuthor;
      return fallbackAuthor;
    }
  }

  void clearCache() {
    _titleCache.clear();
    _authorCache.clear();
  }
}
