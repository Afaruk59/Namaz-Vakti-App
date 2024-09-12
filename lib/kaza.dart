import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:provider/provider.dart';

class Kaza extends StatelessWidget {
  const Kaza({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade300
                : Provider.of<ChangeSettings>(context).color.shade800,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.01, 0.4],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Kaza Takibi'),
        ),
        body: KazaCard(),
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
              SizedBox(
                height: 10,
              ),
              PrayCard(
                title: 'Sabah',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Sabah'),
              ),
              PrayCard(
                title: 'Öğle',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Öğle'),
              ),
              PrayCard(
                title: 'İkindi',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('İkindi'),
              ),
              PrayCard(
                title: 'Akşam',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Akşam'),
              ),
              PrayCard(
                title: 'Yatsı',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Yatsı'),
              ),
              PrayCard(
                title: 'Vitir',
                value: Provider.of<ChangeSettings>(context, listen: false).loadKaza('Vitir'),
              ),
              PrayCard(
                title: 'Oruç',
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
  TextEditingController _textFieldController = TextEditingController();

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
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(elevation: 10, shape: CircleBorder()),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.title}',
                    style: TextStyle(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Kaza Sayısı:'),
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
                                  child: Text('OK'),
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
                      style: TextStyle(fontSize: 18),
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
              child: Icon(Icons.remove),
              style: ElevatedButton.styleFrom(elevation: 10, shape: CircleBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
