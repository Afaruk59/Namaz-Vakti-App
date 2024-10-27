import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/pages/kaza.dart';
import 'package:namaz_vakti_app/l10n/l10n.dart';
import 'package:namaz_vakti_app/pages/books.dart';
import 'package:namaz_vakti_app/pages/dates.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/startup.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await initService();
  //await requestNotificationPermission();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
    Provider.of<ChangeSettings>(context, listen: false).loadGradFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadFirstFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadLanguage();
    Provider.of<ChangeSettings>(context).locale == const Locale('ar')
        ? HijriCalendar.setLocal('ar')
        : HijriCalendar.setLocal('en');
    //Provider.of<ChangeSettings>(context, listen: false).loadNotFromSharedPref();
    //Provider.of<ChangeSettings>(context, listen: false).loadAlarm();
    //Provider.of<ChangeSettings>(context, listen: false).loadGaps();
    return MaterialApp(
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: Provider.of<ChangeSettings>(context).locale,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Provider.of<ChangeSettings>(context).gradient == true
            ? Colors.transparent
            : Theme.of(context).navigationBarTheme.backgroundColor,
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
      initialRoute:
          Provider.of<ChangeSettings>(context, listen: false).isfirst == true ? '/startup' : '/',
      routes: {
        '/': (context) => ChangeNotifierProvider<TimeData>(
              create: (context) => TimeData(),
              child: const HomePage(),
            ),
        '/times': (context) => const Times(),
        '/qibla': (context) => const Qibla(),
        '/zikir': (context) => const Zikir(),
        '/dates': (context) => const Dates(),
        '/books': (context) => const Books(),
        '/settings': (context) => const Settings(),
        '/kaza': (context) => const Kaza(),
        '/location': (context) => const Location(),
        // '/alarms': (context) => const Alarms(),
        '/startup': (context) => const Startup(),
      },
    );
  }
}
