import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:namaz_vakti_app/books/features/book/models/highlight_info.dart';
import 'package:namaz_vakti_app/books/features/book/utils/text_processor.dart';

/// Sayfa içeriği görünümlerini oluşturan yardımcı sınıf
class ContentViewBuilder {
  /// Metin ve resim içeren birleşik görünüm oluşturur
  static Widget buildCombinedView({
    required List<Map<String, dynamic>> parsedElements,
    required List<HighlightInfo> highlights,
    required Color backgroundColor,
    required double fontSize,
    required bool isImageFullScreen,
    required Function(TextSelection, SelectionChangedCause?, String, int) onSelectionChanged,
    required Widget Function(BuildContext, EditableTextState) contextMenuBuilder,
  }) {
    // Separate text elements and image elements
    List<Map<String, dynamic>> textElements = [];
    List<Map<String, dynamic>> imageElements = [];

    for (var element in parsedElements) {
      if (element['type'] == 'image') {
        imageElements.add(element);
      } else {
        textElements.add(element);
      }
    }

    // Combine all text elements into a single string with appropriate formatting
    List<InlineSpan> allTextSpans = [];
    String combinedText = '';
    int textOffset = 0;

    // First pass: collect all text and calculate offsets
    for (var element in textElements) {
      final fullText = TextProcessor.extractFullText(element);
      combinedText += fullText;
    }

    // Second pass: build text spans with proper formatting
    for (int i = 0; i < textElements.length; i++) {
      var element = textElements[i];
      final fullText = TextProcessor.extractFullText(element);
      final currentOffset = textOffset;

      // Add paragraph spacing if not the first element
      if (i > 0) {
        allTextSpans.add(TextSpan(text: '\n\n'));
      }

      // Add the text spans for this element
      allTextSpans.addAll(TextProcessor.buildHighlightedTextSpans(
          element['segments'], fullText, currentOffset, highlights, fontSize, backgroundColor));

      textOffset += fullText.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Display all text elements as a single selectable text widget
        if (allTextSpans.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SelectableText.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: fontSize,
                  color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
                children: allTextSpans,
              ),
              textAlign: TextAlign.justify,
              onSelectionChanged: (selection, cause) {
                onSelectionChanged(selection, cause, combinedText, 0);
              },
              contextMenuBuilder: contextMenuBuilder,
              enableInteractiveSelection: true,
            ),
          ),

        // Display all image elements
        ...imageElements.map((element) {
          // Resim elementi
          String imageUrl = element['src'] ?? '';
          if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
            imageUrl = 'https://www.hakikatkitabevi.net' + imageUrl;
          }

          return Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            height: isImageFullScreen ? 500 : 300,
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: BoxDecoration(
                color: backgroundColor,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  ),
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Resim yüklenemedi',
                      style: TextStyle(
                        color:
                            backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              enableRotation: false,
              basePosition: Alignment.center,
              tightMode: true,
              gestureDetectorBehavior: HitTestBehavior.opaque,
              scaleStateCycle: (scaleState) {
                switch (scaleState) {
                  case PhotoViewScaleState.initial:
                    return PhotoViewScaleState.covering;
                  case PhotoViewScaleState.covering:
                    return PhotoViewScaleState.originalSize;
                  case PhotoViewScaleState.originalSize:
                  default:
                    return PhotoViewScaleState.initial;
                }
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Sadece metin içeren görünüm oluşturur
  static Widget buildTextView({
    required List<Map<String, dynamic>> parsedElements,
    required List<HighlightInfo> highlights,
    required Color backgroundColor,
    required double fontSize,
    required ScrollController scrollController,
    required Function(TextSelection, SelectionChangedCause?, String, int) onSelectionChanged,
    required Widget Function(BuildContext, EditableTextState) contextMenuBuilder,
  }) {
    // Reset offset for building spans
    int textOffset = 0;

    // Reset combinedText and allTextSpans
    String combinedText = '';
    List<InlineSpan> allTextSpans = [];

    // First pass: collect all text and calculate offsets
    for (var element in parsedElements) {
      final fullText = TextProcessor.extractFullText(element);
      combinedText += fullText;
    }

    // Second pass: build text spans with proper formatting
    for (int i = 0; i < parsedElements.length; i++) {
      var element = parsedElements[i];
      final fullText = TextProcessor.extractFullText(element);
      final currentOffset = textOffset;

      // Add paragraph spacing if not the first element
      if (i > 0) {
        allTextSpans.add(TextSpan(text: '\n\n'));
      }

      // Add the text spans for this element
      allTextSpans.addAll(TextProcessor.buildHighlightedTextSpans(
          element['segments'], fullText, currentOffset, highlights, fontSize, backgroundColor));

      textOffset += fullText.length;
    }

    return Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thickness: MaterialStateProperty.all(6.0),
          thumbColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.6)),
          radius: Radius.circular(3.0),
          thumbVisibility: MaterialStateProperty.all(true),
          mainAxisMargin: 4.0,
          crossAxisMargin:
              1.0, // Increased from 1.0 to create more space between text and scrollbar
        ),
      ),
      child: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
              right: 10.0, // Increased from 8.0 to create more space between text and scrollbar
              left: 4.0,
              top: 4.0,
              bottom: 4.0),
          child: Container(
            width: double.infinity,
            child: SelectableText.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: fontSize,
                  color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
                children: allTextSpans,
              ),
              textAlign: TextAlign.justify,
              onSelectionChanged: (selection, cause) {
                onSelectionChanged(selection, cause, combinedText, 0);
              },
              contextMenuBuilder: contextMenuBuilder,
              enableInteractiveSelection: true,
            ),
          ),
        ),
      ),
    );
  }
}
