import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/quran/audio/quran_audio_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';

/// Kuran için kilit ekranında medya kontrollerini yöneten sınıf
class QuranMediaController {
  static const MethodChannel _channel =
      MethodChannel('com.afaruk59.namaz_vakti_app/media_controls');
  final QuranAudioService _audioService;
  final AudioPlayerService _audioPlayerService;
  bool _isServiceRunning = false;

  // Expose service running state
  bool get isServiceRunning => _isServiceRunning;

  // Playback state sabitleri
  static const int STATE_NONE = 0;
  static const int STATE_PLAYING = 3;
  static const int STATE_PAUSED = 2;
  static const int STATE_STOPPED = 1;

  // Sayfa değişimi için callback'ler
  Function(int)? _onNextPage;
  Function(int)? _onPreviousPage;
  int _currentPage = 1;
  int _totalPages = 604; // Kuran için toplam sayfa sayısı

  QuranMediaController({
    required QuranAudioService audioService,
    required AudioPlayerService audioPlayerService,
  })  : _audioService = audioService,
        _audioPlayerService = audioPlayerService {
    _setupListeners();
    setupMethodCallHandler();
  }

  /// Servis başlatma
  Future<void> startService() async {
    try {
      if (!_isServiceRunning) {
        await _channel.invokeMethod('startService');
        _isServiceRunning = true;

        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 200));
      }
    } catch (e) {
      print('QuranMediaController startService hatası: $e');
      // Hata durumunda servis durumunu güncelle
      _isServiceRunning = false;
    }
  }

  /// Servis durdurma
  Future<void> stopService() async {
    if (_isServiceRunning) {
      // Önce playback state'i durdurulmuş olarak işaretle (kitap ile aynı)
      await updatePlaybackState(STATE_STOPPED);
      await Future.delayed(Duration(milliseconds: 100));
      await _channel.invokeMethod('stopService');
      await Future.delayed(Duration(milliseconds: 100));
      // Bazı cihazlarda ilk durdurma işlemi göz ardı edilebiliyor, tekrar çağır
      await _channel.invokeMethod('stopService');
      _isServiceRunning = false;
    }
  }

  /// Oynatma durumunu güncelleme
  Future<void> updatePlaybackState(int state) async {
    try {
      if (!_isServiceRunning) {
        await startService();
        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 100));
      }

      await _channel.invokeMethod('updatePlaybackState', {'state': state.toInt()});

      // Oynatma durumu değiştiğinde pozisyonu da güncelle
      if (state == STATE_PLAYING) {
        await updatePosition(_audioService.position.inMilliseconds);
      }
    } catch (e) {
      print('QuranMediaController updatePlaybackState hatası: $e');
    }
  }

  /// Metadata güncelleme
  Future<void> updateMetadata({
    required String title,
    required String surahName,
    required int ayahNumber,
    required int durationMs,
    int pageNumber = 0,
  }) async {
    if (_isServiceRunning) {
      // Başlığa sayfa numarasını ekle
      String displayTitle = pageNumber > 0 ? "${title} - Sayfa ${pageNumber}" : title;

      // Yazar kısmına sadece sure adı ekle (ayet numarası olmadan)
      String author;
      if (ayahNumber == 0) {
        // Besmele çalıyorsa
        author = "${surahName} - Besmele";
      } else {
        // Normal ayet çalıyorsa
        author = surahName;
      }

      await _channel.invokeMethod('updateMetadata', {
        'title': displayTitle,
        'author': author,
        'coverUrl': '', // Kuran için varsayılan kapak resmi kullanılabilir
        'duration': durationMs.toInt(),
      });
    }
  }

  /// Pozisyon güncelleme
  Future<void> updatePosition(int positionMs) async {
    if (_isServiceRunning) {
      await _channel.invokeMethod('updatePosition', {'position': positionMs.toInt()});
    }
  }

  /// Kuran sayfası için medya kontrollerini güncelleme
  Future<void> updateForQuranPage(int pageNumber, String surahName, int ayahNumber) async {
    try {
      // Her dinleme başlatıldığında method channel handler'ı tekrar ata
      setupMethodCallHandler();
      if (!_isServiceRunning) {
        await startService();
        // Servis başlatıldıktan sonra kısa bir gecikme ekle
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Metadata güncelle (sadece bir kez)
      await updateMetadata(
        title: "Kuran-ı Kerim",
        surahName: surahName,
        ayahNumber: ayahNumber,
        durationMs: _audioService.duration.inMilliseconds > 0
            ? _audioService.duration.inMilliseconds
            : 30000, // Eğer süre henüz belli değilse varsayılan bir değer kullan
        pageNumber: pageNumber,
      );

      // Oynatma durumunu güncelle - eğer ses çalınıyorsa PLAYING, değilse PAUSED olarak ayarla
      final state = _audioService.isPlaying ? STATE_PLAYING : STATE_PAUSED;
      await updatePlaybackState(state);

      // Pozisyonu güncelle
      if (_audioService.isPlaying) {
        await updatePosition(_audioService.position.inMilliseconds);
      }
    } catch (e) {
      print('QuranMediaController updateForQuranPage hatası: $e');
    }
  }

  /// Dinleyicileri ayarla
  void _setupListeners() {
    // AudioService'deki değişiklikleri dinle
    _audioService.addListener(() {
      // Oynatma durumu değiştiğinde
      if (_audioService.isPlaying) {
        updatePlaybackState(STATE_PLAYING);
      } else {
        // Zincirleme oynatmada veya otomatik geçişte STOPPED asla gönderme!
        updatePlaybackState(STATE_PAUSED);
      }
      // Pozisyon değiştiğinde
      updatePosition(_audioService.position.inMilliseconds);
    });
  }

  /// Sayfa değişimi için callback'leri ayarla
  void setPageChangeCallbacks({
    required Function(int) onNextPage,
    required Function(int) onPreviousPage,
    required int currentPage,
  }) {
    _onNextPage = onNextPage;
    _onPreviousPage = onPreviousPage;
    _currentPage = currentPage;
  }

  /// Mevcut sayfa bilgisini güncelle
  void updateCurrentPage(int currentPage) {
    _currentPage = currentPage;
  }

  /// Method call handler'ı ayarla
  void setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'play':
            await _audioService.resumeAudio();
            return true;
          case 'pause':
            await _audioService.pauseAudio();
            return true;
          case 'stop':
            await _audioService.stop();
            return true;
          case 'next':
            // Sonraki sayfa işlemi
            if (_onNextPage != null && _currentPage < _totalPages) {
              // Önce playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Sayfa değişimini gerçekleştir
              try {
                _onNextPage!(_currentPage + 1);

                // Sayfa değişiminden sonra playback state'i tekrar güncelle
                updatePlaybackState(_audioService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              } catch (e) {
                print('Sonraki sayfa işlemi hatası: $e');
                updatePlaybackState(STATE_PAUSED);
              }
            }
            return true;
          case 'previous':
            // Önceki sayfa işlemi
            if (_onPreviousPage != null && _currentPage > 1) {
              // Önce playback state'i güncelle - kullanıcıya hemen geri bildirim ver
              updatePlaybackState(STATE_PAUSED);

              // Sayfa değişimini gerçekleştir
              try {
                _onPreviousPage!(_currentPage - 1);

                // Sayfa değişiminden sonra playback state'i tekrar güncelle
                updatePlaybackState(_audioService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
              } catch (e) {
                print('Önceki sayfa işlemi hatası: $e');
                updatePlaybackState(STATE_PAUSED);
              }
            }
            return true;
          case 'seekTo':
            // Belirli bir konuma atlama
            final position = call.arguments as int;
            await _audioService.seekToPosition(Duration(milliseconds: position));
            return true;
          case 'getPosition':
            // Mevcut pozisyonu döndür
            return _audioService.position.inMilliseconds;
          case 'audio_error':
            // Audio error durumunda güvenli bir şekilde durumu güncelle
            print('QuranMediaController: Audio error received, updating playback state');
            updatePlaybackState(STATE_PAUSED);
            return true;
          default:
            return false;
        }
      } catch (e) {
        print('QuranMediaController method call hatası: $e');
        // Hata durumunda güvenli bir şekilde durumu güncelle
        try {
          updatePlaybackState(_audioService.isPlaying ? STATE_PLAYING : STATE_PAUSED);
        } catch (updateError) {
          print('QuranMediaController: Playback state update error: $updateError');
        }
        return false;
      }
    });
  }

  /// Kaynakları temizle
  void dispose() {
    stopService();
    _channel.setMethodCallHandler(null); // Method channel handler'ı sıfırla
  }
}
