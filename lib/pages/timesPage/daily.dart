import 'dart:async';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';

class Daily extends StatefulWidget {
  const Daily({super.key});

  @override
  State<Daily> createState() => _DailyState();
}

class _DailyState extends State<Daily> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // 5 saniyede bir otomatik geçiş yap
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        _currentPage = (_currentPage + 1) % 2;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [''];
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> result = words.where((word) => word.trim().isNotEmpty).toList();

    return result.isEmpty ? [text] : result;
  }

  Widget _buildTextContent(String text) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: splitIntoSentences(text)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeData = Provider.of<TimeData>(context);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildTextContent(timeData.day),
            _buildTextContent(timeData.word),
          ],
        ),
      ),
    );
  }
}
