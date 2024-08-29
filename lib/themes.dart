import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakti_app/main.dart';

class Themes {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.brown,
    applyElevationOverlayColor: true,
    appBarTheme: AppBarTheme(
      elevation: 10,
      color: const Color.fromARGB(255, 91, 64, 54),
      titleTextStyle:
          GoogleFonts.dmSerifText(fontSize: MainApp.currentHeight! < 700.0 ? 20.0 : 25.0),
    ),
    cardTheme: CardTheme(color: Color.fromARGB(255, 124, 92, 81), elevation: 10),
    cardColor: const Color.fromARGB(255, 46, 46, 46),
  );

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color.fromARGB(255, 230, 230, 230),
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.brown,
    applyElevationOverlayColor: true,
    appBarTheme: AppBarTheme(
      elevation: 10,
      color: Color.fromARGB(255, 164, 135, 124),
      titleTextStyle:
          GoogleFonts.dmSerifText(fontSize: MainApp.currentHeight! < 700.0 ? 20.0 : 25.0),
    ),
    cardTheme: CardTheme(color: Color.fromARGB(255, 195, 158, 146), elevation: 10),
    cardColor: const Color.fromARGB(255, 230, 230, 230),
    dividerTheme: DividerThemeData(
      color: const Color.fromARGB(255, 52, 52, 52),
    ),
  );
}
