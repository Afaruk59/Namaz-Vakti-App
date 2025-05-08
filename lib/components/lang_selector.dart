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
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class LangSelector extends StatelessWidget {
  const LangSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListTile(
          title: Text(AppLocalizations.of(context)!.ln),
          subtitle: Text(AppLocalizations.of(context)!.lang),
          trailing: const Icon(Icons.translate_rounded),
          onTap: () {
            Navigator.pushNamed(context, '/lang');
          },
        ),
      ),
    );
  }
}

class LangPage extends StatelessWidget {
  const LangPage({super.key});
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
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.ln,
      actions: const [],
      gradient: true,
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(
                Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
            child: ListView.builder(
              itemCount: langs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: TextButton(
                      onPressed: () {
                        Provider.of<ChangeSettings>(context, listen: false).saveLanguage(index);
                        Navigator.pop(context);
                      },
                      child: Text(
                        langs[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
