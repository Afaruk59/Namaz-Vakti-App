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
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class Kaza extends StatelessWidget {
  const Kaza({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.kazaTitle,
      actions: const [],
      background: true,
      body: const KazaCard(),
    );
  }
}

class KazaCard extends StatelessWidget {
  const KazaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        children: [
          const SizedBox(
            height: 10,
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.sabah,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Sabah'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.ogle,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Öğle'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.ikindi,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('İkindi'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.aksam,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Akşam'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.yatsi,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Yatsı'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.vitir,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Vitir'),
          ),
          PrayCard(
            title: AppLocalizations.of(context)!.oruc,
            value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Oruç'),
          ),
        ],
      ),
    );
  }
}

class PrayCard extends StatefulWidget {
  const PrayCard({
    super.key,
    required this.value,
    required this.title,
  });

  final int value;
  final String title;

  @override
  State<PrayCard> createState() => _PrayCardState();
}

class _PrayCardState extends State<PrayCard> {
  int _changedVal = 0;
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _changedVal = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _changedVal++;
                  Provider.of<ChangeSettings>(context, listen: false)
                      .saveKaza(widget.title, _changedVal);
                });
              },
              child: const Icon(Icons.add),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!.kazaMessageTitle),
                              content: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly, // Sadece rakamlar
                                ],
                                controller: _textFieldController,
                                decoration: InputDecoration(hintText: '$_changedVal'),
                              ),
                              actions: [
                                TextButton(
                                  child: Text(AppLocalizations.of(context)!.ok),
                                  onPressed: () {
                                    if (_textFieldController.text != '') {
                                      setState(() {
                                        _changedVal = int.parse(_textFieldController.text);
                                      });
                                      Provider.of<ChangeSettings>(context, listen: false)
                                          .saveKaza(widget.title, _changedVal);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            );
                          });
                    },
                    child: Text(
                      '$_changedVal',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  if (_changedVal != 0) {
                    _changedVal--;
                    Provider.of<ChangeSettings>(context, listen: false)
                        .saveKaza(widget.title, _changedVal);
                  }
                });
              },
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}
