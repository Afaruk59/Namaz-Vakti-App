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
import 'package:namaz_vakti_app/l10n/app_localization.dart';
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
  final Map<String, String> _months = {
    'MUHARREM': 'al-Muḥarram',
    'SAFER': 'Ṣafar',
    "REBÎ'UL-EVVEL": 'Rabīʿ al-ʾAwwal',
    "REBÎ'UL-ÂHIR": 'Rabīʿ ath-Thānī',
    "CEMÂZİL-EVVEL": 'Jumādā al-ʾŪlā',
    "CEMÂZİL-ÂHIR": 'Jumādā al-ʾĀkhirah',
    "RECEB": 'Rajab',
    "ŞA'BÂN": 'Shaʿbān',
    "RAMEZÂN": 'Ramaḍān',
    "ŞEVVÂL": 'Shawwāl',
    "ZİL-KA'DE": 'Ḏū al-Qaʿdah',
    "ZİL-HİCCE": 'Ḏū al-Ḥijjah',
  };
  final Map<String, Map<String, String>> translations = {
    "Üç Ayların başlaması": {
      "en": "Beginning of the Three Holy Months",
      "ar": "بداية الأشهر الثلاثة",
      "de": "Beginn der drei heiligen Monate",
      "es": "Comienzo de los Tres Meses Sagrados",
      "fr": "Début des trois mois sacrés",
      "it": "Inizio dei tre mesi sacri",
      "ru": "Начало трёх священных месяцев"
    },
    "Regâib Kandili Gecesi (Receb ayının ilk Cuma gecesi)": {
      "en": "Night of Raghaib (First Friday night of the month of Rajab)",
      "ar": "ليلة الرغائب (ليلة الجمعة الأولى من رجب)",
      "de": "Nacht von Raghaib (Erster Freitagabend im Monat Radschab)",
      "es": "Noche de Raghaib (Primer viernes del mes de Rayab)",
      "fr": "Nuit de Raghaïb (Premier vendredi du mois de Rajab)",
      "it": "Notte di Raghaib (Primo venerdì del mese di Rajab)",
      "ru": "Ночь Рагаиб (первая пятничная ночь месяца Раджаб)"
    },
    "Mi'râc Kandili Gecesi": {
      "en": "Night of Mi'raj (Ascension)",
      "ar": "ليلة المعراج",
      "de": "Nacht der Miraj (Himmelfahrt des Propheten)",
      "es": "Noche del Mi'ray (Ascensión del Profeta)",
      "fr": "Nuit du Mi'râj (Ascension du Prophète)",
      "it": "Notte del Mi'rāj (Ascensione del Profeta)",
      "ru": "Ночь Мирадж (вознесение Пророка)"
    },
    "Berât Kandili Gecesi": {
      "en": "Night of Bara'at",
      "ar": "ليلة البراءة",
      "de": "Nacht von Bara'a",
      "es": "Noche de Bara'at",
      "fr": "Nuit de la Bara'a",
      "it": "Notte di Barāʾa",
      "ru": "Ночь Бараат"
    },
    "Ramezân-ı şerîf'in başlangıcı": {
      "en": "Beginning of the Holy Month of Ramadan",
      "ar": "بداية شهر رمضان المبارك",
      "de": "Beginn des heiligen Monats Ramadan",
      "es": "Comienzo del sagrado mes de Ramadán",
      "fr": "Début du mois sacré de Ramadan",
      "it": "Inizio del mese sacro di Ramadan",
      "ru": "Начало священного месяца Рамадан"
    },
    "Kadr Gecesi": {
      "en": "Night of Qadr (Power)",
      "ar": "ليلة القدر",
      "de": "Nacht der Bestimmung (Lailat al-Qadr)",
      "es": "Noche del Decreto (Laylat al-Qadr)",
      "fr": "Nuit du Destin (Laylat al-Qadr)",
      "it": "Notte del Destino (Laylat al-Qadr)",
      "ru": "Ночь Предопределения (Лейлат аль-Кадр)"
    },
    "Fıtr Bayramı Gecesi": {
      "en": "Night Before Eid al-Fitr",
      "ar": "ليلة عيد الفطر",
      "de": "Vorabend des Festes des Fastenbrechens (Eid al-Fitr)",
      "es": "Noche anterior a la Fiesta de la ruptura del ayuno (Eid al-Fitr)",
      "fr": "Veille de l'Aïd el-Fitr",
      "it": "Notte prima della Festa di fine Ramadan (Eid al-Fitr)",
      "ru": "Ночь перед праздником Ид аль-Фитр"
    },
    "Ramezân-ı şerîf bayramının 1. Günü": {
      "en": "1st Day of Eid al-Fitr",
      "ar": "اليوم الأول من عيد الفطر",
      "de": "Erster Tag des Eid al-Fitr",
      "es": "Primer día del Eid al-Fitr",
      "fr": "Premier jour de l'Aïd el-Fitr",
      "it": "Primo giorno dell'Eid al-Fitr",
      "ru": "Первый день Ид аль-Фитр"
    },
    "Ramezân-ı şerîf bayramının 2. Günü": {
      "en": "2nd Day of Eid al-Fitr",
      "ar": "اليوم الثاني من عيد الفطر",
      "de": "Zweiter Tag des Eid al-Fitr",
      "es": "Segundo día del Eid al-Fitr",
      "fr": "Deuxième jour de l'Aïd el-Fitr",
      "it": "Secondo giorno dell'Eid al-Fitr",
      "ru": "Второй день Ид аль-Фитр"
    },
    "Ramezân-ı şerîf bayramının 3. Günü": {
      "en": "3rd Day of Eid al-Fitr",
      "ar": "اليوم الثالث من عيد الفطر",
      "de": "Dritter Tag des Eid al-Fitr",
      "es": "Tercer día del Eid al-Fitr",
      "fr": "Troisième jour de l'Aïd el-Fitr",
      "it": "Terzo giorno dell'Eid al-Fitr",
      "ru": "Третий день Ид аль-Фитр"
    },
    "Terviye Günü": {
      "en": "Day of Tarwiyah",
      "ar": "يوم التروية",
      "de": "Tag von Tarwiyah",
      "es": "Día de Tarwiyah",
      "fr": "Jour de Tarwiyah",
      "it": "Giorno di Tarwiyah",
      "ru": "День Тарвия"
    },
    "Arefe Günü": {
      "en": "Day of Arafah",
      "ar": "يوم عرفة",
      "de": "Tag von Arafat",
      "es": "Día de Arafat",
      "fr": "Jour d'Arafat",
      "it": "Giorno di Arafat",
      "ru": "День Арафат"
    },
    "Kurban Bayramı 1. Günü": {
      "en": "1st Day of Eid al-Adha",
      "ar": "اليوم الأول من عيد الأضحى",
      "de": "Erster Tag des Opferfestes (Eid al-Adha)",
      "es": "Primer día de la Fiesta del Sacrificio (Eid al-Adha)",
      "fr": "Premier jour de l'Aïd al-Adha",
      "it": "Primo giorno dell'Eid al-Adha",
      "ru": "Первый день Курбан-байрама"
    },
    "Kurban Bayramı 2. Günü": {
      "en": "2nd Day of Eid al-Adha",
      "ar": "اليوم الثاني من عيد الأضحى",
      "de": "Zweiter Tag des Opferfestes",
      "es": "Segundo día del Eid al-Adha",
      "fr": "Deuxième jour de l'Aïd al-Adha",
      "it": "Secondo giorno dell'Eid al-Adha",
      "ru": "Второй день Курбан-байрама"
    },
    "Kurban Bayramı 3. Günü": {
      "en": "3rd Day of Eid al-Adha",
      "ar": "اليوم الثالث من عيد الأضحى",
      "de": "Dritter Tag des Opferfestes",
      "es": "Tercer día del Eid al-Adha",
      "fr": "Troisième jour de l'Aïd al-Adha",
      "it": "Terzo giorno dell'Eid al-Adha",
      "ru": "Третий день Курбан-байрама"
    },
    "Kurban Bayramı 4. Günü": {
      "en": "4th Day of Eid al-Adha",
      "ar": "اليوم الرابع من عيد الأضحى",
      "de": "Vierter Tag des Opferfestes",
      "es": "Cuarto día del Eid al-Adha",
      "fr": "Quatrième jour de l'Aïd al-Adha",
      "it": "Quarto giorno dell'Eid al-Adha",
      "ru": "Четвёртый день Курбан-байрама"
    },
    "Hicrî Yılbaşı Gecesi": {
      "en": "Hijri New Year's Eve",
      "ar": "ليلة رأس السنة الهجرية",
      "de": "Vorabend des islamischen Neujahrs",
      "es": "Víspera del Año Nuevo Hégira",
      "fr": "Veille du Nouvel An hégirien",
      "it": "Vigilia del Capodanno islamico",
      "ru": "Ночь перед Хиджри новым годом"
    },
    "Hicrî Yılbaşı": {
      "en": "Hijri New Year",
      "ar": "رأس السنة الهجرية",
      "de": "Islamisches Neujahr",
      "es": "Año Nuevo Hégira",
      "fr": "Nouvel An hégirien",
      "it": "Capodanno islamico",
      "ru": "Исламский Новый год (Хиджра)"
    },
    "Aşûre Gecesi": {
      "en": "Eve of Ashura",
      "ar": "ليلة عاشوراء",
      "de": "Vorabend von Ashura",
      "es": "Víspera de Ashura",
      "fr": "Veille de l'Achoura",
      "it": "Vigilia di Ashura",
      "ru": "Ночь перед Ашурой"
    },
    "Aşûre Günü": {
      "en": "Day of Ashura",
      "ar": "يوم عاشوراء",
      "de": "Tag von Ashura",
      "es": "Día de Ashura",
      "fr": "Jour de l'Achoura",
      "it": "Giorno di Ashura",
      "ru": "День Ашура"
    },
    "Mevlid Kandili Gecesi": {
      "en": "Night of Mawlid (Birth of the Prophet)",
      "ar": "ليلة المولد النبوي",
      "de": "Nacht des Prophetengeburtstages (Mawlid)",
      "es": "Noche del Mawlid (Nacimiento del Profeta)",
      "fr": "Nuit du Mawlid (Naissance du Prophète)",
      "it": "Notte del Mawlid (Nascita del Profeta)",
      "ru": "Ночь Мавлид (рождение Пророка)"
    }
  };

  String getTranslation(String turkishValue) {
    final langCode = Provider.of<ChangeSettings>(context, listen: false).langCode;

    if (translations.containsKey(turkishValue)) {
      debugPrint('Tam eşleşme bulundu: $turkishValue');
      return translations[turkishValue]![langCode] ?? turkishValue;
    }
    return turkishValue;
  }

  String getMonth(String month) {
    final langCode = Provider.of<ChangeSettings>(context, listen: false).langCode;
    final parts = month.split(' ');
    if (langCode == 'ar') {
      return '${_months[parts[2]]!} ${parts[4]} ${parts[0]}';
    } else {
      return '${parts[0]} ${_months[parts[2]]!} ${parts[4]}';
    }
  }

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
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ListTile(
                          title: Text(
                            Provider.of<ChangeSettings>(context).langCode == 'tr'
                                ? _list[index + 2]
                                : getTranslation(_list[index + 2]),
                          ),
                          subtitle: Text(
                              '${Provider.of<ChangeSettings>(context).langCode == "tr" ? _list[index + 1] : getMonth(_list[index + 1])} | ${_list[index]}'),
                          trailing: FilledButton.tonal(
                              onPressed: () async {
                                try {
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
                                          content: Text(
                                            AppLocalizations.of(context)!.calendarAddSuccess(
                                                getTranslation(_list[index + 2])),
                                          ),
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
