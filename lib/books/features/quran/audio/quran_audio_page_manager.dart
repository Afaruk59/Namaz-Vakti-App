import 'package:xml/xml.dart';
import 'package:dio/dio.dart';

/// Kuran ses çalma için sayfa yönetimi işlemlerini içeren mixin
mixin QuranAudioPageManager {
  // Bu değişkenler QuranAudioService'den erişilebilir olmalı
  bool get isPlaying;
  bool get isBesmelePlaying;
  int get currentSurah;
  int get currentAyah;
  int get currentPage;
  bool get isAyahChanging;
  bool get isLastAyahOfPage;
  Map<int, Map<String, dynamic>> get pageLastAyahInfo;
  Dio get dio;

  // Bu metodlar QuranAudioService'den erişilebilir olmalı
  Future<void> setAyahChanging(bool value);
  Future<void> setCurrentWordIndex(int index);
  Future<void> setBesmelePlaying(bool value);
  Future<void> setLastAyahOfPage(bool value);
  Future<void> setLastAyahWordCount(int count);
  Future<void> setCurrentPage(int pageNumber);
  Future<void> setCurrentSurah(int surahNo);
  Future<void> setCurrentAyah(int ayahNo);
  Future<void> setUserInitiated(bool value);
  Future<void> audioPlayerPause();
  Future<void> audioPlayerPlay(String url);
  int getMaxAyahCount(int surahNo);
  String getAyahAudioUrl(int surahNo, int ayahNo);
  Future<Map<String, dynamic>> loadWordTrackData(int surahNo, int ayahNo);
  Future<void> stopAudio();
  void notifyListenersPublic();
  Future<void> addPageLastAyahInfo(int pageNumber, Map<String, dynamic> info);

  // Besmele işlemleri için gerekli metodlar
  Future<void> playBesmele();
  Future<void> playSurahBismillah(int surahNo);

  /// Mevcut sayfayı ayarlar
  Future<void> updateCurrentPage(int pageNumber) async {
    // Geçersiz sayfa numarası kontrolü
    if (pageNumber < 0 || pageNumber > 604) {
      print('Geçersiz sayfa numarası: $pageNumber');
      return;
    }

    // Eğer sayfa değişmediyse işlem yapma
    if (currentPage == pageNumber) {
      print('Sayfa değişmedi, işlem yapılmadı: $pageNumber');
      return;
    }

    print('Sayfa değişimi: $currentPage -> $pageNumber');
    await setCurrentPage(pageNumber);

    // Sayfa değiştiğinde son ayet bilgilerini yükle
    await loadPageLastAyahInfo(pageNumber);

    notifyListenersPublic();
  }

  /// Sayfa son ayet bilgilerini yükler
  Future<void> loadPageLastAyahInfo(int pageNumber) async {
    try {
      // Önbellekte varsa, önbellekten al
      if (pageLastAyahInfo.containsKey(pageNumber)) {
        final info = pageLastAyahInfo[pageNumber]!;
        // Yeni sayfada başlangıçta false olmalı, ancak mevcut sayfada çalınan ayet son ayet ise true olmalı
        if (currentPage == pageNumber &&
            currentSurah == info['surahId'] &&
            currentAyah == info['ayahId']) {
          await setLastAyahOfPage(true);
          print(
              'Son ayet bayrağı ayarlandı: $currentPage sayfasında $currentSurah:$currentAyah son ayet');
        } else {
          await setLastAyahOfPage(false);
        }
        await setLastAyahWordCount(info['wordCount'] ?? 0);
        print(
            'Sayfa son ayet bilgisi önbellekten alındı: $pageNumber - Sure: ${info['surahId']}, Ayet: ${info['ayahId']}, Kelime: ${info['wordCount']}');

        // İlk ayet bilgisi de önbellekte varsa, onu da yazdır
        if (info.containsKey('firstSurahId') &&
            info.containsKey('firstAyahId')) {
          print(
              'Sayfa ilk ayet bilgisi önbellekten alındı: $pageNumber - Sure: ${info['firstSurahId']}, Ayet: ${info['firstAyahId']}');
        }

        return;
      }

      // XML dosyasını çek
      final apiPageNumber = pageNumber + 1; // API'de sayfa numaraları 1 fazla
      final String apiUrl =
          'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$apiPageNumber.xml';

      final response = await dio.get(apiUrl);
      if (response.statusCode == 200) {
        final xmlData = response.data.toString();
        final document = XmlDocument.parse(xmlData);
        final ayahNodes = document.findAllElements('a');

        if (ayahNodes.isNotEmpty) {
          // İlk ayet bilgilerini al
          final firstAyah = ayahNodes.first;
          final firstSurahId = int.parse(firstAyah.getAttribute('s') ?? '1');
          final firstAyahId = int.parse(firstAyah.getAttribute('a') ?? '1');

          // Son ayet bilgilerini al
          final lastAyah = ayahNodes.last;
          final surahId = int.parse(lastAyah.getAttribute('s') ?? '1');
          final ayahId = int.parse(lastAyah.getAttribute('a') ?? '1');

          // Son ayetin kelime sayısını hesapla
          final wordNodes = lastAyah.findAllElements('t');
          final wordCount = wordNodes.length;

          // Bilgileri önbelleğe ekle
          final pageInfo = {
            'surahId': surahId,
            'ayahId': ayahId,
            'wordCount': wordCount,
            'firstSurahId': firstSurahId,
            'firstAyahId': firstAyahId
          };

          await addPageLastAyahInfo(pageNumber, pageInfo);

          // Yeni sayfada başlangıçta false olmalı, ancak mevcut sayfada çalınan ayet son ayet ise true olmalı
          if (currentPage == pageNumber &&
              currentSurah == surahId &&
              currentAyah == ayahId) {
            await setLastAyahOfPage(true);
            print(
                'Son ayet bayrağı ayarlandı: $currentPage sayfasında $currentSurah:$currentAyah son ayet');
          } else {
            await setLastAyahOfPage(false);
          }
          await setLastAyahWordCount(wordCount);

          print(
              'Sayfa son ayet bilgisi yüklendi: $pageNumber - Sure: $surahId, Ayet: $ayahId, Kelime: $wordCount');
          print(
              'Sayfa ilk ayet bilgisi yüklendi: $pageNumber - Sure: $firstSurahId, Ayet: $firstAyahId');
        }
      }
    } catch (e) {
      print('Sayfa son ayet bilgisi yükleme hatası: $e');
    }
  }

  /// Bir sonraki ayeti otomatik olarak çalar (ses dosyası tamamlandığında)
  Future<void> playNextAyahAuto() async {
    try {
      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);
      await setCurrentWordIndex(-1);
      notifyListenersPublic();

      final maxAyahCount = getMaxAyahCount(currentSurah);
      final currentPageNumber = currentPage; // Mevcut sayfa numarasını sakla

      print(
          'Sonraki ayete otomatik geçiş - Mevcut sayfa: $currentPageNumber, Sure: $currentSurah, Ayet: $currentAyah');

      // Eğer sayfanın son ayeti çalındıysa, bir sonraki sayfaya geç
      if (isLastAyahOfPage) {
        print('Sayfanın son ayeti tamamlandı, bir sonraki sayfaya geçiliyor');
        final nextPage = currentPageNumber + 1;

        // Sayfa bilgilerini yükle
        await loadPageLastAyahInfo(nextPage);

        // Sayfa numarasını güncelle
        await updateCurrentPage(nextPage);

        // Sayfa değişimini bildir - kullanıcı tarafından başlatılmadığını belirt
        await setUserInitiated(false);

        // Sayfa değişimini bildirmek için notifyListeners çağır
        notifyListenersPublic();

        print(
            'Sayfa değişimi bildiriliyor: $currentPageNumber -> $nextPage (otomatik)');

        // Sayfa değişiminin tamamlanması için kısa bir bekleme ekle
        await Future.delayed(Duration(milliseconds: 500));

        // Sayfa değişimini tekrar bildir (daha güçlü bir bildirim için)
        notifyListenersPublic();

        // Sayfa değişimi bayrağını sıfırla
        await setLastAyahOfPage(false);

        // Bir sonraki sayfanın ilk ayetini çal
        if (pageLastAyahInfo.containsKey(nextPage)) {
          // Bir sonraki sayfanın ilk ayetini bul
          int nextSurahId = currentSurah;
          int nextAyahId = currentAyah + 1;

          // Sayfa bilgilerinden ilk ayeti al
          final pageInfo = pageLastAyahInfo[nextPage]!;
          if (pageInfo.containsKey('firstSurahId') &&
              pageInfo.containsKey('firstAyahId')) {
            nextSurahId = pageInfo['firstSurahId'];
            nextAyahId = pageInfo['firstAyahId'];

            // Eğer ilk ayet 0 ise (besmele), sure başı olduğunu belirt ve besmele ile başla
            bool shouldPlayBesmele = false;
            if (nextAyahId == 0) {
              print(
                  'Sonraki sayfanın ilk ayeti besmele (0), sure başı ile başlıyor');
              nextAyahId = 1; // Besmele sonrası 1. ayeti çalacağız
              shouldPlayBesmele = true; // Besmele çalınmalı
            } else if (nextAyahId == 1 &&
                nextSurahId != 9 &&
                nextSurahId != 1) {
              // Eğer ilk ayet 1 ise ve sure 9 (Tevbe) veya 1 (Fatiha) değilse, besmele çalınmalı
              shouldPlayBesmele = true;
            }

            print(
                'Sonraki sayfanın ilk ayeti: Sure $nextSurahId, Ayet $nextAyahId, Besmele: $shouldPlayBesmele');

            // Sonraki sayfanın ilk ayetini çal
            await playAyahWithOptions(nextSurahId, nextAyahId,
                playBesmeleParam: shouldPlayBesmele,
                userInitiated: false,
                pageNo: nextPage);
          } else {
            // Sayfa bilgilerinde ilk ayet bilgisi yoksa, varsayılan olarak bir sonraki ayeti çal
            await playAyahWithOptions(nextSurahId, nextAyahId,
                userInitiated: false, pageNo: nextPage);
          }
        } else {
          // Sayfa bilgisi henüz yüklenmemişse, varsayılan olarak bir sonraki ayeti çal
          if (currentAyah < maxAyahCount) {
            await playAyahWithOptions(currentSurah, currentAyah + 1,
                userInitiated: false, pageNo: nextPage);
          } else if (currentSurah < 114) {
            // Sonraki sureye geçiş - Besmele ile başla
            await playAyahWithOptions(currentSurah + 1, 1,
                playBesmeleParam: true, userInitiated: false, pageNo: nextPage);
          }
        }

        // Sayfa değişimi durumunda _isAyahChanging bayrağını daha geç sıfırla
        // Bu, sayfa değişimi sırasında progress bar'ın kaybolmasını önler
        Future.delayed(Duration(milliseconds: 1000), () async {
          await setAyahChanging(false);
          notifyListenersPublic();
        });
        return;
      }

      // Eğer mevcut ayet besmele ise (ayet 0), bu bir sure başlangıcıdır
      // Bu durumda aynı surenin 1. ayetine geçmeliyiz
      if (currentAyah == 0) {
        print(
            'Besmele tamamlandı, aynı surenin 1. ayetine geçiliyor: Sure $currentSurah, Ayet 1');

        // Önce mevcut çalan sesi duraklat
        // KALDIRILDI: if (isPlaying) { await audioPlayerPause(); await Future.delayed(Duration(milliseconds: 100)); }

        // Aynı surenin 1. ayetine geç
        await playAyahWithOptions(currentSurah, 1,
            userInitiated: false,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
        return;
      }

      if (currentAyah < maxAyahCount) {
        print(
            'Sonraki ayete geçiliyor - Sure: $currentSurah, Ayet: ${currentAyah + 1}, Sayfa: $currentPageNumber');

        // Önce mevcut çalan sesi duraklat (tamamen durdurmak yerine)
        // KALDIRILDI: if (isPlaying) { await audioPlayerPause(); await Future.delayed(Duration(milliseconds: 100)); }

        // Aynı surede bir sonraki ayete geç
        await playAyahWithOptions(currentSurah, currentAyah + 1,
            userInitiated: false,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
      } else if (currentSurah < 114) {
        print(
            'Sonraki sureye geçiliyor - Sure: ${currentSurah + 1}, Ayet: 1, Sayfa: $currentPageNumber');

        // Önce mevcut çalan sesi duraklat (tamamen durdurmak yerine)
        // KALDIRILDI: if (isPlaying) { await audioPlayerPause(); await Future.delayed(Duration(milliseconds: 100)); }

        // Sonraki sureye geçiş - Besmele ile başla
        await playAyahWithOptions(currentSurah + 1, 1,
            playBesmeleParam: true,
            userInitiated: false,
            pageNo: currentPageNumber // Mevcut sayfa numarasını koru
            );
      } else {
        // Son sureye geldik, ses çalmayı durdur
        print('Son sure tamamlandı, ses durduruldu');
        await stopAudio();
        await setAyahChanging(false);
      }
    } catch (e) {
      print('Sonraki ayete geçerken hata: $e');
      await setAyahChanging(false); // Hata durumunda bayrağı sıfırla
    }
  }

  /// Belirli bir ayeti çalar
  Future<void> playAyahWithOptions(int surahNo, int ayahNo,
      {bool playBesmeleParam = false,
      int pageNo = 0,
      bool userInitiated = true}) async {
    try {
      print(
          'playAyah çağrıldı: Sure: $surahNo, Ayet: $ayahNo, Sayfa: $pageNo, Kullanıcı: $userInitiated');

      // Ayet değişimi bayrağını aktif et
      await setAyahChanging(true);

      // Sayfa değişimi durumunu bildir
      notifyListenersPublic();

      // Kullanıcı tarafından başlatılan işlem mi?
      await setUserInitiated(userInitiated);

      // Sayfa numarası belirtilmişse, önce sayfa numarasını güncelle
      if (pageNo > 0 || pageNo == 0) {
        // 0 da geçerli bir sayfa numarası
        if (currentPage != pageNo) {
          print('Sayfa numarası değişiyor: $currentPage -> $pageNo');
          await setCurrentPage(pageNo);

          // Sayfa değiştiğinde son ayet bilgilerini yükle
          await loadPageLastAyahInfo(currentPage);

          // Sayfa değişimini bildir
          notifyListenersPublic();
        } else {
          // Sayfa değişmese bile son ayet bilgilerini kontrol et
          if (!pageLastAyahInfo.containsKey(currentPage)) {
            await loadPageLastAyahInfo(currentPage);
          }
        }
      } else {
        // Sayfa numarası belirtilmemişse, mevcut sayfa için son ayet bilgilerini kontrol et
        if (!pageLastAyahInfo.containsKey(currentPage)) {
          await loadPageLastAyahInfo(currentPage);
        }
      }

      // Zaten Besmele çalıyorsa ve sayfa değişimi yapılmadıysa yeni bir çalma başlatma
      // Sayfa değişimi yapıldıysa (userInitiated=true), Besmele çalıyor olsa bile yeni çalma başlat
      if (isBesmelePlaying && !userInitiated) {
        print('Besmele zaten çalıyor, yeni çalma başlatılmadı');
        // Ayet değişimi bayrağını hemen sıfırlama, biraz daha bekle
        Future.delayed(Duration(milliseconds: 500), () async {
          await setAyahChanging(false);
          notifyListenersPublic();
        });
        return;
      }

      // Besmele çalıyorsa ve sayfa değişimi yapıldıysa, önce Besmele'yi duraklat
      // KALDIRILDI: if (isBesmelePlaying) { await audioPlayerPause(); await setBesmelePlaying(false); await Future.delayed(Duration(milliseconds: 200)); }

      // Mevcut çalan sesi duraklat
      // KALDIRILDI: if (isPlaying) { await audioPlayerPause(); notifyListenersPublic(); await Future.delayed(Duration(milliseconds: 200)); }

      // Besmele çalma kontrolü
      // Sure 9 (Tevbe) dışındaki tüm surelerin ilk ayetlerinde Besmele çalınır
      if (ayahNo == 1 && surahNo != 9 && surahNo != 1) {
        // Kullanıcı tarafından başlatılan bir sayfa değişimi ise ve uzak bir sayfaya zıplama yapılıyorsa
        // Besmele çalmayı atla ve doğrudan ayeti çal
        if (userInitiated &&
            (pageNo - currentPage).abs() > 2 &&
            !playBesmeleParam) {
          print(
              'Uzak sayfaya zıplama yapıldı, Besmele atlanıyor ve doğrudan ayet çalınıyor');
          // Doğrudan ayeti çal
        } else {
          // Eğer playBesmeleParam false ise ve bu bir otomatik geçiş ise (userInitiated=false),
          // besmele çalmayı atla çünkü bu muhtemelen bir sonraki ayete otomatik geçiştir
          if (!playBesmeleParam && !userInitiated) {
            print(
                'Otomatik geçiş sırasında besmele atlanıyor - Sure: $surahNo, Ayet: $ayahNo');
            // Doğrudan ayeti çal
          } else {
            print('Sure başı, Besmele çalınıyor - Sure: $surahNo');
            // ÖNEMLİ: Burada playSurahBismillah metoduna surahNo parametresini geçiyoruz
            // Bu sayede besmele tamamlandığında doğru sureye geçilecek
            await playSurahBismillah(surahNo);
            // Ayet değişimi bayrağını hemen sıfırlama, biraz daha bekle
            Future.delayed(Duration(milliseconds: 500), () async {
              await setAyahChanging(false);
              notifyListenersPublic();
            });
            return;
          }
        }
      }

      // Eğer playBesmeleParam true ise ve besmele çalmıyorsa, besmele çal
      if (playBesmeleParam && !isBesmelePlaying) {
        // Kullanıcı tarafından başlatılan bir sayfa değişimi ise ve uzak bir sayfaya zıplama yapılıyorsa
        // Besmele çalmayı atla ve doğrudan ayeti çal
        if (userInitiated && (pageNo - currentPage).abs() > 2) {
          print(
              'Uzak sayfaya zıplama yapıldı, Besmele atlanıyor ve doğrudan ayet çalınıyor');
          // Doğrudan ayeti çal
        } else {
          // Otomatik geçişlerde (userInitiated=false) ve playBesmeleParam=true olduğunda
          // besmele çalınmalı, çünkü bu bir sayfa değişimi sonrası ilk ayettir
          print(userInitiated
              ? 'playBesmele=true, Besmele çalınıyor (kullanıcı başlattı)'
              : 'Otomatik geçiş sırasında besmele çalınıyor - Sure: $surahNo, Ayet: $ayahNo');

          // ÖNEMLİ: Burada playSurahBismillah metoduna surahNo parametresini geçiyoruz
          // Bu sayede besmele tamamlandığında doğru sureye geçilecek
          await playSurahBismillah(surahNo);
          // Ayet değişimi bayrağını hemen sıfırlama, biraz daha bekle
          Future.delayed(Duration(milliseconds: 500), () async {
            await setAyahChanging(false);
            notifyListenersPublic();
          });
          return;
        }
      }

      print(
          'Ayet çalınıyor - Sure: $surahNo, Ayet: $ayahNo, Sayfa: $currentPage');

      // Kelime takip verilerini yükle
      // Burada await kullanarak kelime takip verilerinin tamamen yüklenmesini bekleyelim
      final wordTrackData = await loadWordTrackData(surahNo, ayahNo);

      // Kelime takip verilerini kontrol et
      if (wordTrackData.isEmpty || (wordTrackData['tracks'] as List).isEmpty) {
        print('Uyarı: Kelime takip verisi boş veya eksik');

        // Kelime takip verisi boş olsa bile devam et, ancak bir kez daha yüklemeyi dene
        Future.delayed(Duration(milliseconds: 300), () async {
          try {
            print('Kelime takip verisi yeniden yükleniyor: $surahNo:$ayahNo');
            await loadWordTrackData(surahNo, ayahNo);
          } catch (e) {
            print('Kelime takip verisi yeniden yükleme hatası: $e');
          }
        });
      } else {
        print(
            'Kelime takip verisi yüklendi - ${(wordTrackData['tracks'] as List).length} kelime');
      }

      // Ses dosyasını çal
      final String audioUrl = getAyahAudioUrl(surahNo, ayahNo);
      print('Ses dosyası URL: $audioUrl');

      // Kelime vurgulamasını kaldır
      await setCurrentWordIndex(-1);

      // Ses dosyasını çalmadan önce kısa bir bekleme ekle
      // Bu, özellikle geri sayfalara zıplarken sorunları önlemeye yardımcı olur
      await Future.delayed(Duration(milliseconds: 200));

      // Önce sure ve ayet numaralarını ayarla, sonra ses dosyasını çal
      await setCurrentSurah(surahNo);
      await setCurrentAyah(ayahNo);
      await setBesmelePlaying(false);

      // Ses dosyasını çal
      await audioPlayerPlay(audioUrl);

      // Çalınan ayet, sayfanın son ayeti mi kontrol et
      if (pageLastAyahInfo.containsKey(currentPage)) {
        final lastAyahInfo = pageLastAyahInfo[currentPage]!;
        final isLastAyah = (surahNo == lastAyahInfo['surahId'] &&
            ayahNo == lastAyahInfo['ayahId']);

        await setLastAyahOfPage(isLastAyah);

        if (isLastAyah) {
          print('Sayfanın son ayeti çalınıyor: Sure $surahNo, Ayet $ayahNo');
          // Son ayetin kelime sayısını güncelle
          await setLastAyahWordCount(lastAyahInfo['wordCount'] ?? 0);
        }
      }

      // Ayet değişimi tamamlandı, bayrağı sıfırla
      // Daha uzun bir gecikme ekleyerek ilk kelimenin vurgulanmasını sağla
      // ve sayfa değişimi sırasında progress bar'ın kaybolmasını önle
      Future.delayed(Duration(milliseconds: 800), () async {
        await setAyahChanging(false);
        notifyListenersPublic();
      });

      notifyListenersPublic();
    } catch (e) {
      print('Ayet çalma hatası: $e');
      await setBesmelePlaying(false);
      await setAyahChanging(false); // Hata durumunda bayrağı sıfırla
      notifyListenersPublic();
      // Hatayı yukarı ilet
      rethrow;
    }
  }
}
