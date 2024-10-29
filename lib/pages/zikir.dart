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
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Zikir extends StatelessWidget {
  const Zikir({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.zikirPageTitle),
      ),
      body: const ZikirCard(),
    );
  }
}

class ZikirCard extends StatefulWidget {
  const ZikirCard({super.key});

  @override
  State<ZikirCard> createState() => _ZikirCardState();
}

class _ZikirCardState extends State<ZikirCard> {
  static int _target = 33;
  static int _count = 0;
  static int _stack = 0;
  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _textFieldController2 = TextEditingController();
  static String _selectedProfile = ' ';
  static List<String> _profiles = [' '];

  @override
  void initState() {
    super.initState();
    _profiles = Provider.of<ChangeSettings>(context, listen: false).loadProfiles();
    _selectedProfile = Provider.of<ChangeSettings>(context, listen: false).loadSelectedProfile();
    _target = Provider.of<ChangeSettings>(context, listen: false).loadZikirSet(_selectedProfile);
    _count = Provider.of<ChangeSettings>(context, listen: false).loadZikirCount(_selectedProfile);
    _stack = Provider.of<ChangeSettings>(context, listen: false).loadZikirStack(_selectedProfile);
  }

  void _vibratePhone() async {
    Vibration.vibrate(duration: 50);
  }

