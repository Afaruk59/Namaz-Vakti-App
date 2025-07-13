import 'package:flutter/material.dart';
import 'quran_audio_player.dart';
import 'quran_word_tracker.dart';
import 'quran_audio_repository.dart';
import 'package:xml/xml.dart';
import 'package:dio/dio.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';

// Yeni oluşturulan parçaları import et
import 'quran_audio_playback_controller.dart';
import 'quran_audio_navigation.dart';
import 'quran_audio_besmele_handler.dart';
import 'quran_audio_page_manager.dart';

/// Kuran ses çalma ve kelime takibi için ana servis sınıfı
class QuranAudioService extends ChangeNotifier
    with
        QuranAudioPlaybackController,
        QuranAudioNavigation,
        QuranAudioBesmeleHandler,
        QuranAudioPageManager {
  final QuranAudioPlayer _audioPlayer;
  final QuranWordTracker _wordTracker;
  final QuranAudioRepository _repository;
  final Dio _dio = Dio();
  final AudioPlayerService _audioPlayerService;

  bool _isPlaying = false;
  bool _isBesmelePlaying = false;
  bool _isMealPlaying = false;
  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentAyah = 1;
  bool _isDisposed = false;
  bool _isUserInitiated = true; // Kullanıcı tarafından başlatılan ses çalma işlemi
  bool _isAyahChanging = false; // Ayet değişimi sırasında vurgulamayı engelle
  bool _wasBesmelePlaying = false; // Besmele duraklatıldığında durumu sakla

  // Sayfa son ayet bilgileri
  Map<int, Map<String, dynamic>> _pageLastAyahInfo = {};
  bool _isLastAyahOfPage = false;
  int _lastAyahWordCount = 0;

  // Getters
  @override
  bool get isPlaying => _isPlaying;
  @override
  bool get isBesmelePlaying => _isBesmelePlaying;
  bool get isMealPlaying => _isMealPlaying;
  double get playbackRate => _audioPlayer.playbackRate;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration;
  int get currentWordIndex => _wordTracker.currentWordIndex;
  @override
  bool get isDisposed => _isDisposed;
  @override
  int get currentPage => _currentPage;
  @override
  bool get isUserInitiated => _isUserInitiated;
  @override
  int get currentSurah => _currentSurah;
  @override
  int get currentAyah => _currentAyah;
  @override
  bool get isAyahChanging => _isAyahChanging;
  @override
  bool get isLastAyahOfPage => _isLastAyahOfPage;
  @override
  Map<int, Map<String, dynamic>> get pageLastAyahInfo => _pageLastAyahInfo;
  @override
  Dio get dio => _dio;

  /// Mevcut sure ve ayet bilgilerini döndürür
  String getCurrentSurahAndAyah() {
    if (_isBesmelePlaying || _wasBesmelePlaying) {
      return "Besmele";
    }

    final surahName = _repository.getSurahName(_currentSurah);
    return "$surahName:$_currentAyah";
  }

  /// Mevcut sure adını döndürür
  String getCurrentSurahName() {
    return _repository.getSurahName(_currentSurah);
  }

  /// Besmele çalıyor mu kontrol eder
  bool get isBesmelePlayingOrWas => _isBesmelePlaying || _wasBesmelePlaying;

  QuranAudioService()
      : _audioPlayer = QuranAudioPlayer(),
        _wordTracker = QuranWordTracker(),
        _repository = QuranAudioRepository(),
        _audioPlayerService = AudioPlayerService() {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.addListener(_onAudioPlayerUpdate);
    _wordTracker.addListener(_onWordTrackerUpdate);

    _audioPlayer.addCompletionListener(() {
      if (_isBesmelePlaying) {
        handleBesmeleComplete();
      } else {
        playNextAyahAuto();
      }
    });
  }

  void _onAudioPlayerUpdate() {
    if (_isDisposed) return;
    // AudioPlayer'dan gelen çalma durumunu al
    final wasPlaying = _isPlaying;
    final wasBesmelePlaying = _isBesmelePlaying;

    // Ayet değişimi sırasında ses durumu değişikliklerini daha dikkatli yönet
    if (!_isAyahChanging) {
      // Normal durumda (ayet değişimi yokken) ses durumunu güncelle
      _isPlaying = _audioPlayer.isPlaying;

      // Durum değişikliğini logla
      if (wasPlaying != _isPlaying) {
        print(
            'AudioPlayer durum değişikliği: $_isPlaying, isBesmelePlaying: $_isBesmelePlaying, AudioPlayer.isPlaying: ${_audioPlayer.isPlaying}');

        // Eğer ses durduysa ve besmele çalıyorsa, besmele durumunu da güncelle
        if (!_isPlaying && _isBesmelePlaying) {
          print('Besmele duraklatıldı - AudioPlayer.isPlaying: ${_audioPlayer.isPlaying}');
          // Besmele duraklatıldığında _isBesmelePlaying'i false yap
          _isBesmelePlaying = false;
          _wordTracker.setBesmelePlaying(false);
        }

        // Eğer ses başladıysa ve _wasBesmelePlaying true ise veya getCurrentSurahAndAyah() "Besmele" ise, besmele durumunu güncelle
        if (_isPlaying && (_wasBesmelePlaying || getCurrentSurahAndAyah() == "Besmele")) {
          print('Besmele devam ettiriliyor - AudioPlayer.isPlaying: ${_audioPlayer.isPlaying}');
          _isBesmelePlaying = true;
          _wasBesmelePlaying = false; // Sıfırla
          _wordTracker.setBesmelePlaying(true);
        }
      }
    } else {
      // Ayet değişimi sırasında, ses durumu değişikliklerini log'la ama bayrakları değiştirme
      if (wasPlaying != _audioPlayer.isPlaying) {
        print(
            'Ayet değişimi sırasında AudioPlayer durum değişikliği: ${_audioPlayer.isPlaying}, isBesmelePlaying: $_isBesmelePlaying');
      }
    }

    // Ayet değişimi durumunu QuranWordTracker'a ilet
    _wordTracker.updateWordTrack(_audioPlayer.position, isAyahChanging: _isAyahChanging);

    // AudioPlayerService ile senkronize et
    _syncWithAudioPlayerService();

    notifyListeners();
  }

  /// AudioPlayerService ile senkronize et
  void _syncWithAudioPlayerService() {
    try {
      // AudioPlayerService'in durumunu güncelle
      if (_isPlaying != _audioPlayerService.isPlaying) {
        if (_isPlaying) {
          // Quran audio player çalıyorsa AudioPlayerService'i de çalıştır
          _audioPlayerService.forceUpdatePlayingState(true);
        } else {
          // Quran audio player durmuşsa AudioPlayerService'i de durdur
          _audioPlayerService.forceUpdatePlayingState(false);
        }
      }

      // Pozisyonu senkronize et
      if (_audioPlayer.position != _audioPlayerService.position) {
        _audioPlayerService.seekTo(_audioPlayer.position);
      }
    } catch (e) {
      print('QuranAudioService _syncWithAudioPlayerService hatası: $e');
    }
  }

  void _onWordTrackerUpdate() {
    if (_isDisposed) return;
    // Son ayetin son kelimesini takip et
    if (_isLastAyahOfPage && _wordTracker.currentWordIndex >= 0 && _lastAyahWordCount > 0) {
      // Son kelimeye yaklaşıldığında log ekle
      if (_wordTracker.currentWordIndex >= _lastAyahWordCount - 3) {
        print(
            'Son ayetin son kelimelerine yaklaşılıyor: ${_wordTracker.currentWordIndex + 1}/$_lastAyahWordCount');
      }

      // Son kelimeye gelindiğinde
      if (_wordTracker.currentWordIndex >= _lastAyahWordCount - 1) {
        print('Son ayetin son kelimesi okunuyor, ses dosyası bitince sayfa değişecek');
        // Sayfa değişimi için işaretleme yap, ancak hemen değiştirme
        // Ses dosyası tamamlandığında _playNextAyah metodu çağrılacak ve orada sayfa değişimi yapılacak
      }
    }
    notifyListeners();
  }

  /// Kaynakları temizler
  Future<void> cleanup() async {
    try {
      _removeListeners();
      if (_audioPlayer != null && !_isDisposed) {
        await _audioPlayer.cleanup();
      }
      _wordTracker.setCurrentWordIndex(-1);
    } catch (e) {
      print('QuranAudioService cleanup hatası: $e');
      // Hata durumunda state'i güvenli bir şekilde sıfırla
      _wordTracker.setCurrentWordIndex(-1);
    }
  }

  /// Kaynakları temizler ve dispose eder
  @override
  Future<void> dispose() async {
    try {
      if (_isDisposed) return;

      _removeListeners();
      if (!_isDisposed) {
        await _audioPlayer.dispose();
      }
      await _audioPlayerService.stopAudio(); // Stop the audio player service
      _isDisposed = true;
      super.dispose();
    } catch (e) {
      print('QuranAudioService dispose hatası: $e');
      _isDisposed = true;
      super.dispose();
    }
  }

  /// Dinleyicileri kaldırır
  void _removeListeners() {
    try {
      if (!_isDisposed) {
        _audioPlayer.removeListener(_onAudioPlayerUpdate);
        _wordTracker.removeListener(_onWordTrackerUpdate);
      }
    } catch (e) {
      print('QuranAudioService _removeListeners hatası: $e');
    }
  }

  // Mixin'ler için gerekli implementasyonlar

  // QuranAudioPlaybackController için implementasyonlar
  @override
  Future<void> setCurrentWordIndex(int index) async {
    _wordTracker.setCurrentWordIndex(index);
  }

  @override
  Future<void> setBesmelePlaying(bool value) async {
    _isBesmelePlaying = value;
    _wordTracker.setBesmelePlaying(value);
  }

  @override
  Future<void> audioPlayerPause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  @override
  Future<void> audioPlayerStop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isBesmelePlaying = false;
    _wasBesmelePlaying = false;
  }

  @override
  Future<void> audioPlayerPlay(String url) async {
    await _audioPlayer.play(url);
    _isPlaying = _audioPlayer.isPlaying;
  }

  @override
  Future<void> audioPlayerSeekTo(Duration position) async {
    await _audioPlayer.seekTo(position);
  }

  @override
  Future<void> audioPlayerSetPlaybackRate(double rate) async {
    await _audioPlayer.setPlaybackRate(rate);
  }

  @override
  Future<void> audioPlayerResume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  @override
  String getAyahAudioUrl(int surahNo, int ayahNo) {
    // Diyanet URL'sini kullan
    return 'https://webdosya.diyanet.gov.tr/kuran/kuranikerim/Sound/ar_osmanSahin/${surahNo}_${ayahNo}.mp3';
  }

  @override
  void notifyListenersPublic() {
    notifyListeners();
  }

  @override
  String getSurahName(int surahNo) {
    return _repository.getSurahName(surahNo);
  }

  @override
  Future<void> audioPlayerIsPlaying() async {
    _isPlaying = _audioPlayer.isPlaying;
  }

  // QuranAudioNavigation için implementasyonlar
  @override
  Future<void> setAyahChanging(bool value) async {
    _isAyahChanging = value;
    _wordTracker.setAyahChanging(value);
  }

  @override
  int getMaxAyahCount(int surahNo) {
    // Sure numarasına göre maksimum ayet sayısını döndür
    final surahAyahCounts = [
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6
    ];

    if (surahNo >= 1 && surahNo <= 114) {
      return surahAyahCounts[surahNo - 1];
    }
    return 0;
  }

  // QuranAudioBesmeleHandler için implementasyonlar
  @override
  String getBismillahAudioUrl(int surahNo) {
    return _repository.getBismillahAudioUrl(surahNo);
  }

  @override
  Future<Map<String, dynamic>> loadWordTrackData(int surahNo, int ayahNo) async {
    try {
      // _wordTracker.loadWordTrackData metodunu çağır
      final result = await _wordTracker.loadWordTrackData(surahNo, ayahNo);

      // Eğer sonuç boşsa, kendi implementasyonumuzu deneyelim
      if (result.isEmpty || (result['tracks'] as List).isEmpty) {
        print('WordTracker sonucu boş, kendi implementasyonumuzu deniyoruz');
        final String apiUrl =
            'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/s$surahNo/a$ayahNo.xml';

        final response = await _dio.get(apiUrl);
        if (response.statusCode == 200) {
          final xmlData = response.data.toString();
          final document = XmlDocument.parse(xmlData);
          final ayahNode = document.findAllElements('a').first;
          final wordNodes = ayahNode.findAllElements('t');

          final List<Map<String, dynamic>> tracks = [];
          for (var wordNode in wordNodes) {
            final start = double.parse(wordNode.getAttribute('s') ?? '0');
            final end = double.parse(wordNode.getAttribute('e') ?? '0');
            final wordIndex = int.parse(wordNode.getAttribute('i') ?? '0');

            tracks.add({
              'start': start,
              'end': end,
              'index': wordIndex,
            });
          }

          final resultData = {
            'surahId': surahNo,
            'ayahId': ayahNo,
            'tracks': tracks,
          };

          // WordTracker'a da bu veriyi set et
          await _wordTracker.setWordTrackData(resultData);

          return resultData;
        }
        return {};
      }

      return result;
    } catch (e) {
      print('Kelime takip verisi yükleme hatası: $e');
      return {};
    }
  }

  @override
  Future<void> loadWordTrackDataInBackground(int surahNo, int ayahNo) async {
    await _wordTracker.loadWordTrackDataInBackground(surahNo, ayahNo);
  }

  // QuranAudioPageManager için implementasyonlar
  @override
  Future<void> setLastAyahOfPage(bool value) async {
    _isLastAyahOfPage = value;
  }

  @override
  Future<void> setLastAyahWordCount(int count) async {
    _lastAyahWordCount = count;
    notifyListeners();
  }

  @override
  Future<void> setCurrentPage(int pageNumber) async {
    _currentPage = pageNumber;
    _wordTracker.setCurrentPage(pageNumber);
  }

  @override
  Future<void> setCurrentSurah(int surahNo) async {
    _currentSurah = surahNo;
  }

  @override
  Future<void> setCurrentAyah(int ayahNo) async {
    _currentAyah = ayahNo;
  }

  @override
  Future<void> setUserInitiated(bool value) async {
    _isUserInitiated = value;
    notifyListeners();
  }

  @override
  Future<void> addPageLastAyahInfo(int pageNumber, Map<String, dynamic> info) async {
    _pageLastAyahInfo[pageNumber] = info;
    notifyListeners();
  }

  // Dışa açık metodlar

  /// Sesi oynatır
  Future<void> play() async {
    return await playAudio();
  }

  /// Sesi duraklatır
  Future<void> pause() async {
    try {
      await pauseAudio();

      // AudioPlayerService ile senkronize et
      _syncWithAudioPlayerService();
    } catch (e) {
      print('QuranAudioService pause hatası: $e');
    }
  }

  /// Duraklatılmış sesi devam ettirir
  Future<void> resume() async {
    try {
      await resumeAudio();

      // AudioPlayerService ile senkronize et
      _syncWithAudioPlayerService();
    } catch (e) {
      print('QuranAudioService resume hatası: $e');
    }
  }

  /// Sesi durdurur
  Future<void> stop() async {
    try {
      await stopAudio();

      // AudioPlayerService'den Quran kitap kodunu temizle
      await _audioPlayerService.setPlayingBookCode(null);

      // AudioPlayerService ile senkronize et
      _syncWithAudioPlayerService();

      // State'i sıfırla
      _isPlaying = false;
      _isBesmelePlaying = false;
      _wasBesmelePlaying = false;
      notifyListeners();
    } catch (e) {
      print('QuranAudioService stop hatası: $e');
    }
  }

  /// Belirli bir konuma atlar
  Future<void> seekTo(Duration position) async {
    return await seekToPosition(position);
  }

  /// Belirli bir konuma atlar (iç metod)
  Future<void> seekToPosition(Duration position) async {
    try {
      if (_isDisposed) return;

      print('seekToPosition çağrıldı: ${position.inMilliseconds} ms');

      // AudioPlayer'ı belirli bir konuma atla
      await _audioPlayer.seekTo(position);

      // UI'ı güncelle
      notifyListeners();
    } catch (e) {
      print('QuranAudioService seekToPosition hatası: $e');
    }
  }

  /// Oynatma hızını ayarlar
  Future<void> setPlaybackRate(double rate) async {
    return await setAudioPlaybackRate(rate);
  }

  /// Kullanıcı tarafından manuel olarak bir sonraki ayete geçiş
  Future<void> playNextAyah() async {
    return await navigateToNextAyah();
  }

  /// Kullanıcı tarafından manuel olarak bir önceki ayete geçiş
  Future<void> playPreviousAyah() async {
    return await navigateToPreviousAyah();
  }

  /// Mevcut sayfadaki ilk ayeti mi okuyoruz kontrol eder
  bool isFirstAyahOfCurrentPage() {
    return checkIsFirstAyahOfPage();
  }

  /// Mevcut sayfadaki son ayeti mi okuyoruz kontrol eder
  bool isLastAyahOfCurrentPage() {
    return checkIsLastAyahOfPage();
  }

  /// Belirli bir ayeti çalar
  Future<void> playAyah({
    required int surahNo,
    required int ayahNo,
    required String audioUrl,
    required String xmlUrl,
    required bool shouldPlayBesmele,
    required bool isUserInitiated,
  }) async {
    try {
      if (_isDisposed) return;

      // Durum değişkenlerini güncelle
      await setCurrentSurah(surahNo);
      await setCurrentAyah(ayahNo);
      await setUserInitiated(isUserInitiated);
      await setCurrentWordIndex(-1);

      // AudioPlayerService'e Quran kitap kodunu set et
      await _audioPlayerService.setPlayingBookCode('quran');

      // Besmele çalma durumunu kontrol et
      if (shouldPlayBesmele) {
        // Önce sure numarasını ayarla, sonra besmele çal
        await setCurrentSurah(surahNo);
        await playBesmele();
      } else {
        // Doğrudan ayeti çal
        await playAyahWithXml(surahNo, ayahNo, audioUrl, xmlUrl);
      }

      // AudioPlayerService ile senkronize et
      _syncWithAudioPlayerService();
    } catch (e) {
      print('QuranAudioService playAyah hatası: $e');
      // Hata durumunda durum değişkenlerini sıfırla
      await stop();
    }
  }

  /// Besmele çalar
  @override
  Future<void> playBesmele() async {
    try {
      if (_isDisposed) return;

      // Besmele çalma durumunu güncelle
      await setBesmelePlaying(true);

      // Besmele ses dosyasını çal
      final besmeleUrl = _repository.getBismillahAudioUrl(_currentSurah);
      await audioPlayerPlay(besmeleUrl);

      // UI'ı güncelle
      notifyListeners();
    } catch (e) {
      print('QuranAudioService playBesmele hatası: $e');
      await setBesmelePlaying(false);
    }
  }

  /// Belirli bir sure için besmele çalar (yardımcı metod)
  Future<void> playBesmeleForSurah(int surahNo) async {
    // Önce mevcut sure numarasını güncelle
    await setCurrentSurah(surahNo);
    // Sonra besmele çal
    await playBesmele();
  }

  /// Ayet ses dosyasını XML ile çalar
  Future<void> playAyahWithXml(int surahNo, int ayahNo, String audioUrl, String xmlUrl) async {
    try {
      if (_isDisposed) return;

      // Kelime takip verilerini yükle
      final wordTrackData = await loadWordTrackData(surahNo, ayahNo);
      if (wordTrackData.isEmpty) {
        throw Exception('Kelime takip verileri yüklenemedi');
      }

      // Kelime takip verilerini ayarla
      _wordTracker.setWordTrackData(wordTrackData);

      // Ses dosyasını çal
      await audioPlayerPlay(audioUrl);

      // UI'ı güncelle
      notifyListeners();
    } catch (e) {
      print('QuranAudioService playAyahWithXml hatası: $e');
      // Hata durumunda durum değişkenlerini sıfırla
      await stop();
    }
  }
}
