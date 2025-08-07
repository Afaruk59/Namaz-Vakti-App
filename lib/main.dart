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
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/features/book/audio/media_controller.dart';
import 'package:namaz_vakti_app/books/features/book/screens/book_page_screen.dart';
import 'package:namaz_vakti_app/books/features/book/screens/bookmarks_screen.dart';
import 'package:namaz_vakti_app/pages/about.dart';
import 'package:namaz_vakti_app/pages/kaza.dart';
import 'package:namaz_vakti_app/l10n/l10n.dart';
import 'package:namaz_vakti_app/pages/dates.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/pages/license.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/startup.dart';
import 'package:namaz_vakti_app/pages/timesPage/alarms/alarms.dart';
import 'package:namaz_vakti_app/pages/timesPage/search.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'dart:io' show Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:namaz_vakti_app/books/screens/book_screen.dart';
import 'package:namaz_vakti_app/books/features/book/services/audio_page_service.dart';
import 'package:namaz_vakti_app/sualler/Search_page.dart';
import 'package:namaz_vakti_app/sualler/favorites_page.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (Platform.isAndroid) {
    const platform = MethodChannel('com.afaruk59.namaz_vakti_app/notifications');
    try {
      debugPrint("Starting notification service");
      await platform.invokeMethod('startNotificationService');
    } on PlatformException catch (e) {
      debugPrint('Failed to start notification service: ${e.message}');
    }
  }
  WidgetsFlutterBinding.ensureInitialized();

  const platform = MethodChannel('com.afaruk59.namaz_vakti_app/media_service');
  final audioPlayerService = AudioPlayerService();
  final mediaController = MediaController(audioPlayerService: audioPlayerService);
  AudioPageService();

  tz.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation(DateTime.now().timeZoneOffset.inHours >= 3 ? 'Europe/Istanbul' : 'UTC'));

  await ChangeSettings().createSharedPrefObject();

  initializeDateFormatting().then((_) {
    runApp(
      ChangeNotifierProvider<ChangeSettings>(
        create: (context) => ChangeSettings(),
        child: MainApp(
          mediaController: mediaController,
          audioPlayerService: audioPlayerService,
          platform: platform,
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      FlutterNativeSplash.remove();
    });
  });
}

class MainApp extends StatelessWidget {
  static String version = '1.5.1';
  final MediaController mediaController;
  final AudioPlayerService audioPlayerService;
  final MethodChannel? platform;

  const MainApp({
    super.key,
    required this.mediaController,
    required this.audioPlayerService,
    this.platform,
  });

  @override
  Widget build(BuildContext context) {
    if (platform != null) {
      platform!.setMethodCallHandler((call) async {
        if (call.method == 'next') {
          debugPrint('main.dart: Androidden next çağrısı geldi.');
          BookScreen.goToNextPageFromBackground();
        }
        return null;
      });
    }
    Provider.of<ChangeSettings>(context, listen: false).loadProfileFromSharedPref(context);
    Provider.of<ChangeSettings>(context).locale == const Locale('ar')
        ? HijriCalendar.setLocal('ar')
        : HijriCalendar.setLocal('en');
    return MaterialApp(
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: Provider.of<ChangeSettings>(context).locale,
      debugShowCheckedModeBanner: false,
      initialRoute:
          Provider.of<ChangeSettings>(context, listen: false).isfirst == true ? '/startup' : '/',
      onGenerateRoute: (settings) {
        Widget? page;

        switch (settings.name) {
          case '/':
            page = ChangeNotifierProvider<TimeData>(
              create: (context) => TimeData(),
              child: const HomePage(),
            );
            break;
          case '/times':
            page = const Times();
            break;
          case '/qibla':
            page = const Qibla();
            break;
          case '/zikir':
            page = const Zikir();
            break;
          case '/dates':
            page = const Dates();
            break;
          case '/books':
            page = const BookScreen();
            break;
          case '/settings':
            page = const Settings();
            break;
          case '/kaza':
            page = const Kaza();
            break;
          case '/alarms':
            page = const Alarms();
            break;
          case '/startup':
            page = const Startup();
            break;
          case '/about':
            page = const About();
            break;
          case '/license':
            page = const License();
            break;
          case '/search':
            page = const Search();
            break;
          case '/bookmarks':
            page = const BookmarksScreen();
            break;
          case '/bookPage':
            page = const BookPageScreen(
              bookCode: '',
            );
            break;
          case '/sual':
            page = const SualPage();
            break;
          case '/favorites':
            page = const FavoritesPage();
            break;
        }

        if (page != null) {
          return PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) => page!,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.fastEaseInToSlowEaseOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        }
        return null;
      },
      theme: ThemeData(
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          showDragHandle: true,
          backgroundColor: Provider.of<ChangeSettings>(context).color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconSize: const WidgetStatePropertyAll(24),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            iconSize: const WidgetStatePropertyAll(24),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            iconSize: const WidgetStatePropertyAll(24),
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
            iconSize: const WidgetStatePropertyAll(24),
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
            iconSize: const WidgetStatePropertyAll(24),
            elevation: const WidgetStatePropertyAll(10),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              ),
            ),
          ),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        brightness: Provider.of<ChangeSettings>(context).isDark == false
            ? Brightness.light
            : Brightness.dark,
        colorSchemeSeed: Provider.of<ChangeSettings>(context).color,
        applyElevationOverlayColor: true,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Provider.of<ChangeSettings>(context).isDark == false
                ? Brightness.dark
                : Brightness.light,
          ),
          toolbarHeight: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 40 : 50,
          titleSpacing: 30,
          color: Colors.transparent,
          titleTextStyle: Platform.isAndroid
              ? GoogleFonts.ubuntu(
                  fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 22 : 25.0,
                  color: Provider.of<ChangeSettings>(context).isDark == false
                      ? Colors.black87
                      : Colors.white)
              : TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.bold,
                  fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 24 : 28.0,
                  color: Provider.of<ChangeSettings>(context).isDark == false
                      ? Colors.black87
                      : Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 10,
          color: Provider.of<ChangeSettings>(context).color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.transparent,
          height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 60 : 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    );
  }
}