  void _vibrateCustom() async {
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: MainApp.currentHeight! < 700.0 ? 3 : 2,
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Colors.grey, // Kenar rengini belirleyin
                                      width: 1.0, // Kenar kalınlığını belirleyin
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        10.0), // Kenarların yuvarlaklığını belirleyin
                                  ),
                                  color: Theme.of(context).cardColor,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(AppLocalizations.of(context)!
                                                      .resetMessageTitle),
                                                  content: Text(AppLocalizations.of(context)!
                                                      .resetMessageBody),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          Text(AppLocalizations.of(context)!.leave),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _stack = 0;
                                                          _target = 33;
                                                          _count = 0;
                                                        });
                                                        Provider.of<ChangeSettings>(context,
                                                                listen: false)
                                                            .saveZikirProfile(_selectedProfile,
                                                                _count, _target, _stack);
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          Text(AppLocalizations.of(context)!.yes),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                        style: ElevatedButton.styleFrom(elevation: 10),
                                        child: const Icon(Icons.restart_alt),
                                      ),
                                      Provider.of<ChangeSettings>(context, listen: false)
                                                  .loadVib() ==
                                              true
                                          ? FilledButton.tonal(
                                              onPressed: () {
                                                setState(() {
                                                  Provider.of<ChangeSettings>(context,
                                                          listen: false)
                                                      .saveVib(false);
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(elevation: 10),
                                              child: const Icon(Icons.vibration),
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  Provider.of<ChangeSettings>(context,
                                                          listen: false)
                                                      .saveVib(true);
                                                });
                                              },
                                              child: const Icon(Icons.vibration),
                                            ),
                                      Text(
                                        '$_stack',
                                        style: const TextStyle(
                                            fontSize: 25, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Colors.grey, // Kenar rengini belirleyin
                                      width: 1.0, // Kenar kalınlığını belirleyin
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        10.0), // Kenarların yuvarlaklığını belirleyin
                                  ),
                                  color: Theme.of(context).cardColor,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    side: const BorderSide(
                                                      color:
                                                          Colors.grey, // Kenar rengini belirleyin
                                                      width: 1.0, // Kenar kalınlığını belirleyin
                                                    ),
                                                    borderRadius: BorderRadius.circular(
                                                        10.0), // Kenarların yuvarlaklığını belirleyin
                                                  ),
                                                  color: Theme.of(context).cardColor,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.spaceEvenly,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(
                                                                  horizontal: 10.0),
                                                              child: Text(
                                                                textAlign: TextAlign.center,
                                                                AppLocalizations.of(context)!
                                                                    .zikirCount,
                                                                style:
                                                                    const TextStyle(fontSize: 17),
                                                              ),
                                                            ),
                                                            const Divider(
                                                              height: 20,
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                showDialog(
                                                                    context: context,
                                                                    builder:
                                                                        (BuildContext context) {
                                                                      return AlertDialog(
                                                                        title: Text(
                                                                            AppLocalizations.of(
                                                                                    context)!
                                                                                .zikirMessageTitle),
                                                                        content: TextField(
                                                                          keyboardType:
                                                                              TextInputType.number,
                                                                          inputFormatters: <TextInputFormatter>[
                                                                            FilteringTextInputFormatter
                                                                                .digitsOnly, // Sadece rakamlar
                                                                          ],
                                                                          controller:
                                                                              _textFieldController,
                                                                          decoration:
                                                                              InputDecoration(
                                                                                  hintText:
                                                                                      '$_target'),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () {
                                                                              Navigator.of(context)
                                                                                  .pop();
                                                                            },
                                                                            child: Text(
                                                                                AppLocalizations.of(
                                                                                        context)!
                                                                                    .leave),
                                                                          ),
                                                                          TextButton(
                                                                            child: Text(
                                                                                AppLocalizations.of(
                                                                                        context)!
                                                                                    .ok),
                                                                            onPressed: () {
                                                                              if (_textFieldController
                                                                                          .text !=
                                                                                      '' &&
                                                                                  _textFieldController
                                                                                          .text
                                                                                          .length <
                                                                                      5) {
                                                                                setState(() {
                                                                                  _target = int.parse(
                                                                                      _textFieldController
                                                                                          .text);
                                                                                });
                                                                                Provider.of<ChangeSettings>(
                                                                                        context,
                                                                                        listen:
                                                                                            false)
                                                                                    .saveZikirProfile(
                                                                                        _selectedProfile,
                                                                                        _count,
                                                                                        _target,
                                                                                        _stack);
                                                                              }
                                                                              Navigator.of(context)
                                                                                  .pop();
                                                                            },
                                                                          ),
                                                                        ],
                                                                      );
                                                                    });
                                                              },
                                                              child: Text(
                                                                textAlign: TextAlign.center,
                                                                '$_target',
                                                                style: const TextStyle(
                                                                    fontSize: 25,
                                                                    fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding:
                                              Provider.of<ChangeSettings>(context).langCode == 'ar'
                                                  ? const EdgeInsets.only(left: 10.0)
                                                  : const EdgeInsets.only(right: 10.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              FilledButton.tonal(
                                                onLongPress: () {
                                                  setState(() {
                                                    _target += 10;
                                                    Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .saveZikirProfile(_selectedProfile, _count,
                                                            _target, _stack);
                                                  });
                                                },
                                                onPressed: () {
                                                  setState(() {
                                                    _target++;
                                                    Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .saveZikirProfile(_selectedProfile, _count,
                                                            _target, _stack);
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 10,
                                                ),
                                                child: const Icon(Icons.add),
                                              ),
                                              FilledButton.tonal(
                                                onLongPress: () {
                                                  setState(() {
                                                    if (_target != 0) {
                                                      _target -= 10;
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .saveZikirProfile(_selectedProfile,
                                                              _count, _target, _stack);
                                                    }
                                                  });
                                                },
                                                onPressed: () {
                                                  setState(() {
                                                    if (_target != 0) {
                                                      _target--;
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .saveZikirProfile(_selectedProfile,
                                                              _count, _target, _stack);
                                                    }
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 10,
                                                ),
                                                child: const Icon(Icons.remove),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Stack(
                          children: [
                            TextButton(
                              style: ButtonStyle(
                                // ignore: deprecated_member_use
                                overlayColor: MaterialStateProperty.all(Colors.transparent),
                              ),
                              onPressed: () async {
                                setState(() {
                                  _count++;
                                  if (_count >= _target) {
                                    _count = 0;
                                    _stack++;
                                  }
                                });
                                Provider.of<ChangeSettings>(context, listen: false)
                                    .saveZikirProfile(_selectedProfile, _count, _target, _stack);
                                if (Provider.of<ChangeSettings>(context, listen: false).loadVib() ==
                                    true) {
                                  if (_count == 0) {
                                    _vibrateCustom();
                                  } else {
                                    _vibratePhone();
                                  }
                                }
                              },
                              child: Stack(
                                children: [
                                  RotatedBox(
                                    quarterTurns: 3,
                                    child: Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.3), // Gölge rengi ve opaklığı
                                            spreadRadius: 5, // Gölgenin yayılma alanı
                                            blurRadius: 10, // Gölgenin bulanıklığı
                                            offset: const Offset(
                                                0, 5), // Gölgenin yatay ve dikey kayması
                                          ),
                                        ],
                                      ),
                                      child: LinearProgressIndicator(
                                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        value: _count / _target, // İlerleme yüzdesi
                                        minHeight: 4.0, // Göstergenin yüksekliği
                                        backgroundColor:
                                            Theme.of(context).cardColor, // Arka plan rengi
                                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context)
                                            .cardTheme
                                            .color!), // İlerleme çubuğu rengi
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '$_count',
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _selectedProfile != ' '
                                ? Positioned(
                                    right: 20,
                                    top: 20,
                                    child: Card(
                                      color: Theme.of(context).cardColor,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _selectedProfile,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            Positioned(
                              left: 20,
                              top: 15,
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.my_library_books_outlined),
                                offset: const Offset(5, 0),
                                elevation: 10,
                                enabled: true,
                                onSelected: (String result) {
                                  setState(() {
                                    _selectedProfile = result;
                                    Provider.of<ChangeSettings>(context, listen: false)
                                        .saveSelectedProfile(_selectedProfile);
                                    _target = Provider.of<ChangeSettings>(context, listen: false)
                                        .loadZikirSet(_selectedProfile);
                                    _count = Provider.of<ChangeSettings>(context, listen: false)
                                        .loadZikirCount(_selectedProfile);
                                    _stack = Provider.of<ChangeSettings>(context, listen: false)
                                        .loadZikirStack(_selectedProfile);
                                  });
                                },
                                color: Theme.of(context).cardTheme.color!,
                                itemBuilder: (BuildContext context) {
                                  return _profiles.map((String item) {
                                    return PopupMenuItem<String>(
                                      value: item,
                                      child: Card(
                                        color: Theme.of(context).cardColor,
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              item != ' '
                                                  ? Text(
                                                      item,
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold),
                                                    )
                                                  : Container(),
                                              Text(
                                                '${AppLocalizations.of(context)!.popupInfo1} ${Provider.of<ChangeSettings>(context, listen: false).loadZikirStack(item)}',
                                              ),
                                              Text(
                                                  '${AppLocalizations.of(context)!.popupInfo2} ${Provider.of<ChangeSettings>(context, listen: false).loadZikirSet(item)}/${Provider.of<ChangeSettings>(context, listen: false).loadZikirCount(item)}'),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(horizontal: 15.0),
                                                child: SizedBox(
                                                  height: 8,
                                                  child: LinearProgressIndicator(
                                                    borderRadius:
                                                        const BorderRadius.all(Radius.circular(10)),
                                                    value: Provider.of<ChangeSettings>(context,
                                                                listen: false)
                                                            .loadZikirCount(item) /
                                                        Provider.of<ChangeSettings>(context,
                                                                listen: false)
                                                            .loadZikirSet(item), // İlerleme yüzdesi
                                                    minHeight: 4.0, // Göstergenin yüksekliği
                                                    backgroundColor: Colors.grey, // Arka plan rengi
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                        Theme.of(context)
                                                            .cardTheme
                                                            .color!), // İlerleme çubuğu rengi
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 60,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                              AppLocalizations.of(context)!.profileMessageTitle),
                                          content: TextField(
                                            controller: _textFieldController2,
                                            decoration: const InputDecoration(hintText: ''),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(AppLocalizations.of(context)!.leave),
                                            ),
                                            TextButton(
                                              child: Text(AppLocalizations.of(context)!.ok),
                                              onPressed: () {
                                                setState(() {
                                                  if (_textFieldController2.text != '' &&
                                                      _textFieldController2.text.startsWith(' ') ==
                                                          false &&
                                                      _textFieldController2.text.length <= 20) {
                                                    _profiles.add(_textFieldController2.text);
                                                    Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .saveProfiles(_profiles);

                                                    _selectedProfile = _textFieldController2.text;
                                                    Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .saveSelectedProfile(_selectedProfile);
                                                    _target = Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .loadZikirSet(_selectedProfile);
                                                    _count = Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .loadZikirCount(_selectedProfile);
                                                    _stack = Provider.of<ChangeSettings>(context,
                                                            listen: false)
                                                        .loadZikirStack(_selectedProfile);
                                                  }
                                                });
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                icon: const Icon(Icons.edit),
                              ),
                            ),
                            _selectedProfile != ' '
                                ? Positioned(
                                    left: 20,
                                    top: 105,
                                    child: IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(AppLocalizations.of(context)!
                                                    .removeMessageTitle),
                                                content: Text(AppLocalizations.of(context)!
                                                    .removeMessageBody),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child:
                                                        Text(AppLocalizations.of(context)!.leave),
                                                  ),
                                                  TextButton(
                                                    child:
                                                        Text(AppLocalizations.of(context)!.remove),
                                                    onPressed: () {
                                                      _profiles.remove(_selectedProfile);
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .saveProfiles(_profiles);
                                                      setState(() {
                                                        _selectedProfile = ' ';
                                                      });
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .saveSelectedProfile(_selectedProfile);

                                                      _target = Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .loadZikirSet(_selectedProfile);
                                                      _count = Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .loadZikirCount(_selectedProfile);
                                                      _stack = Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .loadZikirStack(_selectedProfile);
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      icon: const Icon(Icons.remove_circle_outline),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
