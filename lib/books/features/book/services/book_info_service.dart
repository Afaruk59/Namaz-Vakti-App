import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:flutter/material.dart';

class BookInfoService {
  // Statik Dio instance'ı oluştur ve doğru şekilde yapılandır
  static final Dio _dio = Dio()
    ..options.responseType = ResponseType.plain // HTML yanıtını düz metin olarak al
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 15)
    ..options.headers = {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Connection': 'keep-alive',
    };

  /// Verilen URL'den <meta name="description" ...> içeriğini çeker.
  static Future<String?> fetchBookDescription(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final String responseData = response.data.toString();
        final document = html_parser.parse(responseData);
        final metaList = document.getElementsByTagName('meta');
        final meta = metaList.firstWhere(
          (e) => e.attributes['name'] == 'description',
          orElse: () => html_dom.Element.tag('meta'),
        );
        if (!meta.attributes.containsKey('name') || meta.attributes['name'] != 'description') {
          return null;
        }
        return meta.attributes['content'];
      }
    } catch (e) {
      debugPrint('BookInfoService error: $e');
    }
    return null;
  }

  /// Verilen URL'den <title>...</title> içindeki parantez içindeki kitap adını çeker.
  static Future<String?> fetchBookTitle(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final String responseData = response.data.toString();
        final document = html_parser.parse(responseData);
        final titleTag = document.getElementsByTagName('title').firstOrNull;
        if (titleTag == null) return null;
        final titleText = titleTag.text;
        final match = RegExp(r'\(([^\)]+)\)').firstMatch(titleText);
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
        return titleText;
      }
    } catch (e) {
      debugPrint('BookInfoService error (title): $e');
    }
    return null;
  }
}
