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
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider.of<ChangeSettings>(context, listen: false).isfirst == true
        ? GradientBack(
            child: Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.settingsPageTitle),
              ),
              body: const SettingsCard(),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.settingsPageTitle),
            ),
            body: const SettingsCard(),
          );
  }
}

class SettingsCard extends StatefulWidget {
  const SettingsCard({
    super.key,
  });

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  Color pickerColor = Colors.white;

  Future<dynamic> colorPalette(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.colorPaletteTitle),
        content: SingleChildScrollView(
          child: ColorPicker(
            enableAlpha: false,
            labelTypes: const [],
            pickerColor: pickerColor,
            onColorChanged: (value) {
              setState(() {
                pickerColor = value;
              });
              Provider.of<ChangeSettings>(context, listen: false).changeCol(value);
              Provider.of<ChangeSettings>(context, listen: false).saveCol(value);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              setState(() {
                pickerColor = Colors.blueGrey[
                    Provider.of<ChangeSettings>(context, listen: false).isDark == true
                        ? 800
                        : 500]!;
              });
              Provider.of<ChangeSettings>(context, listen: false).changeCol(pickerColor);
              Provider.of<ChangeSettings>(context, listen: false).saveCol(pickerColor);
            },
            child: Text(AppLocalizations.of(context)!.retry),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(
              Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
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
                    title: Text(AppLocalizations.of(context)!.otoLocal),
                    value: Provider.of<ChangeSettings>(context).otoLocal,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleOtoLoc(),
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
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.layout),
                    subtitle: Provider.of<ChangeSettings>(context).rounded == true
                        ? Text(AppLocalizations.of(context)!.rounded)
                        : Text(AppLocalizations.of(context)!.sharp),
                    value: Provider.of<ChangeSettings>(context).rounded,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleShape(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.themeColor),
                    subtitle: Text(
                        Provider.of<ChangeSettings>(context, listen: false).color.toHexString()),
                    onTap: () {
                      pickerColor = Provider.of<ChangeSettings>(context, listen: false).color;
                      colorPalette(context);
                    },
                    trailing: FilledButton.tonal(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                      ),
                      onPressed: () {
                        pickerColor = Provider.of<ChangeSettings>(context, listen: false).color;
                        colorPalette(context);
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
