import 'package:flutter/material.dart';

/// Tema yönetimi için yardımcı sınıf
class ThemeManager {
  final Function(Color) onBackgroundColorChanged;
  final Function(bool) onAutoBackgroundChanged;

  bool _isAutoBackground = false;
  Color _backgroundColor = Colors.white;

  ThemeManager({
    required this.onBackgroundColorChanged,
    required this.onAutoBackgroundChanged,
  });

  /// Tema ayarlarını yükler
  void loadThemeSettings(BuildContext? context) {
    _isAutoBackground = false;
    _backgroundColor = Colors.white;
    onBackgroundColorChanged(_backgroundColor);
    onAutoBackgroundChanged(_isAutoBackground);
  }

  /// Otomatik arka plan rengini günceller
  void updateAutoBackground(BuildContext context) {
    if (_isAutoBackground) {
      final newBackgroundColor =
          Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

      // Sadece renk değiştiyse güncelle
      if (_backgroundColor != newBackgroundColor) {
        _backgroundColor = newBackgroundColor;
        onBackgroundColorChanged(newBackgroundColor);
      }
    }
  }

  /// Arka plan rengini ayarlar
  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    onBackgroundColorChanged(color);
  }

  /// Otomatik arka plan modunu ayarlar
  void setAutoBackground(bool value) {
    _isAutoBackground = value;
    onAutoBackgroundChanged(value);
  }

  /// Arka plan rengi
  Color get backgroundColor => _backgroundColor;

  /// Otomatik arka plan modu
  bool get isAutoBackground => _isAutoBackground;
}
