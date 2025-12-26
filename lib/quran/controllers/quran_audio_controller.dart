import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/quran_audio_service.dart';
import '../audio/quran_audio_repository.dart';
import '../controllers/quran_page_controller.dart';
import '../audio/quran_media_controller.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kuran ses kontrolü için controller sınıfı
class QuranAudioController with ChangeNotifier {
  final QuranAudioService audioService;
  final QuranPageController pageController;
  final BuildContext context;
  late QuranMediaController mediaController;
  final AudioPlayerService audioPlayerService = AudioPlayerService.forContext('quran');

  bool showAudioProgress = false;
  final Map<int, Future<Map<String, dynamic>>> pageDataCache = {};
  final QuranAudioRepository audioRepository = QuranAudioRepository();
  bool _isDetached = false; // Add this flag to track if controller is detached but not disposed
  bool _mediaNotificationClosed = false;

  QuranAudioController({
    required this.audioService,
    required this.pageController,
    required this.context,
  }) {
    audioService.addListener(_onAudioServiceUpdate);

    // MediaController'ı başlat
    mediaController = QuranMediaController(
      audioService: audioService,
      audioPlayerService: audioPlayerService,
    );

    // Sayfa değişim callback'lerini ayarla
    _setupMediaCallbacks();
  }

  // MediaController için sayfa değişim callback'lerini ayarla
  void _setupMediaCallbacks() {
    mediaController.setPageChangeCallbacks(
      onNextPage: (nextPage) {
        // Sonraki sayfaya git
        if (nextPage <= 604) {
          pageController.changePage(nextPage);
        }
      },
      onPreviousPage: (prevPage) {
        // Önceki sayfaya git
        if (prevPage >= 0) {
          pageController.changePage(prevPage);
        }
      },
      currentPage: pageController.currentPage,
    );
    // Method channel handler'ı tekrar kur
    mediaController.setupMethodCallHandler();
  }

  // Sayfa değiştiğinde MediaController'ı güncelle
  void updateMediaController() {
    if (_mediaNotificationClosed) return;
    // Mevcut sayfa bilgisini güncelle
    mediaController.updateCurrentPage(pageController.currentPage);

    // Eğer ses çalınıyorsa, medya bilgilerini güncelle
    if (showAudioProgress) {
      String surahName;
      int ayahNumber;

      // Besmele çalıyorsa veya besmele durumundaysa
      if (audioService.isBesmelePlayingOrWas) {
        // Besmele için sure adını al, ayet numarasını 0 yap
        surahName =
            audioService.currentSurah > 0 ? audioService.getCurrentSurahName() : "Kuran-ı Kerim";
        ayahNumber = 0; // Besmele için ayet numarası 0
      } else {
        // Normal ayet çalıyorsa
        final surahAndAyah = audioService.getCurrentSurahAndAyah();
        if (surahAndAyah.contains(':')) {
          surahName = surahAndAyah.split(':')[0];
          ayahNumber = audioService.currentAyah;
        } else {
          // Fallback durumu
          surahName =
              audioService.currentSurah > 0 ? audioService.getCurrentSurahName() : "Kuran-ı Kerim";
          ayahNumber = audioService.currentAyah;
        }
      }

      mediaController.updateForQuranPage(
        pageController.currentPage,
        surahName,
        ayahNumber,
        context: context,
      );
    }
    notifyListeners();
  }

