/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:http/io_client.dart';

class TimeData extends ChangeSettings {
  DateTime? yatsi2;
  DateTime? imsak2;
  DateTime? imsak;
  DateTime? sabah;
  DateTime? gunes;
  DateTime? ogle;
  DateTime? ikindi;
  DateTime? aksam;
  DateTime? yatsi;
  DateTime? israk;
  DateTime? kerahat;
  DateTime? asrisani;
  DateTime? isfirar;
  DateTime? istibak;
  DateTime? isaisani;
  DateTime? kible;

  List<Map<String, String>> prayerTimes = [];
  Map<String, String>? selectedDayTimes;
  DateTime? selectedDate;
  bool isLoading = true;

  bool isTimeLoading = true;
  bool _disposed = false;

  String clock = '';
  Duration difference = const Duration(minutes: 1);
  int pray = 0;
  DateTime soontime = DateTime.now();
  DateTime preTime = DateTime.now();
  Duration mainDifference = const Duration(minutes: 1);
  bool isClockEnabled = true;

  Duration detailedDifference = const Duration(minutes: 1);
  int detailedPray = 0;
  DateTime detailedSoontime = DateTime.now();
  DateTime detailedPreTime = DateTime.now();
  Duration detailedMainDifference = const Duration(minutes: 1);
  bool noPray = false;
  String miladi = DateFormat('dd MMMM yyyy').format(DateTime.now());

  String day = '';
  String word = '';
  String calendarTitle = '';
  String calendar = '';

  String hijriDay = '';
  String hijriMonth = '';
  String hijriYear = '';

  static Future<http.Response> fetchWithFallback(String url) async {
    // URL'yi düzenle - protokol yoksa ekle, varsa al
    String baseUrl = url;
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'https://$baseUrl';
    }

    // Protokolü çıkar
    String urlWithoutProtocol = baseUrl.replaceFirst('https://', '').replaceFirst('http://', '');

    // Önce normal HTTPS ile dene
    final httpsUrl = 'https://$urlWithoutProtocol';

    try {
      debugPrint('🔒 Trying HTTPS: $httpsUrl');
      final response = await http.get(Uri.parse(httpsUrl)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        debugPrint('✅ HTTPS başarılı');
        return response;
      }

      debugPrint('⚠️ HTTPS yanıt kodu: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ HTTPS hatası: ${e.runtimeType} - $e');

      // Sertifika hatası ise, sertifika doğrulamasını bypass ederek dene
      if (e is HandshakeException) {
        debugPrint('🔓 Sertifika doğrulaması olmadan HTTPS deneniyor...');
        try {
          final httpClient = HttpClient()
            ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          final ioClient = IOClient(httpClient);

          final response = await ioClient.get(Uri.parse(httpsUrl)).timeout(
                const Duration(seconds: 10),
              );

          ioClient.close();

          if (response.statusCode == 200) {
            debugPrint('✅ HTTPS (sertifika bypass) başarılı');
            return response;
          }

          debugPrint('⚠️ HTTPS (bypass) yanıt kodu: ${response.statusCode}');
        } catch (bypassError) {
          debugPrint('❌ HTTPS (bypass) hatası: ${bypassError.runtimeType} - $bypassError');
        }
      }

      debugPrint('🔓 HTTP ile deneniyor...');
    }

