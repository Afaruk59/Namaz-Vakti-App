import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProgressService {
  static final BookProgressService _instance = BookProgressService._internal();
  factory BookProgressService() => _instance;
  BookProgressService._internal();

  final Map<String, int> _totalPages = {};
  final Map<String, int> _currentPages = {};
  final Map<String, int> _firstValidPages = {};
  SharedPreferences? _prefs; // Change to nullable
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // Clear existing data when reinitializing
    _totalPages.clear();
    _currentPages.clear();

    _prefs = await SharedPreferences.getInstance();
    await _initializeTotalPages();
    _loadSavedProgress();
  }

  Future<void> _initializeTotalPages() async {
    final List<String> bookCodes = [
      '001',
      '002',
      '003',
      '004',
      '005',
      '006',
      '007',
      '008',
      '009',
      '010',
      '011',
      '012',
      '013',
      '014'
    ];

    // Tüm kitapların sayfa sayılarını paralel olarak çekelim
    final futures = bookCodes.map((bookCode) => _fetchBookTotalPages(bookCode));
    await Future.wait(futures);
  }

  Future<void> _fetchBookTotalPages(String bookCode) async {
    try {
      final maxPage = await _apiService.getBookMaxPage(bookCode);
      if (maxPage > 0) {
        _totalPages[bookCode] = maxPage;
        await _findFirstValidPage(bookCode);
      }
    } catch (e) {
      print('Error fetching total pages for book $bookCode: $e');
      try {
        final indexItems = await _apiService.getBookIndex(bookCode);
        if (indexItems.isNotEmpty) {
          int maxPage =
              indexItems.fold(0, (max, item) => item.pageNumber > max ? item.pageNumber : max);
          if (maxPage > 0) {
            _totalPages[bookCode] = maxPage;
            await _findFirstValidPage(bookCode);
          }
        }
      } catch (e) {
        print('Error fetching index for book $bookCode: $e');
      }
    }
  }

  Future<void> _findFirstValidPage(String bookCode) async {
    try {
      int firstPage = 1;
      bool foundValidPage = false;

      while (!foundValidPage && firstPage <= (_totalPages[bookCode] ?? 1)) {
        final page = await _apiService.getBookPage(bookCode, firstPage);
        if (page.pageText.trim().isNotEmpty) {
          _firstValidPages[bookCode] = firstPage;
          foundValidPage = true;
        } else {
          firstPage++;
        }
      }
    } catch (e) {
      print('Error finding first valid page for book $bookCode: $e');
      _firstValidPages[bookCode] = 1;
    }
  }

  void _loadSavedProgress() {
    if (_prefs == null) return;

    final List<String> bookCodes = [
      '001',
      '002',
      '003',
      '004',
      '005',
      '006',
      '007',
      '008',
      '009',
      '010',
      '011',
      '012',
      '013',
      '014'
    ];

    for (String bookCode in bookCodes) {
      final savedPage = _prefs?.getInt('${bookCode}_current_page');
      if (savedPage != null) {
        _currentPages[bookCode] = savedPage;
      }
    }
  }

  Future<void> refreshProgress() async {
    if (_prefs == null) {
      await initialize();
      return;
    }

    // Just reload saved progress
    _loadSavedProgress();
  }

  Future<void> setCurrentPage(String bookCode, int page) async {
    _currentPages[bookCode] = page;
    await _prefs?.setInt('${bookCode}_current_page', page);
  }

  int getFirstValidPage(String bookCode) {
    return _firstValidPages[bookCode] ?? 1;
  }

  bool isFirstPage(String bookCode, int currentPage) {
    return currentPage <= (_firstValidPages[bookCode] ?? 1);
  }

  int getCurrentPage(String bookCode) {
    return _currentPages[bookCode] ??
        _prefs?.getInt('${bookCode}_current_page') ??
        getFirstValidPage(bookCode);
  }

  int getTotalPages(String bookCode) {
    return _totalPages[bookCode] ?? 1;
  }

  // Kitabın ilk sayfasını döndürür
  Future<int> getFirstPage(String bookCode) async {
    // Eğer önbellekte yoksa, ilk geçerli sayfayı bulmak için API sorgulayalım
    if (!_firstValidPages.containsKey(bookCode)) {
      await _findFirstValidPage(bookCode);
    }
    return _firstValidPages[bookCode] ?? 1;
  }

  // Kitabın son sayfasını döndürür
  Future<int> getLastPage(String bookCode) async {
    // Eğer önbellekte yoksa, toplam sayfa sayısını almak için API sorgulayalım
    if (!_totalPages.containsKey(bookCode)) {
      await _fetchBookTotalPages(bookCode);
    }
    return _totalPages[bookCode] ?? 1;
  }

  double getProgress(String bookCode) {
    if (!_totalPages.containsKey(bookCode)) {
      return 0.0;
    }
    final currentPage = getCurrentPage(bookCode);
    final totalPages = getTotalPages(bookCode);
    return totalPages > 0 ? currentPage / totalPages : 0.0;
  }
}
