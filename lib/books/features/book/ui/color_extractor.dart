import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:async'; // Add this import for Completer
import 'dart:typed_data'; // Add this import for ByteData

class ColorExtractor {
  // Varsayılan koyu mavi renk
  static const Color defaultBlue = Color(0xFF1976D2); // Colors.blue[700]

  /// Belirli bir kitap kodu için renk döndürür
  /// Kapak resminden renk çıkarır
  static Future<Color> getBookColor(String bookCode, ImageProvider? coverImage,
      {Color defaultColor = defaultBlue}) async {
    // Kapak resmi yoksa varsayılan rengi döndür
    if (coverImage == null) {
      return defaultColor;
    }

    // Kapak resminden renk çıkar
    return await extractDominantColor(coverImage, defaultColor: defaultColor);
  }

  /// Extracts the dominant color from an image
  /// Returns a default color if extraction fails
  static Future<Color> extractDominantColor(ImageProvider imageProvider,
      {Color defaultColor = defaultBlue}) async {
    try {
      // Load the image
      final ui.Image image = await _loadImage(imageProvider);

      // Sample the image to get color data
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return defaultColor;

      // Process the image data to find dominant color
      final List<int> pixels = byteData.buffer.asUint8List();
      final Map<int, int> colorFrequency = {};

      // Renk grupları için ağırlıklar (mavi tonlarına daha fazla ağırlık verelim)
      final Map<int, double> colorWeights = {};

      // Sample pixels (every 10th pixel to improve performance)
      for (int i = 0; i < pixels.length; i += 40) {
        if (i + 3 < pixels.length) {
          final int r = pixels[i];
          final int g = pixels[i + 1];
          final int b = pixels[i + 2];
          final int a = pixels[i + 3];

          // Skip transparent pixels
          if (a < 128) continue;

          // Çok açık veya çok koyu renkleri atla (genellikle arka plan veya metin)
          final double brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
          if (brightness < 0.1 || brightness > 0.9) continue;

          // Create a color key (reduce precision to group similar colors)
          final int colorKey = (r ~/ 10 << 16) | (g ~/ 10 << 8) | (b ~/ 10);
          colorFrequency[colorKey] = (colorFrequency[colorKey] ?? 0) + 1;

          // Mavi tonlarına daha fazla ağırlık ver
          double weight = 1.0;
          if (b > r && b > g) {
            weight = 1.5; // Mavi baskınsa ağırlığı artır
          }
          colorWeights[colorKey] = weight;
        }
      }

      // Find the most frequent color with weights
      double maxWeightedFrequency = 0;
      int dominantColorKey = 0;

      colorFrequency.forEach((key, frequency) {
        final double weight = colorWeights[key] ?? 1.0;
        final double weightedFrequency = frequency * weight;

        if (weightedFrequency > maxWeightedFrequency) {
          maxWeightedFrequency = weightedFrequency;
          dominantColorKey = key;
        }
      });

      // Convert back to RGB
      final int r = (dominantColorKey >> 16) & 0xFF;
      final int g = (dominantColorKey >> 8) & 0xFF;
      final int b = dominantColorKey & 0xFF;

      // Create the color with full precision
      Color extractedColor = Color.fromRGBO(r * 10, g * 10, b * 10, 1.0);

      // Rengi biraz koyulaştır (daha iyi görünüm için)
      HSLColor hslColor = HSLColor.fromColor(extractedColor);
      return hslColor.withLightness((hslColor.lightness - 0.1).clamp(0.2, 0.6)).toColor();
    } catch (e) {
      print('Error extracting dominant color: $e');
      return defaultColor;
    }
  }

  /// Helper method to load an image from an ImageProvider
  static Future<ui.Image> _loadImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final ImageStream stream = provider.resolve(ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      stream.removeListener(listener);
      completer.complete(info.image);
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      stream.removeListener(listener);
      completer.completeError(exception, stackTrace);
    });

    stream.addListener(listener);
    return completer.future;
  }
}
