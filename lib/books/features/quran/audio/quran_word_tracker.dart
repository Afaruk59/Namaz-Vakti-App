import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

/// Kuran kelime takibi ve XML işleme sınıfı
class QuranWordTracker extends ChangeNotifier {
  final Dio _dio = Dio();
  int _currentWordIndex = -1;
  Map<String, dynamic>? _wordTrackData;
  int _currentPage = 1;
  bool _isBesmelePlaying = false;
  Map<String, dynamic> _wordTrackCache = {};
  bool _isAyahChanging = false; // Ayet değişimi sırasında vurgulamayı engelle

  // Mevcut sure ve ayet numaralarını takip etmek için değişkenler ekle
  int _currentSurah = 1;
  int _currentAyah = 1;

  // Getters
  int get currentWordIndex => _currentWordIndex;
  bool get isBesmelePlaying => _isBesmelePlaying;
  int get currentPage => _currentPage;

  /// Mevcut sayfayı ayarlar
  void setCurrentPage(int pageNumber) {
    _currentPage = pageNumber;
    notifyListeners();
  }

  /// Besmele çalma durumunu ayarlar
  void setBesmelePlaying(bool isPlaying) {
    _isBesmelePlaying = isPlaying;
    notifyListeners();
  }

  /// Ayet değişim durumunu ayarlar
  void setAyahChanging(bool isChanging) {
    _isAyahChanging = isChanging;
    if (isChanging) {
      // Ayet değişimi sırasında kelime vurgulamasını kaldır
      _currentWordIndex = -1;
    }
    notifyListeners();
  }

  /// Aktif kelime indeksini ayarlar
  void setCurrentWordIndex(int index) {
    // Ayet değişimi sırasında kelime vurgulaması yapma
    if (_isAyahChanging && index >= 0) {
      return;
    }
    _currentWordIndex = index;
    notifyListeners();
  }

  /// Mevcut sure ve ayet numaralarını ayarlamak için metod
  void setCurrentAyah(int surahNo, int ayahNo) {
    _currentSurah = surahNo;
    _currentAyah = ayahNo;
    notifyListeners();
  }

  /// Kelime takip verilerini ayarlar
  Future<void> setWordTrackData(Map<String, dynamic> data) async {
    _wordTrackData = data;

    // Mevcut sure ve ayet numaralarını güncelle
    if (data.containsKey('surahId')) {
      _currentSurah = data['surahId'];
    }

    if (data.containsKey('ayahId')) {
      _currentAyah = data['ayahId'];
    }

    // Önbelleğe ekle
    final cacheKey = '${_currentSurah}_${_currentAyah}';
    _wordTrackCache[cacheKey] = data;

    notifyListeners();
  }

  /// Kelime takip verilerini yükler
  Future<Map<String, dynamic>> loadWordTrackData(
      int surahNo, int ayahNo) async {
    try {
      // Besmele çalınıyorsa, besmele için varsayılan veri döndür
      if (_isBesmelePlaying) {
        print('Besmele çalınıyor, varsayılan besmele verisi kullanılıyor');
        _wordTrackData = _getDefaultBesmeleData(surahNo);
        notifyListeners();
        return _wordTrackData!;
      }

      // Önbellek anahtarı oluştur
      final cacheKey = '${_currentPage}_${surahNo}_$ayahNo';

      // Önbellekte varsa, önbellekten döndür
      if (_wordTrackCache.containsKey(cacheKey)) {
        print('Kelime takip verisi önbellekten alındı: $cacheKey');
        _wordTrackData = _wordTrackCache[cacheKey]!;
        notifyListeners();
        return _wordTrackData!;
      }

      print(
          'Kelime takip verisi yükleniyor - Sayfa: $_currentPage, Sure: $surahNo, Ayet: $ayahNo');

      // Besmele için özel durum
      if (ayahNo == 0) {
        print('Besmele için kelime takip verisi yükleniyor');
        _wordTrackData = _getDefaultBesmeleData(surahNo);
        _wordTrackCache[cacheKey] = _wordTrackData!;
        notifyListeners();

        // Arka planda gerçek veriyi yüklemeye çalış
        _loadBesmeleXmlInBackground(surahNo);

        return _wordTrackData!;
      }

      // XML sayfasını belirle
      final xmlPage = _currentPage;

      // Yeniden deneme mekanizması
      int maxRetries = 3;
      int currentTry = 0;

      while (currentTry < maxRetries) {
        try {
          // API'de sayfa numaraları 1'den başlıyor, uygulama içinde 0'dan başlıyor
          // Bu yüzden API çağrısında sayfa numarasını +1 yapıyoruz
          final apiPageNumber = xmlPage + 1;

          final String apiUrl =
              'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$apiPageNumber.xml';

          print('XML API URL: $apiUrl');

          final response = await _dio.get(apiUrl,
              options: Options(
                  receiveTimeout: Duration(seconds: 15),
                  sendTimeout: Duration(seconds: 15)));

          if (response.statusCode == 200) {
            final xmlData = response.data.toString();
            print('XML verisi alındı - Uzunluk: ${xmlData.length}');

            _wordTrackData = _parseWordTrackXml(xmlData, surahNo, ayahNo);

            // Veri bulunamadıysa varsayılan veri kullan
            if (_wordTrackData?.isEmpty ?? true) {
              print('XML verisi boş, varsayılan veri kullanılıyor');
              _wordTrackData = _getDefaultAyahData(surahNo, ayahNo);
            }

            // Önbelleğe ekle
            _wordTrackCache[cacheKey] = _wordTrackData!;

            // Mevcut sure ve ayet numaralarını güncelle
            _currentSurah = surahNo;
            _currentAyah = ayahNo;

            notifyListeners();
            return _wordTrackData!;
          } else {
            print('XML yükleme başarısız - HTTP Kodu: ${response.statusCode}');
            currentTry++;
          }
        } catch (e) {
          print('XML yükleme hatası (Deneme ${currentTry + 1}): $e');
          currentTry++;
        }

        // Kısa bir bekleme süresi ekle
        if (currentTry < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * currentTry));
        }
      }

