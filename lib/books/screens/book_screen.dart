// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:namaz_vakti_app/books/shared/models/book_model.dart';
import 'package:namaz_vakti_app/books/features/book/screens/book_page_screen.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_progress_service.dart';
import 'package:namaz_vakti_app/books/features/book/ui/color_extractor.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/book_bookmark_indicator.dart';
import 'package:namaz_vakti_app/books/features/book/services/audio_page_service.dart';
import 'package:namaz_vakti_app/books/other_books.dart';
import 'no_internet_screen.dart';
import 'package:namaz_vakti_app/books/features/book/services/book_info_service.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  BookScreenState createState() => BookScreenState();

  /// Arka plandan (method channel ile) çağrıldığında bir sonraki sayfaya geçişi tetikler
  static void goToNextPageFromBackground() {
    // Bunu bir global event, provider, veya callback ile ilgili ekrana iletmek gerekir.
    // Şimdilik sadece log basalım.
    debugPrint(
        'BookScreen.goToNextPageFromBackground: Arka plandan bir sonraki sayfa çağrısı geldi.');
    // Burada örneğin: BookPageScreen'e bir event gönderebilirsin.
    // Örn: BookPageScreen.nextPageFromBackground();
  }
}

class BookScreenState extends State<BookScreen> {
  final List<Book> books = Book.samples();
  final BookProgressService _progressService = BookProgressService();
  bool _isProgressLoaded = false;
  bool _hasInternetConnection = true;
  bool _isLoading = true;

  // Cache için static değişkenler - ilk açılış kontrolü için
  static bool _isInitializedOnce = false;
  static bool _cachedInternetConnection = true;
  static bool _cachedProgressLoaded = false;

  // Cache for extracted colors
  final Map<String, Color> _bookCoverColors = {};
  // Yer işareti göstergelerini yenilemek için key
  int _bookmarkRefreshCounter = 0;

  // WebView controller
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _hasInternetConnection = true;
    _isLoading = true;

    // Stop any audio playback when returning to the home screen
    AudioPageService().stopAudioAndClearPlayer();

    // Initialize WebView controller
    _initializeWebView();