  void _onAudioServiceUpdate() {
    if (!hasListeners) return;

    final newPage = audioService.currentPage;

    // Otomatik sayfa değişimi kontrolü - sadece otomatik ses çalma işlemlerinde
    if (newPage != pageController.currentPage &&
        newPage >= 0 &&
        newPage <= 604 &&
        audioService.isPlaying) {
      // Only change page automatically if audio is playing
      // Besmele çalıyorsa sayfa değişimi yapma
      if (audioService.isBesmelePlaying) {
        print('Besmele çalarken otomatik sayfa değişimi engellendi');
        // Sayfa değişimi yapmadan ses çalmaya devam et
        if (audioService.isPlaying) {
          audioService.resume();
        }
      } else {
        // Besmele çalmıyorsa normal davran
        print('Otomatik sayfa değişimi yapılıyor: ${pageController.currentPage} -> $newPage');

        // Sayfa değişimini gerçekleştir
        pageController.changePage(newPage);

        print('Sayfa değişimi gerçekleştirildi: $newPage');

        // Sayfa değişiminden sonra ses durumunu kontrol et
        if (audioService.isPlaying) {
          // Sayfa değişimi tamamlandıktan sonra kısa bir bekleme ekle
          Future.delayed(Duration(milliseconds: 500), () {
            if (audioService.isPlaying) {
              print('Sayfa değişiminden sonra ses devam ettiriliyor');
              audioService.resume();
            }
          });
        }
      }
    } else {
      // Kullanıcı tarafından yapılan manuel sayfa değişimlerinde
      // AudioService'in sayfa numarasını güncelle
      if ((audioService.isPlaying || audioService.isBesmelePlaying) &&
          audioService.currentPage != pageController.currentPage) {
        print(
            'Kullanıcı tarafından sayfa değişimi yapıldı. AudioService sayfa numarası güncelleniyor: ${pageController.currentPage}');
        audioService.setCurrentPage(pageController.currentPage);
      }
    }

    // Kelime takibi için sayfa verilerini önbelleğe al
    if (audioService.isPlaying && !pageDataCache.containsKey(pageController.currentPage)) {
      pageDataCache[pageController.currentPage] = pageController.loadCurrentPageData();
    }

    // Ses çalma durumunu güncelle
    // Progress bar'ı sadece stop düğmesine basıldığında gizle
    // Ayet geçişleri sırasında progress bar'ı görünür tut

    // Sayfa değişimi veya ayet değişimi sırasında progress bar'ı korumak için
    // audioService.isAyahChanging kontrolü ekleyelim
    bool isInTransition = audioService.isAyahChanging;

    // Eğer ses çalıyorsa, besmele çalıyorsa veya geçiş durumundaysa progress bar'ı göster
    if (audioService.isPlaying || audioService.isBesmelePlaying || isInTransition) {
      if (!showAudioProgress) {
        showAudioProgress = true;
        print('Progress bar gösteriliyor - ses çalıyor veya geçiş durumunda');
      }
    } else {
      // Ses çalmıyorsa ve geçiş durumunda değilse, sadece position sıfırsa progress bar'ı gizle
      // Bu, sadece stop düğmesine basıldığında olur
      if (showAudioProgress && audioService.position.inMilliseconds == 0 && !isInTransition) {
        // Eğer ses tamamen durdurulmuşsa (stop), showAudioProgress'i false yap
        showAudioProgress = false;
        print('Progress bar gizleniyor - ses tamamen durduruldu');
      }
    }

    // MediaController'ı güncelle
    if (showAudioProgress) {
      String surahName;
      int ayahNumber;

      // Besmele çalıyorsa veya besmele durumundaysa
      if (audioService.isBesmelePlayingOrWas) {
        // Besmele için sure adını al, ayet numarasını 0 yap
        surahName =
            audioService.currentSurah > 0 ? audioService.getCurrentSurahName() : "Kuran-ı Kerim";
        ayahNumber = 0; // Besmele için ayet numarası 0
      } else {
        // Normal ayet çalıyorsa
        final surahAndAyah = audioService.getCurrentSurahAndAyah();
        if (surahAndAyah.contains(':')) {
          surahName = surahAndAyah.split(':')[0];
          ayahNumber = audioService.currentAyah;
        } else {
          // Fallback durumu
          surahName =
              audioService.currentSurah > 0 ? audioService.getCurrentSurahName() : "Kuran-ı Kerim";
          ayahNumber = audioService.currentAyah;
        }
      }

      mediaController.updateForQuranPage(
        pageController.currentPage,
        surahName,
        ayahNumber,
        context: context,
      );
    }

    notifyListeners();
  }

