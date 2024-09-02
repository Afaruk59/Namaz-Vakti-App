import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/kaza.dart';
import 'package:namaz_vakti_app/timesPage/alarms.dart';
import 'package:namaz_vakti_app/books.dart';
import 'package:namaz_vakti_app/dates.dart';
import 'package:namaz_vakti_app/homePage.dart';
import 'package:namaz_vakti_app/timesPage/loading.dart';
import 'package:namaz_vakti_app/timesPage/location.dart';
import 'package:namaz_vakti_app/notification.dart';
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
  await NotificationService.init();
  tz.initializeTimeZones();
  await ChangeSettings().createSharedPrefObject();
  ChangeSettings().loadLocalFromSharedPref();
  ChangeSettings.loadFirstFromSharedPref();
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
    Provider.of<ChangeSettings>(context, listen: false).loadThemeFromSharedPref();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ChangeSettings>(context).themeData,
      initialRoute: ChangeSettings.isfirst == true ? '/startup' : '/times',
      routes: {
        '/': (context) => homePage(),
        '/times': (context) => Times(),
        '/qibla': (context) => Qibla(),
        '/zikir': (context) => Zikir(),
        '/dates': (context) => Dates(),
        '/books': (context) => Books(),
        '/settings': (context) => Settings(),
        '/kaza': (context) => Kaza(),
        '/location': (context) => Location(),
        '/loading': (context) => Loading(),
        '/alarms': (context) => Alarms(),
        '/startup': (context) => Startup(),
      },
    );
  }
}
