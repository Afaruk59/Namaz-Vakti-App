import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';

/// Metin işleme ve vurgulama için yardımcı sınıf
class TextProcessor {
  /// Metin elementinden tüm metni çıkarır
  static String extractFullText(Map<String, dynamic> element) {
    try {
      final segments = element['segments'] as List;
      final buffer = StringBuffer();

      for (var segment in segments) {
        if (segment is Map && segment.containsKey('text')) {
          buffer.write(segment['text']);
          buffer.write(' ');
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Metin çıkarma hatası: $e');
      return '';
    }
  }

  /// Vurgulanmış metinleri içeren TextSpan oluşturur
  static List<TextSpan> buildHighlightedTextSpans(List<dynamic> segments, String fullText,
      int baseOffset, List<HighlightInfo> highlights, double fontSize, Color backgroundColor) {
    List<TextSpan> textSpans = [];
    int currentOffset = baseOffset;

    for (var segment in segments) {
      if (segment is Map && segment.containsKey('text')) {
        String segmentText = segment['text'] + ' ';
        bool isBold = segment['bold'] ?? false;
        int segmentStartOffset = currentOffset;
        int segmentEndOffset = currentOffset + segmentText.length;

        // Bu segment içinde vurgulanmış metin var mı kontrol et
        List<HighlightInfo> segmentHighlights = [];

        // Bu segment içindeki vurgulamaları bul
        for (var highlight in highlights) {
          // Vurgulamanın bu segment içinde olup olmadığını kontrol et
          bool isInSegment = (highlight.startIndex >= segmentStartOffset &&
                  highlight.startIndex < segmentEndOffset) ||
              (highlight.endIndex > segmentStartOffset && highlight.endIndex <= segmentEndOffset) ||
              (highlight.startIndex <= segmentStartOffset &&
                  highlight.endIndex >= segmentEndOffset);

          if (isInSegment) {
            segmentHighlights.add(highlight);
          }
        }

        // Eğer bu segmentte vurgulama yoksa, tüm segmenti normal olarak ekle
        if (segmentHighlights.isEmpty) {
          textSpans.add(TextSpan(
            text: segmentText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              height: 1.5,
              letterSpacing: 0.5,
            ),
          ));
        } else {
          // Vurgulamaları başlangıç pozisyonuna göre sırala
          segmentHighlights.sort((a, b) => a.startIndex.compareTo(b.startIndex));

          int currentPos = 0;

          for (var highlight in segmentHighlights) {
            // Vurgulamanın segment içindeki göreceli pozisyonlarını hesapla
            int highlightStartInSegment =
                (highlight.startIndex - segmentStartOffset).clamp(0, segmentText.length);
            int highlightEndInSegment =
                (highlight.endIndex - segmentStartOffset).clamp(0, segmentText.length);

            // Vurgulamadan önceki normal metni ekle
            if (highlightStartInSegment > currentPos) {
              textSpans.add(TextSpan(
                text: segmentText.substring(currentPos, highlightStartInSegment),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ));
            }

            // Vurgulanmış metni ekle
            if (highlightStartInSegment < highlightEndInSegment) {
              textSpans.add(TextSpan(
                text: segmentText.substring(highlightStartInSegment, highlightEndInSegment),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  height: 1.5,
                  letterSpacing: 0.5,
                  backgroundColor: highlight.color.withOpacity(0.3),
                ),
              ));
            }

            currentPos = highlightEndInSegment;
          }

          // Vurgulamalardan sonraki normal metni ekle
          if (currentPos < segmentText.length) {
            textSpans.add(TextSpan(
              text: segmentText.substring(currentPos),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ));
          }
        }

        // Offset'i güncelle
        currentOffset += segmentText.length;
      }
    }

    return textSpans;
  }
}
