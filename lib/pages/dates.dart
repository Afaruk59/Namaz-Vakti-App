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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class Dates extends StatelessWidget {
  const Dates({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: Provider.of<ChangeSettings>(context).currentHeight! < 700.0
          ? AppLocalizations.of(context)!.datesTitleShort
          : AppLocalizations.of(context)!.datesTitle,
      actions: const [],
      gradient: true,
      body: const DatesCard(),
    );
  }
}

class DatesCard extends StatefulWidget {
  const DatesCard({super.key});

  @override
  State<DatesCard> createState() => _DatesCardState();
}

class _DatesCardState extends State<DatesCard> {
  static List<String> _list = [];
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  @override
  initState() {
    super.initState();
    if (_list.isEmpty) {
      _loadDates();
    }
  }

  Future<void> _loadDates() async {
    final response = await http.get(Uri.parse('http://turktakvim.com/yillikhicri.php'));

    dom.Document document = html_parser.parse(response.body);

    final element = document.querySelectorAll('tr.active td');

    setState(() {
      _list = element.map((e) => e.text).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Scrollbar(
          child: _list.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.symmetric(
                      vertical:
                          Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 10.0),
                  child: ListView.builder(
                    itemCount: _list.length ~/ 3,
                    itemBuilder: (context, index) {
                      index *= 3;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0
                                ? 5
                                : 10.0),
                        child: Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ListTile(
                              title: Text(_list[index + 2]),
                              subtitle: Text('${_list[index + 1]} | ${_list[index]}'),
                              trailing: FilledButton.tonal(
                                  onPressed: () async {
                                    try {
                                      // 1. İzin iste
                                      var permissionStatus =
                                          await Permission.calendarFullAccess.status;
                                      if (!permissionStatus.isGranted) {
                                        permissionStatus =
                                            await Permission.calendarFullAccess.request();
                                        if (!permissionStatus.isGranted) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Takvim izni verilmedi'),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      // 2. Takvimleri al
                                      var calendarsResult =
                                          await _deviceCalendarPlugin.retrieveCalendars();

                                      // Tüm takvimlerin detaylı bilgisini logla
                                      if (calendarsResult.data != null) {
                                        for (var cal in calendarsResult.data!) {
                                          debugPrint(
                                              'Takvim Detay - ID: ${cal.id}, İsim: ${cal.name}, Açıklama: ${cal.accountName}, Tip: ${cal.accountType}');
                                        }
                                      }

                                      debugPrint(
                                          'Takvimler: ${calendarsResult.data?.map((c) => "${c.id}: ${c.name}").join(", ")}');
                                      var calendars = calendarsResult.data;

                                      if (calendars == null || calendars.isEmpty) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Takvim bulunamadı'),
                                              duration: Duration(seconds: 5),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // LOCAL tipindeki takvimi bul
                                      var localCalendar = calendars.firstWhere(
                                        (cal) => cal.accountType?.toUpperCase() == 'LOCAL',
                                        orElse: () => calendars.first,
                                      );

                                      debugPrint(
                                          'Otomatik seçilen takvim: ${localCalendar.name} (${localCalendar.id}), Tip: ${localCalendar.accountType}');

                                      // 3. Etkinlik oluştur
                                      // Tarih formatını kontrol et ve düzelt
                                      final originalDate = _list[index];
                                      debugPrint('Orijinal tarih: $originalDate');

                                      // Tarih formatını doğrula ve düzelt
                                      DateTime eventDate;
                                      try {
                                        final parts = originalDate.split('-');
                                        if (parts.length == 3) {
                                          // Gün-Ay-Yıl formatı (örn: 01-05-2024)
                                          final day = int.parse(parts[0]);
                                          final month = int.parse(parts[1]);
                                          final year = int.parse(parts[2]);
                                          eventDate = DateTime(year, month, day);
                                          debugPrint(
                                              'Oluşturulan tarih: ${eventDate.toIso8601String()}');
                                        } else {
                                          // Farklı format dene
                                          eventDate = DateTime.parse(originalDate);
                                        }
                                      } catch (e) {
                                        debugPrint('Tarih parse hatası: $e');
                                        // Bugünün tarihini kullan
                                        eventDate = DateTime.now();
                                      }

                                      debugPrint('Event date: $eventDate');

                                      // Başlangıç ve bitiş saatlerini ayarla
                                      final startDate = DateTime(eventDate.year, eventDate.month,
                                          eventDate.day, 0, 0, 0 // Günün başlangıcı
                                          );

                                      final endDate = DateTime(eventDate.year, eventDate.month,
                                          eventDate.day, 23, 59, 59 // Günün sonu
                                          );

                                      final event = Event(
                                        localCalendar.id,
                                        title: _list[index + 2],
                                        description: '${_list[index + 1]} | ${_list[index]}',
                                        start: TZDateTime.from(startDate, tz.local),
                                        end: TZDateTime.from(endDate, tz.local),
                                        allDay: true, // Tüm gün etkinlik olarak işaretle
                                      );

                                      // 4. Etkinliği kaydet
                                      final result =
                                          await _deviceCalendarPlugin.createOrUpdateEvent(event);

                                      debugPrint(
                                          'Sonuç: ${result?.isSuccess}, ID: ${result?.data}');

                                      if (context.mounted) {
                                        if (result?.isSuccess == true) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${_list[index + 2]} takvime eklendi'),
                                              duration: const Duration(seconds: 5), // Süreyi uzat
                                              behavior:
                                                  SnackBarBehavior.floating, // Daha görünür yap
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Takvime eklenemedi: ${result?.errors.map((e) => e.errorMessage).join(", ") ?? "Bilinmeyen hata"}'),
                                              duration: const Duration(seconds: 5), // Süreyi uzat
                                              behavior:
                                                  SnackBarBehavior.floating, // Daha görünür yap
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Genel hata: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Bir hata oluştu: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Icon(Icons.edit_calendar_rounded)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
