import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';

class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daha Fazla'),
      ),
      body: Padding(
        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
        child: Card(
          child: ListView(
            children: [
              SizedBox(
                height: 15,
              ),
              MoreCard(
                title: 'Mübarek Günler ve Geceler',
                icon: Icon(Icons.calendar_month),
                route: '/dates',
              ),
              MoreCard(
                title: 'Kaza Takibi',
                icon: Icon(Icons.note_alt),
                route: '/kaza',
              ),
              MoreCard(
                title: 'Kaynak Kitaplar',
                icon: Icon(Icons.library_books_outlined),
                route: '/books',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreCard extends StatelessWidget {
  const MoreCard({
    super.key,
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final Icon icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ListTile(
            splashColor: Colors.transparent,
            onTap: () {
              Navigator.pushNamed(context, route);
            },
            title: Text(title),
            trailing: FilledButton.tonal(
              style: ElevatedButton.styleFrom(elevation: 10),
              onPressed: () {
                Navigator.pushNamed(context, route);
              },
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
