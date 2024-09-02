import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
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

  Future<void> _fetchWord() async {
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
  }

  Future<void> fetchCalendar() async {
    final url =
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
    } else {
      print('Sayfa alınamadı: ${response.statusCode}');
    }
  }

  final titleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      right: 4,
      child: FilledButton.tonal(
        style: ElevatedButton.styleFrom(
          elevation: 15,
        ),
        child: Icon(Icons.date_range_rounded),
        onPressed: () async {
          if (_ilk) {
            await _fetchDay();
            await _fetchWord();
            await fetchCalendar();
            _ilk = false;
          }
          showModalBottomSheet(
            backgroundColor: Theme.of(context).cardTheme.color,
            context: context,
            showDragHandle: true,
            scrollControlDisabledMaxHeightRatio: 0.7,
            elevation: 10,
            builder: (BuildContext context) {
              return Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.grey, // Kenar rengini belirleyin
                    width: 2.0, // Kenar kalınlığını belirleyin
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                color: Theme.of(context).cardColor,
                child: Scrollbar(
                  child: Padding(
                    padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
                    child: ListView(
                      children: [
                        Text(
                          _day!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Günün Sözü:',
                          style: titleStyle,
                        ),
                        Text(
                          _word!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Arka Yaprak:',
                          style: titleStyle,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: FilledButton.tonal(
                            onPressed: () async {
                              final Uri url = Uri.parse('https://www.turktakvim.com/');
                              await launchUrl(url);
                            },
                            child: Text('Turktakvim.com'),
                            style: ElevatedButton.styleFrom(elevation: 10),
                          ),
                        ),
                        SizedBox(
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
      ),
    );
  }
}
