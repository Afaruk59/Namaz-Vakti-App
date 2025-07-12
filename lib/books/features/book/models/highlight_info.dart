import 'package:flutter/material.dart';

/// Vurgulama bilgilerini saklamak için yardımcı sınıf
class HighlightInfo {
  final String text;
  final Color color;
  final int startIndex;
  final int endIndex;
  final int? surahId;
  final String? surahName;
  final String? ayahNumber;

  HighlightInfo({
    required this.text,
    required this.color,
    required this.startIndex,
    required this.endIndex,
    this.surahId,
    this.surahName,
    this.ayahNumber,
  });
}
