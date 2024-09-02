import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/main.dart';

class Dates extends StatelessWidget {
  const Dates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mübarek Gün ve Geceler'),
      ),
      body: DatesCard(),
    );
  }
}

class DatesCard extends StatefulWidget {
  const DatesCard({super.key});

  @override
  State<DatesCard> createState() => _DatesCardState();
}

class _DatesCardState extends State<DatesCard> {
  static List<String> _date1 = [];
  static List<String> _date2 = [];
  static List<String> _date3 = [];
  static List<String> _date4 = [];
  static List<String> _date5 = [];
  static List<String> _date6 = [];
  static List<String> _date7 = [];
  static List<String> _date8 = [];
  static List<String> _date9 = [];
  static List<String> _date10 = [];
  static List<String> _date11 = [];
  static List<String> _date12 = [];
  static List<String> _date13 = [];
  static List<String> _date14 = [];
  static List<String> _date15 = [];
  static List<String> _date16 = [];
  static List<String> _date17 = [];
  static List<String> _date18 = [];
  static List<String> _date19 = [];
  static List<String> _date20 = [];
  static List<String> _date21 = [];
  static List<String> _date22 = [];
  static List<String> _date23 = [];
  static List<String> _date24 = [];
  static List<String> _date25 = [];
  static List<String> _date26 = [];
  static bool isCompleted = false;

  @override
  initState() {
    super.initState();
    if (isCompleted == false) {
      _fetchDates();
    }
  }

  void addElements(List<String> list, List<String> splitList) {
    list.add(splitList[3]);
    list.add(splitList[6]);
    list.add(splitList[9]);
    list.add(splitList[12]);
    list.add(splitList[15]);
    list.add(splitList[18]);
    list.add(splitList[21]);
  }

  List<String> findElements(dom.Document document, int count) {
    final String query = '+ tr ' * (count - 1);
    final element = document.querySelector('tr + tr + tr + tr $query');
    return element!.text.split('\n');
  }

  Future<void> _fetchDates() async {
    String year = DateFormat('yyyy').format(DateTime.now());
    final response =
        await http.get(Uri.parse('https://vakithesaplama.diyanet.gov.tr/dinigunler.php?yil=$year'));

    dom.Document document = html_parser.parse(response.body);
    setState(() {
      addElements(_date1, findElements(document, 1));
      addElements(_date2, findElements(document, 2));
      addElements(_date3, findElements(document, 3));
      addElements(_date4, findElements(document, 4));
      addElements(_date5, findElements(document, 5));
      addElements(_date6, findElements(document, 6));
      addElements(_date7, findElements(document, 7));
      addElements(_date8, findElements(document, 8));
      addElements(_date9, findElements(document, 9));
      addElements(_date10, findElements(document, 10));
      addElements(_date11, findElements(document, 11));
      addElements(_date12, findElements(document, 12));
      addElements(_date13, findElements(document, 13));
      addElements(_date14, findElements(document, 14));
      addElements(_date15, findElements(document, 15));
      addElements(_date16, findElements(document, 16));
      addElements(_date17, findElements(document, 17));
      addElements(_date18, findElements(document, 18));
      addElements(_date19, findElements(document, 19));
      addElements(_date20, findElements(document, 20));
      addElements(_date21, findElements(document, 21));
      addElements(_date22, findElements(document, 22));
      addElements(_date23, findElements(document, 23));
      addElements(_date24, findElements(document, 24));
      addElements(_date25, findElements(document, 25));
      addElements(_date26, findElements(document, 26));
    });
    isCompleted = true;
  }

  @override
  Widget build(BuildContext context) {
    return isCompleted == true
        ? ListView(
            children: [
              SizedBox(
                height: 15,
              ),
              DateCard(text: _date1),
              DateCard(text: _date2),
              DateCard(text: _date3),
              DateCard(text: _date4),
              DateCard(text: _date5),
              DateCard(text: _date6),
              DateCard(text: _date7),
              DateCard(text: _date8),
              DateCard(text: _date9),
              DateCard(text: _date10),
              DateCard(text: _date11),
              DateCard(text: _date12),
              DateCard(text: _date13),
              DateCard(text: _date14),
              DateCard(text: _date15),
              DateCard(text: _date16),
              DateCard(text: _date17),
              DateCard(text: _date18),
              DateCard(text: _date19),
              DateCard(text: _date20),
              DateCard(text: _date21),
              DateCard(text: _date22),
              DateCard(text: _date23),
              DateCard(text: _date24),
              DateCard(text: _date25),
              DateCard(text: _date26),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}

class DateCard extends StatelessWidget {
  const DateCard({super.key, required this.text});
  final List<String> text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        child: ListTile(
          title: Text(
            style: TextStyle(fontSize: 16),
            text[6],
          ),
          subtitle: Text('${text[0]}${text[1]}${text[2]}  -${text[3]}${text[4]}'),
        ),
      ),
    );
  }
}
