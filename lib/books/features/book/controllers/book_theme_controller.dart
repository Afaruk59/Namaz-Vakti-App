import 'package:flutter/material.dart';
// import 'package:kitaplar_1/features/book/services/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookThemeController {
  double fontSize = 16.0;
  Color _backgroundColor = Colors.white;

  // Callback when font size changes
  final Function(double) onFontSizeChanged;
  final Function(Color)? onBackgroundColorChanged;

  BookThemeController({
    required this.onFontSizeChanged,
    this.onBackgroundColorChanged,
  }) {
    _loadFontSize();
    _loadBackgroundColor();
  }

  // Load font size from preferences
  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontSize = prefs.getDouble('global_font_size');
      if (savedFontSize != null) {
        fontSize = savedFontSize;
        onFontSizeChanged(fontSize);
      }
      debugPrint('Font size loaded: $fontSize');
    } catch (e) {
      debugPrint('Error loading font size: $e');
    }
  }

  // Load background color from preferences
  Future<void> _loadBackgroundColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt('book_background_color');
      if (colorValue != null) {
        _backgroundColor = Color(colorValue);
        onBackgroundColorChanged?.call(_backgroundColor);
      }
    } catch (e) {
      debugPrint('Error loading background color: $e');
    }
  }

  // Save font size to preferences
  Future<void> saveFontSize(double newFontSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('global_font_size', newFontSize);
      fontSize = newFontSize;
      onFontSizeChanged(fontSize);
      debugPrint('Font size saved: $fontSize');
    } catch (e) {
      debugPrint('Error saving font size: $e');
    }
  }

  // Update background color
  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    onBackgroundColorChanged?.call(_backgroundColor);
    try {
      final prefs = await SharedPreferences.getInstance();
      // ignore: deprecated_member_use
      await prefs.setInt('book_background_color', color.value);
    } catch (e) {
      debugPrint('Error saving background color: $e');
    }
  }

  // Get current background color
  Color get backgroundColor => _backgroundColor;

  // Toggle auto background mode
  void setAutoBackground(bool isAuto) {
    // themeManager.setAutoBackground(isAuto);
  }

  // Update auto background based on context
  void updateAutoBackground(BuildContext context) {
    // if (themeManager.isAutoBackground) {
    //   themeManager.updateAutoBackground(context);
    // }
  }

  // Check if auto background is enabled
  bool get isAutoBackground => false;
}
