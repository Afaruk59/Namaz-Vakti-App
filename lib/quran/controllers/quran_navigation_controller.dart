import 'package:flutter/material.dart';
import '../controllers/quran_page_controller.dart';
import '../controllers/quran_audio_controller.dart';

/// Kuran sayfaları arasında gezinme işlevleri için controller sınıfı
class QuranNavigationController {
  final QuranPageController pageController;
  final QuranAudioController audioController;
  final BuildContext context;

  QuranNavigationController({
    required this.pageController,
    required this.audioController,
    required this.context,
  });

  void showPageInputDialog() {
    int? selectedPage;
    // Ses çalıyor mu kontrol et
    final wasPlaying = audioController.showAudioProgress;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sayfa Numarası Girin'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0-604 arası bir sayfa numarası girin',
            ),
            onChanged: (value) {
              selectedPage = int.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPage != null &&
                    selectedPage! >= 0 &&
                    selectedPage! <= 604) {
                  // Önce ses çalmayı tamamen durdur
                  if (audioController.audioService.isPlaying ||
                      audioController.audioService.isBesmelePlaying) {
                    print('Sayfa değişimi öncesi ses durduruldu');
                    await audioController.audioService.stop();

                    // UI'ı güncelle
                    audioController.showAudioProgress = false;
                  }

                  // Sayfa değişimini gerçekleştir
                  print(
                      'Sayfa değişimi yapılıyor: ${pageController.currentPage} -> $selectedPage');
                  pageController.changePage(selectedPage!);
                  Navigator.of(context).pop();

                  // Eğer önceden ses çalıyorsa, yeni sayfanın sesini otomatik başlat
                  if (wasPlaying) {
                    // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
                    // Daha uzun bir bekleme süresi ekleyerek sayfa değişiminin tamamlanmasını bekle
                    Future.delayed(Duration(milliseconds: 1500), () {
                      print(
                          'Sayfa değişimi sonrası ses çalma başlatılıyor: $selectedPage');
                      // Yeni sayfanın verilerini yükle ve sesi çal
                      audioController.loadAndPlayCurrentPage();
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Lütfen 0-604 arası geçerli bir sayfa numarası girin.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('Git'),
            ),
          ],
        );
      },
    );
  }

  void goToPreviousPage() {
    // Ses çalıyor mu kontrol et
    final wasPlaying = audioController.showAudioProgress ||
        audioController.audioService.isPlaying ||
        audioController.audioService.isBesmelePlaying;

    // Ses çalıyorsa durdur
    if (audioController.audioService.isPlaying ||
        audioController.audioService.isBesmelePlaying) {
      audioController.audioService.stop();
    }

    // Önceki sayfa (sola doğru - Kuran sağdan sola okunduğu için)
    pageController.pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Eğer önceden ses çalıyorsa veya besmele çalıyorsa, yeni sayfanın sesini otomatik başlat
    if (wasPlaying) {
      // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
      Future.delayed(Duration(milliseconds: 500), () {
        audioController.loadAndPlayCurrentPage();
      });
    }
  }

  void goToNextPage() {
    // Ses çalıyor mu kontrol et
    final wasPlaying = audioController.showAudioProgress ||
        audioController.audioService.isPlaying ||
        audioController.audioService.isBesmelePlaying;

    // Ses çalıyorsa durdur
    if (audioController.audioService.isPlaying ||
        audioController.audioService.isBesmelePlaying) {
      audioController.audioService.stop();
    }

    // Sonraki sayfa (sağa doğru - Kuran sağdan sola okunduğu için)
    pageController.pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Eğer önceden ses çalıyorsa veya besmele çalıyorsa, yeni sayfanın sesini otomatik başlat
    if (wasPlaying) {
      // Sayfa değişimi tamamlandıktan sonra yeni sayfanın sesini çal
      Future.delayed(Duration(milliseconds: 500), () {
        audioController.loadAndPlayCurrentPage();
      });
    }
  }

  // Kuran içinde arama yapan metod
  Future<List<Map<String, dynamic>>> searchInQuran(
      String bookCode, String query) async {
    // IndexDrawer içindeki quranIndex listesini kullanarak arama yapıyoruz
    // Bu metod, IndexDrawer'ın searchFunction parametresi için kullanılıyor
    if (query.isEmpty) return [];

    // Kuran surelerinde arama yap
    final results = <Map<String, dynamic>>[];

    // Basit bir sure listesi ile arama yapıyoruz
    final surahNames = [
      'Fatiha', 'Bakara', 'Al-i İmran', 'Nisa', 'Maide', 'Enam', 'Araf',
      'Enfal', 'Tevbe', 'Yunus', 'Hud', 'Yusuf', 'Rad', 'İbrahim',
      'Hicr', 'Nahl', 'İsra', 'Kehf', 'Meryem', 'Taha', 'Enbiya',
      'Hac', 'Muminun', 'Nur', 'Furkan', 'Şuara', 'Neml', 'Kasas',
      'Ankebut', 'Rum', 'Lokman', 'Secde', 'Ahzab', 'Sebe', 'Fatır',
      'Yasin', 'Saffat', 'Sad', 'Zümer', 'Mümin', 'Fussilet', 'Şura',
      'Zuhruf', 'Duhan', 'Casiye', 'Ahkaf', 'Muhammed', 'Fetih',
      'Hucurat', 'Kaf', 'Zariyat', 'Tur', 'Necm', 'Kamer', 'Rahman',
      'Vakia', 'Hadid', 'Mücadele', 'Haşr', 'Mümtehine', 'Saff',
      'Cuma', 'Münafikun', 'Tegabün', 'Talak', 'Tahrim', 'Mülk',
      'Kalem', 'Hakka', 'Mearic', 'Nuh', 'Cin', 'Müzzemmil', 'Müddessir',
      'Kıyame', 'İnsan', 'Mürselat', 'Nebe', 'Naziat', 'Abese', 'Tekvir',
      'İnfitar', 'Mutaffifin', 'İnşikak', 'Buruc', 'Tarık', 'Ala',
      'Gaşiye', 'Fecr', 'Beled', 'Şems', 'Leyl', 'Duha', 'İnşirah',
      'Tin', 'Alak', 'Kadir', 'Beyyine', 'Zilzal', 'Adiyat', 'Karia',
      'Tekasür', 'Asr', 'Hümeze', 'Fil', 'Kureyş', 'Maun', 'Kevser',
      'Kafirun', 'Nasr', 'Tebbet', 'İhlas', 'Felak', 'Nas'
    ];

    for (int i = 0; i < surahNames.length; i++) {
      if (surahNames[i].toLowerCase().contains(query.toLowerCase())) {
        results.add({
          'page': i + 1, // Basit sayfa numarası
          'text': surahNames[i],
          'shortdesc': 'Sure ${i + 1}',
        });
      }
    }

    // Arama sonuçlarını döndür
    return results;
  }
}
