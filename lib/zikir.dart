import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class Zikir extends StatelessWidget {
  const Zikir({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Zikir'),
      ),
      body: ZikirCard(),
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
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _textFieldController2 = TextEditingController();
  static String _selectedProfile = 'Varsayılan';
  static List<String> _profiles = ['Varsayılan'];

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
    var isVib = await Vibration.hasVibrator();
    if (isVib ?? false == true) {
      Vibration.vibrate(duration: 50);
    } else {
      print('Device cannot vibrate.');
    }
  }

  void _vibrateCustom() async {
    var isVib = await Vibration.hasCustomVibrationsSupport();
    if (isVib ?? false == true) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    } else {
      print('Device cannot vibrate.');
    }
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
                                    side: BorderSide(
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
                                                  title: Text('Zikiri Sıfırla'),
                                                  content:
                                                      Text('Gerçekten sıfırlamak istiyor musunuz?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('Vazgeç'),
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
                                                      child: Text('Evet'),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                        child: Icon(Icons.restart_alt),
                                        style: ElevatedButton.styleFrom(elevation: 10),
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
                                              child: Icon(Icons.vibration),
                                              style: ElevatedButton.styleFrom(elevation: 10),
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  Provider.of<ChangeSettings>(context,
                                                          listen: false)
                                                      .saveVib(true);
                                                });
                                              },
                                              child: Icon(Icons.vibration),
                                            ),
                                      Text(
                                        '$_stack',
                                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
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
                                        flex: 3,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(
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
                                                            Text(
                                                              textAlign: TextAlign.center,
                                                              'Zikir Sayısı',
                                                              style: TextStyle(fontSize: 17),
                                                            ),
                                                            Divider(
                                                              height: 20,
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                showDialog(
                                                                    context: context,
                                                                    builder:
                                                                        (BuildContext context) {
                                                                      return AlertDialog(
                                                                        title:
                                                                            Text('Zikir Sayısı:'),
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
                                                                            child: Text('Vazgeç'),
                                                                          ),
                                                                          TextButton(
                                                                            child: Text('OK'),
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
                                                                style: TextStyle(
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
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 10.0),
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
                                                child: Icon(Icons.add),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 10,
                                                ),
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
                                                child: Icon(Icons.remove),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 10,
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
                                            offset: Offset(0, 5), // Gölgenin yatay ve dikey kayması
                                          ),
                                        ],
                                      ),
                                      child: LinearProgressIndicator(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                      style: TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _selectedProfile != 'Varsayılan'
                                ? Positioned(
                                    right: 20,
                                    top: 20,
                                    child: Card(
                                      color: Theme.of(context).cardColor,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _selectedProfile,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            Positioned(
                              left: 15,
                              top: 15,
                              child: PopupMenuButton<String>(
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
                                  print("Seçilen: $result");
                                },
                                itemBuilder: (BuildContext context) {
                                  return _profiles.map((String item) {
                                    return PopupMenuItem<String>(
                                      value: item,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item),
                                          Text(
                                            '${Provider.of<ChangeSettings>(context, listen: false).loadZikirStack(item)} - ${Provider.of<ChangeSettings>(context, listen: false).loadZikirSet(item)} / ${Provider.of<ChangeSettings>(context, listen: false).loadZikirCount(item)}',
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          LinearProgressIndicator(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            value: Provider.of<ChangeSettings>(context,
                                                        listen: false)
                                                    .loadZikirCount(item) /
                                                Provider.of<ChangeSettings>(context, listen: false)
                                                    .loadZikirSet(item), // İlerleme yüzdesi
                                            minHeight: 4.0, // Göstergenin yüksekliği
                                            backgroundColor:
                                                Theme.of(context).cardColor, // Arka plan rengi
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context)
                                                    .cardTheme
                                                    .color!), // İlerleme çubuğu rengi
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            Positioned(
                              left: 15,
                              top: 55,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Yeni Profil'),
                                          content: TextField(
                                            controller: _textFieldController2,
                                            decoration: InputDecoration(hintText: ''),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Vazgeç'),
                                            ),
                                            TextButton(
                                              child: Text('OK'),
                                              onPressed: () {
                                                setState(() {
                                                  if (_textFieldController2.text != '' &&
                                                      _textFieldController2.text.startsWith(' ') ==
                                                          false) {
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
                                icon: Icon(Icons.add),
                              ),
                            ),
                            _selectedProfile != 'Varsayılan'
                                ? Positioned(
                                    left: 15,
                                    top: 95,
                                    child: IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Profili Sil'),
                                                content: Text(
                                                    'Gerçekten profili silmek istiyor musunuz?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text('Vazgeç'),
                                                  ),
                                                  TextButton(
                                                    child: Text('Sil'),
                                                    onPressed: () {
                                                      _profiles.remove(_selectedProfile);
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .saveProfiles(_profiles);
                                                      setState(() {
                                                        _selectedProfile = 'Varsayılan';
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
                                      icon: Icon(Icons.remove_circle_outline),
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
