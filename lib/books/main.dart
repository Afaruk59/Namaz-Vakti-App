import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'features/book/audio/audio_player_service.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/services/audio_page_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/media_controller.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Medya servisi için method channel'ı kur
    const platform = MethodChannel('com.example.kitaplar_1/media_service');

    // AudioPlayerService'i başlat (singleton instance oluştur)
    final audioPlayerService = AudioPlayerService();
    // MediaController'ı başlat
    final mediaController = MediaController(audioPlayerService: audioPlayerService);
    // Initialize AudioPageService
    AudioPageService();

    // --- NEXT HANDLER EKLEME ---
    // Kitap ve Kuran controller'larını global olarak erişilebilir yap
    // (Varsa, yoksa ilgili ekranlarda uygun şekilde tetiklenmeli)
    // Burada HomeScreen'e bir callback ileteceğiz
    runApp(MyApp(
      mediaController: mediaController,
      audioPlayerService: audioPlayerService,
      platform: platform,
    ));
  } catch (e) {
    print('Uygulama başlatma hatası: $e');
    // Kritik hata durumunda basit bir hata ekranı göster
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Uygulama başlatılamadı. Lütfen tekrar deneyin.'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final MediaController mediaController;
  final AudioPlayerService audioPlayerService;
  final MethodChannel? platform;

  const MyApp({
    super.key,
    required this.mediaController,
    required this.audioPlayerService,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    // MethodChannel handler'ı burada kur
    if (platform != null) {
      platform!.setMethodCallHandler((call) async {
        if (call.method == 'next') {
          // HomeScreen'e bir şekilde haber verilmeli
          // En iyi yol: bir global event/callback veya state management ile
          // Şimdilik: HomeScreen'e bir static method ekleyip çağırabiliriz
          print('main.dart: Androidden next çağrısı geldi.');
          HomeScreen.goToNextPageFromBackground();
        }
        return null;
      });
    }
    return MaterialApp(
      title: 'Kitap Oku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
