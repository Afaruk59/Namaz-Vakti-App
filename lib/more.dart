import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.morePageTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
          child: Column(
            children: [
              SizedBox(height: MainApp.currentHeight! < 700.0 ? 5 : 15.0),
              MoreCard(
                title: AppLocalizations.of(context)!.datesTitle,
                icon: const Icon(Icons.calendar_month),
                route: '/dates',
              ),
              MoreCard(
                title: AppLocalizations.of(context)!.kazaTitle,
                icon: const Icon(Icons.note_alt),
                route: '/kaza',
              ),
              MoreCard(
                title: AppLocalizations.of(context)!.booksTitle,
                icon: const Icon(Icons.library_books_outlined),
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
      padding: EdgeInsets.symmetric(horizontal: MainApp.currentHeight! < 700.0 ? 5 : 15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MainApp.currentHeight! < 700.0 ? 5 : 15.0),
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
