import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/services/api_service.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';

class BookPageManager {
  final String bookCode;
  final ApiService apiService;
  final BookProgressService bookProgressService;
  final Function(BookPageModel) onPageLoaded;
  final Function(int) onPageChanged;

  Map<int, BookPageModel> _pageCache = {};
  bool _isLoadingPage = false;
  int _currentPage = 1;

  BookPageManager({
    required this.bookCode,
    required this.apiService,
    required this.bookProgressService,
    required this.onPageLoaded,
    required this.onPageChanged,
  }) {
    _currentPage = bookProgressService.getCurrentPage(bookCode);
  }

  int get currentPage => _currentPage;
  bool get isFirstPage => bookProgressService.isFirstPage(bookCode, _currentPage);
  bool get isLastPage => _currentPage >= bookProgressService.getTotalPages(bookCode);

  Future<void> initializeFirstPage() async {
    try {
      // Önce mevcut sayfayı kontrol et
      final bookPage = await apiService.getBookPage(bookCode, _currentPage);

      // Eğer sayfa boşsa, geçerli bir sayfa bulmak için loadPage metodunu kullan
      if (bookPage.pageText.trim().isEmpty) {
        print('İlk sayfa boş, geçerli bir sayfa aranıyor...');
        await loadPage(_currentPage + 1, isForward: true);
      } else {
        // Sayfa boş değilse, cache'e ekle ve kullan
        _pageCache[_currentPage] = bookPage;
        onPageLoaded(bookPage);
        print('İlk sayfa yüklendi: $_currentPage');
      }

      // Sonraki ve önceki sayfaları ön belleğe al
      preloadAdjacentPages(_currentPage);
    } catch (e) {
      print('İlk sayfayı yükleme hatası: $e');
      // Hata durumunda bir sonraki sayfayı denemeyi dene
      await loadPage(_currentPage + 1, isForward: true);
    }
  }

  Future<void> preloadAdjacentPages(int currentPage) async {
    final prevPage = currentPage - 1;
    final nextPage = currentPage + 1;

    if (prevPage > 0 && !_pageCache.containsKey(prevPage)) {
      try {
        final page = await apiService.getBookPage(bookCode, prevPage);
        if (page.pageText.trim().isNotEmpty) {
          _pageCache[prevPage] = page;
        }
      } catch (e) {
        print('Error preloading previous page: $e');
      }
    }

    if (!_pageCache.containsKey(nextPage)) {
      try {
        final page = await apiService.getBookPage(bookCode, nextPage);
        if (page.pageText.trim().isNotEmpty) {
          _pageCache[nextPage] = page;
        }
      } catch (e) {
        print('Error preloading next page: $e');
      }
    }
  }

  Future<BookPageModel> getPageFromCacheOrLoad(int pageNumber) async {
    // Önce cache'de var mı kontrol et
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    try {
      // Cache'de yoksa API'den yükle
      final page = await apiService.getBookPage(bookCode, pageNumber);

      // Boş olmayan sayfaları cache'e ekle
      if (page.pageText.trim().isNotEmpty) {
        _pageCache[pageNumber] = page;
        return page;
      }

      // Eğer sayfa boşsa, bir sonraki sayfayı dene (maksimum 5 deneme)
      int currentAttempt = pageNumber + 1;
      int maxAttempts = 5;
      int attemptCount = 0;

      while (attemptCount < maxAttempts) {
        // Geçersiz sayfa numaralarını kontrol et
        if (currentAttempt > bookProgressService.getTotalPages(bookCode)) {
          break;
        }

        // Sonraki sayfayı yüklemeyi dene
        try {
          final nextPage = await apiService.getBookPage(bookCode, currentAttempt);
          if (nextPage.pageText.trim().isNotEmpty) {
            _pageCache[currentAttempt] = nextPage;
            // Boş sayfayı atlayıp geçerli sayfaya geçtiğimizi bildir
            print('Skipped empty page $pageNumber, found valid page $currentAttempt');
            return nextPage;
          }
        } catch (e) {
          print('Error loading next page $currentAttempt: $e');
        }

        currentAttempt++;
        attemptCount++;
      }

      // Eğer geçerli bir sayfa bulunamadıysa, orijinal boş sayfayı döndür
      return page;
    } catch (e) {
      print('Error in getPageFromCacheOrLoad for page $pageNumber: $e');
      // Hata durumunda boş bir sayfa modeli döndür
      return BookPageModel(
        audio: 0,
        pageText: 'Sayfa yüklenirken bir hata oluştu: $e',
        mp3: [],
      );
    }
  }

