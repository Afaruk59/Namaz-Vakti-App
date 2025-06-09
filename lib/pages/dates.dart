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
import 'package:namaz_vakti_app/components/container_item.dart';
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
      background: true,
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
    return Scrollbar(
      child: _list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                  vertical: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 10.0),
              child: ListView.builder(
                itemCount: _list.length ~/ 3,
                itemBuilder: (context, index) {
                  index *= 3;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 10.0),
                    child: ContainerItem(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ListTile(
                          title: Text(_list[index + 2]),
                          subtitle: Text('${_list[index + 1]} | ${_list[index]}'),
                          trailing: FilledButton.tonal(
                              onPressed: () async {
                                try {
                                  // iOS'ta device_calendar plugin'inin kendi izin sistemini kullan
                                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                                    debugPrint('iOS platformu - device_calendar izin kontrolü');
                                    var permissionsGranted =
                                        await _deviceCalendarPlugin.hasPermissions();
                                    debugPrint('Takvim izin durumu: $permissionsGranted');

                                    if (permissionsGranted.isSuccess &&
                                        !(permissionsGranted.data ?? false)) {
                                      debugPrint('İzin yok, talep ediliyor');
                                      var permissionResult =
                                          await _deviceCalendarPlugin.requestPermissions();
                                      debugPrint(
                                          'İzin talebi sonucu: ${permissionResult.isSuccess}, data: ${permissionResult.data}');

                                      if (!permissionResult.isSuccess ||
                                          !(permissionResult.data ?? false)) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context)!
                                                  .calendarPermissionDenied),
                                              action: SnackBarAction(
                                                label: 'Ayarlar',
                                                onPressed: () async {
                                                  // iOS ayarlarına yönlendir
                                                  await openAppSettings();
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    }
                                  } else {
                                    // Android için permission_handler kullan
                                    debugPrint('Android platformu - permission_handler kontrolü');
                                    Permission calendarPermission = Permission.calendarFullAccess;

                                    var permissionStatus = await calendarPermission.status;
                                    debugPrint('Android izin durumu: $permissionStatus');

                                    if (!permissionStatus.isGranted) {
                                      permissionStatus = await calendarPermission.request();
                                      debugPrint('Android izin talebi sonucu: $permissionStatus');

                                      if (!permissionStatus.isGranted) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context)!
                                                  .calendarPermissionDenied),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    }
                                  }

                                  var calendarsResult =
                                      await _deviceCalendarPlugin.retrieveCalendars();
                                  debugPrint(
                                      'Takvimler: ${calendarsResult.data?.map((c) => "${c.id}: ${c.name}").join(", ")}');
                                  var calendars = calendarsResult.data;

                                  if (calendars == null || calendars.isEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text(AppLocalizations.of(context)!.calendarNotFound),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  String? selectedCalendarId;

                                  if (calendars.length > 1 && context.mounted) {
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                              AppLocalizations.of(context)!.selectCalendarTitle),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            height: 300,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: calendars.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(
                                                      calendars[index].name ?? 'İsimsiz Takvim'),
                                                  onTap: () {
                                                    selectedCalendarId = calendars[index].id;
                                                    Navigator.of(context).pop();
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(AppLocalizations.of(context)!.leave),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    selectedCalendarId = calendars.first.id;
                                  }

                                  if (selectedCalendarId == null) {
                                    return;
                                  }

                                  final calendar = calendars.firstWhere(
                                    (cal) => cal.id == selectedCalendarId,
                                    orElse: () => calendars.first,
                                  );

                                  debugPrint('Seçilen Takvim: ${calendar.name} (${calendar.id})');

                                  final originalDate = _list[index];
                                  debugPrint('Orijinal tarih: $originalDate');

                                  DateTime eventDate;
                                  try {
                                    final parts = originalDate.split('-');
                                    if (parts.length == 3) {
                                      final day = int.parse(parts[0]);
                                      final month = int.parse(parts[1]);
                                      final year = int.parse(parts[2]);
                                      eventDate = DateTime(year, month, day);
                                      debugPrint(
                                          'Oluşturulan tarih: ${eventDate.toIso8601String()}');
                                    } else {
                                      eventDate = DateTime.parse(originalDate);
                                    }
                                  } catch (e) {
                                    debugPrint('Tarih parse hatası: $e');
                                    eventDate = DateTime.now();
                                  }

                                  debugPrint('Event date: $eventDate');

                                  final startDate = DateTime(
                                      eventDate.year, eventDate.month, eventDate.day, 0, 0, 0);

                                  final endDate = DateTime(
                                      eventDate.year, eventDate.month, eventDate.day, 23, 59, 59);

                                  final event = Event(
                                    calendar.id,
                                    title: _list[index + 2],
                                    description: '${_list[index + 1]} | ${_list[index]}',
                                    start: TZDateTime.from(startDate, tz.local),
                                    end: TZDateTime.from(endDate, tz.local),
                                    allDay: true,
                                  );

                                  final result =
                                      await _deviceCalendarPlugin.createOrUpdateEvent(event);

                                  debugPrint('Sonuç: ${result?.isSuccess}, ID: ${result?.data}');

                                  if (context.mounted) {
                                    if (result?.isSuccess == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context)!
                                              .calendarAddSuccess(_list[index + 2])),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context)!
                                              .calendarAddError(result?.errors
                                                      .map((e) => e.errorMessage)
                                                      .join(", ") ??
                                                  "Bilinmeyen hata")),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Genel hata: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppLocalizations.of(context)!
                                            .generalError(e.toString())),
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
    );
  }
}
