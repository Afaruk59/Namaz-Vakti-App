/// Kuran ses çalma için temel oynatma kontrollerini içeren mixin
mixin QuranAudioPlaybackController {
  // Bu değişkenler QuranAudioService'den erişilebilir olmalı
  bool get isDisposed;
  bool get isPlaying;
  bool get isBesmelePlaying;
  int get currentSurah;
  int get currentAyah;

  // Bu metodlar QuranAudioService'den erişilebilir olmalı
  Future<void> setCurrentWordIndex(int index);
  Future<void> setBesmelePlaying(bool value);
  Future<void> audioPlayerPause();
  Future<void> audioPlayerStop();
  Future<void> audioPlayerPlay(String url);
  Future<void> audioPlayerSeekTo(Duration position);
  Future<void> audioPlayerSetPlaybackRate(double rate);
  Future<void> audioPlayerResume();
  String getAyahAudioUrl(int surahNo, int ayahNo);
  String getBismillahAudioUrl(int surahNo);
  void notifyListenersPublic();

  /// Stop the current audio playback
  Future<void> stopAudioPlayback() async {
    try {
      if (isDisposed) return;

      // Stop audio player
      await audioPlayerStop();

      // Reset word tracking
      await setCurrentWordIndex(-1);
    } catch (e) {
      print('QuranAudioPlaybackController: Error stopping audio: $e');
    }
  }

  /// Sesi oynatır
  Future<void> playAudio() async {
    try {
      if (isDisposed) return;

      if (currentSurah == 0 || currentAyah == 0) {
        return;
      }

      // Mevcut ayetin ses dosyasını çal
      final String audioUrl = getAyahAudioUrl(currentSurah, currentAyah);
      await audioPlayerPlay(audioUrl);
    } catch (e) {
      print('QuranAudioService play hatası: $e');
    }
  }

  /// Sesi duraklatır
  Future<void> pauseAudio() async {
    try {
      if (isDisposed) return;

      print(
          'Pause çağrıldı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Bu fonksiyon sadece kullanıcı manuel olarak duraklatırsa çağrılmalı.
      // Zincirleme oynatmada otomatik olarak çağrılmamalı.
      // KALDIRILDI: Otomatik zincirleme oynatmada pause çağrısı.

      // Ses çalıyor mu kontrol et
      if (isPlaying) {
        // Ses çalıyor, duraklat
        await audioPlayerPause();

        // Besmele çalma durumunu koruyoruz, ancak UI için isBesmelePlaying'i false yapıyoruz
        // Bu sayede UI'da play/pause butonu doğru şekilde gösterilecek
        if (isBesmelePlaying) {
          print(
              'Besmele duraklatıldı, UI için isBesmelePlaying false yapılıyor');
          await setBesmelePlaying(false);
        }

        print(
            'Ses duraklatıldı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');
      } else {
        // Ses zaten duraklatılmış, bayrakları güncelle

        // Besmele çalma durumunu koruyoruz, ancak UI için isBesmelePlaying'i false yapıyoruz
        if (isBesmelePlaying) {
          print(
              'Besmele zaten duraklatılmış, UI için isBesmelePlaying false yapılıyor');
          await setBesmelePlaying(false);
        }

        print(
            'Ses zaten duraklatılmış - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');
      }

      // UI'ı güncelle
      notifyListenersPublic();
    } catch (e) {
      print('QuranAudioService pause hatası: $e');
      await setBesmelePlaying(false);
      notifyListenersPublic();
    }
  }

  /// Duraklatılmış sesi devam ettirir
  Future<void> resumeAudio() async {
    try {
      if (isDisposed) return;

      print(
          'Resume çağrıldı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Ses duraklatılmış mı kontrol et
      if (!isPlaying) {
        // Ses duraklatılmış, devam ettir
        await audioPlayerResume();

        // Eğer besmele çalıyorsa veya çalıyordu, isBesmelePlaying'i true yap
        if (getCurrentSurahAndAyah() == "Besmele") {
          print('Besmele devam ettiriliyor, isBesmelePlaying true yapılıyor');
          await setBesmelePlaying(true);
        }

        print(
            'Ses devam ettiriliyor - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');
      } else {
        // Ses zaten çalıyor, bayrakları güncelle
        print(
            'Ses zaten çalıyor - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');
      }

      // UI'ı güncelle
      notifyListenersPublic();
    } catch (e) {
      print('QuranAudioService resume hatası: $e');

      // Hata durumunda tekrar deneme
      try {
        if (!isPlaying) {
          await audioPlayerSeekTo(Duration.zero);
          await audioPlayerResume();

          print(
              'Ses devam ettirme tekrar denendi - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

          notifyListenersPublic();
        }
      } catch (innerError) {
        print('Ses devam ettirme tekrar deneme hatası: $innerError');
      }
    }
  }

  /// Sesi durdurur
  Future<void> stopAudio() async {
    try {
      if (isDisposed) return;

      print(
          'Stop çağrıldı - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // Önce AudioPlayer'ı durdur
      await audioPlayerStop();

      // Durum bayraklarını güncelle
      await setBesmelePlaying(false); // WordTracker'ı da güncelle
      await setCurrentWordIndex(-1);

      print(
          'Ses durduruldu - isPlaying: $isPlaying, isBesmelePlaying: $isBesmelePlaying');

      // UI'ı güncelle
      notifyListenersPublic();
    } catch (e) {
      print('QuranAudioService stop hatası: $e');

      // Hata durumunda da bayrakları sıfırla
      await setBesmelePlaying(false);
      await setCurrentWordIndex(-1);

      // UI'ı güncelle
      notifyListenersPublic();
    }
  }

  /// Belirli bir konuma atlar
  Future<void> seekToPosition(Duration position) async {
    await audioPlayerSeekTo(position);
    notifyListenersPublic();
  }

  /// Oynatma hızını ayarlar
  Future<void> setAudioPlaybackRate(double rate) async {
    await audioPlayerSetPlaybackRate(rate);
    notifyListenersPublic();
  }

  /// Mevcut sure ve ayet bilgilerini döndürür
  String getCurrentSurahAndAyah() {
    if (isBesmelePlaying) {
      return "Besmele";
    }

    final surahName = getSurahName(currentSurah);
    return "$surahName:$currentAyah";
  }

  /// Sure adını döndürür
  String getSurahName(int surahNo) {
    // Bu metod QuranAudioService'de implement edilmeli
    return "Sure $surahNo";
  }
}