    _initializeData();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) async {
            debugPrint('Page finished loading: $url');
            // Sayfa yüklendikten sonra zoom seviyesini küçült
            await Future.delayed(const Duration(milliseconds: 500));
            await _webViewController.runJavaScript('''
              document.body.style.zoom = "0.45";
              var viewportMeta = document.querySelector('meta[name="viewport"]');
              if (viewportMeta) {
                viewportMeta.setAttribute('content', 'width=device-width, initial-scale=0.75, maximum-scale=3.0, user-scalable=yes');
              } else {
                var meta = document.createElement('meta');
                meta.name = "viewport";
                meta.content = "width=device-width, initial-scale=0.75, maximum-scale=3.0, user-scalable=yes";
                document.getElementsByTagName('head')[0].appendChild(meta);
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Page resource error: ${error.description}');
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Eğer daha önce initialize edilmişse, cache'lenmiş değerleri kullan
      if (_isInitializedOnce) {
        setState(() {
          _hasInternetConnection = _cachedInternetConnection;
          _isProgressLoaded = _cachedProgressLoaded;
          _isLoading = false;
        });

        // Connectivity stream'i her zaman başlat (gerçek zamanlı güncellemeler için)
        _setupConnectivityStream();
        return;
      }

      // İlk açılış - tam initialization yap
      final results = await Future.wait([
        _checkConnectivitySilently(),
        _initializeProgressService(),
      ]);

      bool isConnected = results[0] as bool;

      if (mounted) {
        setState(() {
          _hasInternetConnection = isConnected;
          _isProgressLoaded = true;
        });

        // Cache'e kaydet
        _cachedInternetConnection = isConnected;
        _cachedProgressLoaded = true;
        _isInitializedOnce = true;

        // Sadece internet yoksa dialog gösterelim
        if (!isConnected) {
          _showNoInternetDialog();
        }
      }

      // Connectivity stream'i başlatalım
      _setupConnectivityStream();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeProgressService() async {
    try {
      await _progressService.initialize();

      if (mounted) {
        setState(() {
          _isProgressLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing progress service: $e');
      if (mounted) {
        setState(() {
          _isProgressLoaded = false;
        });
      }
    }
  }

  Future<bool> _checkConnectivitySilently() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return true; // Hata durumunda varsayılan olarak bağlantı var kabul edelim
    }
  }

  void _setupConnectivityStream() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
      if (mounted) {
        bool isConnected = result != ConnectivityResult.none;

        if (isConnected && !_hasInternetConnection) {
          // İnternet bağlantısı yeni geldi
          setState(() {
            _hasInternetConnection = true;
            _cachedInternetConnection = true; // Cache'i güncelle
          });

          // Eğer progress yüklenmemişse, yeniden yüklemeye çalış
          if (!_isProgressLoaded) {
            setState(() {
              _isLoading = true;
            });

            try {
              await _progressService.initialize();

              if (mounted) {
                setState(() {
                  _isProgressLoaded = true;
                  _cachedProgressLoaded = true; // Cache'i güncelle
                  _isLoading = false;
                });
              }
            } catch (e) {
              debugPrint('Error reinitializing services: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          }
        } else if (!isConnected) {
          setState(() {
            _hasInternetConnection = false;
            _cachedInternetConnection = false; // Cache'i güncelle
          });
        }
      }
    });
  }

  Future<void> _openWifiSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      final url = Uri.parse('App-Prefs:root=WIFI');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  Future<void> _showNoInternetDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İnternet Bağlantısı Yok'),
          content: const Text('İnternet bağlantınızı kontrol edin.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _openWifiSettings();
              },
              child: const Text('Ayarlara Git'),
            ),
          ],
        );
      },
    );
  }

  double _getBookProgress(Book book) {
    if (!_isProgressLoaded || !_hasInternetConnection) {
      return 0.0;
    }

    final progress = _progressService.getProgress(book.code);
    return progress;
  }

  // Method to get or extract dominant color from book cover
  Future<Color> _getBookCoverColor(Book book) async {
    // Return cached color if available
    if (_bookCoverColors.containsKey(book.code)) {
      return _bookCoverColors[book.code]!;
    }

    // Default colors
    Color defaultColor = Colors.blue;
    Color extractedColor = defaultColor;

    // For books with cover images, extract the dominant color
    if (book.coverImageUrl.isNotEmpty) {
      try {
        extractedColor = await ColorExtractor.extractDominantColor(AssetImage(book.coverImageUrl),
            defaultColor: defaultColor);
      } catch (e) {
        debugPrint('Error extracting color: $e');
      }
    }

    // Cache the extracted color
    _bookCoverColors[book.code] = extractedColor;
    return extractedColor;
  }

  // Kitap kartını oluşturan widget'ı ayrı bir metoda çıkaralım
  Widget _buildBookCard(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Kapak resmi ve badge aynı Stack'te
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: book.coverImageUrl.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            book.coverImageUrl,
                            fit: BoxFit.fitHeight,
                          ),
                          FutureBuilder<Color>(
                            future: _getBookCoverColor(book),
                            builder: (context, snapshot) {
                              final bookCoverColor = snapshot.data ?? Colors.blue;
                              return Positioned(
                                top: 1,
                                left: 10,
                                child: BookBookmarkIndicator(
                                  bookCode: book.code,
                                  color: bookCoverColor,
                                  key: ValueKey('bookmark_${book.code}_$_bookmarkRefreshCounter'),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.book,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ],
          ),
        ),
        // --- ALTTAKİ İLERLEME ÇUBUĞU VE INFO BUTONU ---
        FutureBuilder<Color>(
          future: _getBookCoverColor(book),
          builder: (context, snapshot) {
            final bookCoverColor = snapshot.data ?? Colors.blue;
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  // İlerleme çubuğu
                  Expanded(
                    child: SizedBox(
                      height: 5.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.5),
                        child: LinearProgressIndicator(
                          value: _getBookProgress(book),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(bookCoverColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Info butonu

                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: FutureBuilder<String?>(
                            future: BookInfoService.fetchBookTitle(
                                'https://www.hakikatkitabevi.net/book.php?bookCode=${book.code}'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 24,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              // BookInfoService'den gelen başlık varsa onu, yoksa book.title'ı göster
                              final title = (snapshot.hasData &&
                                      snapshot.data != null &&
                                      snapshot.data!.isNotEmpty)
                                  ? snapshot.data!
                                  : book.title;
                              return Text(title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold));
                            },
                          ),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 0,
                              maxHeight: MediaQuery.of(context).size.height * 0.7,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FutureBuilder<String?>(
                                    future: BookInfoService.fetchBookDescription(
                                        'https://www.hakikatkitabevi.net/book.php?bookCode=${book.code}'),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 60,
                                          child: Center(child: CircularProgressIndicator()),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('Açıklama yüklenemedi.',
                                              textAlign: TextAlign.justify),
                                        );
                                      }
                                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('Açıklama bulunamadı.',
                                              textAlign: TextAlign.justify),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          snapshot.data!,
                                          textAlign: TextAlign.justify,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                      child: FilledButton.tonal(
                                          onPressed: () async {
                                            try {
                                              final url =
                                                  Uri.parse('https://www.hakikatkitabevi.net');
                                              debugPrint('URL açılmaya çalışılıyor: $url');

                                              // URL'yi doğrudan açmaya çalış
                                              final launched = await launchUrl(
                                                url,
                                                mode: LaunchMode.externalApplication,
                                              );

                                              if (launched) {
                                                debugPrint('URL başarıyla açıldı');
                                              } else {
                                                debugPrint('URL açılamadı');
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Site açılamadı. Lütfen tekrar deneyin.'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              debugPrint('URL açma hatası: $e');
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Link açılırken hata oluştu: $e'),
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('www.hakikatkitabevi.net'))),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.info_outline_rounded, size: 20),
                  ),
                ],
              ),
            );
          },
        ),
        // --- SONU ---
      ],
    );
  }

  // Ana ekranın içeriğini oluştur
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasInternetConnection) {
      return const NoInternetScreen();
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: OrientationBuilder(
        builder: (context, orientation) {
          // Portrait modda 3 sütun, landscape modda 5 sütun
          final int gridColumns = orientation == Orientation.portrait ? 3 : 5;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return FutureBuilder<Color>(
                future: _getBookCoverColor(book),
                builder: (context, snapshot) {
                  final bookCoverColor = snapshot.data ?? Colors.blue;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookPageScreen(
                            bookCode: book.code,
                            initialPage: getCurrentPage(book.code),
                            appBarColor: bookCoverColor,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          // Kitap sayfasından geri dönüldüğünde sadece ilgili kitabın yer işareti göstergesini güncelle
                          setState(() {
                            // Yer işareti göstergelerini yenilemek için sayacı artır
                            _bookmarkRefreshCounter++;
                          });
                        }
                      });
                    },
                    child: _buildBookCard(book),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  int getCurrentPage(String bookCode) {
    return _progressService.getCurrentPage(bookCode);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.booksTitle,
      actions: [
        Provider.of<ChangeSettings>(context).langCode == 'tr'
            ? IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/bookmarks',
                    );
                  },
                  icon: const Icon(Icons.bookmark_rounded, size: 24),
                ),
              )
            : const SizedBox.shrink(),
        const SizedBox(
          width: 10,
        ),
      ],
      background: false,
      body: Provider.of<ChangeSettings>(context).langCode == 'tr'
          ? _buildBody()
          : OtherBooksPage(language: Provider.of<ChangeSettings>(context).langCode!),
    );
  }

  // Yer işareti göstergelerini yenilemek için public metod
  void refreshBookmarkIndicators() {
    if (mounted) {
      setState(() {
        // Yer işareti göstergelerini yenilemek için sayacı artır
        _bookmarkRefreshCounter++;
      });
    }
  }
}
