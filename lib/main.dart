import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namaz_vakti_app/api/sheets/cities_sheets_api.dart';
import 'package:namaz_vakti_app/books.dart';
import 'package:namaz_vakti_app/dates.dart';
import 'package:namaz_vakti_app/detailedTimes.dart';
import 'package:namaz_vakti_app/homePage.dart';
import 'package:namaz_vakti_app/location.dart';
import 'package:namaz_vakti_app/qibla.dart';
import 'package:namaz_vakti_app/seferi.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/times.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CitiesSheetsApi.init();
  await changeTheme().createSharedPrefObject();

  initializeDateFormatting().then((_) {
    runApp(ChangeNotifierProvider<changeTheme>(
        create: (context) => changeTheme(), child: const MainApp()));
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
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
      },
    );
  }
}

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.blue,
  appBarTheme: AppBarTheme(color: Color.fromARGB(255, 29, 80, 138)),
  cardTheme: CardTheme(color: Color.fromARGB(255, 83, 126, 175)),
  cardColor: Color.fromARGB(255, 46, 46, 46),
);

ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue,
    appBarTheme: AppBarTheme(color: Colors.blue[400]),
    cardTheme: CardTheme(color: Colors.blue[200]),
    cardColor: Color.fromARGB(255, 230, 230, 230));

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

TextStyle timeStyle = TextStyle(fontSize: 20);
