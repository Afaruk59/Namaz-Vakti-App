import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Kaza extends StatelessWidget {
  const Kaza({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.kazaTitle),
        ),
        body: const KazaCard(),
      ),
    );
  }
}

class KazaCard extends StatelessWidget {
  const KazaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Scrollbar(
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
        ),
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
              style: ElevatedButton.styleFrom(elevation: 10, shape: const CircleBorder()),
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
              style: ElevatedButton.styleFrom(elevation: 10, shape: const CircleBorder()),
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}
