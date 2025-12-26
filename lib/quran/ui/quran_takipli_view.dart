import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';
import 'package:namaz_vakti_app/books/features/book/widgets/highlight_color_dialog.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';
import 'package:namaz_vakti_app/quran/services/takipli_quran_service.dart';
import 'package:namaz_vakti_app/quran/audio/quran_audio_repository.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/quran/services/surah_localization_service.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

/// Takipli Kuran görünümü için bileşen
class QuranTakipliView extends StatefulWidget {
  final Map<String, dynamic> pageData;
  final int activeWordIndex;
  final String selectedFont;
  final double fontSize;
  final Color backgroundColor;
  final Map<int, GlobalKey> wordKeys;
  final ScrollController scrollController;
  final bool isAutoScroll; // Otomatik kaydırma ayarı için değişken
  final int pageNumber; // <-- yeni parametre
  final bool showMeal;
  final VoidCallback? onHighlightChanged;

  const QuranTakipliView({
    Key? key,
    required this.pageData,
    required this.activeWordIndex,
    required this.selectedFont,
    required this.fontSize,
    required this.backgroundColor,
    required this.wordKeys,
    required this.scrollController,
    required this.isAutoScroll, // Yeni parametre
    required this.pageNumber, // <-- yeni parametre
    required this.showMeal,
    this.onHighlightChanged,
  }) : super(key: key);

  @override
  _QuranTakipliViewState createState() => _QuranTakipliViewState();
}

class _QuranTakipliViewState extends State<QuranTakipliView> {
  // Önceki aktif kelime indeksini takip etmek için değişken ekle
  int _previousActiveWordIndex = -1;

  // Son seçilen (uzun basılan) ayetin index'i
  int? _selectedAyahIndex;
  // Popup menü için kelimenin global pozisyonu
  Offset? _popupPosition;

  // Vurgulanan ayetler (kalıcı)
  List<HighlightInfo> _highlights = [];

  final BookmarkService _bookmarkService = BookmarkService();

  // Secde ayetlerinin listesi (sure numarası, ayet numarası)
  final List<Map<String, int>> _secdeAyetleri = [
    {'sure': 7, 'ayet': 206}, // A'raf Suresi 206. ayet
    {'sure': 13, 'ayet': 15}, // Ra'd Suresi 15. ayet
    {'sure': 16, 'ayet': 50}, // Nahl Suresi 50. ayet
    {'sure': 17, 'ayet': 109}, // İsra Suresi 109. ayet
    {'sure': 19, 'ayet': 58}, // Meryem Suresi 58. ayet
    {'sure': 22, 'ayet': 18}, // Hac Suresi 18. ayet
    {'sure': 22, 'ayet': 77}, // Hac Suresi 77. ayet
    {'sure': 25, 'ayet': 60}, // Furkan Suresi 60. ayet
    {'sure': 27, 'ayet': 26}, // Neml Suresi 26. ayet
    {'sure': 32, 'ayet': 15}, // Secde Suresi 15. ayet
    {'sure': 38, 'ayet': 24}, // Sad Suresi 24. ayet
    {'sure': 41, 'ayet': 38}, // Fussilet Suresi 38. ayet
    {'sure': 53, 'ayet': 62}, // Necm Suresi 62. ayet
    {'sure': 84, 'ayet': 21}, // İnşikak Suresi 21. ayet
    {'sure': 96, 'ayet': 19}, // Alak Suresi 19. ayet
  ];

  // Bir ayetin secde ayeti olup olmadığını kontrol eden metod
  bool _isSecdeAyeti(int sureNo, int ayetNo) {
    return _secdeAyetleri.any(
        (element) => element['sure'] == sureNo && element['ayet'] == ayetNo);
  }

  // Secde ayeti için özel container oluşturan metod
  Widget _buildSecdeAyetiContainer({
    required Widget child,
    required bool isSecde,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        // Secde ayeti için kırmızı çerçeve ekle
        border: isSecde ? Border.all(color: Colors.red, width: 2.0) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSecde)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)?.quranProstration ?? 'Secde',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHighlights();

