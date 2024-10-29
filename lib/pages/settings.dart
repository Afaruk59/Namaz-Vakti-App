/*
Copyright [2024] [Afaruk59]

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
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/change_settings.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPageTitle),
      ),
      body: const SettingsCard(),
    );
  }
}

class SettingsCard extends StatelessWidget {
  static Locale? preLang;
  const SettingsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    preLang = Provider.of<ChangeSettings>(context).locale;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.ln),
                    subtitle: Text(AppLocalizations.of(context)!.lang),
                    trailing: const LangSelector(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    value: Provider.of<ChangeSettings>(context).isDark,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleTheme(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.gradient),
                    value: Provider.of<ChangeSettings>(context).gradient,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleGrad(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.themeColor),
                    trailing: FilledButton.tonal(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.colorPaletteTitle),
                            content: const SizedBox(
                              height: 200,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.blueGrey),
                                        ColorCircle(col: Colors.red),
                                        ColorCircle(col: Colors.blue),
                                        ColorCircle(col: Colors.green),
                                        ColorCircle(col: Colors.yellow),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.amber),
                                        ColorCircle(col: Colors.grey),
                                        ColorCircle(col: Colors.indigo),
                                        ColorCircle(col: Colors.lightBlue),
                                        ColorCircle(col: Colors.lightGreen),
                                        ColorCircle(col: Colors.lime),
                                        ColorCircle(col: Colors.orange),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.pink),
                                        ColorCircle(col: Colors.purple),
                                        ColorCircle(col: Colors.teal),
                                        ColorCircle(col: Colors.brown),
                                        ColorCircle(col: Colors.cyan),
                                        ColorCircle(col: Colors.deepOrange),
                                        ColorCircle(col: Colors.deepPurple),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(Icons.color_lens),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LangSelector extends StatelessWidget {
  const LangSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.language),
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
            child: Center(
              child: Text(
                'Türkçe',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 1,
            child: Center(
              child: Text(
                'English',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 2,
            child: Center(
              child: Text(
                'عربي',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 3,
            child: Center(
              child: Text(
                'Deutsch',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 4,
            child: Center(
              child: Text(
                'Español',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 5,
            child: Center(
              child: Text(
                'Français',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 6,
            child: Center(
              child: Text(
                'Italiano',
              ),
            ),
          ),
          const PopupMenuItem<int>(
            value: 7,
            child: Center(
              child: Text(
                'Русский',
              ),
            ),
          ),
        ];
      },
    );
  }
}

class ColorCircle extends StatelessWidget {
  const ColorCircle({super.key, required this.col});
  final MaterialColor col;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: const CircleBorder(),
        color: col,
        child: TextButton(
          child: Container(),
          onPressed: () {
            Provider.of<ChangeSettings>(context, listen: false).changeCol(col);
            Provider.of<ChangeSettings>(context, listen: false).saveCol(col);
          },
        ),
      ),
    );
  }
}
