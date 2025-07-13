import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class BookInfoService {
  /// Verilen URL'den <meta name="description" ...> içeriğini çeker.
  static Future<String?> fetchBookDescription(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data);
        final metaList = document.getElementsByTagName('meta');
        final meta = metaList.firstWhere(
          (e) => e.attributes['name'] == 'description',
          orElse: () => Element.tag('meta'),
        );
        if (!meta.attributes.containsKey('name') || meta.attributes['name'] != 'description')
          return null;
        return meta.attributes['content'];
      }
    } catch (e) {
      print('BookInfoService error: $e');
    }
    return null;
  }

  /// Verilen URL'den <title>...</title> içindeki parantez içindeki kitap adını çeker.
  static Future<String?> fetchBookTitle(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data);
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
      print('BookInfoService error (title): $e');
    }
    return null;
  }
}
