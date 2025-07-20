import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';

/// Metin seçimi için context menü oluşturan widget
class TextContextMenu extends StatelessWidget {
  final EditableTextState editableTextState;
  final String selectedText;
  final int selectedStartIndex;
  final int selectedEndIndex;
  final List<HighlightInfo> highlights;
  final Function(HighlightInfo) onRemoveHighlight;
  final Function(String, int, int) onShowColorPicker;
  final Function(String)? onSearch;
  final Function(String) onShareText;

  const TextContextMenu({
    super.key,
    required this.editableTextState,
    required this.selectedText,
    required this.selectedStartIndex,
    required this.selectedEndIndex,
    required this.highlights,
    required this.onRemoveHighlight,
    required this.onShowColorPicker,
    this.onSearch,
    required this.onShareText,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection selection = value.selection;
    final selectedText = selection.textInside(value.text);

    // Seçilen metnin zaten vurgulanmış olup olmadığını kontrol et
    bool isAlreadyHighlighted = false;
    HighlightInfo? existingHighlight;

    if (selectedText.isNotEmpty && selectedStartIndex >= 0 && selectedEndIndex > 0) {
      // Seçilen metin aralığının herhangi bir vurgulamayla örtüşüp örtüşmediğini kontrol et
      for (var highlight in highlights) {
        // Tam olarak aynı metin ve aynı konum mu?
        if (selectedStartIndex >= highlight.startIndex && selectedEndIndex <= highlight.endIndex) {
          isAlreadyHighlighted = true;
          existingHighlight = highlight;
          break;
        }
      }
    }

    return AdaptiveTextSelectionToolbar(
      anchors: editableTextState.contextMenuAnchors,
      children: [
        // Kopyala butonu
        if (selectedText.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Kopyala'),
            onPressed: () {
              // Eğer seçilen metin bir vurgulamanın içindeyse, tüm vurgulanmış metni kopyala
              String textToCopy = selectedText;

              if (isAlreadyHighlighted && existingHighlight != null) {
                // Vurgulanmış metnin tamamını kopyala
                textToCopy = existingHighlight.text;
              }

              Clipboard.setData(ClipboardData(text: textToCopy));
              editableTextState.hideToolbar();
            },
          ),

        // Vurgula veya Vurgulamayı Kaldır butonu
        if (selectedText.isNotEmpty)
          TextButton.icon(
            icon: isAlreadyHighlighted
                ? const Icon(Icons.highlight_off, size: 18)
                : const Icon(Icons.highlight, size: 18),
            label: Text(isAlreadyHighlighted ? 'Vurgulamayı Kaldır' : 'Vurgula'),
            onPressed: () {
              editableTextState.hideToolbar();
              if (isAlreadyHighlighted && existingHighlight != null) {
                // Vurgulamayı kaldır
                onRemoveHighlight(existingHighlight);
              } else {
                // Yeni vurgulama ekle
                onShowColorPicker(selectedText, selectedStartIndex, selectedEndIndex);
              }
            },
          ),

        // Ara butonu
        if (selectedText.isNotEmpty && onSearch != null)
          TextButton.icon(
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Ara'),
            onPressed: () {
              // Seçilen metni arama için callback'e ilet
              onSearch!(selectedText);
              editableTextState.hideToolbar();
            },
          ),

        // Paylaş butonu
        if (selectedText.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Paylaş'),
            onPressed: () {
              onShareText(selectedText);
              editableTextState.hideToolbar();
            },
          ),
      ],
    );
  }
}
