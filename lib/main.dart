import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/alarms.dart';
import 'package:namaz_vakti_app/books.dart';
import 'package:namaz_vakti_app/dates.dart';
import 'package:namaz_vakti_app/detailedTimes.dart';
import 'package:namaz_vakti_app/homePage.dart';
import 'package:namaz_vakti_app/loading.dart';
import 'package:namaz_vakti_app/location.dart';
import 'package:namaz_vakti_app/qibla.dart';
import 'package:namaz_vakti_app/seferi.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/times.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await changeTheme().createSharedPrefObject();
  await ChangeLocation().createSharedPrefObject();
  ChangeLocation().loadLocalFromSharedPref();

  initializeDateFormatting().then((_) {
    runApp(ChangeNotifierProvider<changeTheme>(
        create: (context) => changeTheme(), child: const MainApp()));
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static double? currentHeight;

  @override
  Widget build(BuildContext context) {
    MainApp.currentHeight = MediaQuery.of(context).size.height;
    Provider.of<changeTheme>(context, listen: false).loadThemeFromSharedPref();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<changeTheme>(context).themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => homePage(),
        '/times': (context) => Times(),
        '/qibla': (context) => Qibla(),
        '/seferi': (context) => Seferi(),
        '/dates': (context) => Dates(),
        '/books': (context) => Books(),
        '/settings': (context) => Settings(),
        '/detailedTimes': (context) => DetailedTimes(),
        '/location': (context) => Location(),
        '/loading': (context) => Loading(),
        '/alarms': (context) => Alarms(),
      },
    );
  }
}

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.brown,
  appBarTheme: AppBarTheme(
    color: const Color.fromARGB(255, 91, 64, 54),
    toolbarHeight: MainApp.currentHeight! < 700.0 ? 50.0 : kToolbarHeight,
    titleTextStyle: GoogleFonts.dmSerifText(fontSize: MainApp.currentHeight! < 700.0 ? 20.0 : 25.0),
  ),
  cardTheme: CardTheme(color: Color.fromARGB(255, 124, 92, 81), elevation: 10),
  cardColor: const Color.fromARGB(255, 46, 46, 46),
);

ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color.fromARGB(255, 230, 230, 230),
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.brown,
    appBarTheme: AppBarTheme(
      color: Color.fromARGB(255, 164, 135, 124),
      toolbarHeight: MainApp.currentHeight! < 700.0 ? 50.0 : kToolbarHeight,
      titleTextStyle:
          GoogleFonts.dmSerifText(fontSize: MainApp.currentHeight! < 700.0 ? 20.0 : 25.0),
    ),
    cardTheme: CardTheme(color: Color.fromARGB(255, 195, 158, 146), elevation: 10),
    cardColor: const Color.fromARGB(255, 230, 230, 230),
    dividerTheme: DividerThemeData(color: const Color.fromARGB(255, 52, 52, 52)));

class changeTheme with ChangeNotifier {
  static late SharedPreferences _sharedPrefObject;

  bool isDark = false;

  ThemeData get themeData {
    return isDark ? darkTheme : lightTheme;
  }

  void toggleTheme() {
    isDark = !isDark;
    saveThemetoSharedPref(isDark);
    notifyListeners();
  }

  Future<void> createSharedPrefObject() async {
    _sharedPrefObject = await SharedPreferences.getInstance();
  }

  void loadThemeFromSharedPref() {
    isDark = _sharedPrefObject.getBool('darkTheme') ?? false;
    print('loaded: $isDark');
  }

  void saveThemetoSharedPref(bool value) {
    _sharedPrefObject.setBool('darkTheme', value);
    print('saved: $isDark');
  }
}
