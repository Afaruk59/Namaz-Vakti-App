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

// Vakit modeli
class PrayerTimeModel {
  final String name;
  final DateTime? time;
  final int index;
  final bool isNoPray; // Namaz kılınamayan vakit mi?

  PrayerTimeModel({
    required this.name,
    required this.time,
    required this.index,
    this.isNoPray = false,
  });
}

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
  DateTime? geceYarisi;
  DateTime? teheccud;
  DateTime? seher;

  List<Map<String, String>> prayerTimes = [];
  Map<String, String>? selectedDayTimes;
  DateTime? selectedDate;
  bool isLoading = true;

  bool isTimeLoading = true;
  bool _disposed = false;

  String clock = '';
  Duration difference = const Duration(minutes: 1);
  int pray = 0; // Şu anki geçerli vakit index'i (widget'larda vurgulamak için)
  int nextPray = 0; // Bir sonraki vakit index'i (clock'ta göstermek için)
  DateTime soontime = DateTime.now();
  DateTime preTime = DateTime.now();
  Duration mainDifference = const Duration(minutes: 1);
  bool isClockEnabled = true;

  Duration detailedDifference = const Duration(minutes: 1);
  int detailedPray = 0; // Şu anki geçerli vakit index'i (detaylı vakitler için)
  int detailedNextPray = 0; // Bir sonraki vakit index'i (detaylı vakitler için)
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

  // Ana vakitler listesi (gerçek kronolojik saat sırasına göre)
  // NOT: İmsak2 ve Yatsı2 widget'larda gösterilmez, sadece süre hesaplaması için kullanılır
  List<PrayerTimeModel> getMainPrayerTimes() {
    // Sadece görünür vakitleri ekle (imsak2 eklenmiyor)
    final times = [
      PrayerTimeModel(name: 'imsak', time: imsak, index: 0),
      PrayerTimeModel(name: 'sabah', time: sabah, index: 1),
      PrayerTimeModel(name: 'gunes', time: gunes, index: 2),
      PrayerTimeModel(name: 'ogle', time: ogle, index: 3),
      PrayerTimeModel(name: 'ikindi', time: ikindi, index: 4),
      PrayerTimeModel(name: 'aksam', time: aksam, index: 5),
      PrayerTimeModel(name: 'yatsi', time: yatsi, index: 6),
    ];

    // Null olmayan vakitleri filtrele
    final validTimes = times.where((t) => t.time != null).toList();

    // Sadece saat/dakika değerine göre sırala (00:00 - 23:59 doğal sırada)
    validTimes.sort((a, b) {
      final hourA = a.time!.hour;
      final hourB = b.time!.hour;

      if (hourA != hourB) return hourA.compareTo(hourB);
      return a.time!.minute.compareTo(b.time!.minute);
    });

    // Sıralandıktan sonra her vakite yeni index ver (updateTime'da kullanılacak)
    for (int i = 0; i < validTimes.length; i++) {
      validTimes[i] = PrayerTimeModel(
        name: validTimes[i].name,
        time: validTimes[i].time,
        index: i,
        isNoPray: validTimes[i].isNoPray,
      );
    }

    return validTimes;
  }

  // Detaylı vakitler listesi (gerçek kronolojik saat sırasına göre)
  // NOT: İmsak2 ve Yatsı2 widget'larda gösterilmez, sadece süre hesaplaması için kullanılır
  List<PrayerTimeModel> getDetailedPrayerTimes() {
    // Sadece görünür vakitleri ekle (imsak2 eklenmiyor)
    final times = [
      PrayerTimeModel(name: 'geceYarisi', time: geceYarisi, index: 0),
      PrayerTimeModel(name: 'teheccud', time: teheccud, index: 1),
      PrayerTimeModel(name: 'seher', time: seher, index: 2),
      PrayerTimeModel(name: 'imsak', time: imsak, index: 3),
      PrayerTimeModel(name: 'sabah', time: sabah, index: 4),
      PrayerTimeModel(name: 'gunes', time: gunes, index: 5, isNoPray: true),
      PrayerTimeModel(name: 'israk', time: israk, index: 6),
      PrayerTimeModel(name: 'kerahat', time: kerahat, index: 7, isNoPray: true),
      PrayerTimeModel(name: 'ogle', time: ogle, index: 8),
      PrayerTimeModel(name: 'ikindi', time: ikindi, index: 9),
      PrayerTimeModel(name: 'asrisani', time: asrisani, index: 10),
      PrayerTimeModel(name: 'isfirar', time: isfirar, index: 11, isNoPray: true),
      PrayerTimeModel(name: 'aksam', time: aksam, index: 12),
      PrayerTimeModel(name: 'istibak', time: istibak, index: 13),
      PrayerTimeModel(name: 'yatsi', time: yatsi, index: 14),
      PrayerTimeModel(name: 'isaisani', time: isaisani, index: 15),
    ];

    // Null olmayan vakitleri filtrele
    final validTimes = times.where((t) => t.time != null).toList();

    // Sadece saat/dakika değerine göre sırala (00:00 - 23:59 doğal sırada)
    validTimes.sort((a, b) {
      final hourA = a.time!.hour;
      final hourB = b.time!.hour;

      if (hourA != hourB) return hourA.compareTo(hourB);
      return a.time!.minute.compareTo(b.time!.minute);
    });

    // Sıralandıktan sonra her vakite yeni index ver (0-based)
    for (int i = 0; i < validTimes.length; i++) {
      validTimes[i] = PrayerTimeModel(
        name: validTimes[i].name,
        time: validTimes[i].time,
        index: i, // 0-based index
        isNoPray: validTimes[i].isNoPray,
      );
    }

    return validTimes;
  }

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

      // Gece Yarısı, Teheccüd ve Seher vakitlerini hesapla
      selectDate(time);
      if (aksam != null && imsak2 != null) {
        // Şer'î gece: Akşam vaktinden ertesi gün imsak vaktine kadar
        final aksamMinutes = aksam!.hour * 60 + aksam!.minute;
        final imsakMinutes = imsak2!.hour * 60 + imsak2!.minute;

        // Şer'î gecenin uzunluğu (dakika cinsinden)
        final seriGeceUzunlugu = (24 * 60) - aksamMinutes + imsakMinutes;

        // 1. Gece Yarısı Vakti: Şer'î gecenin yarısı
        final geceYarisiDakika = aksamMinutes + (seriGeceUzunlugu / 2).round();
        final geceYarisiSaat = (geceYarisiDakika ~/ 60) % 24;
        final geceYarisiDk = geceYarisiDakika % 60;
        geceYarisi = DateTime(1970, 1, 1, geceYarisiSaat, geceYarisiDk.toInt());

        // 2. Teheccüd Vakti: Şer'î gecenin son üçte biri (2/3'ü geçtikten sonra)
        final teheccudDakika = aksamMinutes + ((seriGeceUzunlugu * 2) / 3).round();
        final teheccudSaat = (teheccudDakika ~/ 60) % 24;
        final teheccudDk = teheccudDakika % 60;
        teheccud = DateTime(1970, 1, 1, teheccudSaat, teheccudDk.toInt());

        // 3. Seher Vakti: Şer'î gecenin son altıda biri (5/6'sı geçtikten sonra)
        final seherDakika = aksamMinutes + ((seriGeceUzunlugu * 5) / 6).round();
        final seherSaat = (seherDakika ~/ 60) % 24;
        final seherDk = seherDakika % 60;
        seher = DateTime(1970, 1, 1, seherSaat, seherDk.toInt());

        debugPrint('Gece Yarısı: ${DateFormat('HH:mm').format(geceYarisi!)}');
        debugPrint('Teheccüd: ${DateFormat('HH:mm').format(teheccud!)}');
        debugPrint('Seher: ${DateFormat('HH:mm').format(seher!)}');
      } else {
        geceYarisi = null;
        teheccud = null;
        seher = null;
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
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!)}&page=onyuz&dil=${langCode == 'tr' ? 'tr' : 'en'}';

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
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!)}&page=arkayuz&dil=${langCode == 'tr' ? 'tr' : 'en'}';

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
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(selectedDate!)}&page=onyuz&dil=${langCode == 'tr' ? 'tr' : (langCode == 'ar' ? 'ar' : 'en')}';

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
      final prayerTimes = getMainPrayerTimes();

      // Şu anki vakti bul
      PrayerTimeModel? currentPrayer;
      PrayerTimeModel? previousPrayer;

      for (int i = 0; i < prayerTimes.length; i++) {
        final prayerTime = prayerTimes[i];
        if (prayerTime.time == null) continue;

        final prayerDateTime = DateTime(
            now.year, now.month, now.day, prayerTime.time!.hour, prayerTime.time!.minute, 0);

        if (prayerDateTime.isAfter(now)) {
          currentPrayer = prayerTime;
          previousPrayer = i > 0 ? prayerTimes[i - 1] : null;

          // Önceki vakit yatsi2 ise (gece yarısından sonra ilk vakit için)
          if (previousPrayer == null && yatsi2 != null) {
            // Yatsı2 için index'i Yatsı'nın index'i olarak kullan (son vakit)
            final yatsiIndex = prayerTimes.isNotEmpty ? prayerTimes.last.index : 6;
            previousPrayer = PrayerTimeModel(name: 'yatsi2', time: yatsi2, index: yatsiIndex);
          }
          break;
        }
      }

      // Hiçbir vakit bulunamadıysa (tüm vakitler geçmiş, gece yarısından sonra)
      // Ertesi gün imsak'ı bir sonraki vakit olarak ata
      if (currentPrayer == null) {
        // Son vakit şu anki geçerli vakit
        previousPrayer = prayerTimes.isNotEmpty ? prayerTimes.last : null;

        // İmsak2'yi bir sonraki vakit olarak kullan
        if (imsak2 != null && previousPrayer != null) {
          currentPrayer = PrayerTimeModel(
            name: 'imsak2',
            time: imsak2,
            index: prayerTimes.length, // Listenin sonundan sonraki index
          );
        }
      }

      if (currentPrayer != null && previousPrayer != null && previousPrayer.time != null) {
        pray = previousPrayer.index; // Şu anki geçerli vakit (previousPrayer)
        nextPray = currentPrayer.index; // Bir sonraki vakit (currentPrayer) - clock'ta gösteriliyor
        soontime = currentPrayer.time!; // Bir sonraki vakit (currentPrayer)
        preTime = previousPrayer.time!; // Geçerli vakit başlangıcı

        // Fark hesaplama
        if ((currentPrayer.name == 'imsak2' || currentPrayer.name == 'imsak') &&
            yatsi != null &&
            DateTime(1970, 1, 1, now.hour, now.minute, now.second, now.millisecond)
                .isAfter(yatsi!)) {
          mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
              .difference(preTime);
          difference =
              soontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second));
        } else if (currentPrayer.name == 'imsak') {
          mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
              .difference(preTime);
          difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
        } else {
          mainDifference = soontime.difference(preTime);
          difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
        }
      }

      notifyListeners();
    }
  }

  void updateDetailedTime() {
    DateTime now = DateTime.now();
    clock = DateFormat('HH:mm:ss').format(now);

    if (isTimeLoading == false && geceYarisi != null) {
      final prayerTimes = getDetailedPrayerTimes();

      // Şu anki vakti bul
      PrayerTimeModel? currentPrayer;
      PrayerTimeModel? previousPrayer;

      for (int i = 0; i < prayerTimes.length; i++) {
        final prayerTime = prayerTimes[i];
        if (prayerTime.time == null) continue;

        final prayerDateTime = DateTime(
            now.year, now.month, now.day, prayerTime.time!.hour, prayerTime.time!.minute, 0);

        if (prayerDateTime.isAfter(now)) {
          currentPrayer = prayerTime;
          previousPrayer = i > 0 ? prayerTimes[i - 1] : null;

          // Önceki vakit yok ise yatsi2 (gece yarısından sonra ilk vakit için)
          if (previousPrayer == null && yatsi2 != null) {
            // Yatsı2 için index'i İşa-i Sani'nin index'i olarak kullan (son vakit)
            final yatsiIndex = prayerTimes.isNotEmpty ? prayerTimes.last.index : 15;
            previousPrayer = PrayerTimeModel(name: 'yatsi2', time: yatsi2, index: yatsiIndex);
          }
          break;
        }
      }

      // Hiçbir vakit bulunamadıysa (tüm vakitler geçmiş, gece yarısından sonra)
      // Ertesi gün imsak'ı bir sonraki vakit olarak ata
      if (currentPrayer == null) {
        // Son vakit şu anki geçerli vakit
        previousPrayer = prayerTimes.isNotEmpty ? prayerTimes.last : null;

        // İmsak2'yi bir sonraki vakit olarak kullan
        if (imsak2 != null && previousPrayer != null) {
          currentPrayer = PrayerTimeModel(
            name: 'imsak2',
            time: imsak2,
            index: prayerTimes.length, // Listenin sonundan sonraki index
          );
        }
      }

      if (currentPrayer != null && previousPrayer != null && previousPrayer.time != null) {
        detailedPray = previousPrayer.index; // Şu anki geçerli vakit (previousPrayer)
        detailedNextPray = currentPrayer.index; // Bir sonraki vakit (currentPrayer)
        noPray = previousPrayer.isNoPray; // Şu anki vakitte namaz kılınabilir mi?
        detailedSoontime = currentPrayer.time!; // Bir sonraki vakit (currentPrayer)
        detailedPreTime = previousPrayer.time!; // Geçerli vakit başlangıcı

        // Fark hesaplama
        if ((currentPrayer.name == 'imsak2' || currentPrayer.name == 'imsak') &&
            isaisani != null &&
            DateTime(1970, 1, 1, now.hour, now.minute, now.second, now.millisecond)
                .isAfter(isaisani!)) {
          detailedMainDifference = DateTime(1970, 1, 2, detailedSoontime.hour,
                  detailedSoontime.minute, detailedSoontime.second)
              .difference(detailedPreTime);
          detailedDifference =
              detailedSoontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second));
        } else if (currentPrayer.name == 'imsak') {
          detailedMainDifference = DateTime(1970, 1, 2, detailedSoontime.hour,
                  detailedSoontime.minute, detailedSoontime.second)
              .difference(detailedPreTime);
          detailedDifference =
              detailedSoontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
        } else {
          detailedMainDifference = detailedSoontime.difference(detailedPreTime);
          detailedDifference =
              detailedSoontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
        }
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
