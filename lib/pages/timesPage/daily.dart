import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class Daily extends StatefulWidget {
  const Daily({super.key});

  @override
  State<Daily> createState() => _DailyState();
}

class _DailyState extends State<Daily> {
  static String _day = '';
  static bool _ilk = true;

  Future<void> fetchWordnDay() async {
    final url = Uri.parse('https://www.turktakvim.com/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final olayElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununolayi');

        setState(() {
          _day = olayElement?.text ?? "Günün önemi bulunamadı.";
        });
      } else {
        setState(() {
          _day = "Siteye erişim başarısız.";
        });
      }
    } catch (e) {
      setState(() {
        _day = "Hata oluştu: $e";
      });
    }
    setState(() {
      _ilk = false;
    });
  }

  @override
  void initState() {
    super.initState();
    if (_ilk) {
      fetchWordnDay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Center(
        child: _ilk
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(5.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_day),
                ),
              ),
      ),
    );
  }
}
