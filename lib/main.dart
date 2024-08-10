import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/homePage.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
          appBarTheme: AppBarTheme(color: Colors.blue[400]),
          cardTheme: CardTheme(color: Colors.blue[200])),
      home: homePage(),
    );
  }
}
