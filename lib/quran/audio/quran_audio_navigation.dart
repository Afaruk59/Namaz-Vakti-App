/// Kuran ses çalma için ayet ve sure navigasyonu işlemlerini içeren mixin
mixin QuranAudioNavigation {
  // Bu değişkenler QuranAudioService'den erişilebilir olmalı
  bool get isPlaying;
  bool get isBesmelePlaying;
  int get currentSurah;
  int get currentAyah;
  int get currentPage;
  bool get isAyahChanging;
  Map<int, Map<String, dynamic>> get pageLastAyahInfo;
  bool get isUserInitiated;

  // Bu metodlar QuranAudioService'den erişilebilir olmalı
  Future<void> setAyahChanging(bool value);
  Future<void> setCurrentWordIndex(int index);
  Future<void> setBesmelePlaying(bool value);
  Future<void> audioPlayerStop();
  int getMaxAyahCount(int surahNo);
  Future<void> playAyahWithOptions(int surahNo, int ayahNo,
      {bool playBesmeleParam, int pageNo, bool userInitiated});
  Future<void> playSurahBismillah(int surahNo);
  Future<void> stopAudio();
  void notifyListenersPublic();

  /// Kullanıcı tarafından manuel olarak bir sonraki ayete geçiş
  Future<void> navigateToNextAyah() async {
    // Ses çalmıyorsa işlem yapma
    if (!isPlaying && !isBesmelePlaying) {
      print('Ses çalmıyor, sonraki ayete geçiş yapılmadı');
      return;
    }

    // Sayfanın son ayetindeyse işlem yapma
    if (checkIsLastAyahOfPage()) {
      print('Sayfanın son ayetindeyiz, sonraki ayete geçiş yapılmadı');
      return;
    }

    // Besmele çalıyorsa, besmeleyi durdur ve ilgili ayeti çal
    if (isBesmelePlaying) {
      await audioPlayerStop();
      await setBesmelePlaying(false);

      // Besmele sonrası ilk ayeti çal
      await playAyahWithOptions(currentSurah, 1,
          userInitiated: true, pageNo: currentPage);
      return;
    }

    try {
      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);
      await setCurrentWordIndex(-1);
      notifyListenersPublic();

      final maxAyahCount = getMaxAyahCount(currentSurah);
      final currentPageNumber = currentPage; // Mevcut sayfa numarasını sakla

      print(
          'Sonraki ayete geçiş - Mevcut sayfa: $currentPageNumber, Sure: $currentSurah, Ayet: $currentAyah');

      if (currentAyah < maxAyahCount) {
        print(
            'Sonraki ayete geçiliyor - Sure: $currentSurah, Ayet: ${currentAyah + 1}, Sayfa: $currentPageNumber');

        // Aynı surede bir sonraki ayete geç
        await playAyahWithOptions(currentSurah, currentAyah + 1,
            userInitiated: true,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
      } else if (currentSurah < 114) {
        print(
            'Sonraki sureye geçiliyor - Sure: ${currentSurah + 1}, Ayet: 1, Sayfa: $currentPageNumber');

        // Sonraki sureye geçiş - Besmele ile başla
        await playAyahWithOptions(currentSurah + 1, 1,
            playBesmeleParam: true,
            userInitiated: true,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
      } else {
        // Son sureye geldik, ses çalmayı durdur
        print('Son sure tamamlandı, ses durduruldu');
        await stopAudio();
      }
    } catch (e) {
      print('Sonraki ayete geçerken hata: $e');
    } finally {
      await setAyahChanging(false); // Bayrağı sıfırla
    }
  }

  /// Kullanıcı tarafından manuel olarak bir önceki ayete geçiş
  Future<void> navigateToPreviousAyah() async {
    // Ses çalmıyorsa işlem yapma
    if (!isPlaying && !isBesmelePlaying) {
      print('Ses çalmıyor, önceki ayete geçiş yapılmadı');
      return;
    }

    // Sayfanın ilk ayetindeyse işlem yapma
    if (checkIsFirstAyahOfPage()) {
      print('Sayfanın ilk ayetindeyiz, önceki ayete geçiş yapılmadı');
      return;
    }

    try {
      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);
      await setCurrentWordIndex(-1);
      notifyListenersPublic();

      final currentPageNumber = currentPage; // Mevcut sayfa numarasını sakla

      // Besmele çalıyorsa, besmeleyi tekrar çal
      if (isBesmelePlaying) {
        await audioPlayerStop();
        await playSurahBismillah(currentSurah);
        return;
      }

      print(
          'Önceki ayete geçiş - Mevcut sayfa: $currentPageNumber, Sure: $currentSurah, Ayet: $currentAyah');

      // İlk ayetteyse ve besmele varsa, besmeleyi çal
      // Ancak bu durumda checkIsFirstAyahOfPage() true döndüreceği için
      // bu koşula hiç girilmeyecek. Yine de güvenlik için bırakıyoruz.
      if (currentAyah == 1 && currentSurah != 9 && currentSurah != 1) {
        print('İlk ayetteyiz, besmeleyi çalıyoruz - Sure: $currentSurah');
        await playSurahBismillah(currentSurah);
        return;
      }

      // Aynı surede önceki ayete geç
      if (currentAyah > 1) {
        print(
            'Önceki ayete geçiliyor - Sure: $currentSurah, Ayet: ${currentAyah - 1}, Sayfa: $currentPageNumber');

        await playAyahWithOptions(currentSurah, currentAyah - 1,
            userInitiated: true,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
      } else {
        // Bu kısım artık çalışmayacak çünkü checkIsFirstAyahOfPage() true döndürecek
        // ve fonksiyonun başında return edilecek. Yine de güvenlik için bırakıyoruz.
        print('İlk ayetteyiz, önceki ayete geçiş yapılmadı');
      }
    } catch (e) {
      print('Önceki ayete geçerken hata: $e');
    } finally {
      await setAyahChanging(false); // Bayrağı sıfırla
    }
  }

  /// Mevcut sayfadaki ilk ayeti mi okuyoruz kontrol eder
  bool checkIsFirstAyahOfPage() {
    try {
      // Sayfa bilgisi yüklenmemişse false döndür
      if (!pageLastAyahInfo.containsKey(currentPage)) {
        return false;
      }

      // Besmele çalınıyorsa, bu sayfanın başlangıcı olarak kabul edilebilir
      if (isBesmelePlaying) {
        return true;
      }

      // Önbellekteki ilk ayet bilgisini kontrol et
      final info = pageLastAyahInfo[currentPage]!;
      if (info.containsKey('firstSurahId') && info.containsKey('firstAyahId')) {
        final firstSurahId = info['firstSurahId'] as int;
        final firstAyahId = info['firstAyahId'] as int;

        // Mevcut sure ve ayet, sayfanın ilk ayeti mi kontrol et
        final isFirst =
            currentSurah == firstSurahId && currentAyah == firstAyahId;
        return isFirst;
      }

      // İlk ayet bilgisi yoksa, basit bir kontrol yap
      if (isUserInitiated && currentAyah == 1) {
        return true;
      }

      return false;
    } catch (e) {
      print('İlk ayet kontrolü hatası: $e');
      return false;
    }
  }

  /// Mevcut sayfadaki son ayeti mi okuyoruz kontrol eder
  bool checkIsLastAyahOfPage() {
    try {
      // Sayfa bilgisi yüklenmemişse false döndür
      if (!pageLastAyahInfo.containsKey(currentPage)) {
        return false;
      }

      // Sayfa son ayet bilgisini kontrol et
      final lastAyahInfo = pageLastAyahInfo[currentPage]!;
      final isLast = currentSurah == lastAyahInfo['surahId'] &&
          currentAyah == lastAyahInfo['ayahId'];

      return isLast;
    } catch (e) {
      print('Son ayet kontrolü hatası: $e');
      return false;
    }
  }
}
