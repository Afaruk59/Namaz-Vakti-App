import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';

class Daily extends StatefulWidget {
  const Daily({super.key});

  @override
  State<Daily> createState() => _DailyState();
}

class _DailyState extends State<Daily> {
  static String _day = '';
  bool _isLoading = true;

  Future<void> fetchWordnDay() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse(
        'https://turktakvim.com/index.php?tarih=${DateFormat('yyyy-MM-dd').format(Provider.of<TimeData>(context, listen: false).selectedDate!.add(const Duration(days: 1)))}&page=onyuz');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final olayElement = document.querySelector(
            'html body div#Wrapper article#contents div div#takvimon_part2 div span#gununolayi');
        if (mounted) {
          setState(() {
            _day = olayElement?.text ?? "Günün önemi bulunamadı.";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _day = "Siteye erişim başarısız.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _day = "Hata oluştu: $e";
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [''];
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> result = words.where((word) => word.trim().isNotEmpty).toList();

    return result.isEmpty ? [text] : result;
  }

  @override
  void initState() {
    super.initState();
    fetchWordnDay();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: _splitIntoSentences(_day)
                      .map((word) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.0,
                            ),
                            child: Text(
                              word.trim(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
