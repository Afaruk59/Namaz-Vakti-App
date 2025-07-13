import 'package:flutter/material.dart';
import '../services/quran_progress_service.dart';
import '../models/quran_book_model.dart';
import '../services/takipli_quran_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kuran sayfası kontrolcüsü
class QuranPageController extends ChangeNotifier {
  late QuranBook _quranBook;
  late int _currentPage;
  late PageController _pageController;
  final Map<int, NetworkImage> _pageCache = {};
  final Map<int, Map<String, dynamic>> _pageDataCache = {};
  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, GlobalKey> _wordKeys = {};

  double _progress = 0.0;
  bool _isFullScreen = false;
  bool _isAutoScroll = true;
  String _selectedFont = 'Shaikh Hamdullah';
  double _fontSize = 32.0;

  final QuranProgressService _progressService = QuranProgressService();
  final TakipliQuranService _takipliService = TakipliQuranService();

  static Color _backgroundColor = Colors.white;

  // Getters
  QuranBook get quranBook => _quranBook;
  int get currentPage => _currentPage;
  PageController get pageController => _pageController;
  double get progress => _progress;
  bool get isFullScreen => _isFullScreen;
  bool get isAutoScroll => _isAutoScroll;
  String get selectedFont => _selectedFont;
  double get fontSize => _fontSize;
  Map<int, GlobalKey> get wordKeys => _wordKeys;
  TakipliQuranService get takipliService => _takipliService;
  Color get backgroundColor => _backgroundColor;
  bool get isAutoBackground => false;

  final List<Map<String, String>> _availableFonts = [
    {'name': 'Shaikh Hamdullah', 'displayName': 'Font 1'},
    {'name': 'AlQuran Ali', 'displayName': 'Font 2'},
    {'name': 'Hasenat', 'displayName': 'Font 3'},
    {'name': 'Arabic Type', 'displayName': 'Font 4'},
    {'name': 'Majalla', 'displayName': 'Font 5'},
    {'name': 'Simplified Arabic', 'displayName': 'Font 6'},
    {'name': 'Traditional Arabic', 'displayName': 'Font 7'},
  ];

  List<Map<String, String>> get availableFonts => _availableFonts;

  QuranPageController({
    int initialPage = 0,
    String initialFormat = 'Mukabele',
  }) {
    _currentPage = initialPage;
    _quranBook = QuranBook(selectedFormat: initialFormat);
    _pageController = PageController(initialPage: _currentPage);
    _loadBackgroundColor();
  }

  /// Controller'ı başlatır ve kaydedilmiş tercihleri yükler
  Future<void> init() async {
    await _loadSavedPreferences();
  }

