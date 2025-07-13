import 'package:flutter/material.dart';
import '../controllers/quran_page_controller.dart';
import '../controllers/quran_audio_controller.dart';
import 'quran_takipli_view.dart' hide QuranTakipliLoading, QuranTakipliError;
import 'quran_regular_view.dart';
import 'quran_takipli_widgets.dart';
import 'dart:io';

/// Kuran sayfası ekranının body kısmını oluşturan widget
class QuranBodyBuilder {
  final QuranPageController pageController;
  final QuranAudioController audioController;
  final BuildContext context;
  final bool showMeal;
  final VoidCallback? onHighlightChanged;

  QuranBodyBuilder({
    required this.pageController,
    required this.audioController,
    required this.context,
    this.showMeal = false,
    this.onHighlightChanged,
  });

  Widget build() {
    // Format değişikliğini kontrol et
    final isTakipli = pageController.quranBook.selectedFormat == 'Mukabele';

    return Container(
      color: pageController.backgroundColor,
      // Tam ekran modunda üstte status bar için padding ekle, altta padding kaldır
      padding: pageController.isFullScreen
          ? EdgeInsets.only(top: MediaQuery.of(context).padding.top)
          : EdgeInsets.only(
              bottom: audioController.showAudioProgress ? 100 : 48,
              right: isTakipli
                  ? 4.0
                  : 0.0, // Scrollbar için sağ tarafta boşluk bırak
            ),
      child: isTakipli ? _buildTakipliView() : _buildRegularView(),
    );
  }