  // Sesi duraklat
  void pauseAudio() async {
    print(
        'pauseAudio çağrıldı - showAudioProgress: $showAudioProgress, isPlaying: ${audioService.isPlaying}, isBesmelePlaying: ${audioService.isBesmelePlaying}');

    // Ses çalıyor mu kontrol et
    if (audioService.isPlaying || audioService.isBesmelePlaying) {
      try {
        // Sesi duraklat
        await audioService.pauseAudio();
        print(
            'Ses duraklatıldı - isPlaying: ${audioService.isPlaying}, isBesmelePlaying: ${audioService.isBesmelePlaying}');
        notifyListeners();
      } catch (e) {
        print('pauseAudio hatası: $e');
      }
    } else {
      print('Ses zaten duraklatılmış durumda');
    }
  }

  // Duraklatılmış sesi devam ettir
  void resumeAudio() async {
    print(
        'resumeAudio çağrıldı - showAudioProgress: $showAudioProgress, isPlaying: ${audioService.isPlaying}, isBesmelePlaying: ${audioService.isBesmelePlaying}');

    // Progress bar gösteriliyor mu kontrol et
    if (showAudioProgress) {
      try {
        // Koşulsuz olarak resume() metodunu çağır
        // audioService.resume() metodu içinde gerekli kontroller yapılıyor
        await audioService.resumeAudio();
        print(
            'Ses devam ettiriliyor - isPlaying: ${audioService.isPlaying}, isBesmelePlaying: ${audioService.isBesmelePlaying}');
        notifyListeners();
      } catch (e) {
        print('resumeAudio hatası: $e');
      }
    } else {
      print('Progress bar gösterilmiyor, ses devam ettirilmedi');
    }
  }

