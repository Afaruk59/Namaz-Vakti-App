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
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
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

  Future<void> _fetchDay() async {
    final response = await http
        .get(Uri.parse('https://www.turktakvim.com/vakitler.asp?fr=4&bg=FFFFFF&fn=000000&sz=12'));

    if (response.statusCode == 200) {
      // HTML sayfasını parse et
      dom.Document document = html_parser.parse(response.body);

      // İstediğiniz elementleri seçin (örneğin, ilk <p> elementi)
      final element = document.querySelector('td');

      setState(() {
        // Elementin içeriğini al
        _day = element != null ? element.text : 'İçerik bulunamadı';
      });
    } else {
      setState(() {
        _day = 'İçerik alınamadı';
      });
    }

    final translator = GoogleTranslator();
    if (Provider.of<ChangeSettings>(context, listen: false).langCode != 'tr') {
      var translation = await translator.translate(_day!,
          to: Provider.of<ChangeSettings>(context, listen: false).langCode ?? 'tr');
      setState(() {
        _day = translation.text;
      });
    }
  }

  Future<void> _fetchWord() async {
    final response = await http
        .get(Uri.parse('https://www.turktakvim.com/vakitler.asp?fr=5&bg=FFFFFF&fn=000000&sz=12'));

    if (response.statusCode == 200) {
      // HTML sayfasını parse et
      dom.Document document = html_parser.parse(response.body);

      // İstediğiniz elementleri seçin (örneğin, ilk <p> elementi)
      final element = document.querySelector('td');

      setState(() {
        // Elementin içeriğini al
        _word = element != null ? element.text : 'İçerik bulunamadı';
      });
    } else {
      setState(() {
        _word = 'İçerik alınamadı';
      });
    }
  }

  Future<void> _fetchCalendar() async {
    const url =
        'https://www.turktakvim.com/10/Tr/'; // İçeriğini almak istediğiniz web sayfası URL'si

    // Web sayfasının HTML içeriğini almak için HTTP isteği yap
    final response = await http.get(Uri.parse(url));

    // HTTP isteği başarılı ise devam et
    if (response.statusCode == 200) {
      // HTML içeriğini parse et
      var document = html_parser.parse(response.body);

      // Tüm text içeriğini al
      var textContent = document.body!.text;

      // Text içeriğini göster (örneğin konsola yazdır)
      setState(() {
        _calendar = textContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 25,
      icon: const Icon(Icons.date_range_rounded),
      onPressed: () async {
        if (_ilk) {
          await _fetchDay();
          await _fetchWord();
          await _fetchCalendar();
          setState(() {
            _ilk = false;
          });
        }
        showModalBottomSheet(
          backgroundColor: Theme.of(context).cardTheme.color,
          context: context,
          showDragHandle: true,
          scrollControlDisabledMaxHeightRatio: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Provider.of<ChangeSettings>(context, listen: false).rounded == true ? 50 : 10,
            ),
          ),
          isScrollControlled:
              Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0
                  ? true
                  : false,
          elevation: 10,
          builder: (BuildContext context) {
            return Card(
              elevation: 10,
              color: Theme.of(context).cardColor,
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
                          borderRadius: BorderRadius.circular(
                            Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
                          ),
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
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
      },
    );
  }
}
