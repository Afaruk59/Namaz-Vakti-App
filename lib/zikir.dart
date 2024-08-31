import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/main.dart';
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
  static int target = 33;
  static int count = 0;
  static int stack = 0;
  static bool vibration = false;
  TextEditingController _textFieldController = TextEditingController();

  void _vibratePhone() async {
    var isVib = await Vibration.hasVibrator();
    if (isVib ?? false == true && vibration == true) {
      Vibration.vibrate();
    } else {
      print('Device cannot vibrate.');
    }
  }

  void _vibrateCustom() async {
    var isVib = await Vibration.hasCustomVibrationsSupport();
    if (isVib ?? false == true && vibration == true) {
      Vibration.vibrate(pattern: [500, 500]);
    } else {
      print('Device cannot vibrate.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () {
                                          setState(() {
                                            stack = 0;
                                          });
                                        },
                                        child: Icon(Icons.restart_alt),
                                        style: ElevatedButton.styleFrom(elevation: 10),
                                      ),
                                      vibration == true
                                          ? FilledButton.tonal(
                                              onPressed: () {
                                                setState(() {
                                                  vibration = false;
                                                });
                                              },
                                              child: Icon(Icons.vibration),
                                              style: ElevatedButton.styleFrom(elevation: 10),
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  vibration = true;
                                                });
                                              },
                                              child: Icon(Icons.vibration),
                                            ),
                                      Text(
                                        '$stack',
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
                                                              MainAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              textAlign: TextAlign.center,
                                                              'Zikir Sayısı',
                                                              style: TextStyle(fontSize: 17),
                                                            ),
                                                            Divider(
                                                              height: 20,
                                                            ),
                                                            Text(
                                                              textAlign: TextAlign.center,
                                                              '$target',
                                                              style: TextStyle(
                                                                  fontSize: 25,
                                                                  fontWeight: FontWeight.bold),
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
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            FilledButton.tonal(
                                              onPressed: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text('Zikir Sayısı:'),
                                                        content: TextField(
                                                          keyboardType: TextInputType.number,
                                                          inputFormatters: <TextInputFormatter>[
                                                            FilteringTextInputFormatter
                                                                .digitsOnly, // Sadece rakamlar
                                                          ],
                                                          controller: _textFieldController,
                                                          decoration:
                                                              InputDecoration(hintText: '$target'),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            child: Text('OK'),
                                                            onPressed: () {
                                                              if (_textFieldController.text != '' &&
                                                                  _textFieldController.text.length <
                                                                      5) {
                                                                setState(() {
                                                                  target = int.parse(
                                                                      _textFieldController.text);
                                                                });
                                                              }
                                                              Navigator.of(context).pop();
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    });
                                              },
                                              child: Icon(Icons.edit),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 10,
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              onLongPress: () {
                                                setState(() {
                                                  target += 10;
                                                });
                                              },
                                              onPressed: () {
                                                setState(() {
                                                  target++;
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
                                                  if (target != 0) {
                                                    target -= 10;
                                                  }
                                                });
                                              },
                                              onPressed: () {
                                                setState(() {
                                                  if (target != 0) {
                                                    target--;
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
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TextButton(
                          style: ButtonStyle(
                            // ignore: deprecated_member_use
                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: () async {
                            setState(() {
                              count++;
                              if (count >= target) {
                                count = 0;
                                stack++;
                              }
                            });
                            if (count == 0) {
                              _vibrateCustom();
                            } else {
                              _vibratePhone();
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
                                    value: count / target, // İlerleme yüzdesi
                                    minHeight: 4.0, // Göstergenin yüksekliği
                                    backgroundColor: Theme.of(context).cardColor, // Arka plan rengi
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context)
                                        .cardTheme
                                        .color!), // İlerleme çubuğu rengi
                                  ),
                                ),
                              ),
                              Center(
                                  child: Text(
                                '$count',
                                style: TextStyle(fontSize: 40),
                              )),
                            ],
                          ),
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
