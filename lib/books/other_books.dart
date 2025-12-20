import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/books/pdf_viewer_page.dart';
import 'package:namaz_vakti_app/quran/screens/modular_quran_page_screen.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_bookmark_indicator.dart';

class OtherBooksPage extends StatefulWidget {
  final String language;
  
  const OtherBooksPage({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  State<OtherBooksPage> createState() => OtherBooksPageState();
}

class OtherBooksPageState extends State<OtherBooksPage> {
  List<BookItem> books = [];
  bool _isLoading = true;
  String? _error;
  int _bookmarkRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      books = [];
    });

    try {
      final url = 'https://www.hakikatkitabevi.net/?listBook=${widget.language}';
      print('Loading books from: $url');
      
      // Create Dio instance with custom configuration
      final dio = Dio();
      
      // Configure Dio to handle malformed headers and network issues
      dio.options.connectTimeout = Duration(seconds: 15);
      dio.options.receiveTimeout = Duration(seconds: 15);
      dio.options.sendTimeout = Duration(seconds: 15);
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;
      
      // Add interceptor to handle malformed content-type headers
      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          // Fix malformed content-type header if present
          final contentType = response.headers.value('content-type');
          if (contentType != null) {
            // Handle various malformed content-type patterns
            if (contentType.contains('charset=utf-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            } else if (contentType.contains('charset: UTF-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            } else if (contentType.contains('text/html; charset: UTF-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          print('Dio error: ${error.message}');
          print('Error type: ${error.type}');
          if (error.response != null) {
            print('Response status: ${error.response?.statusCode}');
            print('Response data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ));
      
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.plain, // Get response as plain text
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.data.length}');
      
      if (response.statusCode == 200) {
        final parsedBooks = _parseBooksFromHtml(response.data);
        print('Parsed ${parsedBooks.length} books from website');
        
        if (!mounted) return;
        
        // Kuran'ı her zaman ilk sıraya ekle
        final quran = BookItem(
          code: 'quran',
          title: _getQuranTitle(),
        );
        
        // Kuran'ı listede yoksa başa ekle
        final finalBooks = [quran];
        for (final book in parsedBooks) {
          if (book.code != 'quran') {
            finalBooks.add(book);
          }
        }
        
        setState(() {
          books = finalBooks;
          _isLoading = false;
        });
        
        if (parsedBooks.isEmpty) {
          if (!mounted) return;
          setState(() {
            _error = 'No books found on the website for language: ${widget.language}';
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              _error = 'Connection timeout. Please check your internet connection.';
              break;
            case DioExceptionType.sendTimeout:
              _error = 'Send timeout. Please try again.';
              break;
            case DioExceptionType.receiveTimeout:
              _error = 'Receive timeout. Please try again.';
              break;
            case DioExceptionType.badResponse:
              _error = 'Server error: ${e.response?.statusCode}';
              break;
            case DioExceptionType.cancel:
              _error = 'Request was cancelled.';
              break;
            case DioExceptionType.connectionError:
              _error = 'Connection error. Please check your internet connection.';
              break;
            default:
              _error = 'Network error: ${e.message}';
          }
        } else {
          _error = 'Unexpected error: $e';
        }
      });
      print('Error loading books from website: $e');
    }
  }

  List<BookItem> _parseBooksFromHtml(String html) {
    final List<BookItem> books = [];
    
    print('HTML length: ${html.length}');
    print('HTML preview: ${html.substring(0, html.length > 500 ? 500 : html.length)}...');
    
    // Farklı link formatlarını dene
    final List<RegExp> patterns = [
      // Format 1: <a href="book.php?bookCode=123" title="Kitap Adı">
      RegExp(r'<a[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*title="([^"]*)"[^>]*>'),
      // Format 2: <a href="book.php?bookCode=123&listBook=en" title="Kitap Adı">
      RegExp(r'<a[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*title="([^"]*)"[^>]*>'),
      // Format 3: <a title="Kitap Adı" href="book.php?bookCode=123">
      RegExp(r'<a[^>]*title="([^"]*)"[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*>'),
      // Format 4: Sadece bookCode içeren linkler
      RegExp(r'<a[^>]*href="[^"]*bookCode=(\d+)[^"]*"[^>]*>([^<]*)</a>'),
      // Format 5: img taglarından kitap kodu çıkar
      RegExp(r'<img[^>]*src="[^"]*images/books/(\d+)\.png[^"]*"[^>]*(?:title="([^"]*)")?[^>]*>'),
      // Format 6: Daha genel bookCode arama
      RegExp(r'bookCode=(\d+)'),
    ];
    
    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = pattern.allMatches(html);
      print('Pattern ${i + 1} found ${matches.length} matches');
      
      for (final match in matches) {
        String? code;
        String? title;
        
        if (i == 2) {
          // Format 3 için title ve code yer değiştirmiş
          title = match.group(1);
          code = match.group(2);
        } else if (i == 3) {
          // Format 4 için title ikinci grup
          code = match.group(1);
          title = match.group(2);
        } else if (i == 4) {
          // Format 5 için img tagından
          code = match.group(1);
          title = match.group(2) ?? 'Book $code';
        } else if (i == 5) {
          // Format 6 için sadece code
          code = match.group(1);
          title = 'Book $code';
        } else {
          // Diğer formatlar için normal sıra
          code = match.group(1);
          title = match.group(2);
        }
        
        if (code != null && title != null && title.trim().isNotEmpty) {
          // Duplicate kontrolü
          if (!books.any((book) => book.code == code)) {
            books.add(BookItem(
              code: code,
              title: title.trim(),
            ));
            print('Added book: $code - $title');
          }
        }
      }
    }
    
    print('Total parsed books: ${books.length}');
    return books;
  }



  String _getQuranTitle() {
    switch (widget.language) {
      case 'en':
        return 'Holy Quran';
      case 'ar':
        return 'القرآن الكريم';
      case 'fr':
        return 'Saint Coran';
      case 'de':
        return 'Heiliger Koran';
      case 'es':
        return 'Sagrado Corán';
      case 'it':
        return 'Sacro Corano';
      default:
        return 'Kur\'an-ı Kerim';
    }
  }

  String _getLoadingText() {
    switch (widget.language) {
      case 'en':
        return 'Loading books...';
      case 'ar':
        return 'جاري تحميل الكتب...';
      case 'fr':
        return 'Chargement des livres...';
      case 'de':
        return 'Bücher werden geladen...';
      case 'es':
        return 'Cargando libros...';
      case 'it':
        return 'Caricamento libri...';
      default:
        return 'Loading books...';
    }
  }

  String _getNoBooksText() {
    switch (widget.language) {
      case 'en':
        return 'No books found in this language.';
      case 'ar':
        return 'لم يتم العثور على كتب بهذه اللغة.';
      case 'fr':
        return 'Aucun livre trouvé dans cette langue.';
      case 'de':
        return 'Keine Bücher in dieser Sprache gefunden.';
      case 'es':
        return 'No se encontraron libros en este idioma.';
      case 'it':
        return 'Nessun libro trovato in questa lingua.';
      default:
        return 'No books found in this language.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  _getLoadingText(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBooks,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : books.isEmpty
                ? Center(
                    child: Text(
                      _getNoBooksText(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 16.0,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _buildBookCard(book);
                      },
                    ),
                  );
  }

  Widget _buildBookCard(BookItem book) {
    return Consumer<ChangeSettings>(
      builder: (context, settings, child) {
        return GestureDetector(
          onTap: () {
            // Kitap PDF'ini uygulama içinde aç
            _openBookPDF(book);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Kuran için özel resim, diğerleri için network resmi
                  book.code == 'quran'
                      ? Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Image.asset(
                            'assets/book_covers/quran_other.png',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.menu_book,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        )
                      : Image.network(
                          'https://www.hakikatkitabevi.net/images/books/${book.code}.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.book,
                                color: Colors.grey[600],
                                size: 40,
                              ),
                            );
                          },
                        ),
                  // Quran için bookmark badge
                  if (book.code == 'quran')
                    Positioned(
                      top: 1,
                      left: 10,
                      child: BookBookmarkIndicator(
                        key: ValueKey('${book.code}_$_bookmarkRefreshCounter'),
                        bookCode: book.code,
                        color: settings.color,
                      ),
                    ),
                  // Info badge - sadece Kuran için değil
                  if (book.code != 'quran')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // Info badge'e tıklayınca açıklama göster
                          _openBookDetail(book);
                        },
                        child: CustomPaint(
                          painter: BadgePainter(settings.color),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openBookDetail(BookItem book) {
    // Kitap detay sayfasını aç
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 0,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: FutureBuilder<String?>(
                future: _fetchBookDescription(book.code),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading description...'),
                        ],
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading description: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    );
                  }
                  
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Text(
                      'No description available for this book.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  
                  return Text(
                    snapshot.data!,
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Web sitesinde kitabı aç
                    await _openBookInWebsite(book);
                  },
                  child: Text('www.hakikatkitabevi.net'),
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBookInWebsite(BookItem book) async {
    try {
      final url = 'https://www.hakikatkitabevi.net/book.php?bookCode=${book.code}&listBook=${widget.language}';
      print('Opening: $url');
      
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('URL successfully opened');
      } else {
        print('Could not launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open website. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening website: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openBookPDF(BookItem book) {
    if (book.code == 'quran') {
      // Kuran için özel ekran
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModularQuranPageScreen(),
        ),
      ).then((_) {
        // Quran'dan geri döndüğünde bookmark göstergelerini yenile
        debugPrint('OtherBooksPage: Returned from Quran, refreshing bookmark indicators');
        refreshBookmarkIndicators();
      });
    } else {
      // Diğer kitaplar için PDF viewer
      final pdfUrl = 'https://www.hakikatkitabevi.net/public/book.download.php?view=1&type=PDF&bookCode=${book.code}';
      print('Opening PDF: $pdfUrl');
      
      // PDF viewer sayfasını aç
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: pdfUrl,
            bookCode: book.code,
            bookTitle: book.title,
          ),
        ),
      );
    }
  }

  Future<String?> _fetchBookDescription(String bookCode) async {
    try {
      final url = 'https://www.hakikatkitabevi.net/book.php?bookCode=$bookCode&listBook=${widget.language}';
      print('Fetching book description from: $url');
      
      // Create Dio instance with custom configuration
      final dio = Dio();
      
      // Configure Dio to handle malformed headers and network issues
      dio.options.connectTimeout = Duration(seconds: 15);
      dio.options.receiveTimeout = Duration(seconds: 15);
      dio.options.sendTimeout = Duration(seconds: 15);
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;
      
      // Add interceptor to handle malformed content-type headers
      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          // Fix malformed content-type header if present
          final contentType = response.headers.value('content-type');
          if (contentType != null) {
            // Handle various malformed content-type patterns
            if (contentType.contains('charset=utf-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            } else if (contentType.contains('charset: UTF-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            } else if (contentType.contains('text/html; charset: UTF-8;charset=utf-8')) {
              response.headers.set('content-type', 'text/html; charset=utf-8');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          print('Dio error while fetching description: ${error.message}');
          handler.next(error);
        },
      ));
      
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      if (response.statusCode == 200) {
        return _parseBookDescription(response.data);
      }
      
      return null;
    } catch (e) {
      print('Error fetching book description: $e');
      return null;
    }
  }

  String? _parseBookDescription(String html) {
    try {
      // Önce detaylı açıklamayı bulmaya çalış (bdetail div'i içinde)
      final RegExp detailedDescriptionPattern = RegExp(
        r'<div[^>]*id="bdetail"[^>]*style="[^"]*"[^>]*align="justify"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      
      final detailedMatch = detailedDescriptionPattern.firstMatch(html);
      if (detailedMatch != null && detailedMatch.groupCount > 0) {
        String description = detailedMatch.group(1) ?? '';
        
        // HTML taglarını temizle ama paragraf yapısını koru
        description = description
            .replaceAll(RegExp(r'<p[^>]*>'), '\n\n') // <p> taglarını çift satır sonu ile değiştir
            .replaceAll(RegExp(r'</p>'), '') // </p> taglarını kaldır
            .replaceAll(RegExp(r'<[^>]*>'), '') // Diğer HTML taglarını kaldır
            .replaceAll(RegExp(r'&nbsp;'), ' ') // &nbsp; karakterlerini boşlukla değiştir
            .replaceAll(RegExp(r'&amp;'), '&') // &amp; karakterlerini & ile değiştir
            .replaceAll(RegExp(r'&lt;'), '<') // &lt; karakterlerini < ile değiştir
            .replaceAll(RegExp(r'&gt;'), '>') // &gt; karakterlerini > ile değiştir
            .replaceAll(RegExp(r'&quot;'), '"') // &quot; karakterlerini " ile değiştir
            .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Çoklu satır sonlarını temizle
            .trim();
        
        if (description.isNotEmpty) {
          print('Found detailed description: $description');
          return description;
        }
      }
      
      // Eğer detaylı açıklama bulunamazsa, kısa açıklamayı dene
      final RegExp shortDescriptionPattern = RegExp(
        r'<td[^>]*valign="top"[^>]*width="610"[^>]*>.*?<div[^>]*style="padding-right:20px;"[^>]*align="(?:justify|right)"[^>]*dir="(?:rtl|)"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      
      final shortMatch = shortDescriptionPattern.firstMatch(html);
      if (shortMatch != null && shortMatch.groupCount > 0) {
        String description = shortMatch.group(1) ?? '';
        
        // HTML taglarını temizle
        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '') // HTML taglarını kaldır
            .replaceAll(RegExp(r'&nbsp;'), ' ') // &nbsp; karakterlerini boşlukla değiştir
            .replaceAll(RegExp(r'&amp;'), '&') // &amp; karakterlerini & ile değiştir
            .replaceAll(RegExp(r'&lt;'), '<') // &lt; karakterlerini < ile değiştir
            .replaceAll(RegExp(r'&gt;'), '>') // &gt; karakterlerini > ile değiştir
            .replaceAll(RegExp(r'&quot;'), '"') // &quot; karakterlerini " ile değiştir
            .trim();
        
        if (description.isNotEmpty) {
          print('Found short description: $description');
          return description;
        }
      }
      
      // Son alternatif - daha genel arama
      final RegExp altPattern = RegExp(
        r'<div[^>]*style="padding-right:20px;"[^>]*align="(?:justify|right)"[^>]*dir="(?:rtl|)"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      
      final altMatch = altPattern.firstMatch(html);
      if (altMatch != null && altMatch.groupCount > 0) {
        String description = altMatch.group(1) ?? '';
        
        // HTML taglarını temizle
        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .trim();
        
        if (description.isNotEmpty) {
          print('Found description with alt pattern: $description');
          return description;
        }
      }
      
      // En genel arama - sadece padding-right:20px olan div'leri ara
      final RegExp generalPattern = RegExp(
        r'<div[^>]*style="[^"]*padding-right:20px[^"]*"[^>]*>(.*?)</div>',
        dotAll: true,
      );
      
      final generalMatch = generalPattern.firstMatch(html);
      if (generalMatch != null && generalMatch.groupCount > 0) {
        String description = generalMatch.group(1) ?? '';
        
        // HTML taglarını temizle
        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .trim();
        
        if (description.isNotEmpty) {
          print('Found description with general pattern: $description');
          return description;
        }
      }
      
      print('No description found in HTML');
      return null;
    } catch (e) {
      print('Error parsing book description: $e');
      return null;
    }
  }

  // Yer işareti göstergelerini yenilemek için public metod
  void refreshBookmarkIndicators() {
    if (mounted) {
      debugPrint('OtherBooksPage: refreshBookmarkIndicators called, counter: $_bookmarkRefreshCounter -> ${_bookmarkRefreshCounter + 1}');
      setState(() {
        // Yer işareti göstergelerini yenilemek için sayacı artır
        _bookmarkRefreshCounter++;
      });
    }
  }
}

class BadgePainter extends CustomPainter {
  final Color color;
  
  BadgePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Üst kenar - düz
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    
    // Sağ kenar
    path.lineTo(size.width, size.height - 8);
    
    // Alt kenar - yılan dili (tırtıklı)
    final toothWidth = 4.0;
    final toothHeight = 6.0;
    double x = size.width;
    double y = size.height - 8;
    
    while (x > 0) {
      x -= toothWidth;
      if (x < 0) x = 0;
      path.lineTo(x, y);
      
      if (x > 0) {
        x -= toothWidth;
        if (x < 0) x = 0;
        path.lineTo(x, y + toothHeight);
      }
    }
    
    // Sol kenar
    path.lineTo(0, size.height - 8);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Gölge efekti
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
    
    final shadowPath = Path();
    shadowPath.addPath(path, Offset(0, 2));
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BookItem {
  final String code;
  final String title;
  final String? description;

  BookItem({
    required this.code,
    required this.title,
    this.description,
  });
}