  void stopAudio() async {
    // Ses çalıyor, duraklatılmış veya besmele çalıyor durumda olabilir
    if (showAudioProgress || audioService.isBesmelePlaying) {
      print('Stop düğmesine basıldı, ses tamamen durduruluyor');
      // --- EKLENDİ: Bildirim player'ı kapatmak için playback state'i güncelle ---
      await mediaController.updatePlaybackState(QuranMediaController.STATE_STOPPED);
      await Future.delayed(Duration(milliseconds: 100));
      await mediaController.stopService();
      await Future.delayed(Duration(milliseconds: 200));
      await mediaController.stopService();

      await audioService.stop();

      // Progress bar'ı hemen gizle
      showAudioProgress = false;
      _mediaNotificationClosed = true;

      // ÖNEMLİ: Kuran sistemi durdurulduğunda playing_book_code'u temizle
      // Bu, kitap sistemi handler'larının aktif olmasını sağlar
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('playing_book_code');
        print(
            'QuranAudioController: playing_book_code temizlendi, kitap sistemi handler\'ları aktif olabilir');
      } catch (e) {
        print('QuranAudioController: playing_book_code temizlenemedi: $e');
      }

      notifyListeners();
    }
  }

  Future<void> playAudio() async {
    // --- EKLENDİ: Kuran için notification player tuşları çalışsın diye gerekli anahtarları kaydet ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playing_book_code', 'quran');
    await prefs.setInt('quran_current_audio_page', pageController.currentPage);
    await prefs.setInt('quran_first_page', 1);
    await prefs.setInt('quran_last_page', 604);

    // Her playAudio çağrısında callback ve handler'ı tekrar kur
    if (_mediaNotificationClosed) return;
    _setupMediaCallbacks();

    // --- EKLENDİ: Servis ve handler'ı başlat ---
    await mediaController.startService();
    mediaController.setupMethodCallHandler();

    // Method channel servisini native tarafa bildir (kitap sistemi gibi)
    try {
      const mediaServiceChannel = MethodChannel('com.afaruk59.namaz_vakti_app/media_controls');
      await mediaServiceChannel.invokeMethod('initMediaService');

      // ÖNEMLİ: Kuran sistemi aktif olduğunda, kitap sistemi handler'ını temizle
      // Bu, method channel çakışmalarını önler
      await mediaServiceChannel.invokeMethod('clearBookHandler');

      // Ek güvenlik: Method channel handler'ını yeniden kur
      await Future.delayed(const Duration(milliseconds: 100));
      mediaController.setupMethodCallHandler();
    } catch (e) {
      print('Quran initMediaService hatası: $e');
    }
    // Eğer ses çalıyor, duraklatılmış veya besmele çalıyor durumda ise
    if (showAudioProgress || audioService.isBesmelePlaying) {
      print('Play/Stop düğmesine basıldı, ses tamamen durduruluyor');
      await audioService.stop();
      showAudioProgress = false;

      // MediaController'ı durdur
      mediaController.stopService();

      notifyListeners();
      return;
    }

    final currentDisplayPage = pageController.currentPage;
    print('Ses çalma başlatılıyor - Sayfa: $currentDisplayPage');

    if (currentDisplayPage < 0 || currentDisplayPage > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu sayfa için ses kaydı bulunmamaktadır')),
      );
      return;
    }

    // Önce UI'ı güncelle, kullanıcıya geri bildirim ver
    showAudioProgress = true;
    notifyListeners();

    try {
      // Önbellekte sayfa verisi var mı kontrol et, yoksa yükle
      if (!pageDataCache.containsKey(currentDisplayPage)) {
        print('Sayfa verisi önbellekte yok, yükleniyor: $currentDisplayPage');
        // Sayfa verisini yüklerken kullanıcıya bilgi ver - sadece Mukabele formatında göster
        if (pageController.quranBook.selectedFormat == 'Mukabele') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sayfa verisi yükleniyor...')),
          );
        }
        // Doğrudan takipliService'i kullanarak sayfa verisini yükle
        pageDataCache[currentDisplayPage] =
            pageController.takipliService.getPageData(currentDisplayPage);
      } else {
        print('Sayfa verisi önbellekte bulundu: $currentDisplayPage');
      }

      // Mevcut sayfanın verilerini önbellekten al
      final pageData = await pageDataCache[currentDisplayPage]!;

      // pageData boş kontrolü
      if (pageData.isEmpty) {
        throw Exception('Sayfa verisi yüklenemedi');
      }

      final currentSurahNo = pageData['surahNo'] as int?;
      final currentAyahNo = pageData['ayahNo'] as int?;

      if (currentSurahNo == null || currentAyahNo == null) {
        throw Exception('Mevcut sayfa için sure ve ayet numarası bulunamadı');
      }

      print(
          'Sayfa verisi yüklendi: Sure: $currentSurahNo, Ayet: $currentAyahNo, Sayfa: $currentDisplayPage');

      // Önce _audioService'in currentPage değerini güncelle
      audioService.setCurrentPage(currentDisplayPage);

      // Kısa bir bekleme ekleyerek sayfa değişiminin tamamlanmasını bekle
      await Future.delayed(Duration(milliseconds: 200));

      // Eğer ayet 1 ise ve sure 9 (Tevbe) değilse, besmele çal
      final shouldPlayBesmele = currentAyahNo == 1 && currentSurahNo != 9 && currentSurahNo != 1;

      // Ses dosyası ve XML için aynı ayeti kullan
      final audioUrl = audioRepository.getAudioUrl(currentSurahNo, currentAyahNo);
      final xmlUrl = audioRepository.getXmlUrl(currentSurahNo, currentAyahNo);

      print('Audio URL: $audioUrl');
      print('XML URL: $xmlUrl');

      // Ses çalmayı başlat
      await audioService.playAyah(
        surahNo: currentSurahNo,
        ayahNo: currentAyahNo,
        audioUrl: audioUrl,
        xmlUrl: xmlUrl,
        shouldPlayBesmele: shouldPlayBesmele,
        isUserInitiated: true,
      );

      // MediaController'ı güncelle
      final surahName = audioRepository.getSurahName(currentSurahNo);
      if (!_mediaNotificationClosed) {
        mediaController.updateForQuranPage(
          currentDisplayPage,
          surahName,
          currentAyahNo,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Ses çalma hatası: $e');
      showAudioProgress = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses çalma hatası: $e')),
      );
    }
  }

  // Komşu sayfaların verilerini önbelleğe al
  void _preloadAdjacentPageData(int currentPage) {
    try {
      // Önceki sayfa
      if (currentPage > 0 && !pageDataCache.containsKey(currentPage - 1)) {
        pageDataCache[currentPage - 1] =
            pageController.takipliService.getPageData(currentPage - 1).catchError((error) {
          print('Önceki sayfa önbelleğe alma hatası: $error');
          // Hata durumunda önbellekten kaldır
          pageDataCache.remove(currentPage - 1);
          return <String, dynamic>{};
        });
      }

      // Sonraki sayfa
      if (currentPage < 604 && !pageDataCache.containsKey(currentPage + 1)) {
        pageDataCache[currentPage + 1] =
            pageController.takipliService.getPageData(currentPage + 1).catchError((error) {
          print('Sonraki sayfa önbelleğe alma hatası: $error');
          // Hata durumunda önbellekten kaldır
          pageDataCache.remove(currentPage + 1);
          return <String, dynamic>{};
        });
      }

      // Önceki 2. sayfa (geri zıplamalarda daha hızlı yükleme için)
      if (currentPage > 1 && !pageDataCache.containsKey(currentPage - 2)) {
        pageDataCache[currentPage - 2] =
            pageController.takipliService.getPageData(currentPage - 2).catchError((error) {
          print('Önceki 2. sayfa önbelleğe alma hatası: $error');
          // Hata durumunda önbellekten kaldır
          pageDataCache.remove(currentPage - 2);
          return <String, dynamic>{};
        });
      }
    } catch (e) {
      print('Komşu sayfaları önbelleğe alma genel hatası: $e');
      // Genel hata durumunda işlemi sessizce geç, kullanıcı deneyimini etkilemesin
    }
  }

  Future<void> loadAndPlayCurrentPage() async {
    try {
      // AudioService dispose edilmiş mi kontrol et
      if (audioService.isDisposed) {
        print('AudioService dispose edilmiş, ses çalma işlemi iptal edildi');
        return;
      }

      final currentDisplayPage = pageController.currentPage;
      print('loadAndPlayCurrentPage çağrıldı - Sayfa: $currentDisplayPage');

      if (currentDisplayPage < 0 || currentDisplayPage > 604) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu sayfa için ses kaydı bulunmamaktadır')),
        );
        return;
      }

      // UI'ı güncelle, kullanıcıya geri bildirim ver
      showAudioProgress = true;
      notifyListeners();

      // Önce ses çalmayı tamamen durdur
      if (!audioService.isDisposed && (audioService.isPlaying || audioService.isBesmelePlaying)) {
        try {
          print('Yeni ses çalma öncesi mevcut ses durduruldu');
          await audioService.stop();

          // Progress bar'ı görünür tut
          showAudioProgress = true;

          // Kısa bir bekleme ekleyerek ses dosyasının tamamen durmasını sağla
          await Future.delayed(Duration(milliseconds: 200));
        } catch (e) {
          print('Ses durdurma hatası: $e');
          // Hata olsa bile devam et
        }
      }

      // AudioService'in sayfa numarasını güncelle
      if (!audioService.isDisposed) {
        audioService.setCurrentPage(currentDisplayPage);
        print('AudioService sayfa numarası güncellendi: $currentDisplayPage');
      } else {
        print('AudioService dispose edilmiş, sayfa numarası güncellenemedi');
        return;
      }

      // Önbellekte sayfa verisi var mı kontrol et, yoksa yükle
      if (!pageDataCache.containsKey(currentDisplayPage)) {
        print('Sayfa verisi önbellekte yok, yükleniyor: $currentDisplayPage');
        // Sayfa verisini yüklerken kullanıcıya bilgi ver - sadece Mukabele formatında göster
        if (pageController.quranBook.selectedFormat == 'Mukabele') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sayfa verisi yükleniyor...')),
          );
        }
        // Doğrudan takipliService'i kullanarak sayfa verisini yükle
        pageDataCache[currentDisplayPage] =
            pageController.takipliService.getPageData(currentDisplayPage);
      } else {
        print('Sayfa verisi önbellekte bulundu: $currentDisplayPage');
      }

      // Mevcut sayfanın verilerini önbellekten al
      final pageData = await pageDataCache[currentDisplayPage]!;

      // pageData boş kontrolü
      if (pageData.isEmpty) {
        throw Exception('Sayfa verisi yüklenemedi');
      }

      final currentSurahNo = pageData['surahNo'] as int?;
      final currentAyahNo = pageData['ayahNo'] as int?;

      if (currentSurahNo == null || currentAyahNo == null) {
        throw Exception('Mevcut sayfa için sure ve ayet numarası bulunamadı');
      }

      print(
          'Sayfa verisi yüklendi: Sure: $currentSurahNo, Ayet: $currentAyahNo, Sayfa: $currentDisplayPage');

      // AudioService tekrar kontrol et
      if (audioService.isDisposed) {
        print('AudioService dispose edilmiş, ses çalma işlemi iptal edildi');
        showAudioProgress = false;
        notifyListeners();
        return;
      }

      // Kısa bir bekleme ekleyerek sayfa değişiminin tamamlanmasını bekle
      await Future.delayed(Duration(milliseconds: 300));

      // Ses dosyası ve XML için aynı ayeti kullan
      // Eğer ayet 1 ise ve sure 9 (Tevbe) değilse, besmele çal
      final shouldPlayBesmele = currentAyahNo == 1 && currentSurahNo != 9 && currentSurahNo != 1;

      try {
        // Ses dosyası ve XML URL'lerini al
        final audioUrl = audioRepository.getAudioUrl(currentSurahNo, currentAyahNo);
        final xmlUrl = audioRepository.getXmlUrl(currentSurahNo, currentAyahNo);

        // Yeni formatta playAyah metodunu çağır
        await audioService.playAyah(
          surahNo: currentSurahNo,
          ayahNo: currentAyahNo,
          audioUrl: audioUrl,
          xmlUrl: xmlUrl,
          shouldPlayBesmele: shouldPlayBesmele,
          isUserInitiated: true,
        );
      } catch (e) {
        print('Ayet çalma hatası: $e');
        showAudioProgress = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayet çalınamadı: $e')),
        );
        return;
      }

      // Sayfa verilerini önbelleğe al
      _preloadAdjacentPageData(currentDisplayPage);
    } catch (e) {
      print('Ses oynatma genel hatası: $e');
      showAudioProgress = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses dosyası oynatılamadı: $e')),
      );
    }
  }

  void clearCache() {
    pageDataCache.clear();
  }

  // Add an async cleanup method for QuranAudioController
  Future<void> cleanup() async {
    try {
      _mediaNotificationClosed = true;
      // MediaController'ı durdur (2 kez çağır, bazı cihazlarda gerekebilir)
      await mediaController.stopService();
      await Future.delayed(Duration(milliseconds: 200));
      await mediaController.stopService();
      mediaController.dispose();
    } catch (e) {
      print('QuranAudioController cleanup sırasında mediaController temizlenemedi: $e');
    }
  }

  @override
  void dispose() {
    if (_isDetached) {
      audioService.removeListener(_onAudioServiceUpdate);
      super.dispose();
      return;
    }

    audioService.removeListener(_onAudioServiceUpdate);
    // MediaController cleanup should be called manually before dispose
    super.dispose();
  }

  // New method to detach the controller when navigating away instead of stopping audio
  void detach() {
    _isDetached = true;
    audioService.removeListener(_onAudioServiceUpdate);
    // Don't dispose the mediaController, just detach listener
  }

  // New method to reattach the controller when coming back to the page
  void reattach() {
    if (_isDetached) {
      _isDetached = false;
      // Re-add the listener
      audioService.addListener(_onAudioServiceUpdate);

      // Make sure MediaController is still working
      if (mediaController.isServiceRunning) {
        // Update MediaController with current state
        updateMediaController();
      }

      // Update UI state if the object is still mounted
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  // Eğer tekrar açılırsa (kullanıcı play tuşuna basarsa) flag'i sıfırla
  void resetMediaNotificationClosed() {
    _mediaNotificationClosed = false;
  }
}