    // HTTP ile dene
    try {
      final httpUrl = 'http://$urlWithoutProtocol';
      debugPrint('🔓 Trying HTTP: $httpUrl');

      final response = await http.get(Uri.parse(httpUrl)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        debugPrint('✅ HTTP başarılı');
        return response;
      }

      debugPrint('⚠️ HTTP yanıt kodu: ${response.statusCode}');
      throw Exception('HTTP başarısız, status: ${response.statusCode}');
    } catch (httpError) {
      debugPrint('❌ HTTP hatası: ${httpError.runtimeType} - $httpError');
      throw Exception('Tüm bağlantı denemeleri başarısız: $httpError');
    }
  }

  void selectDate(DateTime time) {
    final DateTime picked = time;

    selectedDate = picked;
    final formattedDate = DateFormat('d/M').format(picked);
    selectedDayTimes = prayerTimes.firstWhere(
      (pt) => '${pt['day']}/${pt['month']}' == formattedDate,
      orElse: () => {},
    );
    notifyListeners();
  }

  Future<void> loadPrayerTimes(DateTime time, BuildContext context) async {
    final currentLangCode = Provider.of<ChangeSettings>(context, listen: false).langCode ?? 'tr';

    String url =
        'https://www.namazvakti.com/XML.php?cityID=${Provider.of<ChangeSettings>(context, listen: false).cityID}';
    final response = await fetchWithFallback(url);
    if (response.statusCode == 200) {
      final data = response.body;
      final document = xml.XmlDocument.parse(data);

      final cityinfo = document.findAllElements('cityinfo').first;
      final prayertimes = cityinfo.findAllElements('prayertimes');

      prayerTimes = prayertimes.map((pt) {
        // ignore: deprecated_member_use
        final times = pt.text.split(RegExp(r'\s+'));
        return {
          'day': pt.getAttribute('day') ?? '',
          'month': pt.getAttribute('month') ?? '',
          'imsak': times.isNotEmpty ? times[0] : '',
          'sabah': times.length > 1 ? times[1] : '',
          'güneş': times.length > 2 ? times[2] : '',
          'işrak': times.length > 3 ? times[3] : '',
          'kerahat': times.length > 4 ? times[4] : '',
          'öğle': times.length > 5 ? times[5] : '',
          'ikindi': times.length > 6 ? times[6] : '',
          'asrisani': times.length > 7 ? times[7] : '',
          'isfirar': times.length > 8 ? times[8] : '',
          'akşam': times.length > 9 ? times[9] : '',
          'iştibak': times.length > 10 ? times[10] : '',
          'yatsı': times.length > 11 ? times[11] : '',
          'işaisani': times.length > 12 ? times[12] : '',
          'kıble': times.length > 13 ? times[13] : '',
        };
      }).toList();
      isLoading = false;

      selectDate(time);
      try {
        imsak = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
      } on Exception catch (_) {
        imsak = null;
      }
      try {
        sabah = DateFormat('HH:mm').parse((selectedDayTimes?['sabah']).toString());
      } on Exception catch (_) {
        sabah = null;
      }
      try {
        gunes = DateFormat('HH:mm').parse((selectedDayTimes?['güneş']).toString());
      } on Exception catch (_) {
        gunes = null;
      }
      try {
        ogle = DateFormat('HH:mm').parse((selectedDayTimes?['öğle']).toString());
      } on Exception catch (_) {
        ogle = null;
      }
      try {
        ikindi = DateFormat('HH:mm').parse((selectedDayTimes?['ikindi']).toString());
      } on Exception catch (_) {
        ikindi = null;
      }
      try {
        aksam = DateFormat('HH:mm').parse((selectedDayTimes?['akşam']).toString());
      } on Exception catch (_) {
        aksam = null;
      }
      try {
        yatsi = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());
      } on Exception catch (_) {
        yatsi = null;
      }

      try {
        israk = DateFormat('HH:mm').parse((selectedDayTimes?['işrak']).toString());
      } on Exception catch (_) {
        israk = null;
      }
      try {
        kerahat = DateFormat('HH:mm').parse((selectedDayTimes?['kerahat']).toString());
      } on Exception catch (_) {
        kerahat = null;
      }
      try {
        asrisani = DateFormat('HH:mm').parse((selectedDayTimes?['asrisani']).toString());
      } on Exception catch (_) {
        asrisani = null;
      }
      try {
        isfirar = DateFormat('HH:mm').parse((selectedDayTimes?['isfirar']).toString());
      } on Exception catch (_) {
        isfirar = null;
      }
      try {
        istibak = DateFormat('HH:mm').parse((selectedDayTimes?['iştibak']).toString());
      } on Exception catch (_) {
        istibak = null;
      }
      try {
        isaisani = DateFormat('HH:mm').parse((selectedDayTimes?['işaisani']).toString());
      } on Exception catch (_) {
        isaisani = null;
      }
      try {
        kible = DateFormat('HH:mm').parse((selectedDayTimes?['kıble']).toString());
      } on Exception catch (_) {
        kible = null;
      }

      selectDate(time.add(const Duration(days: 1)));
      try {
        imsak2 = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
      } on Exception catch (_) {
        imsak2 = null;
      }
      selectDate(time.subtract(const Duration(days: 1)));
      try {
        yatsi2 = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());
      } on Exception catch (_) {
        yatsi2 = null;
      }
      isTimeLoading = false;
      await fetchCalendar(currentLangCode);
      await fetchWordnDay(currentLangCode);
      await fetchHijriCalendar(currentLangCode);
      notifyListeners();
    }
  }

  Future<void> fetchWordnDay(String langCode) async {
    final url =
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!.add(const Duration(days: 1)))}&page=onyuz&dil=${langCode == 'tr' ? 'tr' : 'en'}';

    try {
      final response = await fetchWithFallback(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final olayElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununolayi');
        final sozElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununsozu');

        day = olayElement?.text ?? "Günün önemi bulunamadı.";
        word = sozElement?.text ?? "Günün sözü bulunamadı.";
      } else {
        day = "Siteye erişim başarısız.";
        word = "Siteye erişim başarısız.";
      }
    } catch (e) {
      day = "Hata oluştu: $e";
      word = "Hata oluştu: $e";
    }
  }

  Future<void> fetchCalendar(String langCode) async {
    final url =
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!.add(const Duration(days: 1)))}&page=arkayuz&dil=${langCode == 'tr' ? 'tr' : 'en'}';

    try {
      final response = await fetchWithFallback(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final title = document.querySelector('article#contents div h1');
        final content = document.querySelector('article#contents div div[style*="margin:5px"]');

        calendarTitle = title?.text ?? "Başlık bulunamadı.";
        calendar = content?.text ?? "İçerik bulunamadı.";
      } else {
        calendarTitle = "Siteye erişim başarısız.";
        calendar = "Siteye erişim başarısız.";
      }
    } catch (e) {
      calendarTitle = "Hata oluştu: $e";
      calendar = "Hata oluştu: $e";
    }
  }

  Future<void> fetchHijriCalendar(String langCode) async {
    final url =
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!.add(const Duration(days: 1)))}&page=onyuz&dil=${langCode == 'tr' ? 'tr' : (langCode == 'ar' ? 'ar' : 'en')}';

    try {
      final response = await fetchWithFallback(url);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final dayElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part1 div.hicri');

        final hijriFullText = dayElement?.text ?? "Günün önemi bulunamadı.";

        // Hicrî tarihi parçalara ayır
        final parts = hijriFullText.trim().split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          hijriDay = parts[0]; // Gün
          hijriMonth = parts[1]; // Ay
          hijriYear = parts[2]; // Yıl
        } else {
          hijriDay = hijriFullText;
          hijriMonth = '';
          hijriYear = '';
        }
      } else {
        hijriDay = "Hicrî Takvim Siteye erişim başarısız.";
        hijriMonth = '';
        hijriYear = '';
      }
    } catch (e) {
      hijriDay = "Hicrî Takvim Hata oluştu: $e";
      hijriMonth = '';
      hijriYear = '';
    }
    debugPrint('Hicrî Takvim - Gün: $hijriDay, Ay: $hijriMonth, Yıl: $hijriYear');
  }

  void switchClock(bool value) {
    if (value) {
      isClockEnabled = true;
    } else {
      isClockEnabled = false;
    }
  }

  void switchLoading(bool value) {
    if (value) {
      isLoading = true;
    } else {
      isLoading = false;
    }

    notifyListeners();
  }

  void updateTime() {
    DateTime now = DateTime.now();
    clock = DateFormat('HH:mm:ss').format(now);

    if (isTimeLoading == false && imsak != null) {
      if (DateTime(now.year, now.month, now.day, imsak!.hour, imsak!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        pray = 0;
        soontime = imsak!;
        preTime = yatsi2!;
      } else if (DateTime(now.year, now.month, now.day, sabah!.hour, sabah!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 1;
        soontime = sabah!;
        preTime = imsak!;
      } else if (DateTime(now.year, now.month, now.day, gunes!.hour, gunes!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 2;
        soontime = gunes!;
        preTime = sabah!;
      } else if (DateTime(now.year, now.month, now.day, ogle!.hour, ogle!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 3;
        soontime = ogle!;
        preTime = gunes!;
      } else if (DateTime(now.year, now.month, now.day, ikindi!.hour, ikindi!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 4;
        soontime = ikindi!;
        preTime = ogle!;
      } else if (DateTime(now.year, now.month, now.day, aksam!.hour, aksam!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 5;
        soontime = aksam!;
        preTime = ikindi!;
      } else if (DateTime(now.year, now.month, now.day, yatsi!.hour, yatsi!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 6;
        soontime = yatsi!;
        preTime = aksam!;
      } else {
        pray = 7;
        soontime = imsak2!;
        preTime = yatsi!;
      }

      if (soontime == imsak2 &&
          DateTime(1970, 1, 1, now.hour, now.minute, now.second, now.millisecond).isAfter(yatsi!)) {
        mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
            .difference(preTime);
        difference = soontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second));
      } else if (soontime == imsak) {
        mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
            .difference(preTime);
        difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      } else {
        mainDifference = soontime.difference(preTime);
        difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      }
      notifyListeners();
    }
  }

  void updateDetailedTime() {
    DateTime now = DateTime.now();
    clock = DateFormat('HH:mm:ss').format(now);

    if (isTimeLoading == false && imsak != null) {
      if (DateTime(now.year, now.month, now.day, imsak!.hour, imsak!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 0;
        noPray = false;
        detailedSoontime = imsak!;
        detailedPreTime = yatsi2!;
      } else if (DateTime(now.year, now.month, now.day, sabah!.hour, sabah!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 1;
        noPray = false;
        detailedSoontime = sabah!;
        detailedPreTime = imsak!;
      } else if (DateTime(now.year, now.month, now.day, gunes!.hour, gunes!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 2;
        noPray = false;
        detailedSoontime = gunes!;
        detailedPreTime = sabah!;
      } else if (DateTime(now.year, now.month, now.day, israk!.hour, israk!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 3;
        noPray = true;
        detailedSoontime = israk!;
        detailedPreTime = gunes!;
      } else if (DateTime(now.year, now.month, now.day, kerahat!.hour, kerahat!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 4;
        noPray = false;
        detailedSoontime = kerahat!;
        detailedPreTime = israk!;
      } else if (DateTime(now.year, now.month, now.day, ogle!.hour, ogle!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 5;
        noPray = true;
        detailedSoontime = ogle!;
        detailedPreTime = kerahat!;
      } else if (DateTime(now.year, now.month, now.day, ikindi!.hour, ikindi!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 6;
        noPray = false;
        detailedSoontime = ikindi!;
        detailedPreTime = ogle!;
      } else if (DateTime(now.year, now.month, now.day, asrisani!.hour, asrisani!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 7;
        noPray = false;
        detailedSoontime = asrisani!;
        detailedPreTime = ikindi!;
      } else if (DateTime(now.year, now.month, now.day, isfirar!.hour, isfirar!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 8;
        noPray = false;
        detailedSoontime = isfirar!;
        detailedPreTime = asrisani!;
      } else if (DateTime(now.year, now.month, now.day, aksam!.hour, aksam!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 9;
        noPray = true;
        detailedSoontime = aksam!;
        detailedPreTime = isfirar!;
      } else if (DateTime(now.year, now.month, now.day, istibak!.hour, istibak!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 10;
        noPray = false;
        detailedSoontime = istibak!;
        detailedPreTime = aksam!;
      } else if (DateTime(now.year, now.month, now.day, yatsi!.hour, yatsi!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 11;
        noPray = false;
        detailedSoontime = yatsi!;
        detailedPreTime = istibak!;
      } else if (DateTime(now.year, now.month, now.day, isaisani!.hour, isaisani!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        detailedPray = 12;
        noPray = false;
        detailedSoontime = isaisani!;
        detailedPreTime = yatsi!;
      } else {
        detailedPray = 13;
        noPray = false;
        detailedSoontime = imsak2!;
        detailedPreTime = isaisani!;
      }

      if (detailedSoontime == imsak2 &&
          DateTime(1970, 1, 1, now.hour, now.minute, now.second, now.millisecond)
              .isAfter(isaisani!)) {
        detailedMainDifference = DateTime(
                1970, 1, 2, detailedSoontime.hour, detailedSoontime.minute, detailedSoontime.second)
            .difference(preTime);
        detailedDifference =
            detailedSoontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second));
      } else if (detailedSoontime == imsak) {
        detailedMainDifference = DateTime(
                1970, 1, 2, detailedSoontime.hour, detailedSoontime.minute, detailedSoontime.second)
            .difference(preTime);
        detailedDifference =
            detailedSoontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      } else {
        detailedMainDifference = detailedSoontime.difference(preTime);
        detailedDifference =
            detailedSoontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      }
      notifyListeners();
    }
  }

  void changeTime(String time) {
    miladi = time;
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
