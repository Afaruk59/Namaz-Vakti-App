import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
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
  static List<String> _list = [];
  @override
  initState() {
    super.initState();
    if (_list.length == 0) {
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
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        child: Scrollbar(
          child: _list.length == 0
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: ListView.builder(
                    itemCount: _list.length ~/ 3,
                    itemBuilder: (context, index) {
                      index *= 3;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Card(
                          color: Theme.of(context).cardColor,
                          child: ListTile(
                            title: Text(_list[index + 2]),
                            subtitle: Text('${_list[index + 1]} | ${_list[index]}'),
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
