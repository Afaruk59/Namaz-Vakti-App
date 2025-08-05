import 'package:flutter/material.dart';
import 'search_service.dart';
import 'article_detail_page.dart';

class RandomQuestionsWidget extends StatefulWidget {
  const RandomQuestionsWidget({super.key});

  @override
  State<RandomQuestionsWidget> createState() => _RandomQuestionsWidgetState();
}

class _RandomQuestionsWidgetState extends State<RandomQuestionsWidget> {
  List<Article> _randomQuestions = [];
  bool _isLoadingRandomQuestions = false;
  String _randomQuestionsError = '';

  @override
  void initState() {
    super.initState();
    _loadRandomQuestions();
  }

  Future<void> _loadRandomQuestions() async {
    setState(() {
      _isLoadingRandomQuestions = true;
      _randomQuestionsError = '';
    });

    try {
      final questions = await SearchService.getRandomQuestions();
      setState(() {
        _randomQuestions = questions;
        _isLoadingRandomQuestions = false;
      });
    } catch (e) {
      setState(() {
        _randomQuestionsError = e.toString();
        _isLoadingRandomQuestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRandomQuestions) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Çeşitli sualler yükleniyor...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_randomQuestionsError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sorular yüklenirken hata oluştu',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRandomQuestions,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_randomQuestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Merak ettiğiniz dini sualler için arama yapın',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Yukarıdaki arama çubuğuna konuyu yazarak başlayın',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Çeşitli Sualler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadRandomQuestions,
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _randomQuestions.length,
            itemBuilder: (context, index) {
              final question = _randomQuestions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Card(
                  color: Theme.of(context).cardColor,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailPage(
                            articleUrl: question.link,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ListTile(
                        leading: const Icon(Icons.help_rounded),
                        subtitle: Text(question.title),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
