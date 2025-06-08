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
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/components/transparent_card.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Books extends StatelessWidget {
  const Books({super.key});
  static bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    _isDark = Provider.of<ChangeSettings>(context).isDark;
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.booksTitle,
      actions: const [],
      gradient: true,
      body: Scrollbar(
        child: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.ilmihal,
              col: _isDark == false
                  ? const Color.fromARGB(255, 177, 65, 57)
                  : const Color.fromARGB(255, 136, 50, 44),
              description: AppLocalizations.of(context)!.ilmihalInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=001',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.mektubat,
              col: _isDark == false
                  ? const Color.fromARGB(255, 47, 104, 150)
                  : const Color.fromARGB(255, 34, 75, 108),
              description: AppLocalizations.of(context)!.mektubatInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=002',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.islam,
              col: _isDark == false
                  ? const Color.fromARGB(255, 203, 193, 103)
                  : const Color.fromARGB(255, 152, 145, 78),
              description: AppLocalizations.of(context)!.islamInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=003',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.kiyamet,
              col: _isDark == false
                  ? const Color.fromARGB(255, 213, 106, 99)
                  : const Color.fromARGB(255, 165, 83, 77),
              description: AppLocalizations.of(context)!.kiyametInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=004',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.namaz,
              col: _isDark == false
                  ? const Color.fromARGB(255, 121, 179, 123)
                  : const Color.fromARGB(255, 89, 132, 91),
              description: AppLocalizations.of(context)!.namazInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=005',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.cevab,
              col: _isDark == false
                  ? const Color.fromARGB(255, 197, 125, 149)
                  : const Color.fromARGB(255, 159, 101, 120),
              description: AppLocalizations.of(context)!.cevabInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=006',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.eshabikiram,
              col: _isDark == false
                  ? const Color.fromARGB(255, 31, 147, 189)
                  : const Color.fromARGB(255, 23, 109, 140),
              description: AppLocalizations.of(context)!.eshabikiramInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=007',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.faideli,
              col: _isDark == false ? Colors.orange[300]! : const Color.fromARGB(255, 209, 151, 64),
              description: AppLocalizations.of(context)!.faideliInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=008',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.haksoz,
              col: _isDark == false
                  ? const Color.fromARGB(255, 117, 146, 160)
                  : const Color.fromARGB(255, 96, 119, 130),
              description: AppLocalizations.of(context)!.haksozInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=009',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.iman,
              col: _isDark == false
                  ? const Color.fromARGB(255, 180, 133, 189)
                  : const Color.fromARGB(255, 137, 101, 144),
              description: AppLocalizations.of(context)!.imanInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=010',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.ingiliz,
              col: _isDark == false
                  ? const Color.fromARGB(255, 205, 196, 111)
                  : const Color.fromARGB(255, 136, 130, 75),
              description: AppLocalizations.of(context)!.ingilizInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=011',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.kiymetsiz,
              col: _isDark == false
                  ? const Color.fromARGB(255, 199, 141, 160)
                  : const Color.fromARGB(255, 150, 107, 122),
              description: AppLocalizations.of(context)!.kiymetsizInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=012',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.menakib,
              col: _isDark == false
                  ? const Color.fromARGB(255, 195, 168, 128)
                  : const Color.fromARGB(255, 142, 123, 95),
              description: AppLocalizations.of(context)!.menakibInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=013',
            ),
            BookCard(
              bookName: AppLocalizations.of(context)!.sevahid,
              col: _isDark == false
                  ? const Color.fromARGB(255, 187, 137, 63)
                  : const Color.fromARGB(255, 142, 105, 49),
              description: AppLocalizations.of(context)!.sevahidInfo,
              link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=014',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse('https://www.hakikatkitabevi.net/');
                  await launchUrl(url);
                },
                child: const Text(
                  'www.hakikatkitabevi.net',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard(
      {super.key,
      required this.bookName,
      required this.col,
      required this.description,
      required this.link});
  final String bookName;
  final Color col;
  final String description;
  final String link;

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.6,
      isScrollControlled:
          Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0 ? true : false,
      builder: (BuildContext context) {
        return TransparentCard(
          child: Scrollbar(
            child: Padding(
              padding: EdgeInsets.all(
                  Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0
                      ? 5.0
                      : 15.0),
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      bookName,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    description,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Card(
        color: col,
        child: Padding(
          padding: EdgeInsets.all(
              Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 3.0 : 8.0),
          child: ListTile(
            leading: ElevatedButton(
              onPressed: () {
                _showBottomSheet(context);
              },
              child: const Icon(Icons.info),
            ),
            title: Text(
              bookName,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                final Uri url = Uri.parse(link);
                await launchUrl(url);
              },
              child: const Icon(Icons.book_rounded),
            ),
          ),
        ),
      ),
    );
  }
}
