import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'article_detail_page.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> _favorites = [];
  List<String> _favoriteQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    final favoriteQuestions = prefs.getStringList('favoriteQuestions') ?? [];
    setState(() {
      _favorites = favorites;
      _favoriteQuestions = favoriteQuestions;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    List<String> favoriteQuestions = prefs.getStringList('favoriteQuestions') ?? [];

    final index = favorites.indexOf(url);
    if (index != -1) {
      favorites.removeAt(index);
      if (index < favoriteQuestions.length) {
        favoriteQuestions.removeAt(index);
      }
    }

    await prefs.setStringList('favorites', favorites);
    await prefs.setStringList('favoriteQuestions', favoriteQuestions);
    setState(() {
      _favorites = favorites;
      _favoriteQuestions = favoriteQuestions;
    });
  }

  Future<void> _clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites');
    await prefs.remove('favoriteQuestions');
    setState(() {
      _favorites = [];
      _favoriteQuestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: 'Favori Sualler',
      background: true,
      actions: _favorites.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Tüm Favorileri Sil'),
                        content: const Text(
                          'Tüm favori sualleri silmek istediğinizden emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearAllFavorites();
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 20),
            ]
          : <Widget>[],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz favori sualiniz yok',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Beğendiğiniz sualleri favorilere ekleyebilirsiniz.',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      // Yeni gelen en üste gelecek şekilde ters sıralama
                      final reverseIndex = _favorites.length - 1 - index;
                      final favoriteUrl = _favorites[reverseIndex];
                      final title = reverseIndex < _favoriteQuestions.length
                          ? _favoriteQuestions[reverseIndex]
                          : 'Favori Sual';

                      return Dismissible(
                        key: Key(favoriteUrl),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            size: 28,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Favoriden Çıkar'),
                                content: const Text(
                                  'Bu suali favorilerden çıkarmak istediğinizden emin misiniz?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text(
                                      'Çıkar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _removeFavorite(favoriteUrl);
                        },
                        child: Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleDetailPage(
                                    articleUrl: favoriteUrl,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: ListTile(
                                leading: const Icon(Icons.help_rounded),
                                title: Text(
                                  title,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
