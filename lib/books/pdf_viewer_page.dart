import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../data/change_settings.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String bookCode;
  final String bookTitle;

  const PDFViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.bookCode,
    required this.bookTitle,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  PdfController? _pdfController;
  bool _isReady = false;
  String? _localPdfPath;
  DateTime? _lastPageChange;
  bool _showPageNumber = false;
  Timer? _hideTimer;
  int _savedPage = 0;
  bool _isRTL = false;
  Orientation? _lastOrientation;
  int _lastKnownPage = 0;
  String _colorScheme = 'default'; // default, sepia, dark

  @override
  void initState() {
    super.initState();
    // Tüm orientation'ları aktif et (portrait ve landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadLastPage();
    _downloadPdf();
  }

  Future<void> _loadLastPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getInt('pdf_${widget.bookCode}_last_page') ?? 0;
      final colorScheme = prefs.getString('pdf_${widget.bookCode}_color_scheme') ?? 'default';
      print('Loaded last page for book ${widget.bookCode}: $lastPage, color scheme: $colorScheme');
      setState(() {
        _currentPage = lastPage + 1; // PDF indeksini kullanıcı dostu sayfa numarasına çevir
        _savedPage = lastPage;
        _colorScheme = colorScheme;
      });
    } catch (e) {
      print('Error loading last page: $e');
    }
  }

  Future<void> _saveCurrentPage() async {
    try {
      if (!mounted) return; // mounted kontrolü ekle
      final prefs = await SharedPreferences.getInstance();
      // Tüm dillerde aynı mantık - PDF indeksini kullan
      await prefs.setInt('pdf_${widget.bookCode}_last_page', _currentPage);
      print('Saved page $_currentPage for book ${widget.bookCode} (RTL: $_isRTL)');
    } catch (e) {
      print('Error saving page: $e');
    }
  }

  Future<void> _toggleColorScheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String newScheme;

      // Sırayla değiştir: default -> sepia -> dark -> default
      switch (_colorScheme) {
        case 'default':
          newScheme = 'sepia';
          break;
        case 'sepia':
          newScheme = 'dark';
          break;
        case 'dark':
          newScheme = 'default';
          break;
        default:
          newScheme = 'default';
      }

      setState(() {
        _colorScheme = newScheme;
      });
      await prefs.setString('pdf_${widget.bookCode}_color_scheme', newScheme);
      print('Toggled color scheme to $newScheme for book ${widget.bookCode}');
    } catch (e) {
      print('Error toggling color scheme: $e');
    }
  }

  ColorFilter _getColorFilter() {
    switch (_colorScheme) {
      case 'sepia':
        return ColorFilter.matrix([
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'dark':
        return ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      default: // default
        return ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
    }
  }

  Color _getBackgroundColor() {
    switch (_colorScheme) {
      case 'sepia':
        return const Color(0xFFF4F1E8);
      case 'dark':
        return Colors.black;
      default: // default
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (_colorScheme) {
      case 'sepia':
        return const Color(0xFFD4C4A8);
      case 'dark':
        return Colors.grey[600]!;
      default: // default
        return Colors.grey[300]!;
    }
  }

  IconData _getColorSchemeIcon() {
    switch (_colorScheme) {
      case 'sepia':
        return Icons.lightbulb; // Turuncu lamba
      case 'dark':
        return Icons.lightbulb_outline; // Sönük lamba (içi boş)
      default: // default
        return Icons.lightbulb; // Parlak lamba (dolu)
    }
  }

  Color _getColorSchemeIconColor() {
    switch (_colorScheme) {
      case 'sepia':
        return Colors.yellow[600]!; // Sepia için sarı
      case 'dark':
        return Colors.white; // Koyu tema için beyaz
      default: // default
        return Colors.white; // Beyaz tema için beyaz
    }
  }

  String _getColorSchemeTooltip() {
    switch (_colorScheme) {
      case 'sepia':
        return 'Sepia (Sonraki: Koyu)';
      case 'dark':
        return 'Koyu (Sonraki: Beyaz)';
      default: // default
        return 'Beyaz (Sonraki: Sepia)';
    }
  }

  void _saveCurrentPageDebounced() {
    if (!mounted) return; // mounted kontrolü ekle
    _lastPageChange = DateTime.now();
    // Önceki timer'ı iptal et
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 1), () {
      if (mounted &&
          _lastPageChange != null &&
          DateTime.now().difference(_lastPageChange!).inSeconds >= 1) {
        _saveCurrentPage();
      }
    });
  }

  void _showPageNumberTemporarily() {
    if (!mounted) return; // mounted kontrolü ekle
    setState(() {
      _showPageNumber = true;
    });

    // Önceki timer'ı iptal et
    _hideTimer?.cancel();

    // 2 saniye sonra gizle
    _hideTimer = Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPageNumber = false;
        });
      }
    });
  }

  Future<void> _downloadPdf() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pdf_${widget.bookCode}.pdf');

      if (await file.exists()) {
        // PDF controller'ı başlat - kaydedilen sayfa ile
        _pdfController = PdfController(
          document: PdfDocument.openFile(file.path),
          initialPage: _savedPage > 0 ? _savedPage : 0,
        );

        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
          if (_savedPage > 0) {
            _currentPage = _savedPage;
          }
        });
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        widget.pdfUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.data);

        // PDF controller'ı başlat - kaydedilen sayfa ile
        _pdfController = PdfController(
          document: PdfDocument.openFile(file.path),
          initialPage: _savedPage > 0 ? _savedPage : 0,
        );

        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
          if (_savedPage > 0) {
            _currentPage = _savedPage;
          }
        });
      } else {
        setState(() {
          _error = 'Failed to download PDF: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error downloading PDF: $e';
        _isLoading = false;
      });
      print('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<ChangeSettings>(context);
    _isRTL = settings.locale?.languageCode == 'ar';

    return OrientationBuilder(
      builder: (context, orientation) {
        // Orientation değişikliğini kontrol et ve sayfa konumunu koru
        if (_lastOrientation != null &&
            _lastOrientation != orientation &&
            _isReady &&
            _pdfController != null) {
          // Orientation değişti, mevcut sayfayı kaydet ve yeni orientation'da aynı sayfaya git
          _lastKnownPage = _currentPage;
          print(
              'Orientation changed from $_lastOrientation to $orientation, preserving page: $_lastKnownPage');

          // Hemen sayfaya git
          Future.delayed(Duration(milliseconds: 10), () {
            if (_pdfController != null && mounted) {
              _pdfController!.jumpToPage(_lastKnownPage);
              setState(() {
                _currentPage = _lastKnownPage;
              });
            }
          });
        }
        _lastOrientation = orientation;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: settings.color,
            foregroundColor: Colors.white,
            elevation: 4,
            title: Text(
              widget.bookTitle,
              style: TextStyle(
                fontSize: orientation == Orientation.landscape ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _getColorSchemeIcon(),
                  color: _getColorSchemeIconColor(),
                ),
                onPressed: _toggleColorScheme,
                tooltip: _getColorSchemeTooltip(),
              ),
            ],
            toolbarHeight: orientation == Orientation.landscape ? 40 : 56,
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Downloading PDF...'),
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
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _localPdfPath != null
                      ? Stack(
                          children: [
                            Container(
                              height: double.infinity,
                              color: _getBackgroundColor(),
                              child: Stack(
                                children: [
                                  Transform.scale(
                                    scale: orientation == Orientation.landscape ? 3.0 : 1.0,
                                    child: ColorFiltered(
                                      colorFilter: _getColorFilter(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(),
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(4.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _colorScheme == 'dark'
                                                  ? Colors.black.withOpacity(0.5)
                                                  : _getBorderColor().withOpacity(0.3),
                                              blurRadius: 4.0,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4.0),
                                          child: PdfView(
                                            controller: _pdfController!,
                                            scrollDirection: orientation == Orientation.portrait
                                                ? Axis.horizontal
                                                : Axis.vertical,
                                            pageSnapping: orientation == Orientation.portrait,
                                            physics:
                                                const ClampingScrollPhysics(), // Her iki modda da daha hassas gesture detection
                                            onPageChanged: (page) {
                                              if (page != _currentPage) {
                                                print(
                                                    'Page changed from $_currentPage to $page (PDF index: $page)');
                                                setState(() {
                                                  _currentPage =
                                                      page; // PDF indeksini doğrudan kullan
                                                });
                                                print('Current page after setState: $_currentPage');
                                                _saveCurrentPageDebounced();
                                                _showPageNumberTemporarily();
                                              }
                                            },
                                            onDocumentLoaded: (PdfDocument document) {
                                              setState(() {
                                                _isReady = true;
                                                _isLoading = false;
                                                _totalPages = document
                                                    .pagesCount; // PDF sayfa sayısı (0-indexed)
                                                // _currentPage zaten doğru değerde (saved page veya 0)
                                                print(
                                                    'PDF loaded: ${document.pagesCount} pages, current page: $_currentPage');
                                              });

                                              // Artık jumpToPage'e gerek yok çünkü initialPage ile ayarlandı
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Portrait modunda PDF container'ının üstündeki boş alanda slider
                                  if (_isReady &&
                                      _totalPages > 1 &&
                                      orientation == Orientation.portrait)
                                    Positioned(
                                      top: 30,
                                      left: 0,
                                      right: 0,
                                      child: AnimatedOpacity(
                                        opacity: _showPageNumber ? 1.0 : 0.0,
                                        duration: Duration(milliseconds: 300),
                                        child: Center(
                                          child: Container(
                                            width: 250,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 6,
                                                thumbShape:
                                                    RoundSliderThumbShape(enabledThumbRadius: 8),
                                                overlayShape:
                                                    RoundSliderOverlayShape(overlayRadius: 16),
                                                activeTrackColor: Colors.grey,
                                                inactiveTrackColor: Colors.transparent,
                                                thumbColor: Colors.grey,
                                                overlayColor: Colors.grey.withOpacity(0.3),
                                                trackShape: RectangularSliderTrackShape(),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 0),
                                                child: SizedBox(
                                                  width: 250,
                                                  child: Slider(
                                                    value: (_currentPage + 1).toDouble(),
                                                    min: 1.0,
                                                    max: (_totalPages + 1).toDouble(),
                                                    divisions: _totalPages - 1,
                                                    onChanged: (double value) {
                                                      int newPage =
                                                          value.round() - 1; // PDF indeksine çevir
                                                      if (newPage != _currentPage) {
                                                        setState(() {
                                                          _currentPage = newPage;
                                                        });
                                                        _pdfController!.jumpToPage(newPage);
                                                        _saveCurrentPageDebounced();
                                                        _showPageNumberTemporarily();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Sayfa numarası overlay - sadece dokunma sırasında görünür
                            if (_isReady)
                              Positioned(
                                bottom: MediaQuery.of(context).padding.bottom +
                                    (orientation == Orientation.landscape ? 8 : 16),
                                left: 0,
                                right: 0,
                                child: AnimatedOpacity(
                                  opacity: _showPageNumber ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 300),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              orientation == Orientation.landscape ? 12 : 16,
                                          vertical: orientation == Orientation.landscape ? 6 : 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        () {
                                          final displayText =
                                              _isRTL && orientation == Orientation.portrait
                                                  ? '$_currentPage / $_totalPages'
                                                  : '$_currentPage / $_totalPages';
                                          print(
                                              'Display text: $displayText (currentPage: $_currentPage, totalPages: $_totalPages, isRTL: $_isRTL)');
                                          return displayText;
                                        }(),
                                        style: TextStyle(
                                          fontSize: orientation == Orientation.landscape ? 12 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Landscape modunda sağ tarafta dikey slider
                            if (_isReady && _totalPages > 1 && orientation == Orientation.landscape)
                              Positioned(
                                right: 10,
                                top: MediaQuery.of(context).padding.top + 50,
                                bottom: MediaQuery.of(context).padding.bottom + 50,
                                child: AnimatedOpacity(
                                  opacity: _showPageNumber ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 300),
                                  child: Container(
                                    width: 6,
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 6,
                                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                                        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                                        activeTrackColor: Colors.grey,
                                        inactiveTrackColor: Colors.transparent,
                                        thumbColor: Colors.grey,
                                        overlayColor: Colors.grey.withOpacity(0.3),
                                        trackShape: RectangularSliderTrackShape(),
                                      ),
                                      child: RotatedBox(
                                        quarterTurns: _isRTL
                                            ? 3
                                            : 1, // RTL'de ters yön, normalde 90 derece döndür
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 0),
                                          child: SizedBox(
                                            width: MediaQuery.of(context).size.height * 0.6,
                                            child: Slider(
                                              value: (_currentPage + 1).toDouble(),
                                              min: 1.0,
                                              max: (_totalPages + 1).toDouble(),
                                              divisions: _totalPages - 1,
                                              onChanged: (double value) {
                                                int newPage =
                                                    value.round() - 1; // PDF indeksine çevir
                                                if (newPage != _currentPage) {
                                                  setState(() {
                                                    _currentPage = newPage;
                                                  });
                                                  _pdfController!.jumpToPage(newPage);
                                                  _saveCurrentPageDebounced();
                                                  _showPageNumberTemporarily();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: Text('PDF not available'),
                        ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Son sayfayı kaydet
    _saveCurrentPage();
    _hideTimer?.cancel();
    _pdfController?.dispose();
    // Orientation ayarlarını sıfırla (sadece portrait'a dön)
    // mounted kontrolü ekle
    if (mounted) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }
}
