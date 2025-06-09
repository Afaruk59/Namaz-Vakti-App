/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/components/tenbih_card.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.morePageTitle,
      actions: const [],
      background: false,
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
          child: ListView(
            children: [
              SizedBox(
                  height: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
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
              BooksCard(
                title: AppLocalizations.of(context)!.booksTitle,
                icon: const Icon(Icons.local_library_rounded),
                route: '/books',
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
                child: const TenbihCard(),
              ),
              ReviewCard(),
              MoreCard(
                title: AppLocalizations.of(context)!.aboutTitle,
                icon: const Icon(Icons.info),
                route: '/about',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  ReviewCard({super.key});
  final InAppReview inAppReview = InAppReview.instance;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
          child: ListTile(
            title: Text(AppLocalizations.of(context)!.rate),
            onTap: () async {
              if (await inAppReview.isAvailable()) {
                inAppReview.requestReview();
              }
            },
            trailing: FilledButton.tonal(
              onPressed: () async {
                if (await inAppReview.isAvailable()) {
                  inAppReview.requestReview();
                }
              },
              child: const Icon(Icons.star_rounded),
            ),
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
      padding: EdgeInsets.symmetric(
          horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
          child: ListTile(
            splashColor: Colors.transparent,
            onTap: () {
              Navigator.pushNamed(context, route);
            },
            title: Text(title),
            trailing: FilledButton.tonal(
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

class BooksCard extends StatelessWidget {
  const BooksCard({
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
      padding: EdgeInsets.symmetric(
          horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
          child: ListTile(
            splashColor: Colors.transparent,
            onTap: () async {
              final String code =
                  Provider.of<ChangeSettings>(context, listen: false).langCode ?? 'tr';
              if (code == 'tr') {
                Navigator.pushNamed(context, route);
              } else {
                final Uri url =
                    Uri.parse('https://www.hakikatkitabevi.net/books.php?listBook=$code');
                await launchUrl(url);
              }
            },
            title: Text(title),
            trailing: FilledButton.tonal(
              onPressed: () async {
                final String code =
                    Provider.of<ChangeSettings>(context, listen: false).langCode ?? 'tr';
                if (code == 'tr') {
                  Navigator.pushNamed(context, route);
                } else {
                  final Uri url =
                      Uri.parse('https://www.hakikatkitabevi.net/books.php?listBook=$code');
                  await launchUrl(url);
                }
              },
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