  Future<void> loadPage(int pageNumber, {bool isForward = true}) async {
    if (_isLoadingPage) return;
    _isLoadingPage = true;

    try {
      BookPageModel? bookPage;
      int currentAttempt = pageNumber;
      int maxAttempts = 10; // Maksimum deneme sayısını artırıyorum (5'ten 10'a)
      int attemptCount = 0;

      // Geçerli bir sayfa bulana kadar veya maksimum deneme sayısına ulaşana kadar dene
      while (attemptCount < maxAttempts) {
        print('Attempting to load page $currentAttempt (attempt ${attemptCount + 1}/$maxAttempts)');

        // Önce cache'de var mı kontrol et
        if (_pageCache.containsKey(currentAttempt)) {
          bookPage = _pageCache[currentAttempt];
          if (bookPage!.pageText.trim().isNotEmpty) {
            print('Found valid page $currentAttempt in cache');
            break;
          }
        } else {
          // Cache'de yoksa API'den yükle
          try {
            bookPage = await apiService.getBookPage(bookCode, currentAttempt);

            // Boş olmayan sayfaları cache'e ekle
            if (bookPage.pageText.trim().isNotEmpty) {
              _pageCache[currentAttempt] = bookPage;
              print('Loaded valid page $currentAttempt from API');
              break;
            } else {
              print('Page $currentAttempt is empty, trying next page');
            }
          } catch (e) {
            print('Error loading page $currentAttempt: $e');
          }
        }

        // Bir sonraki sayfayı dene
        currentAttempt = isForward ? currentAttempt + 1 : currentAttempt - 1;

        // Geçersiz sayfa numaralarını kontrol et
        if (currentAttempt < 1 || currentAttempt > bookProgressService.getTotalPages(bookCode)) {
          print('Reached invalid page number: $currentAttempt');
          break;
        }

        attemptCount++;
      }

      // Eğer geçerli bir sayfa bulunamadıysa, orijinal sayfada kal
      if (bookPage == null || bookPage.pageText.trim().isEmpty) {
        print('No valid page found after $attemptCount attempts');
        _isLoadingPage = false;
        return;
      }

      // Geçerli bir sayfa bulundu, sayfayı güncelle
      print('Updating to valid page $currentAttempt');
      await bookProgressService.setCurrentPage(bookCode, currentAttempt);
      _currentPage = currentAttempt;
      onPageLoaded(bookPage);
      onPageChanged(currentAttempt);

      // Sonraki ve önceki sayfaları ön belleğe al
      preloadAdjacentPages(currentAttempt);
    } catch (e) {
      print('Error in loadPage method: $e');
    } finally {
      _isLoadingPage = false;
    }
  }

  Future<void> goToPage(int pageNumber) async {
    int validPage = pageNumber;

    // Sayfa sınırlarını kontrol et
    if (validPage < bookProgressService.getFirstValidPage(bookCode)) {
      validPage = bookProgressService.getFirstValidPage(bookCode);
    } else if (validPage > bookProgressService.getTotalPages(bookCode)) {
      validPage = bookProgressService.getTotalPages(bookCode);
    }

    // Eğer geçerli sayfa zaten yüklenmişse, tekrar yükleme
    if (validPage == _currentPage) {
      return;
    }

    await loadPage(validPage, isForward: validPage > _currentPage);
  }

  Future<void> nextPage() async {
    if (!isLastPage) {
      await loadPage(_currentPage + 1, isForward: true);
    }
  }

  Future<void> previousPage() async {
    if (!isFirstPage) {
      await loadPage(_currentPage - 1, isForward: false);
    }
  }
}