  /// Kaynakları temizler
  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    super.dispose();
  }

  /// Kaydedilmiş tercihleri yükler
  Future<void> _loadSavedPreferences() async {
    final savedPage = await _progressService.getCurrentPage();
    final savedFormat = await _progressService.getFormat();
    final savedProgress = await _progressService.getProgressAsync();

    // Only use the saved page if initialPage is 0 (default value)
    // If initialPage was explicitly set, respect that value
    if (_currentPage == 0) {
      _currentPage = savedPage;
      _pageController.jumpToPage(_currentPage);
    } else {
      // initialPage was set by the constructor, save it as the current page
      await _progressService.setCurrentPage(_currentPage);
    }

    if (savedFormat != _quranBook.selectedFormat) {
      _quranBook = QuranBook(selectedFormat: savedFormat);
    }

    _progress = savedProgress;

    // Kaydedilmiş font ayarını yükle
    print('Saved font: $_selectedFont');

    // Kaydedilmiş yazı boyutunu yükle
    print('Saved font size: $_fontSize');

    // Kaydedilmiş otomatik kaydırma ayarını yükle
    print('Saved auto scroll: $_isAutoScroll');

    notifyListeners();
  }

  /// Tam ekran modunu değiştirir
  void toggleFullScreen() {
    print('toggleFullScreen çağrıldı. Mevcut durum: $_isFullScreen');
    _isFullScreen = !_isFullScreen;
    print('Yeni tam ekran durumu: $_isFullScreen');
    // Değişikliği hemen bildir
    notifyListeners();
  }

  /// Yazı tipini değiştirir
  void setFont(String font) {
    // Geçerli bir font adı olup olmadığını kontrol et
    bool isValidFont = _availableFonts.any((f) => f['name'] == font);
    if (!isValidFont) {
      // Geçerli bir font değilse, varsayılan fontu kullan
      font = 'Shaikh Hamdullah';
    }

    _selectedFont = font;
    // Font değiştiğinde sayfa verilerinin önbelleğini temizleme - sadece görünümü güncelle
    // _pageDataCache.clear();
    // Font bilgisini kaydet
    notifyListeners();
  }

  /// Yazı boyutunu değiştirir
  void setFontSize(double size) {
    _fontSize = size;
    // Yazı boyutunu kaydet
    notifyListeners();
  }

  /// Sayfa formatını değiştirir
  void changeFormat(String newFormat) {
    // Eğer aynı format seçildiyse işlem yapma
    if (_quranBook.selectedFormat == newFormat) {
      return;
    }

    // Mevcut sayfa numarasını ve tam ekran durumunu kaydet
    int currentPageBeforeFormatChange = _currentPage;
    bool wasFullScreen = _isFullScreen;
    print(
        'Format değişimi: Mevcut sayfa: $currentPageBeforeFormatChange, Tam ekran: $wasFullScreen, Yeni format: $newFormat');

    // Yeni format ile QuranBook nesnesini güncelle
    _quranBook = QuranBook(selectedFormat: newFormat);

    // Önbellekleri temizle
    _pageCache.clear();
    _pageDataCache.clear();

    // Formatı kaydet
    _progressService.setFormat(newFormat);

    // Sayfa numarasını koruyarak sayfayı güncelle
    _currentPage = currentPageBeforeFormatChange;

    // Tam ekran durumunu koru
    _isFullScreen = wasFullScreen;
    print('Format değişimi sonrası tam ekran durumu: $_isFullScreen');

    // PageController'ı yeniden oluştur ve doğru sayfaya ayarla
    final oldController = _pageController;
    _pageController =
        PageController(initialPage: currentPageBeforeFormatChange);

    // Eski controller'ı dispose et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
    });

    // Sayfa değişimini kaydet
    _saveCurrentPage();

    // Yeni format için sayfaları önbelleğe al
    _preloadAdjacentPages(_currentPage);

    print(
        'Format değişimi tamamlandı: Sayfa: $_currentPage, Format: $newFormat');

    // Değişiklikleri bildir
    notifyListeners();
  }

  /// Belirli bir sayfaya geçer
  void changePage(int pageNumber) {
    // Sayfa numarası kontrolü
    if (pageNumber < 0 || pageNumber > 604) {
      print('Geçersiz sayfa numarası: $pageNumber');
      return;
    }

    // Sayfa numarasını güncelle
    _currentPage = pageNumber;

    // PageView'ı güncelle
    if (pageController.hasClients) {
      pageController.jumpToPage(pageNumber);
    }

    // Sayfa değişimini kaydet
    _saveCurrentPage();

    // Sayfa değişimini bildir
    notifyListeners();
  }

  /// Sayfa değiştiğinde çağrılır
  void onPageChanged(int index) {
    // Sayfa numarası kontrolü
    if (index < 0 || index > 604) {
      print('Geçersiz sayfa numarası: $index');
      return;
    }

    // Mevcut sayfa numarasını güncelle
    _currentPage = index;

    // Sayfa değişimini kaydet
    _saveCurrentPage();

    // Sayfa değişimini bildir
    notifyListeners();
  }

  /// Önceki ve sonraki sayfaları önbelleğe alır
  Future<void> preloadAdjacentPages(BuildContext context) async {
    _preloadAdjacentPages(_currentPage);
  }

  /// Önceki ve sonraki sayfaları önbelleğe alır
  Future<void> _preloadAdjacentPages(int currentPage) async {
    final prevPage = currentPage - 1;
    final nextPage = currentPage + 1;

    // Önceki sayfa için önbellekleme
    if (prevPage >= 0 && !_pageDataCache.containsKey(prevPage)) {
      try {
        final prevData = await _takipliService.getPageData(prevPage);
        _pageDataCache[prevPage] = prevData;
      } catch (e) {
        print('Önceki sayfa önbellekleme hatası: $e');
      }
    }

    // Sonraki sayfa için önbellekleme
    if (nextPage <= 604 && !_pageDataCache.containsKey(nextPage)) {
      try {
        final nextData = await _takipliService.getPageData(nextPage);
        _pageDataCache[nextPage] = nextData;
      } catch (e) {
        print('Sonraki sayfa önbellekleme hatası: $e');
      }
    }

    // Uzak sayfaları önbellekten temizle
    _cleanPageCache(currentPage);
  }

  /// Önbellekten sayfa alır veya yükler
  NetworkImage getPageFromCacheOrLoad(int pageNumber) {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final newImage = NetworkImage(_quranBook.getPageImageUrl(pageNumber));
    _pageCache[pageNumber] = newImage;
    return newImage;
  }

  /// Mevcut sayfanın verilerini yükler
  Future<Map<String, dynamic>> loadCurrentPageData() async {
    final currentDisplayPage = _currentPage;

    try {
      // Önbellekte veri varsa onu kullan
      if (_pageDataCache.containsKey(currentDisplayPage)) {
        return _pageDataCache[currentDisplayPage]!;
      }

      // Mevcut sayfanın verilerini yükle
      final currentData = await _takipliService.getPageData(currentDisplayPage);
      _pageDataCache[currentDisplayPage] = currentData;

      // Komşu sayfaları önbelleğe al
      _preloadAdjacentPages(currentDisplayPage);

      return currentData;
    } catch (e) {
      print('Sayfa verisi yükleme hatası: $e');
      return {};
    }
  }

  /// Belirli bir sayfa için ScrollController döndürür
  ScrollController getScrollController(int pageNumber) {
    if (!_scrollControllers.containsKey(pageNumber)) {
      _scrollControllers[pageNumber] = ScrollController();
    }
    return _scrollControllers[pageNumber]!;
  }

  /// Uzak sayfaları önbellekten temizler
  void _cleanPageCache(int currentPage) {
    final keysToRemove = _pageDataCache.keys
        .where((page) =>
            page != currentPage &&
            page != currentPage - 1 &&
            page != currentPage + 1)
        .toList();

    for (var key in keysToRemove) {
      _pageDataCache.remove(key);
    }
  }

  /// Otomatik kaydırma ayarını değiştirir
  void setAutoScroll(bool value) {
    _isAutoScroll = value;
    notifyListeners();
  }

  /// Tüm ayarları varsayılan değerlere sıfırlar
  Future<void> resetSettings(BuildContext context) async {
    // Controller'daki değerleri güncelle
    _fontSize = 32.0;
    _selectedFont = 'Hasenat';
    _isAutoScroll = true;

    // Önbelleği temizle
    _pageDataCache.clear();

    // Değişiklikleri bildir
    notifyListeners();
  }

  /// Sayfa değişimini kaydet
  void _saveCurrentPage() {
    _progressService.setCurrentPage(_currentPage);
    _progressService.setProgress(_currentPage / 604);
  }

  void setAutoBackground(bool value, [BuildContext? context]) {}
  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('book_background_color', color.value);
    } catch (e) {
      print('Kuran background color save error: $e');
    }
  }

  void updateAutoBackground(BuildContext context) {}

  Future<void> _loadBackgroundColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt('book_background_color');
      if (colorValue != null) {
        _backgroundColor = Color(colorValue);
        notifyListeners();
      }
    } catch (e) {
      print('Kuran background color load error: $e');
    }
  }
}
