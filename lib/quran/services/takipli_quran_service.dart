import 'dart:convert';
import 'package:dio/dio.dart';

class TakipliQuranService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://kuran.diyanet.gov.tr/mushaf/qurandm',
    headers: {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'tr,en-US;q=0.9,en;q=0.8',
      'Connection': 'keep-alive',
      'Referer': 'https://kuran.diyanet.gov.tr/mushaf',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest',
    },
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    sendTimeout: Duration(seconds: 15),
  ));

  // Kuran'ın toplam sayfa sayısı
  static const int totalPages = 604; // 0-604 arası

  // Önbellek mekanizması ekle
  final Map<int, Map<String, dynamic>> _pageCache = {};

  // API'nin sayfa numaralandırması ile uygulama sayfa numaralandırması arasındaki dönüşümü sağlar
  // int _convertPageNumberToApiId(int pageNumber) {
  //   // Uygulama sayfa numarası 1'den başlarken, API'de Fatiha suresi id=0 ile alınıyor
  //   return pageNumber - 1;
  // }

  /// Belirli bir sayfanın verilerini getirir
  Future<Map<String, dynamic>> getPageData(int pageNumber) async {
    // Sayfa numarası kontrolü (0-604 arası)
    if (pageNumber < 0 || pageNumber > 604) {
      throw ArgumentError('Sayfa numarası 0-604 arasında olmalıdır');
    }

    // Önbellekte varsa, önbellekten döndür
    if (_pageCache.containsKey(pageNumber)) {
      print('Sayfa verisi önbellekten alındı: $pageNumber');
      return _pageCache[pageNumber]!;
    }

    try {
      print('TakipliQuranService: Sayfa verisi isteniyor: $pageNumber'); // Debug log

      // API'ye gönderilecek sayfa numarasını ayarla
      final apiPageNumber = pageNumber;

      // Yeniden deneme mekanizması
      int maxRetries = 3;
      int currentTry = 0;
      Exception? lastException;

      while (currentTry < maxRetries) {
        try {
          final response = await _dio.get('/pagedata',
              queryParameters: {
                'id': apiPageNumber,
                'itf': 0,
                'iml': 1,
                'iqr': 1,
                'ml': 5,
                'ql': 7,
                'iar': 0,
              },
              options: Options(
                receiveTimeout: Duration(seconds: 15),
                sendTimeout: Duration(seconds: 15),
              ));

          print('API Yanıtı: ${response.statusCode}'); // Debug log
          print('API Yanıt Verisi: ${response.data}'); // Debug log

          if (response.statusCode == 200) {
            Map<String, dynamic> data;
            if (response.data is Map<String, dynamic>) {
              data = response.data;
            } else if (response.data is String) {
              data = json.decode(response.data);
            } else {
              throw Exception(
                  'Beklenmeyen veri formatı: ${response.data.runtimeType}');
            }

            // QuranAyats null kontrolü
            if (data['QuranAyats'] == null) {
              print('Uyarı: API yanıtında QuranAyats null');
              // Varsayılan değerler ekle
              data['QuranAyats'] = [];
              data['surahNo'] = 1; // Varsayılan olarak Fatiha suresi
              data['ayahNo'] = 1; // Varsayılan olarak ilk ayet
              data['appPageNumber'] = pageNumber;

              // Önbelleğe ekleme - hatalı veri bile olsa önbelleğe ekle
              // böylece aynı hatalı isteği tekrar tekrar yapmayız
              _pageCache[pageNumber] = data;

              return data;
            }

            // QuranAyats dizisinin ilk elemanından sure ve ayet numaralarını al
            if (data['QuranAyats'] != null &&
                (data['QuranAyats'] as List).isNotEmpty) {
              final firstAyat = (data['QuranAyats'] as List).first;
              data['surahNo'] = firstAyat['SureId'];
              data['ayahNo'] = firstAyat['AyetId'];
            } else {
              // QuranAyats boş ise varsayılan değerler ekle
              print('Uyarı: API yanıtında QuranAyats boş');
              data['surahNo'] = 1; // Varsayılan olarak Fatiha suresi
              data['ayahNo'] = 1; // Varsayılan olarak ilk ayet
            }

            // API'den gelen PageNo değerini koruyalım, bu değer takip için önemli
            data['appPageNumber'] = pageNumber;

            // Başarılı veriyi önbelleğe ekle
            _pageCache[pageNumber] = data;

            return data;
          } else {
            throw Exception('Sayfa verisi alınamadı: ${response.statusCode}');
          }
        } catch (e) {
          print(
              'Veri çekme hatası (Deneme ${currentTry + 1}): $e'); // Debug log
          lastException = e is Exception ? e : Exception(e.toString());
          currentTry++;

          // Son deneme değilse kısa bir bekleme ekle
          if (currentTry < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * currentTry));
          }
        }
      }

      // Tüm denemeler başarısız olursa son hatayı fırlat
      throw lastException ?? Exception('Bilinmeyen bir hata oluştu');
    } catch (e) {
      print('Veri çekme hatası: $e'); // Debug log

      // Hata durumunda varsayılan veri döndür
      final defaultData = {
        'QuranAyats': [],
        'surahNo': 1, // Varsayılan olarak Fatiha suresi
        'ayahNo': 1, // Varsayılan olarak ilk ayet
        'appPageNumber': pageNumber,
        'error': e.toString()
      };

      // Hata durumunda bile önbelleğe ekle, böylece aynı hatayı tekrar yaşamayız
      _pageCache[pageNumber] = defaultData;

      return defaultData;
    }
  }

  // Takip XML'ini almak için yeni bir metod
  Future<String> getTrackingXml(int surahId, int ayahId) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$surahId.xml',
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw Exception('Takip XML alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Takip XML çekme hatası: $e'); // Debug log
      throw Exception('Takip XML çekme hatası: $e');
    }
  }

  // Ses dosyası URL'sini oluşturmak için yeni bir metod
  String getAudioUrl(int surahId, int ayahId) {
    return 'https://webdosya.diyanet.gov.tr/kuran/kuranikerim/Sound/ar_osmanSahin/${surahId}_${ayahId}.mp3';
  }

  String getArabicText(Map<String, dynamic> pageData) {
    try {
      // QuranAyats null kontrolü ekle
      if (pageData['QuranAyats'] == null) {
        print('Uyarı: QuranAyats null');
        return 'Arapça metin yüklenemedi';
      }

      final quranAyats = pageData['QuranAyats'] as List<dynamic>;

      if (quranAyats.isEmpty) {
        print('Uyarı: QuranAyats boş');
        return 'Arapça metin yüklenemedi';
      }

      return quranAyats.map((ayat) {
        final ayetText = ayat['AyetText']?.toString() ?? '';
        final ayetNumber = ayat['AyetNumber']?.toString() ?? '';
        return '$ayetText ﴿$ayetNumber﴾';
      }).join(' ');
    } catch (e) {
      print('Arapça metin ayıklama hatası: $e'); // Debug log
      return 'Arapça metin yüklenemedi';
    }
  }

  String getSureName(Map<String, dynamic> pageData) {
    try {
      final sureName =
          pageData['QuranSureLabel']?.toString() ?? 'Sure adı bulunamadı';
      return 'سورة $sureName';
    } catch (e) {
      print('Sure adı ayıklama hatası: $e'); // Debug log
      return 'Sure adı yüklenemedi';
    }
  }

  // Sayfadaki tüm sureleri ve bilgilerini döndürür
  List<Map<String, dynamic>> getAllSurahsInPage(Map<String, dynamic> pageData) {
    try {
      // QuranAyats null kontrolü ekle
      if (pageData['QuranAyats'] == null) {
        print('Uyarı: getAllSurahsInPage - QuranAyats null');
        return [];
      }

      final quranAyats = pageData['QuranAyats'] as List<dynamic>;

      if (quranAyats.isEmpty) {
        print('Uyarı: getAllSurahsInPage - QuranAyats boş');
        return [];
      }

      final List<Map<String, dynamic>> surahs = [];

      // Sayfadaki her ayeti kontrol et
      for (var ayat in quranAyats) {
        // Sure bilgisi varsa
        if (ayat['Sure'] != null) {
          final sureInfo = ayat['Sure'];
          final surahNo = sureInfo['SureId'];
          final surahName = sureInfo['SureNameArabic'];
          final surahNameTurkish = sureInfo['SureNameTurkish'];
          final besmeleVisible = sureInfo['BesmeleVisible'] ?? false;

          // Daha önce eklenmemişse ekle
          if (!surahs.any((s) => s['surahNo'] == surahNo)) {
            surahs.add({
              'surahNo': surahNo,
              'surahName': surahName,
              'surahNameTurkish': surahNameTurkish,
              'besmeleVisible': besmeleVisible,
              'startAyahNo': ayat['AyetId'],
              'position': quranAyats.indexOf(ayat) // Sayfadaki pozisyonu
            });
          }
        }
      }

      return surahs;
    } catch (e) {
      print('Sayfa sureleri ayıklama hatası: $e');
      return [];
    }
  }

  // Belirli bir ayet için sure bilgisini döndürür
  Map<String, dynamic>? getSurahInfoForAyah(
      Map<String, dynamic> pageData, int ayahIndex) {
    try {
      // QuranAyats null kontrolü ekle
      if (pageData['QuranAyats'] == null) {
        print('Uyarı: getSurahInfoForAyah - QuranAyats null');
        return null;
      }

      final quranAyats = pageData['QuranAyats'] as List<dynamic>;

      if (quranAyats.isEmpty) {
        print('Uyarı: getSurahInfoForAyah - QuranAyats boş');
        return null;
      }

      if (ayahIndex < 0 || ayahIndex >= quranAyats.length) {
        return null;
      }

      // Ayetin kendi sure bilgisi varsa onu kullan
      if (quranAyats[ayahIndex]['Sure'] != null) {
        final sureInfo = quranAyats[ayahIndex]['Sure'];
        return {
          'surahNo': sureInfo['SureId'],
          'surahName': sureInfo['SureNameArabic'],
          'surahNameTurkish': sureInfo['SureNameTurkish'],
          'besmeleVisible': sureInfo['BesmeleVisible'] ?? false
        };
      }

      // Yoksa, bu ayetten önceki en yakın sure bilgisini bul
      for (int i = ayahIndex - 1; i >= 0; i--) {
        if (quranAyats[i]['Sure'] != null) {
          final sureInfo = quranAyats[i]['Sure'];
          return {
            'surahNo': sureInfo['SureId'],
            'surahName': sureInfo['SureNameArabic'],
            'surahNameTurkish': sureInfo['SureNameTurkish'],
            'besmeleVisible': sureInfo['BesmeleVisible'] ?? false
          };
        }
      }

      return null;
    } catch (e) {
      print('Ayet için sure bilgisi ayıklama hatası: $e');
      return null;
    }
  }
}
