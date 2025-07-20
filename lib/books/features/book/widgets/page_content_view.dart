// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/services/html_parser.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/highlight_color_dialog.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';
import 'package:namaz_vakti_app/books/features/book/services/highlight_service.dart';
import 'package:namaz_vakti_app/books/features/book/utils/text_selection_helper.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/text_context_menu.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/content_view_builder.dart';
import 'dart:async';

class PageContentView extends StatefulWidget {
  final BookPageModel bookPage;
  final Color backgroundColor;
  final double fontSize;
  final bool isFullScreen;
  final Function(bool) onFullScreenChanged;
  final String bookCode;
  final int pageNumber;
  final Function()? onBookmarkAdded;
  final Function()? onBookmarkRemoved;
  final Function(String)? onSearch;

  const PageContentView({
    super.key,
    required this.bookPage,
    required this.backgroundColor,
    required this.fontSize,
    required this.isFullScreen,
    required this.onFullScreenChanged,
    required this.bookCode,
    required this.pageNumber,
    this.onBookmarkAdded,
    this.onBookmarkRemoved,
    this.onSearch,
  });

  @override
  _PageContentViewState createState() => _PageContentViewState();
}

class _PageContentViewState extends State<PageContentView> {
  // ScrollController'ı sınıf seviyesinde tanımlayalım
  late ScrollController _scrollController;
  // Resim tam ekran modunda mı kontrolü için state ekle
  final bool _isImageFullScreen = false;
  // Vurgulama servisi
  final HighlightService _highlightService = HighlightService();
  // Yer işareti servisi
  final BookmarkService _bookmarkService = BookmarkService();
  // Seçilen metin
  String _selectedText = '';
  // Seçilen metnin başlangıç ve bitiş indeksleri
  int _selectedStartIndex = -1;
  int _selectedEndIndex = -1;
  // Sayfadaki vurgulanmış metinler ve bilgileri
  List<HighlightInfo> _highlights = [];
  // Son yükleme zamanı - gereksiz yeniden yüklemeleri önlemek için
  DateTime _lastLoadTime = DateTime.now();
  // Tüm metin parçalarını tutan liste
  List<InlineSpan> allTextSpans = [];
  // Birleştirilmiş metin
  String combinedText = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Vurgulanmış metinleri arka planda yükle
    _loadHighlightedTexts();
  }

  @override
  void didUpdateWidget(PageContentView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sayfa numarası veya kitap kodu değiştiğinde vurgulanmış metinleri yeniden yükle
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.bookCode != widget.bookCode) {
      _loadHighlightedTexts();
      return;
    }

    // BookmarksScreen'den dönüldüğünde vurgulamaları her zaman yenile
    // Eğer bookPage nesnesi değiştiyse (BookPageScreen'de _refreshBookmarkStatus çağrıldığında)
    // bu, BookmarksScreen'den dönüldüğünü ve vurgulamaların yenilenmesi gerektiğini gösterir
    if (oldWidget.bookPage != widget.bookPage) {
      _loadHighlightedTexts();
      return;
    }

    // Eski yöntem: Zaman farkına göre yenileme
    // Bu yöntem bazen çalışmayabilir, bu yüzden yukarıdaki kontrol daha güvenilir
    final now = DateTime.now();
    if (now.difference(_lastLoadTime).inSeconds >= 5) {
      // Bu, BookmarksScreen'den dönüldüğünde vurgulamaları yenilemek için yeterli olacak
      // ancak ses çalma sırasında sürekli yenilemeyi önleyecek
      _loadHighlightedTexts();
    }
  }

  // Sayfadaki vurgulanmış metinleri yükle
  Future<void> _loadHighlightedTexts() async {
    try {
      final highlights =
          await _highlightService.loadHighlightedTexts(widget.bookCode, widget.pageNumber);

      // Yükleme tamamlandığında vurgulamaları güncelle
      if (mounted) {
        setState(() {
          _highlights = highlights;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Vurgulanmış metinleri yükleme hatası: $e');

      // Hata durumunda boş bir vurgulama listesi göster
      if (mounted) {
        setState(() {
          _highlights = []; // Hata durumunda boş liste göster
          _lastLoadTime = DateTime.now();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Renk seçme dialogunu göster
  void _showColorPickerDialog(String selectedText, int startIndex, int endIndex) {
    showDialog(
      context: context,
      builder: (context) => HighlightColorDialog(
        onColorSelected: (color) {
          _addHighlightedBookmark(selectedText, color, startIndex, endIndex);
        },
      ),
    );
  }

  // Seçilen metni vurgulu yer işareti olarak ekle
  void _addHighlightedBookmark(
      String selectedText, Color color, int startIndex, int endIndex) async {
    final success = await _highlightService.addHighlightedBookmark(
        widget.bookCode, widget.pageNumber, selectedText, color, startIndex, endIndex);

    if (success) {
      // Vurgulanmış metinleri güncelle
      if (mounted) {
        setState(() {
          // Aynı konumda bir vurgulama var mı kontrol et
          final existingIndex =
              _highlights.indexWhere((h) => h.startIndex == startIndex && h.endIndex == endIndex);

          // Varsa güncelle, yoksa ekle
          if (existingIndex >= 0) {
            _highlights[existingIndex] = HighlightInfo(
              text: selectedText,
              color: color,
              startIndex: startIndex,
              endIndex: endIndex,
            );
          } else {
            _highlights.add(HighlightInfo(
              text: selectedText,
              color: color,
              startIndex: startIndex,
              endIndex: endIndex,
            ));
          }
        });
      }

      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metin vurgulandı ve yer işareti olarak eklendi'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Yer işareti eklendiğinde callback'i çağır
      if (widget.onBookmarkAdded != null) {
        widget.onBookmarkAdded!();
      }
    } else {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yer işareti eklenirken bir hata oluştu'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Vurgulamayı kaldır
  void _removeHighlight(HighlightInfo highlight) async {
    final success =
        await _highlightService.removeHighlight(widget.bookCode, widget.pageNumber, highlight);

    if (success) {
      // Vurgulanmış metinleri güncelle
      if (mounted) {
        setState(() {
          _highlights.removeWhere(
              (h) => h.startIndex == highlight.startIndex && h.endIndex == highlight.endIndex);
        });
      }

      // Sayfada başka vurgulama veya yer işareti var mı kontrol et
      final hasPageBookmark = await _highlightService.hasPageBookmarks(
        widget.bookCode,
        widget.pageNumber,
      );

      final hasHighlights = _highlights.isNotEmpty;

      // Eğer sayfada hiç vurgulama veya yer işareti kalmadıysa
      if (!hasPageBookmark && !hasHighlights) {
        // BookPageScreen'e bildir
        if (widget.onBookmarkRemoved != null) {
          widget.onBookmarkRemoved!();
        }
      }

      // BookmarkService önbelleğini temizle
      _bookmarkService.clearCache();

      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vurgulama kaldırıldı'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vurgulama kaldırılırken bir hata oluştu'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Seçilen metni paylaş
  void _shareSelectedText(String selectedText) {
    TextSelectionHelper.shareSelectedText(
      selectedText,
      _highlights,
      _selectedStartIndex,
      _selectedEndIndex,
      widget.bookCode,
      widget.pageNumber,
    );
  }

  // Özel context menüsü oluştur
  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    return TextContextMenu(
      editableTextState: editableTextState,
      selectedText: _selectedText,
      selectedStartIndex: _selectedStartIndex,
      selectedEndIndex: _selectedEndIndex,
      highlights: _highlights,
      onRemoveHighlight: _removeHighlight,
      onShowColorPicker: _showColorPickerDialog,
      onSearch: widget.onSearch,
      onShareText: _shareSelectedText,
    );
  }

  // Metin seçimi değiştiğinde
  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause, String fullText,
      [int baseOffset = 0]) {
    TextSelectionHelper.handleSelectionChanged(
      selection,
      cause,
      fullText,
      baseOffset,
      (selectedText, startIndex, endIndex) {
        setState(() {
          _selectedText = selectedText;
          _selectedStartIndex = startIndex;
          _selectedEndIndex = endIndex;
        });
      },
      _highlights, // Vurgulanmış metinleri geçir
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sayfa içeriğini parse et
    final parsedElements = HtmlParser.parseHtmlString(widget.bookPage.pageText);
    final hasImage = parsedElements.any((element) => element['type'] == 'image');

    // İçerik tipine göre uygun görünümü oluştur
    if (hasImage) {
      return _buildCombinedView(parsedElements);
    } else {
      return _buildTextView(parsedElements);
    }
  }

  Widget _buildCombinedView(List<Map<String, dynamic>> parsedElements) {
    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: () {
            widget.onFullScreenChanged(!widget.isFullScreen);
          },
          child: Container(
            color: widget.backgroundColor,
            padding: EdgeInsets.only(
              left: widget.isFullScreen ? 12.0 : 12.0,
              top: widget.isFullScreen ? 24.0 : 16.0,
              bottom: widget.isFullScreen ? 24.0 : 16.0,
              right: widget.isFullScreen ? 12.0 : 12.0,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                  right: 0.0, // Removed right padding to align with scrollbar
                  left: 4.0,
                  top: 4.0,
                  bottom: 4.0),
              child: ContentViewBuilder.buildCombinedView(
                parsedElements: parsedElements,
                highlights: _highlights,
                backgroundColor: widget.backgroundColor,
                fontSize: widget.fontSize,
                isImageFullScreen: _isImageFullScreen,
                onSelectionChanged: _handleSelectionChanged,
                contextMenuBuilder: _buildContextMenu,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextView(List<Map<String, dynamic>> parsedElements) {
    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: () {
            widget.onFullScreenChanged(!widget.isFullScreen);
          },
          child: Container(
            color: widget.backgroundColor,
            padding: EdgeInsets.only(
              left: widget.isFullScreen ? 12.0 : 12.0,
              top: widget.isFullScreen ? 24.0 : 16.0,
              bottom: widget.isFullScreen ? 24.0 : 16.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    right:
                        4.0), // Increased padding to create more space between text and scrollbar
                child: ContentViewBuilder.buildTextView(
                  parsedElements: parsedElements,
                  highlights: _highlights,
                  backgroundColor: widget.backgroundColor,
                  fontSize: widget.fontSize,
                  scrollController: _scrollController,
                  onSelectionChanged: _handleSelectionChanged,
                  contextMenuBuilder: _buildContextMenu,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