  Widget _buildTakipliView() {
    return GestureDetector(
      onDoubleTap: () {
        // Çift tık ile tam ekran modunu değiştir
        pageController.toggleFullScreen();
      },
      behavior: HitTestBehavior.translucent,
      child: _EdgeAwarePageView(
        pageController: pageController.pageController,
        audioController: audioController,
        itemBuilder: (context, index) {
          // Her sayfa için ayrı bir Future oluştur
          Future<Map<String, dynamic>> loadPage() async {
            try {
              // Önbellekte veri varsa onu kullan
              if (audioController.pageDataCache.containsKey(index)) {
                return audioController.pageDataCache[index]!;
              }

              // Yeni veriyi yükle
              final data =
                  await pageController.takipliService.getPageData(index);
              audioController.pageDataCache[index] = Future.value(data);
              return data;
            } catch (e) {
              print('Sayfa $index yükleme hatası: $e');
              return {};
            }
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: loadPage(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final pageData = snapshot.data!;
                return QuranTakipliView(
                  pageData: pageData,
                  activeWordIndex:
                      audioController.audioService.currentWordIndex,
                  selectedFont: pageController.selectedFont,
                  fontSize: pageController.fontSize,
                  backgroundColor: pageController.backgroundColor,
                  wordKeys: pageController.wordKeys,
                  scrollController: pageController.getScrollController(index),
                  isAutoScroll: pageController.isAutoScroll,
                  pageNumber: index,
                  showMeal: showMeal,
                  onHighlightChanged: onHighlightChanged,
                );
              }

              if (snapshot.hasError) {
                return QuranTakipliError(error: '${snapshot.error}');
              }

              return QuranTakipliLoading();
            },
          );
        },
        itemCount: 605,
        onPageChanged: (index) {
          try {
            // Ses çalıyor mu kontrol et
            final wasPlaying = audioController.showAudioProgress ||
                audioController.audioService.isPlaying ||
                audioController.audioService.isBesmelePlaying;

            // Mevcut sayfayı kaydet (değişimden önce)
            final oldPage = pageController.currentPage;

            print(
                'PageView onPageChanged: Eski sayfa: $oldPage, Yeni sayfa: $index');

            // Ses çalıyorsa durdur
            if (!audioController.audioService.isDisposed &&
                (audioController.audioService.isPlaying ||
                    audioController.audioService.isBesmelePlaying)) {
              try {
                print('Sayfa kaydırma sırasında ses durduruldu');
                audioController.audioService.stop();
              } catch (e) {
                print('Ses durdurma hatası: $e');
              }
            }

            // Önce controller'ın onPageChanged metodunu çağır
            // Bu metot pageController.currentPage değerini günceller
            pageController.onPageChanged(index);

            // AudioService'in sayfa numarasını güncelle
            if (!audioController.audioService.isDisposed) {
              audioController.audioService.setCurrentPage(index);
            }

            // Eğer önceden ses çalıyorsa veya besmele çalıyorsa, yeni sayfanın sesini otomatik başlat
            if (wasPlaying && !audioController.audioService.isDisposed) {
              // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
              // Geri sayfalara zıplarken daha uzun bir bekleme süresi ekle
              final delay = index < oldPage ? 800 : 500;
              Future.delayed(Duration(milliseconds: delay), () {
                if (!audioController.audioService.isDisposed) {
                  try {
                    print(
                        'Sayfa kaydırma sonrası ses çalma başlatılıyor: $index');
                    // Yeni sayfanın verilerini yükle ve sesi çal
                    audioController.loadAndPlayCurrentPage();
                  } catch (e) {
                    print('Sayfa kaydırma sonrası ses çalma hatası: $e');
                  }
                }
              });
            }
          } catch (e) {
            print('onPageChanged genel hatası: $e');
          }
        },
      ),
    );
  }

  Widget _buildRegularView() {
    return GestureDetector(
      onTap: () {
        // Tek tık için mevcut davranış (gerekirse kaldırılabilir)
      },
      onDoubleTap: () {
        // Çift tık ile tam ekran modunu değiştir
        print('QuranBodyBuilder._buildRegularView: onDoubleTap çağrıldı');
        pageController.toggleFullScreen();
      },
      behavior: HitTestBehavior.translucent,
      child: PageView.builder(
        controller: pageController.pageController,
        reverse: true,
        onPageChanged: (index) {
          try {
            // Sayfa değiştiğinde tam ekran durumunu koru
            print(
                'PageView onPageChanged: Sayfa değişti, tam ekran durumu: ${pageController.isFullScreen}');

            // Ses çalıyor mu kontrol et
            final wasPlaying = audioController.showAudioProgress ||
                audioController.audioService.isPlaying ||
                audioController.audioService.isBesmelePlaying;

            // Mevcut sayfayı kaydet (değişimden önce)
            final oldPage = pageController.currentPage;

            print(
                'PageView onPageChanged: Eski sayfa: $oldPage, Yeni sayfa: $index');

            // Ses çalıyorsa durdur
            if (!audioController.audioService.isDisposed &&
                (audioController.audioService.isPlaying ||
                    audioController.audioService.isBesmelePlaying)) {
              try {
                print('Sayfa kaydırma sırasında ses durduruldu');
                audioController.audioService.stop();
              } catch (e) {
                print('Ses durdurma hatası: $e');
              }
            }

            // Önce controller'ın onPageChanged metodunu çağır
            // Bu metot pageController.currentPage değerini günceller
            pageController.onPageChanged(index);

            // AudioService'in sayfa numarasını güncelle
            if (!audioController.audioService.isDisposed) {
              audioController.audioService.setCurrentPage(index);
            }

            // Eğer önceden ses çalıyorsa veya besmele çalıyorsa, yeni sayfanın sesini otomatik başlat
            if (wasPlaying && !audioController.audioService.isDisposed) {
              // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
              // Geri sayfalara zıplarken daha uzun bir bekleme süresi ekle
              final delay = index < oldPage ? 800 : 500;
              Future.delayed(Duration(milliseconds: delay), () {
                if (!audioController.audioService.isDisposed) {
                  try {
                    print(
                        'Sayfa kaydırma sonrası ses çalma başlatılıyor: $index');
                    // Yeni sayfanın verilerini yükle ve sesi çal
                    audioController.loadAndPlayCurrentPage();
                  } catch (e) {
                    print('Sayfa kaydırma sonrası ses çalma hatası: $e');
                  }
                }
              });
            }
          } catch (e) {
            print('onPageChanged genel hatası: $e');
          }
        },
        itemCount: 605,
        itemBuilder: (context, index) {
          // Artık index doğrudan sayfa numarası olduğu için +1 eklemeye gerek yok
          final displayPage = index;
          return QuranRegularView(
            pageNumber: displayPage,
            pageImage: pageController.getPageFromCacheOrLoad(displayPage),
            backgroundColor: pageController.backgroundColor,
            onTap: () {
              // Tek tık için mevcut davranış (gerekirse kaldırılabilir)
            },
            onDoubleTap: () {
              // Çift tık ile tam ekran modunu değiştir
              pageController.toggleFullScreen();
            },
          );
        },
      ),
    );
  }
}

class _EdgeAwarePageView extends StatefulWidget {
  final PageController pageController;
  final QuranAudioController audioController;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  const _EdgeAwarePageView({
    required this.pageController,
    required this.audioController,
    required this.itemBuilder,
    required this.itemCount,
    required this.onPageChanged,
  });
  @override
  State<_EdgeAwarePageView> createState() => _EdgeAwarePageViewState();
}

class _EdgeAwarePageViewState extends State<_EdgeAwarePageView> {
  bool _blockSwipe = false;
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        final details = notification.dragDetails;
        final screenWidth = MediaQuery.of(context).size.width;
        if (details != null &&
            (details.globalPosition.dx < 24 ||
                details.globalPosition.dx > screenWidth - 24)) {
          setState(() {
            _blockSwipe = true;
          });
        } else {
          setState(() {
            _blockSwipe = false;
          });
        }
        return false;
      },
      child: PageView.builder(
        controller: widget.pageController,
        reverse: true,
        physics: _blockSwipe
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: widget.onPageChanged,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
