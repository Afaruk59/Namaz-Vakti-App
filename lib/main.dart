/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/pages/about.dart';
import 'package:namaz_vakti_app/pages/kaza.dart';
import 'package:namaz_vakti_app/l10n/l10n.dart';
import 'package:namaz_vakti_app/pages/books.dart';
import 'package:namaz_vakti_app/pages/dates.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/pages/license.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/startup.dart';
import 'package:namaz_vakti_app/pages/timesPage/alarms.dart';
import 'package:namaz_vakti_app/pages/timesPage/search.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  static String version = '1.3.0';

  @override
  Widget build(BuildContext context) {
    Provider.of<ChangeSettings>(context, listen: false).changeHeight(context);
    Provider.of<ChangeSettings>(context, listen: false).loadCol();
    Provider.of<ChangeSettings>(context, listen: false).loadThemeFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadGradFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadFirstFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadLanguage();
    Provider.of<ChangeSettings>(context, listen: false).loadOtoLoc();
    Provider.of<ChangeSettings>(context).locale == const Locale('ar')
        ? HijriCalendar.setLocal('ar')
        : HijriCalendar.setLocal('en');
    Provider.of<ChangeSettings>(context, listen: false).loadNotFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).loadAlarm();
    Provider.of<ChangeSettings>(context, listen: false).loadGaps();
    Provider.of<ChangeSettings>(context, listen: false).loadShape();
    return MaterialApp(
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: Provider.of<ChangeSettings>(context).locale,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(10),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(10),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
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
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Provider.of<ChangeSettings>(context).isDark == false
                ? Brightness.dark
                : Brightness.light,
          ),
          toolbarHeight: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 40 : 50,
          titleSpacing: 30,
          color: Colors.transparent,
          titleTextStyle: GoogleFonts.ubuntu(
              fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 22 : 25.0,
              color: Provider.of<ChangeSettings>(context).isDark == false
                  ? Colors.black87
                  : Colors.white),
        ),
        cardTheme: CardTheme(
          color: Provider.of<ChangeSettings>(context).color,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          ),
        ),
        cardColor: Provider.of<ChangeSettings>(context).isDark == false
            ? const Color.fromARGB(255, 230, 230, 230)
            : const Color.fromARGB(255, 45, 45, 45),
        navigationBarTheme: NavigationBarThemeData(
          height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 70 : 80,
          backgroundColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
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
        '/alarms': (context) => const Alarms(),
        '/startup': (context) => const Startup(),
        '/about': (context) => const About(),
        '/license': (context) => const License(),
        '/search': (context) => const Search(),
      },
    );
  }
}
