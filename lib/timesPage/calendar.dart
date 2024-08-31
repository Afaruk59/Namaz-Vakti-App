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
  static String? day;
  static String? word;
  static String? calendarTitle;
  static String? calendar;
  static String? calendarTitle2;
  static String? calendar2;
  static String? calendar3;
  static bool ilk = true;

  Future<void> fetchDay() async {
    final response = await http
        .get(Uri.parse('https://www.turktakvim.com/vakitler.asp?fr=5&bg=FFFFFF&fn=000000&sz=12'));

    if (response.statusCode == 200) {
      // HTML sayfasını parse et
      dom.Document document = html_parser.parse(response.body);

      // İstediğiniz elementleri seçin (örneğin, ilk <p> elementi)
      final element = document.querySelector('td');

      setState(() {
        // Elementin içeriğini al
        word = element != null ? element.text : 'İçerik bulunamadı';
      });
    } else {
      setState(() {
        word = 'İçerik alınamadı';
      });
    }
  }

  Future<void> fetchWord() async {
    final response = await http
        .get(Uri.parse('https://www.turktakvim.com/vakitler.asp?fr=4&bg=FFFFFF&fn=000000&sz=12'));

    if (response.statusCode == 200) {
      // HTML sayfasını parse et
      dom.Document document = html_parser.parse(response.body);

      // İstediğiniz elementleri seçin (örneğin, ilk <p> elementi)
      final element = document.querySelector('td');

      setState(() {
        // Elementin içeriğini al
        day = element != null ? element.text : 'İçerik bulunamadı';
      });
    } else {
      setState(() {
        day = 'İçerik alınamadı';
      });
    }
  }

  Future<void> fetchCalendar() async {
    final response = await http.get(Uri.parse('https://www.turktakvim.com/10/Tr/'));

    if (response.statusCode == 200) {
      dom.Document document = html_parser.parse(response.body);

      // MENKIBE başlığı altındaki içeriği çekme
      final menkibeTitle = document.querySelector('h3');
      final menkibe = document.querySelector('div p + p');
      final menkibeTitle2 = document.querySelector('div p + p + p');
      final menkibe2 = document.querySelector('div p + p + p + p');
      final menkibe3 = document.querySelector('div p + p + p + p + p');

      setState(() {
        calendarTitle = menkibeTitle != null ? menkibeTitle.text : 'Menkibe içeriği bulunamadı';
        calendar = menkibe != null ? menkibe.text : 'Menkibe içeriği bulunamadı';
        calendarTitle2 = menkibeTitle2 != null ? menkibeTitle2.text : 'Menkibe içeriği bulunamadı';
        calendar2 = menkibe2 != null ? menkibe2.text : 'Menkibe içeriği bulunamadı';
        calendar3 = menkibe3 != null ? menkibe3.text : 'Menkibe içeriği bulunamadı';
      });
    } else {
      setState(() {
        calendarTitle = 'İçerik alınamadı';
        calendarTitle2 = 'İçerik alınamadı';
        calendar = 'İçerik alınamadı';
        calendar2 = 'İçerik alınamadı';
        calendar3 = 'İçerik alınamadı';
      });
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
          if (ilk) {
            await fetchDay();
            await fetchWord();
            await fetchCalendar();
            ilk = false;
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
                          day!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Günün Sözü:',
                          style: titleStyle,
                        ),
                        Text(
                          word!,
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
                        Text(
                          calendarTitle!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          calendar!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          calendarTitle2!,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          calendar2!,
                        ),
                        Text(
                          calendar3!,
                        ),
                        SizedBox(
                          height: 20,
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
