// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// Yer işareti modeli
class Bookmark {
  final int pageNumber;
  final String? selectedText;
  final Color? highlightColor; // Seçili metnin rengi
  final int? startIndex; // Seçili metnin başlangıç indeksi
  final int? endIndex; // Seçili metnin bitiş indeksi
  final int? surahId; // yeni
  final String? surahName; // yeni
  final String? ayahNumber; // yeni

  Bookmark({
    required this.pageNumber,
    this.selectedText,
    this.highlightColor,
    this.startIndex,
    this.endIndex,
    this.surahId,
    this.surahName,
    this.ayahNumber,
  });

  // JSON'dan Bookmark oluştur
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      pageNumber: json['pageNumber'] as int,
      selectedText: json['selectedText'] as String?,
      highlightColor: json['highlightColor'] != null
          ? Color(json['highlightColor'])
          : null, // int değerini Color'a dönüştür
      startIndex: json['startIndex'] as int?,
      endIndex: json['endIndex'] as int?,
      surahId: json['surahId'] as int?,
      surahName: json['surahName'] as String?,
      ayahNumber: json['ayahNumber'] as String?,
    );
  }

  // Bookmark'u JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'selectedText': selectedText,
      'highlightColor': highlightColor?.value, // Color'ı int değerine dönüştür
      'startIndex': startIndex,
      'endIndex': endIndex,
      'surahId': surahId,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
    };
  }
}

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';

  // Önbellek için statik değişken
  static Map<String, List<Bookmark>>? _cachedBookmarks;

  // Yer işaretlerini yükle
  Future<Map<String, List<Bookmark>>> _loadBookmarks() async {
    // Eğer önbellekte veri varsa, onu kullan
    if (_cachedBookmarks != null) {
      return _cachedBookmarks!;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString(_bookmarksKey);

    if (bookmarksJson == null) {
      _cachedBookmarks = {};
      return {};
    }

    try {
      final Map<String, dynamic> bookmarksMap = json.decode(bookmarksJson);
      Map<String, List<Bookmark>> result = {};

      bookmarksMap.forEach((key, value) {
        if (value is List) {
          result[key] = List<Bookmark>.from(
            value.map((item) => item is Map<String, dynamic>
                ? Bookmark.fromJson(item)
                : Bookmark(pageNumber: item as int)),
          );
        }
      });

      // Sonucu önbelleğe al
      _cachedBookmarks = result;
      return result;
    } catch (e) {
      debugPrint('Yer işaretleri yüklenirken hata: $e');
      _cachedBookmarks = {};
      return {};
    }
  }

  // Yer işaretlerini kaydet
  Future<void> _saveBookmarks(Map<String, List<Bookmark>> bookmarks) async {
    // Önbelleği güncelle
    _cachedBookmarks = bookmarks;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<dynamic>> serializedBookmarks = {};

    bookmarks.forEach((key, value) {
      serializedBookmarks[key] = value.map((bookmark) => bookmark.toJson()).toList();
    });

    final String bookmarksJson = json.encode(serializedBookmarks);
    await prefs.setString(_bookmarksKey, bookmarksJson);
  }

  // Yer işareti ekle (seçili metin, renk ve konum ile)
  Future<void> addBookmark(String bookCode, int pageNumber,
      {String? selectedText,
      Color? highlightColor,
      int? startIndex,
      int? endIndex,
      int? surahId,
      String? surahName,
      String? ayahNumber}) async {
    final bookmarks = await _loadBookmarks();

    if (!bookmarks.containsKey(bookCode)) {
      bookmarks[bookCode] = [];
    }

    // Aynı sayfada, aynı metinle ve aynı konumda bir yer işareti var mı kontrol et
    final existingIndex = bookmarks[bookCode]!.indexWhere((bookmark) =>
        bookmark.pageNumber == pageNumber &&
        bookmark.selectedText == selectedText &&
        bookmark.startIndex == startIndex &&
        bookmark.endIndex == endIndex &&
        bookmark.surahId == surahId &&
        bookmark.ayahNumber == ayahNumber);

    if (existingIndex != -1) {
      // Varsa güncelle (rengi değiştir)
      bookmarks[bookCode]![existingIndex] = Bookmark(
        pageNumber: pageNumber,
        selectedText: selectedText,
        highlightColor: highlightColor,
        startIndex: startIndex,
        endIndex: endIndex,
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
      );
    } else {
      // Yoksa yeni ekle
      bookmarks[bookCode]!.add(Bookmark(
        pageNumber: pageNumber,
        selectedText: selectedText,
        highlightColor: highlightColor,
        startIndex: startIndex,
        endIndex: endIndex,
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
      ));
    }

    // Sayfa numarasına göre sırala
    bookmarks[bookCode]!.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    await _saveBookmarks(bookmarks);
  }

  // Yer işareti kaldır (seçili metin ve konum ile)
  Future<void> removeBookmark(String bookCode, int pageNumber,
      {String? selectedText, int? startIndex, int? endIndex}) async {
    final bookmarks = await _loadBookmarks();

    if (bookmarks.containsKey(bookCode)) {
      if (selectedText != null && startIndex != null && endIndex != null) {
        // Belirli bir metni ve konumu kaldır
        bookmarks[bookCode]!.removeWhere((bookmark) =>
            bookmark.pageNumber == pageNumber &&
            bookmark.selectedText == selectedText &&
            bookmark.startIndex == startIndex &&
            bookmark.endIndex == endIndex);
      } else if (selectedText != null) {
        // Belirli bir metni kaldır (eski uyumluluk için)
        bookmarks[bookCode]!.removeWhere((bookmark) =>
            bookmark.pageNumber == pageNumber && bookmark.selectedText == selectedText);
      } else {
        // Sadece sayfa numarasına göre yer işaretini kaldır
        bookmarks[bookCode]!.removeWhere((bookmark) =>
            bookmark.pageNumber == pageNumber &&
            (bookmark.selectedText == null || bookmark.selectedText!.isEmpty));
      }

      await _saveBookmarks(bookmarks);
    }
  }

  // Sayfa yer işaretli mi kontrol et
  Future<bool> isPageBookmarked(String bookCode, int pageNumber) async {
    final bookmarks = await _loadBookmarks();

    if (!bookmarks.containsKey(bookCode)) {
      return false;
    }

    // Sadece sayfa yer işaretlerini kontrol et (seçili metni olmayan yer işaretleri)
    return bookmarks[bookCode]!.any((bookmark) =>
        bookmark.pageNumber == pageNumber &&
        (bookmark.selectedText == null || bookmark.selectedText!.isEmpty));
  }

  // Sayfada vurgulanmış metin var mı kontrol et
  Future<bool> hasHighlightedText(String bookCode, int pageNumber) async {
    final bookmarks = await _loadBookmarks();

    if (!bookmarks.containsKey(bookCode)) {
      return false;
    }

    // Sadece vurgulanmış metinleri kontrol et
    return bookmarks[bookCode]!.any((bookmark) =>
        bookmark.pageNumber == pageNumber &&
        bookmark.selectedText != null &&
        bookmark.selectedText!.isNotEmpty);
  }

  // Sadece sayfa yer işareti ekle (metin vurgulaması olmadan)
  Future<void> addPageBookmark(String bookCode, int pageNumber) async {
    final bookmarks = await _loadBookmarks();

    if (!bookmarks.containsKey(bookCode)) {
      bookmarks[bookCode] = [];
    }

    // Aynı sayfada bir sayfa yer işareti var mı kontrol et
    final existingIndex = bookmarks[bookCode]!.indexWhere((bookmark) =>
        bookmark.pageNumber == pageNumber &&
        (bookmark.selectedText == null || bookmark.selectedText!.isEmpty));

    if (existingIndex == -1) {
      // Yoksa yeni ekle
      bookmarks[bookCode]!.add(Bookmark(
        pageNumber: pageNumber,
      ));

      // Sayfa numarasına göre sırala
      bookmarks[bookCode]!.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      await _saveBookmarks(bookmarks);
    }
  }

  // Sadece sayfa yer işaretini kaldır (metin vurgulamalarına dokunmadan)
  Future<void> removePageBookmark(String bookCode, int pageNumber) async {
    final bookmarks = await _loadBookmarks();

    if (bookmarks.containsKey(bookCode)) {
      // Sadece sayfa yer işaretlerini kaldır (seçili metni olmayan yer işaretleri)
      bookmarks[bookCode]!.removeWhere((bookmark) =>
          bookmark.pageNumber == pageNumber &&
          (bookmark.selectedText == null || bookmark.selectedText!.isEmpty));

      await _saveBookmarks(bookmarks);
    }
  }

  // Kitabın tüm yer işaretlerini getir
  Future<List<Bookmark>> getBookmarks(String bookCode) async {
    final bookmarks = await _loadBookmarks();

    if (!bookmarks.containsKey(bookCode)) {
      return [];
    }

    return bookmarks[bookCode]!;
  }

  // Tüm yer işaretlerini getir
  Future<Map<String, List<Bookmark>>> getAllBookmarks() async {
    return await _loadBookmarks();
  }

  // Kitabın tüm yer işaretlerini temizle
  Future<void> clearBookmarks(String bookCode) async {
    final bookmarks = await _loadBookmarks();

    if (bookmarks.containsKey(bookCode)) {
      bookmarks.remove(bookCode);
      await _saveBookmarks(bookmarks);
    }
  }

  // Tüm yer işaretlerini temizle
  Future<void> clearAllBookmarks() async {
    await _saveBookmarks({});
  }

  // Yer işareti sayısını getir (BookBookmarkIndicator için)
  Future<int> getBookmarkCount(String bookCode) async {
    // Önbellekte veri varsa, doğrudan kullan
    if (_cachedBookmarks != null) {
      return _cachedBookmarks!.containsKey(bookCode) ? _cachedBookmarks![bookCode]!.length : 0;
    }

    final bookmarks = await getBookmarks(bookCode);
    return bookmarks.length;
  }

  // Önbelleği temizle (uygulama yeniden başlatıldığında veya veri değiştiğinde çağrılabilir)
  void clearCache() {
    _cachedBookmarks = null;
  }

  // Sayfada belirli bir metin için yer işareti olup olmadığını kontrol et
  Future<bool> isTextBookmarked(String bookCode, int pageNumber, String selectedText) async {
    final bookmarks = await getBookmarks(bookCode);
    return bookmarks.any(
        (bookmark) => bookmark.pageNumber == pageNumber && bookmark.selectedText == selectedText);
  }

  // Sayfadaki tüm yer işaretlerini getir
  Future<List<Bookmark>> getPageBookmarks(String bookCode, int pageNumber) async {
    final bookmarks = await getBookmarks(bookCode);
    return bookmarks.where((bookmark) => bookmark.pageNumber == pageNumber).toList();
  }

  // Sayfada belirli bir metne ve konuma ait yer işaretini getir
  Future<Bookmark?> getTextBookmarkWithPosition(
      String bookCode, int pageNumber, String selectedText, int startIndex, int endIndex) async {
    final bookmarks = await getBookmarks(bookCode);
    try {
      return bookmarks.firstWhere((bookmark) =>
          bookmark.pageNumber == pageNumber &&
          bookmark.selectedText == selectedText &&
          bookmark.startIndex == startIndex &&
          bookmark.endIndex == endIndex);
    } catch (e) {
      return null;
    }
  }
}