    // Sayfa ilk yüklendiğinde aktif kelimeye scroll yap
    if (widget.activeWordIndex >= 0 && widget.isAutoScroll) {
      _previousActiveWordIndex = widget.activeWordIndex;

      // Widget ağacı oluşturulduktan sonra scroll yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveWord();
      });
    }
  }

  Future<void> _loadHighlights() async {
    final pageNumber = widget.pageNumber;
    final bookmarks =
        await _bookmarkService.getPageBookmarks('quran', pageNumber);
    setState(() {
      _highlights = bookmarks
          .where((b) =>
              b.selectedText != null &&
              b.highlightColor != null &&
              b.startIndex != null)
          .map((b) => HighlightInfo(
                text: b.selectedText!,
                color: b.highlightColor!,
                startIndex: b.startIndex!,
                endIndex: b.endIndex ?? b.startIndex!,
              ))
          .toList();
    });
  }

  @override
  void didUpdateWidget(QuranTakipliView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Eğer yazı boyutu, arka plan rengi veya font değiştiyse, sayfayı yeniden çiz
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.selectedFont != widget.selectedFont) {
      setState(() {
        // Sadece görünümü güncelle, veri yükleme yok
      });
    }

    // Aktif kelime değiştiyse ve geçerli bir kelime indeksi ise ve otomatik kaydırma açıksa
    if (oldWidget.activeWordIndex != widget.activeWordIndex &&
        widget.activeWordIndex >= 0 &&
        widget.activeWordIndex != _previousActiveWordIndex &&
        widget.isAutoScroll) {
      _previousActiveWordIndex = widget.activeWordIndex;

      // Aktif kelimeye scroll yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveWord();
      });
    }
  }

  // Aktif kelimeye scroll yapan metod
  void _scrollToActiveWord() {
    // Otomatik kaydırma kapalıysa işlem yapma
    if (!widget.isAutoScroll) return;

    // Aktif kelime için GlobalKey var mı kontrol et
    if (widget.wordKeys.containsKey(widget.activeWordIndex)) {
      final GlobalKey activeWordKey = widget.wordKeys[widget.activeWordIndex]!;

      // GlobalKey'in mevcut context'i var mı kontrol et
      if (activeWordKey.currentContext != null) {
        // Kelimenin pozisyonunu ve boyutunu al
        final RenderBox box =
            activeWordKey.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;

        // Ekranın ortasını hesapla
        final screenHeight = MediaQuery.of(context).size.height;
        final screenCenter = screenHeight / 2;

        // Kelimenin ekrandaki pozisyonu (kelimenin ortasını al)
        final wordPosition = position.dy + (size.height / 2);

        // Kelimenin ekranın ortasına gelmesi için gerekli offset hesapla
        // Eğer kelime ekranın ortasından belirli bir mesafe uzaksa scroll yap
        final threshold =
            screenHeight * 0.15; // Ekran yüksekliğinin %15'i kadar tolerans

        if (wordPosition < screenCenter - threshold ||
            wordPosition > screenCenter + threshold) {
          // Kelimenin tam olarak ekranın ortasına gelmesi için offset hesapla
          final scrollOffset =
              widget.scrollController.offset + (wordPosition - screenCenter);

          // Scroll pozisyonunun sınırlarını kontrol et
          final maxScrollExtent =
              widget.scrollController.position.maxScrollExtent;
          final minScrollExtent =
              widget.scrollController.position.minScrollExtent;

          final clampedOffset =
              scrollOffset.clamp(minScrollExtent, maxScrollExtent);

          // Animasyonlu scroll
          widget.scrollController.animateTo(
            clampedOffset,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

          print(
              'Kelime takibi: Kelime ${widget.activeWordIndex} için scroll yapıldı. Pozisyon: $wordPosition, Ekran ortası: $screenCenter');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif kelime değiştiğinde scroll yapılabilmesi için listener ekle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.activeWordIndex >= 0 &&
          widget.activeWordIndex != _previousActiveWordIndex &&
          widget.isAutoScroll) {
        _previousActiveWordIndex = widget.activeWordIndex;
        _scrollToActiveWord();
      }
    });

    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thickness: MaterialStateProperty.all(6.0),
          thumbColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.6)),
          radius: Radius.circular(3.0),
          thumbVisibility: MaterialStateProperty.all(true),
          mainAxisMargin: 4.0,
          crossAxisMargin: 0.0,
        ),
      ),
      child: Scrollbar(
        controller: widget.scrollController,
        child: SingleChildScrollView(
          controller: widget.scrollController,
            padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 80, // Navbar için ekstra boşluk
          ),
          physics:
              ClampingScrollPhysics(), // Dokunma olaylarının üst widget'lara geçmesine izin ver
          child: Column(
            children: _buildTakipliPageWidgets(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTakipliPageWidgets() {
    // QuranAyats null kontrolü
    if (widget.pageData['QuranAyats'] == null) {
      print('Uyarı: QuranTakipliView - QuranAyats null');
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)?.quranPageDataError ?? 'Sayfa verisi yüklenemedi. Lütfen tekrar deneyin.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ];
    }

    final quranAyats = widget.pageData['QuranAyats'] as List<dynamic>;

    // QuranAyats boş kontrolü
    if (quranAyats.isEmpty) {
      print('Uyarı: QuranTakipliView - QuranAyats boş');
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)?.quranNoVersesFound ?? 'Bu sayfada gösterilecek ayet bulunamadı.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ];
    }

    final List<Widget> contentWidgets = [];
    int? currentSurahId;

    // Her kelime için yeni bir GlobalKey oluştur
    int wordIndex = 0;

    // Arka plan rengine göre yazı rengini belirle
    final Color textColor = widget.backgroundColor.computeLuminance() > 0.5
        ? Color(0xFF2E1810)
        : Colors.white;

    // Sayfada secde ayeti var mı kontrol et
    bool sayfadaSecdeAyetiVar = false;
    for (var ayat in quranAyats) {
      final int surahId = ayat['SureId'] ?? 1;
      final String ayetNumberStr = (ayat['AyetNumber'] ?? '١').toString();
      int ayetNumber;
      try {
        ayetNumber = int.parse(_convertArabicNumberToLatin(ayetNumberStr));
      } catch (e) {
        ayetNumber = 1;
      }
      if (_isSecdeAyeti(surahId, ayetNumber)) {
        sayfadaSecdeAyetiVar = true;
        print('Sayfada secde ayeti bulundu: Sure $surahId, Ayet $ayetNumber');
        break;
      }
    }

    // Tüm ayetleri içerecek ana container'ı oluştur
    List<Widget> pageContentWidgets = [];
    List<Widget> allWords = [];

    // Her ayeti işle
    for (var i = 0; i < quranAyats.length; i++) {
      final ayat = quranAyats[i];

      // Ayet içindeki alanların null kontrolü
      final surahInfo = ayat['Sure'];
      final int surahId = ayat['SureId'] ?? 1;
      final String ayetNumberStr = (ayat['AyetNumber'] ?? '١').toString();

      // Arapça sayıyı Latin sayısına çevirirken hata kontrolü
      int ayetNumber;
      try {
        ayetNumber = int.parse(_convertArabicNumberToLatin(ayetNumberStr));
      } catch (e) {
        print('Ayet numarası çevirme hatası: $e');
        ayetNumber = 1;
      }

      // Secde ayeti kontrolü
      bool isSecde = _isSecdeAyeti(surahId, ayetNumber);

      // Sure değişimi kontrolü
      if (currentSurahId != surahId) {
        // Eğer önceki ayetlerden kelimeler varsa, önce onları ekle
        if (allWords.isNotEmpty) {
          pageContentWidgets.add(
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.spaceBetween,
                spacing: 0, // Kelimeler arası boşluğu kaldır
                runSpacing: 5, // Satırlar arası boşluğu koru
                children: allWords,
              ),
            ),
          );
          allWords = [];
        }

        // Yeni sure başlıyor
        if (surahInfo != null) {
          // Sure başlığını, secde ayeti varsa contentWidgets'a, yoksa pageContentWidgets'a ekle
          Widget surahHeader = _buildSurahHeader(
              'سورة ${surahInfo['SureNameArabic']}', textColor);

          if (sayfadaSecdeAyetiVar) {
            // Secde ayeti varsa, ilk sure başlığını çerçevenin dışına (contentWidgets'a) ekle
            // diğer sure başlıklarını çerçevenin içine (pageContentWidgets'a) ekle
            if (contentWidgets.isEmpty) {
              // Sayfadaki ilk sure başlığı ise çerçevenin dışına ekle
              contentWidgets.add(surahHeader);
            } else {
              // Sayfadaki diğer sure başlıkları ise çerçevenin içine ekle
              pageContentWidgets.add(surahHeader);
            }
          } else {
            // Secde ayeti yoksa, sure başlığını çerçevenin içine (pageContentWidgets'a) ekle
            pageContentWidgets.add(surahHeader);
          }

          // Besmele kontrolü - Sadece surenin ilk ayetinden önce göster
          if (ayetNumber == 1 && surahInfo['BesmeleVisible'] == true) {
            // Besmele kelimelerini ayrı ayrı ekle (takip için)
            final besmeleWords =
                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ'.split(' ');

            // Besmele için özel bir container oluştur
            List<Widget> besmeleWidgets = [];

            // Besmele kelimeleri için negatif indeksler kullan (-1, -2, -3, -4)
            for (int i = 0; i < besmeleWords.length; i++) {
              // Negatif indeks kullanarak besmele kelimelerini takip et
              final besmeleIndex = -(i + 1);
              // Besmele kelimelerini vurgulamayı kaldır
              final key = GlobalKey();
              widget.wordKeys[besmeleIndex] = key;

              besmeleWidgets.add(
                Container(
                  key: key,
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Her zaman şeffaf arka plan
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    besmeleWords[i],
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontFamily: widget.selectedFont,
                      height: 1.5,
                      color: Colors
                          .red.shade700, // Besmele yazı rengini kırmızı yap
                      fontWeight:
                          FontWeight.normal, // Her zaman normal kalınlık
                    ),
                  ),
                ),
              );
            }

            pageContentWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing:
                          0, // Besmele kelimeleri arasındaki boşluğu kaldır
                      children: besmeleWidgets,
                    ),
                  ),
                ),
              ),
            );
          }
        }
        currentSurahId = surahId;
      }

      // Ayetin kelimelerini ekle
      final ayetText = ayat['AyetText'].toString();
      // Düzeltme: Birden fazla boşlukları tek boşluğa çevir ve sonra split yap
      final String normalizedText = '$ayetText ﴿${ayat['AyetNumber']}﴾';
      final List<String> words = normalizedText.trim().split(RegExp(r'\s+'));

      // Fatiha suresinin ilk ayeti için özel işlem
      if (surahId == 1 && ayetNumber == 1) {
        // Önce mevcut kelimeleri ekleyelim
        if (allWords.isNotEmpty) {
          pageContentWidgets.add(
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.spaceBetween,
                spacing: 0, // Kelimeler arası boşluğu kaldır
                runSpacing: 5, // Satırlar arası boşluğu koru
                children: allWords,
              ),
            ),
          );
          allWords = [];
        }

        // Fatiha'nın ilk ayetini tek satırda ortada göster ama kelimeleri ayrı ayrı işaretle
        List<Widget> fatihaBirWidgets = [];

        // Her kelimeyi ayrı ayrı işaretle ama görünümü ortada olacak şekilde ayarla
        // Düzeltme: Boş kelimeleri filtrele
        for (final word in words) {
          if (word.isEmpty) continue; // Boş kelimeleri atla

          final key = GlobalKey();
          widget.wordKeys[wordIndex] = key;
          wordIndex++;

          fatihaBirWidgets.add(
            Container(
              key: key,
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: widget.activeWordIndex == wordIndex - 1
                    ? Colors.red.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontFamily: widget.selectedFont,
                  height: 1.5,
                  // Yazı rengi her zaman kırmızı
                  color: widget.activeWordIndex == wordIndex - 1
                      ? Colors.red
                      : Colors.red.shade700,
                  // Yazı kalınlığı: Aktif kelime veya secde ayeti ise kalın, değilse normal
                  fontWeight: widget.activeWordIndex == wordIndex - 1 || isSecde
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }

        // Özel container ekle - ortada göster
        pageContentWidgets.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center, // Ortada göster
                spacing:
                    0, // Fatiha suresi ilk ayet kelimelerinin arasındaki boşluğu kaldır
                runSpacing: 5,
                children: fatihaBirWidgets,
              ),
            ),
          ),
        );
      } else {
        // Diğer ayetler için normal işlem
        for (final word in words) {
          if (word.isEmpty) continue;

          final key = GlobalKey();
          widget.wordKeys[wordIndex] = key;
          wordIndex++;

          HighlightInfo? existingHighlight;
          bool isAlreadyHighlighted = false;
          try {
            existingHighlight =
                _highlights.firstWhere((h) => h.startIndex == i);
            isAlreadyHighlighted = true;
          } catch (e) {
            existingHighlight = null;
            isAlreadyHighlighted = false;
          }
          final highlightColor =
              isAlreadyHighlighted ? existingHighlight!.color : null;
          allWords.add(
            GestureDetector(
              onLongPressStart: (details) {
                setState(() {
                  _selectedAyahIndex = i;
                  _popupPosition = details.globalPosition;
                });
                _showCustomAyahMenu(context, normalizedText, i);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                key: key,
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: isAlreadyHighlighted
                      ? highlightColor!.withOpacity(0.4)
                      : _selectedAyahIndex == i
                          ? Colors.yellow.withOpacity(0.5)
                          : isSecde
                              ? Colors.green.withOpacity(0.15)
                              : widget.activeWordIndex == wordIndex - 1
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontFamily: widget.selectedFont,
                    height: 1.5,
                    color: widget.activeWordIndex == wordIndex - 1
                        ? Colors.red
                        : textColor,
                    fontWeight:
                        widget.activeWordIndex == wordIndex - 1 || isSecde
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Son ayetlerin kelimelerini ekle
    if (allWords.isNotEmpty) {
      pageContentWidgets.add(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            spacing: 0,
            runSpacing: 5,
            children: allWords,
          ),
        ),
      );
    }

    // Tüm sayfa içeriğini tek bir container içine al
    contentWidgets.add(
      _buildSecdeAyetiContainer(
        isSecde:
            sayfadaSecdeAyetiVar, // Sayfada secde ayeti varsa kırmızı çerçeve göster
        backgroundColor: widget.backgroundColor == Colors.white
            ? Color(0xFFFAFAFA)
            : widget.backgroundColor.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: pageContentWidgets,
        ),
      ),
    );

    // Secde ayeti olan sayfalarda bottom bar'ın üstünde boşluk bırakmak için padding ekle
    if (sayfadaSecdeAyetiVar) {
      contentWidgets.add(
        SizedBox(height: 16), // Kırmızı çizginin altında 16 piksel boşluk bırak
      );
    }

    return contentWidgets;
  }

  // Sure başlığı widget'ı
  Widget _buildSurahHeader(String sureName, [Color? textColor]) {
    final Color headerTextColor = textColor ?? Color(0xFF2E1810);

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: 10.0), // Add vertical padding around the header
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://kuran.diyanet.gov.tr/mushaf/data/motif/header/1X/SureHeader2.png'),
            fit: BoxFit.fill,
          ),
        ),
        height: 60,
        child: Center(
          child: Text(
            sureName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: headerTextColor,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 2.0,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Arapça rakamları Latin rakamlarına çeviren metod
  String _convertArabicNumberToLatin(String arabicNumber) {
    const Map<String, String> arabicToLatinMap = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    String latinNumber = '';
    for (int i = 0; i < arabicNumber.length; i++) {
      final char = arabicNumber[i];
      latinNumber += arabicToLatinMap[char] ?? char;
    }

    return latinNumber;
  }

  void _showCustomAyahMenu(
      BuildContext context, String ayahText, int ayahIndex) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Size screenSize = overlay.size;
    final Offset rawPosition = _popupPosition ?? Offset(100, 100);

    // Ayet zaten vurgulanmış mı kontrol et
    HighlightInfo? existingHighlight;
    bool isAlreadyHighlighted = false;
    try {
      existingHighlight =
          _highlights.firstWhere((h) => h.startIndex == ayahIndex);
      isAlreadyHighlighted = true;
    } catch (e) {
      existingHighlight = null;
      isAlreadyHighlighted = false;
    }

    // Meal ayıkla
    String? mealText;
    final quranAyats = widget.pageData['QuranAyats'] as List<dynamic>?;
    final mealAyats = widget.pageData['MealAyats'] as List<dynamic>?;
    int? ayetNum;
    int? sureNum;
    if (quranAyats != null && ayahIndex < quranAyats.length) {
      final ayetNumberStr = _convertArabicNumberToLatin(
          quranAyats[ayahIndex]['AyetNumber']?.toString() ?? '');
      sureNum = quranAyats[ayahIndex]['SureId'] as int?;
      ayetNum = int.tryParse(ayetNumberStr);
    }
    // Meal bul - yeni translation service kullan
    if (sureNum != null && ayetNum != null && widget.showMeal) {
      try {
        // Translation service removed - using fallback meal system
      } catch (e) {
        print('🔍 Translation Error in share: $e');
        // Hata durumunda eski meal sistemini kullan
        if (mealAyats != null) {
          final mealObj = mealAyats.firstWhere(
            (m) {
              final mSureId = int.tryParse(m['SureId']?.toString() ?? '');
              final mAyetNum = int.tryParse(m['AyetNumber']?.toString() ?? '');
              return mSureId == sureNum && mAyetNum == ayetNum;
            },
            orElse: () => null,
          );
          if (mealObj != null && mealObj['AyetText'] != null) {
            mealText = mealObj['AyetText'].toString();
          }
        }
      }
    }

    // Responsive: show overflow if screen is narrow
    // Show up to 3 buttons directly, overflow the rest
    int maxDirectButtons = 3;
    double buttonFontSize = 13;
    double iconSize = 17;
    if (screenSize.width < 340) {
      maxDirectButtons = 2;
      buttonFontSize = 12;
      iconSize = 16;
    }
    // Prepare all action buttons in order
    final List<Widget> allActionButtons = [
      TextButton.icon(
        icon: Icon(Icons.copy, color: Colors.deepPurple, size: iconSize),
        label: Text(AppLocalizations.of(context)?.quranCopy ?? 'Kopyala',
            style:
                TextStyle(color: Colors.deepPurple, fontSize: buttonFontSize)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          minimumSize: Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: ayahText));
          Navigator.of(context).pop();
        },
      ),
      !isAlreadyHighlighted
          ? TextButton.icon(
              icon: Icon(Icons.highlight,
                  color: Colors.deepPurple, size: iconSize),
              label: Text(AppLocalizations.of(context)?.quranHighlight ?? 'Vurgula',
                  style: TextStyle(
                      color: Colors.deepPurple, fontSize: buttonFontSize)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                minimumSize: Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                _showHighlightColorDialog(ayahText, ayahIndex);
                if (widget.onHighlightChanged != null)
                  widget.onHighlightChanged!();
              },
            )
          : TextButton.icon(
              icon: Icon(Icons.highlight_off,
                  color: Colors.deepPurple, size: iconSize),
              label: Text(AppLocalizations.of(context)?.removeHighlight ?? 'Vurguyu Kaldır',
                  style: TextStyle(
                      color: Colors.deepPurple, fontSize: buttonFontSize)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                minimumSize: Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _highlights.removeWhere((h) => h.startIndex == ayahIndex);
                });
                await _bookmarkService.removeBookmark(
                  'quran',
                  widget.pageNumber,
                  selectedText: existingHighlight?.text,
                  startIndex: ayahIndex,
                  endIndex: ayahIndex,
                );
                if (widget.onHighlightChanged != null)
                  widget.onHighlightChanged!();
              },
            ),
      TextButton.icon(
        icon: Icon(Icons.share, color: Colors.deepPurple, size: iconSize),
        label: Text(AppLocalizations.of(context)?.quranShare ?? 'Paylaş',
            style:
                TextStyle(color: Colors.deepPurple, fontSize: buttonFontSize)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          minimumSize: Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          String? sureName;
          String? ayetNumber;
          int? surahId;
          final takipliService = TakipliQuranService();
          final audioRepo = QuranAudioRepository();
          final quranAyats = widget.pageData['QuranAyats'] as List<dynamic>?;
          if (quranAyats != null && ayahIndex < quranAyats.length) {
            surahId = quranAyats[ayahIndex]['SureId'] as int?;
            ayetNumber = _convertArabicNumberToLatin(
                quranAyats[ayahIndex]['AyetNumber']?.toString() ?? '');
            sureName =
                quranAyats[ayahIndex]['Sure']?['SureNameTurkish']?.toString();
            if (sureName == null && surahId != null) {
              sureName = audioRepo.getSurahName(surahId);
            }
          }
          if (sureName == null || sureName.isEmpty) {
            final surahInfo =
                takipliService.getSurahInfoForAyah(widget.pageData, ayahIndex);
            if (surahInfo != null) {
              surahId = surahInfo['surahNo'] as int?;
              sureName = surahInfo['surahNameTurkish']?.toString() ??
                  (surahId != null
                      ? audioRepo.getSurahName(surahId)
                      : 'Bilinmeyen Sure');
            }
          }
          // Arapça dil seçildiğinde veya meal kapalıysa sadece ayet paylaş
          final langCode = Provider.of<ChangeSettings>(context, listen: false).langCode ?? 'en';
          if (!widget.showMeal || langCode == 'ar') {
            // Meal kapalıysa veya Arapça dil seçildiyse doğrudan sadece ayet paylaş
            String shareText = '';
            final localizedSurahName = sureName != null ? SurahLocalizationService.getLocalizedSurahName(sureName, context) : null;
            final verseFormat = ayetNumber != null && localizedSurahName != null 
                ? AppLocalizations.of(context)?.surahVerseFormat(localizedSurahName, int.tryParse(ayetNumber) ?? 0, AppLocalizations.of(context)?.verse ?? 'Verse') ?? '$localizedSurahName, ${AppLocalizations.of(context)?.verse ?? 'Verse'} $ayetNumber'
                : null;
            shareText +=
                '(${AppLocalizations.of(context)?.pageNumber(widget.pageNumber + 1) ?? 'Page ${widget.pageNumber + 1}'}${verseFormat != null ? ' | $verseFormat' : ''})';
            shareText += '\n\n$ayahText';
            await Share.share(shareText);
            Navigator.of(context).pop();
            return;
          }
          // Direkt native paylaş menüsü göster
          String shareText = '';
          final localizedSurahName = sureName != null ? SurahLocalizationService.getLocalizedSurahName(sureName, context) : null;
          final verseFormat = ayetNumber != null && localizedSurahName != null 
              ? AppLocalizations.of(context)?.surahVerseFormat(localizedSurahName, int.tryParse(ayetNumber) ?? 0, AppLocalizations.of(context)?.verse ?? 'Verse') ?? '$localizedSurahName, ${AppLocalizations.of(context)?.verse ?? 'Verse'} $ayetNumber'
              : null;
          shareText +=
              '(${AppLocalizations.of(context)?.pageNumber(widget.pageNumber + 1) ?? 'Page ${widget.pageNumber + 1}'}${verseFormat != null ? ' | $verseFormat' : ''})';
          shareText += '\n\n$ayahText';
          if (mealText != null && mealText.isNotEmpty) {
            shareText += '\n\n[${AppLocalizations.of(context)?.quranTranslation ?? 'Translation'}]: $mealText';
          }
          await Share.share(shareText);
          Navigator.of(context).pop();
        },
      ),
    ];
    // Translation button removed
    // Overflow mantığı
    final bool useOverflow = allActionButtons.length > maxDirectButtons;
    final List<Widget> directButtons = useOverflow
        ? allActionButtons.sublist(0, maxDirectButtons)
        : allActionButtons;
    final List<Widget> overflowButtons =
        useOverflow ? allActionButtons.sublist(maxDirectButtons) : [];
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        // Menüde overflow için iki sayfa mantığı
        bool overflowMode = false;
        return StatefulBuilder(
          builder: (context, setMenuState) {
            // Butonları hazırla
            // ... mevcut kod ...
            // --- DİNAMİK MENÜ POZİSYON HESABI ---
            int visibleButtonCount;
            if (!overflowMode && useOverflow) {
              visibleButtonCount = directButtons.length + 1; // üç nokta
            } else if (overflowMode && useOverflow) {
              visibleButtonCount = overflowButtons.length + 1; // geri ok
            } else {
              visibleButtonCount = allActionButtons.length;
            }
            double menuWidth = visibleButtonCount * 88.0; // daha dar
            const double menuHeight = 34; // daha da ince
            double left = rawPosition.dx;
            double top = rawPosition.dy - menuHeight - 8;
            // Sağdan taşarsa sola kaydır
            if (left + menuWidth > screenSize.width) {
              left = screenSize.width - menuWidth - 8;
            }
            // Soldan taşarsa sağa kaydır
            if (left < 8) left = 8;
            // Yukarıdan taşarsa alta aç
            if (top < 8) top = rawPosition.dy + 8;
            // Alttan taşarsa yukarı kaydır
            if (top + menuHeight > screenSize.height) {
              top = screenSize.height - menuHeight - 8;
            }
            double buttonFontSize = 11.5;
            double iconSize = 15.5;
            // Unused variables removed
            // Sadece uçlar yuvarlatılmış olsun (StadiumBorder gibi)
            BorderRadius menuRadius = BorderRadius.horizontal(
                left: Radius.circular(18), right: Radius.circular(18));
            // --- MENÜ WIDGET'I ---
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      height: menuHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: menuRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 7,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!overflowMode && useOverflow) ...[
                            ...directButtons.map((btn) => _slimButton(
                                btn,
                                buttonFontSize,
                                iconSize)),
                            IconButton(
                              icon: Icon(Icons.more_horiz,
                                  color: Colors.deepPurple, size: iconSize + 2),
                              padding: EdgeInsets.zero,
                              constraints:
                                  BoxConstraints(minWidth: 32, minHeight: 24),
                              onPressed: () {
                                setMenuState(() {
                                  overflowMode = true;
                                });
                              },
                            ),
                          ] else if (overflowMode && useOverflow) ...[
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: Colors.deepPurple, size: iconSize + 2),
                              padding: EdgeInsets.zero,
                              constraints:
                                  BoxConstraints(minWidth: 32, minHeight: 24),
                              onPressed: () {
                                setMenuState(() {
                                  overflowMode = false;
                                });
                              },
                            ),
                            ...overflowButtons.map((btn) => _slimButton(
                                btn,
                                buttonFontSize,
                                iconSize)),
                          ] else ...[
                            ...allActionButtons.map((btn) => _slimButton(
                                btn,
                                buttonFontSize,
                                iconSize)),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {
      _selectedAyahIndex = null;
    });
  }

  /// Translation bubble functionality removed

  void _showHighlightColorDialog(String ayahText, int ayahIndex) async {
    int pageNumber = widget.pageNumber;
    final takipliService = TakipliQuranService();
    final audioRepo = QuranAudioRepository();
    String sureName = '';
    String ayetNumber = '';
    int? surahId;
    String? mealText;
    final surahInfo =
        takipliService.getSurahInfoForAyah(widget.pageData, ayahIndex);
    if (surahInfo != null) {
      surahId = surahInfo['surahNo'] as int?;
      // Önce Türkçe adı al, yoksa repo'dan getir
      sureName = surahInfo['surahNameTurkish']?.toString() ??
          (surahId != null
              ? audioRepo.getSurahName(surahId)
              : 'Bilinmeyen Sure');
    }
    // Ayet numarasını Latin rakama çevir
    final quranAyats = widget.pageData['QuranAyats'] as List<dynamic>?;
    final mealAyats = widget.pageData['MealAyats'] as List<dynamic>?;
    int? ayetNum;
    int? sureNum;
    if (quranAyats != null && ayahIndex < quranAyats.length) {
      ayetNumber = _convertArabicNumberToLatin(
          quranAyats[ayahIndex]['AyetNumber']?.toString() ?? '');
      sureNum = quranAyats[ayahIndex]['SureId'] as int?;
      ayetNum = int.tryParse(ayetNumber);
    }
    // Meal bul - yeni translation service kullan
    if (sureNum != null && ayetNum != null && widget.showMeal) {
      try {
        // Translation service removed - using fallback meal system
      } catch (e) {
        print('🔍 Translation Error in highlight: $e');
        // Hata durumunda eski meal sistemini kullan
        if (mealAyats != null) {
          final mealObj = mealAyats.firstWhere(
            (m) {
              final mSureId = int.tryParse(m['SureId']?.toString() ?? '');
              final mAyetNum = int.tryParse(m['AyetNumber']?.toString() ?? '');
              return mSureId == sureNum && mAyetNum == ayetNum;
            },
            orElse: () => null,
          );
          if (mealObj != null && mealObj['AyetText'] != null) {
            mealText = mealObj['AyetText'].toString();
          }
        }
      }
    }
    showDialog(
      context: context,
      builder: (context) => HighlightColorDialog(
        onColorSelected: (color) async {
          setState(() {
            final existing =
                _highlights.indexWhere((h) => h.startIndex == ayahIndex);
            final localizedSurahName = SurahLocalizationService.getLocalizedSurahName(sureName, context);
            final verseFormat = AppLocalizations.of(context)?.surahVerseFormat(localizedSurahName, int.tryParse(ayetNumber) ?? 0, AppLocalizations.of(context)?.verse ?? 'Verse') ?? '$localizedSurahName, $ayetNumber. Ayet';
            String displayText = '$ayahText\n($verseFormat)';
            if (mealText != null && mealText.isNotEmpty) {
              displayText += '\n[Terceme]: $mealText';
            }
            if (existing >= 0) {
              _highlights[existing] = HighlightInfo(
                text: displayText,
                color: color,
                startIndex: ayahIndex,
                endIndex: ayahIndex,
                surahId: surahId,
                surahName: sureName,
                ayahNumber: ayetNumber,
              );
            } else {
              _highlights.add(HighlightInfo(
                text: displayText,
                color: color,
                startIndex: ayahIndex,
                endIndex: ayahIndex,
                surahId: surahId,
                surahName: sureName,
                ayahNumber: ayetNumber,
              ));
            }
          });
          print(
              'Vurgu eklendi: Sayfa $pageNumber, AyetIndex $ayahIndex, Sure: $sureName, Ayet: $ayetNumber');
          final localizedSurahName = SurahLocalizationService.getLocalizedSurahName(sureName, context);
          final verseFormat = AppLocalizations.of(context)?.surahVerseFormat(localizedSurahName, int.tryParse(ayetNumber) ?? 0, AppLocalizations.of(context)?.verse ?? 'Verse') ?? '$localizedSurahName, $ayetNumber. Ayet';
          String bookmarkText = '$ayahText\n($verseFormat)';
          if (mealText != null && mealText.isNotEmpty) {
            bookmarkText += '\n[Terceme]: $mealText';
          }
          await _bookmarkService.addBookmark(
            'quran',
            pageNumber,
            selectedText: bookmarkText,
            highlightColor: color,
            startIndex: ayahIndex,
            endIndex: ayahIndex,
            surahId: surahId,
            surahName: sureName,
            ayahNumber: ayetNumber,
          );
          if (widget.onHighlightChanged != null) widget.onHighlightChanged!();
        },
      ),
    );
  }
}

/// Takipli görünüm için yükleme bileşeni
class QuranTakipliLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Sayfa yükleniyor...'),
        ],
      ),
    );
  }
}

/// Takipli görünüm için hata bileşeni
class QuranTakipliError extends StatelessWidget {
  final String error;

  const QuranTakipliError({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'Hata: $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

// Translation bubble classes removed

Widget _slimButton(Widget btn, double fontSize, double iconSize,
    {bool isActive = false}) {
  if (btn is TextButton) {
    return TextButton(
      onPressed: btn.onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        minimumSize: Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isActive ? Colors.deepPurple.withOpacity(0.1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (btn.child is Row) ...[
            ...(btn.child as Row).children,
          ] else
            btn.child!,
        ],
      ),
    );
  }
  return btn;
}

// Share options dialog removed - using direct native share
