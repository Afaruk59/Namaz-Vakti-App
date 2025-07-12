import 'package:dio/dio.dart';
import 'package:namaz_vakti_app/books/features/book/services/html_parser.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async'; // Add this for TimeoutException
import 'package:http/http.dart' as http;

// Özel transformer sınıfı - otomatik JSON dönüşümünü devre dışı bırakır
class _NoTransformer extends Transformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data is Map) {
      return options.data.keys
          .map((key) => '$key=${Uri.encodeComponent(options.data[key].toString())}')
          .join('&');
    }
    return options.data?.toString() ?? '';
  }

  @override
  Future transformResponse(RequestOptions options, ResponseBody response) async {
    return await utf8.decoder.bind(response.stream).join();
  }
}

class ApiService {
  final Dio _dio;
  final String baseUrl = 'https://www.hakikatkitabevi.net';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() : _dio = Dio() {
    _dio.options.responseType = ResponseType.plain; // Yanıtı düz metin olarak al
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 10);

    // Transformasyonu devre dışı bırak, manuel olarak işleyeceğiz
    _dio.transformer = _NoTransformer();

    _dio.options.headers = {
      'Connection': 'keep-alive',
      'Accept': 'text/plain',
      'User-Agent': 'Mozilla/5.0',
    };

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        print('API Error: ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          print('Connection timeout - retrying request');
          // Retry the request once
          return handler.resolve(e.response ?? Response(requestOptions: e.requestOptions));
        }
        return handler.next(e);
      },
    ));
  }

  Future<BookPageModel> getBookPage(String bookCode, int activePage) async {
    try {
      final response = await _dio.post(
        '$baseUrl/public/json.bookpage.php',
        data: {
          'bookCode': bookCode,
          'activePage': activePage,
          'bookIndex': '',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final String responseStr = response.data.toString();

          // HTML yanıtı kontrolü
          if (responseStr.trim().startsWith('<!DOCTYPE html>') ||
              responseStr.trim().startsWith('<html') ||
              responseStr.contains('<body')) {
            print("Sunucu HTML yanıtı döndürdü, boş sayfa döndürülüyor");
            // HTML yanıtı durumunda boş bir sayfa modeli döndür
            return BookPageModel(
              audio: 0,
              pageText: '',
              mp3: [],
            );
          }

          final Map<String, dynamic> jsonData = jsonDecode(responseStr);
          return BookPageModel.fromJson(jsonData);
        } catch (e) {
          print("JSON parsing error: $e");
          // JSON ayrıştırma hatası durumunda boş bir sayfa modeli döndür
          return BookPageModel(
            audio: 0,
            pageText: 'Sayfa yüklenirken bir hata oluştu: $e',
            mp3: [],
          );
        }
      } else {
        print("API Error: ${response.statusCode}");
        return BookPageModel(
          audio: 0,
          pageText: 'Sayfa yüklenirken bir hata oluştu: HTTP ${response.statusCode}',
          mp3: [],
        );
      }
    } catch (error) {
      print("Dio Error: $error");
      return BookPageModel(
        audio: 0,
        pageText: 'Sayfa yüklenirken bir hata oluştu: $error',
        mp3: [],
      );
    }
  }

  Future<List<IndexItem>> getBookIndex(String bookCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookread.php?bookCode=$bookCode'),
        headers: {
          'Accept': 'text/html; charset=utf-8',
          'Connection': 'keep-alive',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to load index for book $bookCode');
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return HtmlParser.parseIndexHtml(decodedBody);
      } else {
        throw Exception('Failed to load index: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading index for book $bookCode: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchBook(String bookCode, String searchText) async {
    try {
      print("Arama isteği gönderiliyor: $bookCode, $searchText");
      final response = await _dio.post(
        '$baseUrl/public/json.booksearch.php',
        data: {
          'bookCode': bookCode,
          'searchText': searchText,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      print("Arama yanıtı alındı: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          final String responseStr = response.data.toString();
          print(
              "Yanıt içeriği (ilk 100 karakter): ${responseStr.substring(0, min(100, responseStr.length))}...");

          // HTML yanıtı kontrolü
          if (responseStr.trim().startsWith('<!DOCTYPE html>') ||
              responseStr.trim().startsWith('<html') ||
              responseStr.contains('<body')) {
            print("Sunucu HTML yanıtı döndürdü, boş arama sonucu döndürülüyor");
            return [];
          }

          final Map<String, dynamic> jsonData = jsonDecode(responseStr);
          if (jsonData['rows'] != null && jsonData['rows'] is List) {
            final results = List<Map<String, dynamic>>.from(jsonData['rows']);
            print("Arama sonuçları: ${results.length} sonuç bulundu");
            return results;
          }
          print("Arama sonuçları boş veya geçersiz format");
          return [];
        } catch (e) {
          print("JSON ayrıştırma hatası: $e");
          return [];
        }
      } else {
        print("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (error) {
      print("Dio Hatası: $error");
      return [];
    }
  }

  Future<int> getBookMaxPage(String bookCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookread.php?bookCode=$bookCode'),
        headers: {
          'Accept': 'text/html; charset=utf-8',
          'Connection': 'keep-alive',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to load max page for book $bookCode');
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final RegExp maxPageRegex = RegExp('var maxPage = parseInt\\(\'(\\d+)\'\\);');
        final match = maxPageRegex.firstMatch(decodedBody);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
        throw Exception('MaxPage not found in HTML');
      } else {
        throw Exception('Failed to load max page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading max page for book $bookCode: $e');
      rethrow;
    }
  }
}
