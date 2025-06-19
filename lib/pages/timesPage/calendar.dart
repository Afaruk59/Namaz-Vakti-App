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
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/components/transparent_card.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarBtn extends StatefulWidget {
  const CalendarBtn({super.key});

  @override
  State<CalendarBtn> createState() => _CalendarBtnState();
}

class _CalendarBtnState extends State<CalendarBtn> {
  static String? _day;
  static String? _word;
  static String? _calendar;
  static bool _ilk = true;

  Future<void> fetchWordnDay() async {
    final url = Uri.parse('https://www.turktakvim.com/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final olayElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununolayi');
        final sozElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununsozu');

        setState(() {
          _day = olayElement?.text ?? "Günün önemi bulunamadı.";
          _word = sozElement?.text ?? "Günün sözü bulunamadı.";
        });
      } else {
        setState(() {
          _day = "Siteye erişim başarısız.";
          _word = "Siteye erişim başarısız.";
        });
      }
    } catch (e) {
      setState(() {
        _day = "Hata oluştu: $e";
        _word = "Hata oluştu: $e";
      });
    }
  }

  Future<void> _fetchCalendar() async {
    const url = 'https://www.turktakvim.com/10/Tr/';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = html_parser.parse(response.body);

      var textContent = document.body!.text;

      setState(() {
        _calendar = textContent;
      });
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0 ? true : false,
      enableDrag: true,
      scrollControlDisabledMaxHeightRatio: 0.8,
      builder: (BuildContext context) {
        return TransparentCard(
          child: Scrollbar(
            child: Padding(
              padding: EdgeInsets.all(
                  Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
              child: ListView(
                children: [
                  Text(
                    DateFormat(
                      'dd MMMM yyyy',
                      Provider.of<ChangeSettings>(context, listen: false).langCode,
                    ).format(DateTime.now()),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    _day!,
                  ),
                  const SizedBox(
                    height: 30,
                    child: Divider(
                      thickness: 3,
                    ),
                  ),
                  Text(
                    _word!,
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Provider.of<ChangeSettings>(context).isDark
                            ? Colors.grey.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(
                          Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        _calendar!,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final Uri url = Uri.parse('https://www.turktakvim.com/');
                        await launchUrl(url);
                      },
                      child: const Text('Turktakvim.com'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: SizedBox.expand(
        child: IconButton.filledTonal(
          iconSize: 25,
          style: IconButton.styleFrom(
            shape: Provider.of<ChangeSettings>(context).rounded == true
                ? const CircleBorder()
                : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
          ),
          icon: const Icon(Icons.date_range_rounded),
          onPressed: () async {
            if (_ilk) {
              await fetchWordnDay();
              await _fetchCalendar();
              setState(() {
                _ilk = false;
              });
            }
            _showBottomSheet(context);
          },
        ),
      ),
    );
  }
}
