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
import 'package:namaz_vakti_app/components/container_item.dart';
import 'package:namaz_vakti_app/components/transparent_card.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class LangSelector extends StatelessWidget {
  const LangSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return TransparentCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListTile(
          title: Text(AppLocalizations.of(context)!.ln),
          subtitle: Text(AppLocalizations.of(context)!.lang),
          trailing: const Icon(Icons.translate_rounded),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.ln),
                  content: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: const LangPage(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class LangPage extends StatelessWidget {
  const LangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: TransparentCard(
          child: Padding(
            padding: EdgeInsets.all(
                Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 10.0),
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                return LangItem(index: index);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class LangItem extends StatelessWidget {
  const LangItem({super.key, required this.index});
  final int index;
  static const List<String> langs = [
    'Türkçe',
    'English (%80)',
    'عربي (%80)',
    'Deutsch (%80)',
    'Español (%80)',
    'Français (%80)',
    'Italiano (%80)',
    'Русский (%80)',
  ];

  @override
  Widget build(BuildContext context) {
    return ContainerItem(
      child: ListTile(
        title: Text(langs[index]),
        onTap: () {
          Provider.of<ChangeSettings>(context, listen: false).saveLanguage(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
