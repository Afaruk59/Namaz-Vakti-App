/// Kuran ses çalma için Besmele işlemlerini içeren mixin
mixin QuranAudioBesmeleHandler {
  // Bu değişkenler QuranAudioService'den erişilebilir olmalı
  bool get isPlaying;
  bool get isBesmelePlaying;
  int get currentSurah;
  int get currentAyah;
  int get currentPage;
  bool get isAyahChanging;
  Map<int, Map<String, dynamic>> get pageLastAyahInfo;

  // Bu metodlar QuranAudioService'den erişilebilir olmalı
  Future<void> setAyahChanging(bool value);
  Future<void> setCurrentWordIndex(int index);
  Future<void> setBesmelePlaying(bool value);
  Future<void> audioPlayerPause();
  Future<void> audioPlayerPlay(String url);
  Future<void> audioPlayerIsPlaying();
  String getBismillahAudioUrl(int surahNo);
  String getAyahAudioUrl(int surahNo, int ayahNo);
  Future<void> loadWordTrackData(int surahNo, int ayahNo);
  Future<void> loadWordTrackDataInBackground(int surahNo, int ayahNo);
  Future<void> updateCurrentPage(int pageNumber);
  Future<void> setCurrentSurah(int surahNo);
  Future<void> setCurrentAyah(int ayahNo);
  void notifyListenersPublic();

  /// Besmele çalar
  Future<void> playBesmele() async {
    try {
      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);

      final String besmeleUrl = getBismillahAudioUrl(1);
      print('Besmele çalınıyor - URL: $besmeleUrl');

      // Bayrakları ayarla
      await setBesmelePlaying(true);
      await setCurrentWordIndex(-1);

      // Ses dosyasını çal
      await audioPlayerPlay(besmeleUrl);

      print(
          'Besmele çalma başladı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Ayet değişimi bayrağını sıfırla
      Future.delayed(Duration(milliseconds: 300), () async {
        await setAyahChanging(false);
        notifyListenersPublic();
      });

      notifyListenersPublic();
    } catch (e) {
      print('Besmele çalma hatası: $e');
      await setBesmelePlaying(false);
      await setAyahChanging(false);
      notifyListenersPublic();
    }
  }

  /// Besmele tamamlandığında çağrılır
  Future<void> handleBesmeleComplete() async {
    print('Besmele tamamlandı, $currentSurah:1 ayetine geçiliyor');
    print(
        'Besmele tamamlandı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

    // Eğer ses çalmıyorsa (duraklatılmış), işlemi yapma
    if (!isPlaying) {
      print(
          'Besmele tamamlandı ancak ses duraklatılmış, ilk ayete geçiş yapılmıyor');
      return;
    }

    // Ayet değişimi bayrağını aktif et
    await setAyahChanging(true);

    // Besmele bayrağını sıfırla
    await setBesmelePlaying(false);

    // Vurgulamayı kaldırmak için kelime indeksini sıfırla
    await setCurrentWordIndex(-1);
    notifyListenersPublic();

    // Mevcut sayfa numarasını sakla
    final currentPageNumber = currentPage;
    print('Besmele sonrası sayfa: $currentPageNumber');

    // İlk ayeti çal
    try {
      // ÖNEMLİ: Burada sayfanın ilk ayetini değil, besmele çalınmaya başlandığında
      // kaydedilen sure numarasının ilk ayetini çalmalıyız
      int firstSurahId = currentSurah;
      int firstAyahId = 1; // Varsayılan olarak 1. ayet

      print(
          'Besmele sonrası çalınacak ayet: Sure $firstSurahId, Ayet $firstAyahId');

      // İlk ayet için kelime takip verilerini yükle
      // Burada await kullanarak kelime takip verilerinin tamamen yüklenmesini bekleyelim
      await loadWordTrackData(firstSurahId, firstAyahId);

      // Kısa bir bekleme ekleyerek kelime takip verilerinin işlenmesini sağlayalım
      await Future.delayed(Duration(milliseconds: 200));

      // Sayfanın ilk ayetini doğrudan çal
      final String nextAudioUrl = getAyahAudioUrl(firstSurahId, firstAyahId);
      print(
          'Besmele sonrası ayet çalınıyor - Sure: $firstSurahId, Ayet: $firstAyahId, URL: $nextAudioUrl');

      // Önce sure ve ayet numaralarını ayarla, sonra ses dosyasını çal
      await setCurrentSurah(firstSurahId);
      await setCurrentAyah(firstAyahId);

      // Ses dosyasını çal
      await audioPlayerPlay(nextAudioUrl);

      print(
          'Besmele sonrası ayet çalma başladı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Sayfa numarasını koru
      await updateCurrentPage(currentPageNumber);

      // Ayet değişimi tamamlandı, bayrağı sıfırla
      // Daha uzun bir gecikme ekleyerek ilk kelimenin vurgulanmasını sağlayalım
      Future.delayed(Duration(milliseconds: 500), () async {
        await setAyahChanging(false);
        notifyListenersPublic();
      });

      notifyListenersPublic();
    } catch (e) {
      print('Besmele sonrası ayet çalma hatası: $e');
      await setAyahChanging(false);
      notifyListenersPublic();
    }
  }

  /// Belirli bir surenin Besmele'sini çalar
  Future<void> playSurahBismillah(int surahNo) async {
    try {
      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);

      // Mevcut sayfa numarasını sakla
      // ignore: unused_local_variable
      final currentPageNumber = currentPage;

      // ÖNEMLİ: Besmele çalmadan önce currentSurah değişkenini güncelle
      // Bu sayede handleBesmeleComplete metodu doğru sureye geçecek
      await setCurrentSurah(surahNo);
      // Ayet numarasını da güncelle - besmele tamamlandığında 1. ayete geçilecek
      await setCurrentAyah(0); // Besmele çalarken ayet 0 olarak işaretlenir
      print('Besmele için currentSurah güncellendi: $surahNo, currentAyah: 0');

      // Bu sure için Besmele ses dosyasını çal
      final String bismillahUrl = getBismillahAudioUrl(surahNo);
      print('Sure başı Besmele çalınıyor - Sure: $surahNo, URL: $bismillahUrl');

      // Bayrakları ayarla
      await setCurrentWordIndex(-1);
      await setBesmelePlaying(true);

      // Besmele'yi çalmaya başla
      await audioPlayerPlay(bismillahUrl);

      print(
          'Sure başı Besmele çalma başladı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Ayet değişimi bayrağını sıfırla
      Future.delayed(Duration(milliseconds: 300), () async {
        await setAyahChanging(false);
        notifyListenersPublic();
      });

      notifyListenersPublic();

      // Arka planda gerçek kelime takip verilerini yükle
      await loadWordTrackDataInBackground(
          surahNo, 0); // Besmele için 0 ayet numarası

      // Besmele tamamlandıktan sonra çalınacak ayetin kelime takip verilerini de önceden yükle
      // Bu, besmele tamamlandığında ilk ayetin kelime takibinin hemen başlamasını sağlar
      Future.delayed(Duration(milliseconds: 500), () async {
        try {
          print(
              'Besmele sonrası ayet için kelime takip verisi önceden yükleniyor: $surahNo:1');
          await loadWordTrackData(surahNo, 1);
        } catch (e) {
          print(
              'Besmele sonrası ayet için kelime takip verisi yükleme hatası: $e');
        }
      });
    } catch (e) {
      print('Besmele çalma hatası: $e');
      await setBesmelePlaying(false);
      await setAyahChanging(false);

      // Besmele çalma başarısız olursa doğrudan ilk ayeti çalmayı dene
      try {
        await loadWordTrackData(surahNo, 1);
        final String nextAudioUrl = getAyahAudioUrl(surahNo, 1);
        await audioPlayerPlay(nextAudioUrl);
        await setCurrentSurah(surahNo);
        await setCurrentAyah(1);
        notifyListenersPublic();
      } catch (innerError) {
        print('Besmele sonrası ayet çalma hatası: $innerError');
        notifyListenersPublic();
      }
    }
  }
}
