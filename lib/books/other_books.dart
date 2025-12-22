import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/books/pdf_viewer_page.dart';
import '../l10n/app_localization.dart';

class OtherBooksPage extends StatefulWidget {
  final String language;

  const OtherBooksPage({
    super.key,
    required this.language,
  });

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
      debugPrint('Loading books from: $url');

      final dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.sendTimeout = const Duration(seconds: 15);
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;

      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          final contentType = response.headers.value('content-type');
          if (contentType != null) {
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
          debugPrint('Dio error: ${error.message}');
          debugPrint('Error type: ${error.type}');
          if (error.response != null) {
            debugPrint('Response status: ${error.response?.statusCode}');
            debugPrint('Response data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ));

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.plain,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body length: ${response.data.length}');

      if (response.statusCode == 200) {
        final parsedBooks = _parseBooksFromHtml(response.data);
        debugPrint('Parsed ${parsedBooks.length} books from website');

        if (!mounted) return;

        setState(() {
          books = parsedBooks;
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
      debugPrint('Error loading books from website: $e');
    }
  }

  List<BookItem> _parseBooksFromHtml(String html) {
    final List<BookItem> books = [];

    debugPrint('HTML length: ${html.length}');
    debugPrint('HTML preview: ${html.substring(0, html.length > 500 ? 500 : html.length)}...');

    final List<RegExp> patterns = [
      RegExp(r'<a[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*title="([^"]*)"[^>]*>'),
      RegExp(r'<a[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*title="([^"]*)"[^>]*>'),
      RegExp(r'<a[^>]*title="([^"]*)"[^>]*href="[^"]*book\.php\?bookCode=(\d+)[^"]*"[^>]*>'),
      RegExp(r'<a[^>]*href="[^"]*bookCode=(\d+)[^"]*"[^>]*>([^<]*)</a>'),
      RegExp(r'<img[^>]*src="[^"]*images/books/(\d+)\.png[^"]*"[^>]*(?:title="([^"]*)")?[^>]*>'),
      RegExp(r'bookCode=(\d+)'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = pattern.allMatches(html);
      debugPrint('Pattern ${i + 1} found ${matches.length} matches');

      for (final match in matches) {
        String? code;
        String? title;

        if (i == 2) {
          title = match.group(1);
          code = match.group(2);
        } else if (i == 3) {
          code = match.group(1);
          title = match.group(2);
        } else if (i == 4) {
          code = match.group(1);
          title = match.group(2) ?? 'Book $code';
        } else if (i == 5) {
          code = match.group(1);
          title = 'Book $code';
        } else {
          code = match.group(1);
          title = match.group(2);
        }

        if (code != null && title != null && title.trim().isNotEmpty) {
          if (!books.any((book) => book.code == code)) {
            books.add(BookItem(
              code: code,
              title: title.trim(),
            ));
            debugPrint('Added book: $code - $title');
          }
        }
      }
    }

    debugPrint('Total parsed books: ${books.length}');
    return books;
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
    final l10n = AppLocalizations.of(context)!;
    return _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _getLoadingText(),
                  style: const TextStyle(
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.generalError(_error ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBooks,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              )
            : books.isEmpty
                ? Center(
                    child: Text(
                      _getNoBooksText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            _openBookPDF(book);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://www.hakikatkitabevi.net/images/books/${book.code}.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.book,
                          color: Colors.grey,
                          size: 40,
                        ),
                      );
                    },
                  ),
                  if (true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          _openBookDetail(book);
                        },
                        child: CustomPaint(
                          painter: BadgePainter(settings.color),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                            child: const Icon(
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(book.title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 0,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String?>(
                future: _fetchBookDescription(book.code),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.loadingDescription),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      '${l10n.errorLoadingDescription} ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    );
                  }

                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Text(
                      l10n.noDescriptionAvailable,
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
                    style: const TextStyle(fontSize: 14),
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
                    Navigator.of(dialogContext).pop();
                    await _openBookInWebsite(book);
                  },
                  child: const Text('www.hakikatkitabevi.net'),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBookInWebsite(BookItem book) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final url =
          'https://www.hakikatkitabevi.net/book.php?bookCode=${book.code}&listBook=${widget.language}';
      debugPrint('Opening: $url');

      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('URL successfully opened');
      } else {
        debugPrint('Could not launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.couldNotOpenWebsite),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOpeningWebsite} $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openBookPDF(BookItem book) {
    final pdfUrl =
        'https://www.hakikatkitabevi.net/public/book.download.php?view=1&type=PDF&bookCode=${book.code}';

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

  Future<String?> _fetchBookDescription(String bookCode) async {
    try {
      final url =
          'https://www.hakikatkitabevi.net/book.php?bookCode=$bookCode&listBook=${widget.language}';
      debugPrint('Fetching book description from: $url');

      final dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.sendTimeout = const Duration(seconds: 15);
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;

      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          final contentType = response.headers.value('content-type');
          if (contentType != null) {
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
          debugPrint('Dio error while fetching description: ${error.message}');
          handler.next(error);
        },
      ));

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
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
      debugPrint('Error fetching book description: $e');
      return null;
    }
  }

  String? _parseBookDescription(String html) {
    try {
      final RegExp detailedDescriptionPattern = RegExp(
        r'<div[^>]*id="bdetail"[^>]*style="[^"]*"[^>]*align="justify"[^>]*>(.*?)</div>',
        dotAll: true,
      );

      final detailedMatch = detailedDescriptionPattern.firstMatch(html);
      if (detailedMatch != null && detailedMatch.groupCount > 0) {
        String description = detailedMatch.group(1) ?? '';

        description = description
            .replaceAll(RegExp(r'<p[^>]*>'), '\n\n')
            .replaceAll(RegExp(r'</p>'), '')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
            .trim();

        if (description.isNotEmpty) {
          debugPrint('Found detailed description: $description');
          return description;
        }
      }

      final RegExp shortDescriptionPattern = RegExp(
        r'<td[^>]*valign="top"[^>]*width="610"[^>]*>.*?<div[^>]*style="padding-right:20px;"[^>]*align="(?:justify|right)"[^>]*dir="(?:rtl|)"[^>]*>(.*?)</div>',
        dotAll: true,
      );

      final shortMatch = shortDescriptionPattern.firstMatch(html);
      if (shortMatch != null && shortMatch.groupCount > 0) {
        String description = shortMatch.group(1) ?? '';

        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .trim();

        if (description.isNotEmpty) {
          debugPrint('Found short description: $description');
          return description;
        }
      }

      final RegExp altPattern = RegExp(
        r'<div[^>]*style="padding-right:20px;"[^>]*align="(?:justify|right)"[^>]*dir="(?:rtl|)"[^>]*>(.*?)</div>',
        dotAll: true,
      );

      final altMatch = altPattern.firstMatch(html);
      if (altMatch != null && altMatch.groupCount > 0) {
        String description = altMatch.group(1) ?? '';

        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .trim();

        if (description.isNotEmpty) {
          debugPrint('Found description with alt pattern: $description');
          return description;
        }
      }

      final RegExp generalPattern = RegExp(
        r'<div[^>]*style="[^"]*padding-right:20px[^"]*"[^>]*>(.*?)</div>',
        dotAll: true,
      );

      final generalMatch = generalPattern.firstMatch(html);
      if (generalMatch != null && generalMatch.groupCount > 0) {
        String description = generalMatch.group(1) ?? '';

        description = description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .trim();

        if (description.isNotEmpty) {
          debugPrint('Found description with general pattern: $description');
          return description;
        }
      }

      debugPrint('No description found in HTML');
      return null;
    } catch (e) {
      debugPrint('Error parsing book description: $e');
      return null;
    }
  }

  void refreshBookmarkIndicators() {
    if (mounted) {
      debugPrint(
          'OtherBooksPage: refreshBookmarkIndicators called, counter: $_bookmarkRefreshCounter -> ${_bookmarkRefreshCounter + 1}');
      setState(() {
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

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    path.lineTo(size.width, size.height - 8);

    const toothWidth = 4.0;
    const toothHeight = 6.0;
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

    path.lineTo(0, size.height - 8);
    path.close();

    canvas.drawPath(path, paint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final shadowPath = Path();
    shadowPath.addPath(path, const Offset(0, 2));
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
