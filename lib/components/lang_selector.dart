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
          trailing: const LangSelectorButton(),
        ),
      ),
    );
  }
}

class LangSelectorButton extends StatelessWidget {
  const LangSelectorButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
      ),
      icon: const Icon(Icons.translate_rounded),
      elevation: 10,
      enabled: true,
      onSelected: (int result) {
        Provider.of<ChangeSettings>(context, listen: false).saveLanguage(result);
      },
      color: Theme.of(context).cardTheme.color!,
      itemBuilder: (context) {
        return <PopupMenuEntry<int>>[
          const PopupMenuItem<int>(
            value: 0,
            child: LangItem(title: 'Türkçe'),
          ),
          const PopupMenuItem<int>(
            value: 1,
            child: LangItem(title: 'English (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 2,
            child: LangItem(title: 'عربي (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 3,
            child: LangItem(title: 'Deutsch (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 4,
            child: LangItem(title: 'Español (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 5,
            child: LangItem(title: 'Français (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 6,
            child: LangItem(title: 'Italiano (%80)'),
          ),
          const PopupMenuItem<int>(
            value: 7,
            child: LangItem(title: 'Русский (%80)'),
          ),
        ];
      },
    );
  }
}

class LangItem extends StatelessWidget {
  const LangItem({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Text(
            title,
          ),
        ),
      ),
    );
  }
}
