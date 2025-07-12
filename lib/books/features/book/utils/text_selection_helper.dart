import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';
import 'package:share_plus/share_plus.dart';

/// Metin seçimi işlemleri için yardımcı sınıf
class TextSelectionHelper {
  /// Metin seçimi değiştiğinde çağrılır
  static void handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause,
      String fullText, int baseOffset, Function(String, int, int) onSelectionChanged,
      [List<HighlightInfo>? highlights]) {
    try {
      // Sadece seçim tamamlandığında işlem yap
      if (selection.isValid && !selection.isCollapsed) {
        final start = selection.start.clamp(0, fullText.length);
        final end = selection.end.clamp(0, fullText.length);

        if (start < end) {
          // Seçilen metni ve global indeksleri hesapla
          final selectedText = fullText.substring(start, end);
          final selectedStartIndex = baseOffset + start;
          final selectedEndIndex = baseOffset + end;

          // Eğer highlights parametresi verilmişse, seçimin daha önce vurgulanmış bir alanla çakışıp çakışmadığını kontrol et
          if (highlights != null && highlights.isNotEmpty) {
            // Seçimin tamamen vurgulanmış bir alanın içinde olup olmadığını kontrol et
            bool isCompletelyInsideHighlight = false;

            // Seçimin herhangi bir vurgulanmış alanla çakışıp çakışmadığını kontrol et
            bool isOverlappingWithHighlight = false;

            for (var highlight in highlights) {
              // Seçim tamamen bir vurgulamanın içinde mi?
              if (selectedStartIndex >= highlight.startIndex &&
                  selectedEndIndex <= highlight.endIndex) {
                isCompletelyInsideHighlight = true;
                break;
              }

              // Seçim herhangi bir vurgulamayla çakışıyor mu?
              if ((selectedStartIndex >= highlight.startIndex &&
                      selectedStartIndex < highlight.endIndex) ||
                  (selectedEndIndex > highlight.startIndex &&
                      selectedEndIndex <= highlight.endIndex) ||
                  (selectedStartIndex <= highlight.startIndex &&
                      selectedEndIndex >= highlight.endIndex)) {
                isOverlappingWithHighlight = true;
                break;
              }
            }

            // Eğer seçim tamamen bir vurgulamanın içindeyse, bağlam menüsünün çalışması için seçimi kabul et
            if (isCompletelyInsideHighlight) {
              onSelectionChanged(selectedText, selectedStartIndex, selectedEndIndex);
              print('Seçilen metin (vurgulanmış alanda): $selectedText');
              print('Başlangıç indeksi: $selectedStartIndex, Bitiş indeksi: $selectedEndIndex');
              return;
            }

            // Eğer seçim herhangi bir vurgulamayla çakışıyorsa, seçimi engelle
            if (isOverlappingWithHighlight) {
              // Seçimi engelle - boş bir callback çağrısı yap
              onSelectionChanged("", -1, -1);
              return;
            }
          }

          // Seçim geçerliyse (vurgulanmış alanlarla çakışmıyorsa) callback'i çağır
          onSelectionChanged(selectedText, selectedStartIndex, selectedEndIndex);

          print('Seçilen metin: $selectedText');
          print('Başlangıç indeksi: $selectedStartIndex, Bitiş indeksi: $selectedEndIndex');
        }
      }
    } catch (e) {
      print('Metin seçimi işlenirken hata: $e');
    }
  }

  /// Seçilen metni paylaş
  static void shareSelectedText(String selectedText, List<HighlightInfo> highlights,
      int selectedStartIndex, int selectedEndIndex, String bookCode, int pageNumber) {
    if (selectedText.isEmpty) return;

    // Seçilen metin bir vurgulamanın parçası mı kontrol et
    String textToShare = selectedText;

    // Eğer seçilen metin bir vurgulamanın içindeyse, tüm vurgulanmış metni paylaş
    if (selectedStartIndex >= 0 && selectedEndIndex > 0) {
      for (var highlight in highlights) {
        // Seçilen metin vurgulanmış bir metnin içinde mi?
        if (selectedStartIndex >= highlight.startIndex && selectedEndIndex <= highlight.endIndex) {
          // Vurgulanmış metnin tamamını paylaş
          textToShare = highlight.text;
          print('Vurgulanmış metin paylaşılıyor: $textToShare');
          break;
        }
      }
    }

    // Sayfa linkini oluştur
    final pageUrl =
        'http://www.hakikatkitabevi.net/bookread.php?bookCode=$bookCode&bookPage=$pageNumber';

    // Paylaşılacak metni oluştur
    final shareText = '$textToShare\n\n$pageUrl';

    // Metni paylaş
    Share.share(shareText);
  }
}