      // Tüm denemeler başarısız olursa varsayılan veri döndür
      print(
          'Tüm XML yükleme denemeleri başarısız oldu, varsayılan veri kullanılıyor');
      _wordTrackData = _getDefaultAyahData(surahNo, ayahNo);

      // Başarısız olsa bile önbelleğe ekle (tekrar denemeler için)
      _wordTrackCache[cacheKey] = _wordTrackData!;

      notifyListeners();
      return _wordTrackData!;
    } catch (e) {
      print('XML yükleme hatası: $e');
      _wordTrackData = _getDefaultAyahData(surahNo, ayahNo);
      notifyListeners();
      return _wordTrackData!;
    }
  }

  /// Arka planda besmele XML verilerini yükler
  Future<void> _loadBesmeleXmlInBackground(int surahNo) async {
    try {
      // Önbellek anahtarı
      final cacheKey = '${_currentPage}_${surahNo}_0';

      // Sayfa numarası +1 (API için)
      final apiPageNumber = _currentPage + 1;

      final String apiUrl =
          'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$apiPageNumber.xml';

      try {
        final response = await _dio.get(apiUrl,
            options: Options(
                receiveTimeout: Duration(seconds: 10),
                sendTimeout: Duration(seconds: 10)));

        if (response.statusCode == 200) {
          final xmlData = response.data.toString();
          final document = XmlDocument.parse(xmlData);
          final verseNodes = document.findAllElements('a');
          final parsedData = _parseBismillahXml(verseNodes, surahNo);

          if (parsedData.isNotEmpty) {
            _wordTrackCache[cacheKey] = parsedData;
            // Eğer hala besmele çalınıyorsa, veriyi güncelle
            if (_isBesmelePlaying && _wordTrackData != null) {
              _wordTrackData = parsedData;
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('Arka plan besmele XML yükleme hatası: $e');
        // Hata durumunda işlem yapma, varsayılan veri kullanılmaya devam edilecek
      }
    } catch (e) {
      print('Arka plan besmele XML yükleme hatası: $e');
    }
  }

  /// Arka planda kelime takip verilerini yükler
  Future<void> loadWordTrackDataInBackground(int surahNo, int ayahNo) async {
    try {
      final xmlPage = _currentPage;
      print(
          'Arka planda XML yükleniyor - Sayfa: $xmlPage, Sure: $surahNo, Ayet: $ayahNo');

      // Önbellek anahtarı
      final cacheKey = '${xmlPage}_${surahNo}_$ayahNo';

      // Eğer önbellekte varsa ve geçerli veri ise, tekrar yükleme
      if (_wordTrackCache.containsKey(cacheKey) &&
          _wordTrackCache[cacheKey]!.isNotEmpty &&
          _wordTrackCache[cacheKey]!['tracks'] != null &&
          (_wordTrackCache[cacheKey]!['tracks'] as List).isNotEmpty) {
        print(
            'Arka plan yüklemesi atlandı - veri önbellekte mevcut: $cacheKey');
        return;
      }

      // API'de sayfa numaraları 1'den başlıyor, uygulama içinde 0'dan başlıyor
      final apiPageNumber = xmlPage + 1;

      final String apiUrl =
          'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$apiPageNumber.xml';

      print('Arka plan XML API URL: $apiUrl');

      try {
        final response = await _dio.get(apiUrl,
            options: Options(
                receiveTimeout: Duration(seconds: 15),
                sendTimeout: Duration(seconds: 15)));

        if (response.statusCode == 200) {
          final xmlData = response.data.toString();
          final parsedData = _parseWordTrackXml(xmlData, surahNo, ayahNo);

          if (parsedData.isNotEmpty) {
            _wordTrackCache[cacheKey] = parsedData;

            // Eğer hala aynı ayet çalınıyorsa, veriyi güncelle
            if (_currentSurah == surahNo &&
                _currentAyah == ayahNo &&
                _wordTrackData != null) {
              _wordTrackData = parsedData;
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('Arka plan XML yükleme hatası: $e');
        // Oynatmaya devam et, hatayı ele almaya gerek yok
      }
    } catch (e) {
      print('Arka plan XML yükleme hatası: $e');
      // Oynatmaya devam et, hatayı ele almaya gerek yok
    }
  }

  /// Kelime takibini günceller
  void updateWordTrack(Duration position, {bool isAyahChanging = false}) {
    // Ayet değişimi sırasında kelime takibi yapma
    if (isAyahChanging) {
      if (_currentWordIndex != -1) {
        _currentWordIndex = -1;
        notifyListeners();
      }
      return;
    }

    if (_wordTrackData == null || _wordTrackData!['tracks'] == null) {
      return;
    }

    final currentTime = position.inMilliseconds / 1000.0;
    final List<Map<String, dynamic>> tracks = _wordTrackData!['tracks'];

    // Besmele çalma durumunu kontrol et
    final bool isBesmele = _isBesmelePlaying ||
        (_wordTrackData!['ayahNo'] == 0 &&
            _wordTrackData!['hasBesmele'] == true);

    // Eğer besmele çalınıyorsa, kelime takibi yapma
    if (isBesmele) {
      // Besmele çalınırken kelime indeksini değiştirme
      return;
    }

    if (tracks.isEmpty) {
      return;
    }

    // İlk kelime için özel kontrol
    // Eğer ses dosyası yeni başladıysa ve position çok küçükse, ilk kelimeyi vurgulama
    if (currentTime < 0.3 && tracks.isNotEmpty) {
      final firstTrack = tracks.first;
      final firstStart = firstTrack['start'] as double;

      // Eğer ilk kelimenin başlangıç zamanı 0.5 saniyeden küçükse ve mevcut zaman 0.3 saniyeden küçükse
      // ilk kelimeyi vurgula
      if (firstStart < 0.5 && _currentWordIndex != firstTrack['index']) {
        _currentWordIndex = firstTrack['index'];
        print(
            'İlk kelime vurgulandı - Index: ${firstTrack['index']}, Başlangıç: $firstStart');
        notifyListeners();
        return;
      }
    }

    final lastTrack = tracks.last;
    final lastEndTime = lastTrack['end'] as double;

    // Normal ayetler için zaman aşımı
    final timeoutBuffer = 0.5;

    if (currentTime > lastEndTime + timeoutBuffer) {
      if (_currentWordIndex != -1) {
        _currentWordIndex = -1;
        notifyListeners();
      }
      return;
    }

    var foundWord = false;
    for (var track in tracks) {
      final start = track['start'] as double;
      final end = track['end'] as double;
      final index = track['index'] as int;

      // Normal ayet toleransı
      final tolerance = 0.2;

      if (currentTime >= start - tolerance && currentTime < end + tolerance) {
        foundWord = true;
        if (_currentWordIndex != index) {
          print(
              'Kelime değişti - Zaman: $currentTime, Index: $index, Başlangıç: $start, Bitiş: $end');
          _currentWordIndex = index;
          notifyListeners();
        }
        break;
      }
    }

    if (!foundWord && _currentWordIndex != -1) {
      _currentWordIndex = -1;
      notifyListeners();
    }
  }

  /// XML verisini ayrıştırır
  Map<String, dynamic> _parseWordTrackXml(
      String xmlData, int surahNo, int ayahNo) {
    try {
      print('XML ayrıştırma başladı - Sure: $surahNo, Ayet: $ayahNo');

      // XML verisi boş mu kontrol et
      if (xmlData.isEmpty) {
        print('XML verisi boş');
        return ayahNo == 0
            ? _getDefaultBesmeleData(surahNo)
            : _getDefaultAyahData(surahNo, ayahNo);
      }

      final document = XmlDocument.parse(xmlData);
      final verseNodes = document.findAllElements('a');

      print('Bulunan toplam ayet sayısı: ${verseNodes.length}');

      // Hiç ayet bulunamadıysa varsayılan veri döndür
      if (verseNodes.isEmpty) {
        print('XML içinde ayet bulunamadı');
        return ayahNo == 0
            ? _getDefaultBesmeleData(surahNo)
            : _getDefaultAyahData(surahNo, ayahNo);
      }

      // Besmele (ayet 0) için özel işleme
      if (ayahNo == 0) {
        return _parseBismillahXml(verseNodes, surahNo);
      }

      // Normal ayet işleme
      return _parseRegularAyahXml(verseNodes, surahNo, ayahNo);
    } catch (e, stackTrace) {
      print('XML ayrıştırma hatası: $e');
      print('Hata detayı: $stackTrace');
      return ayahNo == 0
          ? _getDefaultBesmeleData(surahNo)
          : _getDefaultAyahData(surahNo, ayahNo);
    }
  }

  /// Besmele XML verisini ayrıştırır
  Map<String, dynamic> _parseBismillahXml(
      Iterable<XmlElement> verseNodes, int surahNo) {
    // Besmele düğümünü ara
    XmlElement? bismillahNode;
    for (var node in verseNodes) {
      final s = int.parse(node.getAttribute('s') ?? '0');
      final a = int.parse(node.getAttribute('a') ?? '0');

      if (s == surahNo && a == 0) {
        bismillahNode = node;
        break;
      }
    }

    // Besmele düğümü bulunduysa ayrıştır
    if (bismillahNode != null) {
      final List<Map<String, dynamic>> tracks = [];
      final wordNodes = bismillahNode.findAllElements('t');

      print('Besmele kelime sayısı: ${wordNodes.length}');

      final sortedWords = wordNodes.toList()
        ..sort((a, b) {
          final timeA = int.parse(a.getAttribute('s') ?? '0');
          final timeB = int.parse(b.getAttribute('s') ?? '0');
          return timeA.compareTo(timeB);
        });

      for (var i = 0; i < sortedWords.length; i++) {
        final wordNode = sortedWords[i];
        final startTime = int.parse(wordNode.getAttribute('s') ?? '0');
        final wordIndex = int.parse(wordNode.getAttribute('k') ?? '0');

        int endTime;
        if (i < sortedWords.length - 1) {
          endTime = int.parse(sortedWords[i + 1].getAttribute('s') ?? '0');
        } else {
          endTime = startTime + 2000;
        }

        tracks.add({
          'start': startTime / 1000.0,
          'end': endTime / 1000.0,
          'index': i,
          'wordIndex': wordIndex,
        });

        print(
            'Besmele kelimesi eklendi - Başlangıç: ${startTime / 1000.0}, Bitiş: ${endTime / 1000.0}, Index: $i, Kelime Sırası: $wordIndex');
      }

      final result = {
        'surahNo': surahNo,
        'ayahNo': 0,
        'tracks': tracks,
        'totalWords': tracks.length,
        'hasBesmele': true
      };

      print(
          'Besmele XML ayrıştırma tamamlandı - Toplam kelime: ${result['totalWords']}');
      return result;
    } else {
      print('Besmele verisi bulunamadı!');
      // Varsayılan Besmele verisi döndür
      return _getDefaultBesmeleData(surahNo);
    }
  }

  /// Normal ayet XML verisini ayrıştırır
  Map<String, dynamic> _parseRegularAyahXml(
      Iterable<XmlElement> verseNodes, int surahNo, int ayahNo) {
    int totalPreviousWords = 0;
    bool foundTargetVerse = false;
    XmlElement? targetVerseNode;
    bool hasBesmele = false;
    int previousVerseCount = 0; // Önceki ayet sayısı

    // Önce tüm önceki ayetlerin kelime sayılarını hesapla
    for (var node in verseNodes) {
      final s = int.parse(node.getAttribute('s') ?? '0');
      final a = int.parse(node.getAttribute('a') ?? '0');

      // Aynı sayfadaki önceki surelerin kelimelerini say
      if (s < surahNo) {
        // Besmele (a == 0) kelimelerini toplam kelime sayısına ekleme
        if (a != 0) {
          final wordNodes = node.findAllElements('t');
          totalPreviousWords += wordNodes.length;
          previousVerseCount++; // Her ayet için +1
        }
        continue;
      }

      // Mevcut surenin önceki ayetlerinin kelimelerini say
      if (s == surahNo) {
        if (a == 0) {
          hasBesmele = true;
          // Besmele kelimelerini toplam kelime sayısına ekleme
          continue;
        }
        if (a < ayahNo) {
          final wordNodes = node.findAllElements('t');
          totalPreviousWords += wordNodes.length;
          previousVerseCount++; // Her ayet için +1
        } else if (a == ayahNo) {
          targetVerseNode = node;
          foundTargetVerse = true;
          break;
        }
      }
    }

    // Önceki ayetlerin numaraları için kelime sayısına ekleme yap
    totalPreviousWords += previousVerseCount;
    print('Önceki kelime sayısı (ayet numaraları dahil): $totalPreviousWords');

    if (!foundTargetVerse || targetVerseNode == null) {
      print('Hedef ayet bulunamadı!');
      return {};
    }

    final List<Map<String, dynamic>> tracks = [];
    final wordNodes = targetVerseNode.findAllElements('t');

    print('Hedef ayetteki kelime sayısı: ${wordNodes.length}');

    final sortedWords = wordNodes.toList()
      ..sort((a, b) {
        final timeA = int.parse(a.getAttribute('s') ?? '0');
        final timeB = int.parse(b.getAttribute('s') ?? '0');
        return timeA.compareTo(timeB);
      });

    for (var i = 0; i < sortedWords.length; i++) {
      final wordNode = sortedWords[i];
      final startTime = int.parse(wordNode.getAttribute('s') ?? '0');
      final wordIndex = int.parse(wordNode.getAttribute('k') ?? '0');
      final index = totalPreviousWords + (wordIndex - 1);

      int endTime;
      if (i < sortedWords.length - 1) {
        endTime = int.parse(sortedWords[i + 1].getAttribute('s') ?? '0');
      } else {
        endTime = startTime + 2000;
      }

      tracks.add({
        'start': startTime / 1000.0,
        'end': endTime / 1000.0,
        'index': index,
        'wordIndex': wordIndex,
      });

      print(
          'Kelime eklendi - Başlangıç: ${startTime / 1000.0}, Bitiş: ${endTime / 1000.0}, Index: $index, Kelime Sırası: $wordIndex');
    }

    final result = {
      'surahNo': surahNo,
      'ayahNo': ayahNo,
      'tracks': tracks,
      'totalWords': totalPreviousWords +
          tracks.length +
          1, // Mevcut ayetin numarası için +1
      'hasBesmele': hasBesmele
    };

    print('XML ayrıştırma tamamlandı - Toplam kelime: ${result['totalWords']}');
    return result;
  }

  /// Varsayılan Besmele verisi döndürür
  Map<String, dynamic> _getDefaultBesmeleData(int surahNo) {
    return {
      'surahNo': surahNo,
      'ayahNo': 0,
      'tracks': [
        {'start': 0.0, 'end': 1.028, 'index': 0, 'wordIndex': 1},
        {'start': 1.028, 'end': 2.109, 'index': 1, 'wordIndex': 2},
        {'start': 2.109, 'end': 3.805, 'index': 2, 'wordIndex': 3},
        {'start': 3.805, 'end': 5.0, 'index': 3, 'wordIndex': 4}
      ],
      'totalWords': 4,
      'hasBesmele': true
    };
  }

  /// Varsayılan ayet verisi döndürür
  Map<String, dynamic> _getDefaultAyahData(int surahNo, int ayahNo) {
    // Daha fazla kelime içeren varsayılan veri oluştur
    final List<Map<String, dynamic>> tracks = [];

    // Ortalama bir ayetin 15-20 kelime içerdiğini varsayalım
    final int wordCount = 20;

    // Her kelime için yaklaşık 1 saniye süre ayır
    for (var i = 0; i < wordCount; i++) {
      tracks.add({
        'start': i * 1.0,
        'end': (i + 1) * 1.0,
        'index': i,
        'wordIndex': i + 1,
      });
    }

    return {
      'surahNo': surahNo,
      'ayahNo': ayahNo,
      'tracks': tracks,
      'totalWords': wordCount,
      'hasBesmele': false
    };
  }
}
