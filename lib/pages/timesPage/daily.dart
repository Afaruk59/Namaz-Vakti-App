import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';

class Daily extends StatelessWidget {
  const Daily({super.key});

  List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [''];
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> result = words.where((word) => word.trim().isNotEmpty).toList();

    return result.isEmpty ? [text] : result;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: splitIntoSentences(Provider.of<TimeData>(context).day)
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
