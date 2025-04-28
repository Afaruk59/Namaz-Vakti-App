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
import 'package:namaz_vakti_app/components/lang_selector.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider.of<ChangeSettings>(context, listen: false).isfirst == true
        ? ScaffoldLayout(
            title: AppLocalizations.of(context)!.settingsPageTitle,
            actions: const [],
            gradient: true,
            body: const SettingsCard(),
          )
        : ScaffoldLayout(
            title: AppLocalizations.of(context)!.settingsPageTitle,
            actions: const [],
            gradient: false,
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
            hexInputBar: true,
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
                pickerColor = Colors.blueGrey[500]!;
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
          child: ListView(
            children: [
              const LangSelector(),
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
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SegmentedButton(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.phone_android_rounded, size: 24),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.dark_mode_rounded, size: 24),
                        ),
                        ButtonSegment(
                          value: 2,
                          icon: Icon(Icons.light_mode_rounded, size: 24),
                        ),
                      ],
                      emptySelectionAllowed: false,
                      selected: {Provider.of<ChangeSettings>(context).themeIndex},
                      onSelectionChanged: (Set<int> selected) {
                        Provider.of<ChangeSettings>(context, listen: false)
                            .toggleTheme(selected.first);
                      },
                    ),
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
