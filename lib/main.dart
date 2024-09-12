import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/kaza.dart';
import 'package:namaz_vakti_app/timesPage/alarms.dart';
import 'package:namaz_vakti_app/books.dart';
import 'package:namaz_vakti_app/dates.dart';
import 'package:namaz_vakti_app/homePage.dart';
import 'package:namaz_vakti_app/timesPage/loading.dart';
import 'package:namaz_vakti_app/timesPage/location.dart';
import 'package:namaz_vakti_app/qibla.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/startup.dart';
import 'package:namaz_vakti_app/timesPage/times.dart';
import 'package:namaz_vakti_app/zikir.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  tz.initializeTimeZones();
  await ChangeSettings().createSharedPrefObject();
  ChangeSettings().loadLocalFromSharedPref();

  initializeDateFormatting().then((_) {
    runApp(
      ChangeNotifierProvider<ChangeSettings>(
        create: (context) => ChangeSettings(),
        child: const MainApp(),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static double? currentHeight;

  @override
  Widget build(BuildContext context) {
    MainApp.currentHeight = MediaQuery.of(context).size.height;
    Provider.of<ChangeSettings>(context, listen: false).loadCol();
    Provider.of<ChangeSettings>(context, listen: false).loadThemeFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadFirstFromSharedPref();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        brightness: Provider.of<ChangeSettings>(context).isDark == false
            ? Brightness.light
            : Brightness.dark,
        colorSchemeSeed: Provider.of<ChangeSettings>(context).color,
        applyElevationOverlayColor: true,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Durum çubuğu arka planı şeffaf
            statusBarIconBrightness: Provider.of<ChangeSettings>(context).isDark == false
                ? Brightness.dark
                : Brightness.light, // Durum çubuğu simgeleri koyu renk yap
          ),
          toolbarHeight: currentHeight! < 700 ? 40 : 45,
          titleSpacing: 30,
          color: Colors.transparent,
          titleTextStyle: GoogleFonts.ubuntu(
              fontSize: currentHeight! < 700 ? 22 : 25.0,
              color: Provider.of<ChangeSettings>(context).isDark == false
                  ? Colors.black87
                  : Colors.white),
        ),
        cardTheme: CardTheme(
            color: Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade400
                : Provider.of<ChangeSettings>(context).color.shade900,
            elevation: 10),
        cardColor: Provider.of<ChangeSettings>(context).isDark == false
            ? const Color.fromARGB(255, 230, 230, 230)
            : const Color.fromARGB(255, 40, 40, 40),
      ),
      initialRoute: ChangeSettings.isfirst == true ? '/startup' : '/',
      routes: {
        '/': (context) => ChangeNotifierProvider<TimeData>(
              create: (context) => TimeData(),
              child: homePage(),
            ),
        '/times': (context) => Times(),
        '/qibla': (context) => Qibla(),
        '/zikir': (context) => Zikir(),
        '/dates': (context) => Dates(),
        '/books': (context) => Books(),
        '/settings': (context) => Settings(),
        '/kaza': (context) => Kaza(),
        '/location': (context) => Location(),
        '/loading': (context) => ChangeNotifierProvider<TimeData>(
              create: (context) => TimeData(),
              child: Loading(),
            ),
        '/alarms': (context) => Alarms(),
        '/startup': (context) => Startup(),
      },
    );
  }
}

/*
ThemeData(
        useMaterial3: true,
        brightness: Provider.of<ChangeSettings>(context).isDark == false
            ? Brightness.light
            : Brightness.dark,
        colorSchemeSeed: Provider.of<ChangeSettings>(context).color,
        applyElevationOverlayColor: true,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Durum çubuğu arka planı şeffaf
            statusBarIconBrightness: Provider.of<ChangeSettings>(context).isDark == false
                ? Brightness.dark
                : Brightness.light, // Durum çubuğu simgeleri koyu renk yap
          ),
          toolbarHeight: currentHeight! < 700 ? 40 : 45,
          titleSpacing: 30,
          color: Colors.transparent,
          titleTextStyle: GoogleFonts.ubuntu(
              fontSize: currentHeight! < 700 ? 22 : 25.0,
              color: Provider.of<ChangeSettings>(context).isDark == false
                  ? Colors.black87
                  : Colors.white),
        ),
        cardTheme: CardTheme(
            color: Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade300
                : Provider.of<ChangeSettings>(context).color.shade900,
            elevation: 10),
        cardColor: Provider.of<ChangeSettings>(context).isDark == false
            ? const Color.fromARGB(255, 230, 230, 230)
            : const Color.fromARGB(255, 46, 46, 46),
      ),
*/