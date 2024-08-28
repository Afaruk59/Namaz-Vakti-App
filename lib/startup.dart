import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoşgeldiniz.'),
      ),
      body: StartupCard(),
    );
  }
}

class StartupCard extends StatelessWidget {
  const StartupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
            child: Card(
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vakitler Namazvakti.com'dan alınmıştır.",
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: Divider(),
                      ),
                      FilledButton.tonal(
                        style: ElevatedButton.styleFrom(elevation: 10),
                        onPressed: () async {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/loading');
                          bool serviceEnabled;
                          serviceEnabled = await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            return showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Konum Erişimi Gerekli"),
                                content: Row(
                                  children: [
                                    Expanded(
                                      child: Text("Devam etmek için lütfen konumu etkinleştirin."),
                                      flex: 3,
                                    ),
                                    Expanded(
                                      child: Icon(
                                        Icons.location_disabled,
                                        size: 45,
                                      ),
                                      flex: 1,
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text("Vazgeç"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.popAndPushNamed(context, '/times');
                                      isFirst.saveFirsttoSharedPref(false);
                                    },
                                  ),
                                  TextButton(
                                    child: Text("Konumu Aç"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.popAndPushNamed(context, '/startup');
                                      Geolocator.openLocationSettings();
                                      isFirst.saveFirsttoSharedPref(false);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                          await firstLoc();
                          isFirst.saveFirsttoSharedPref(false);
                        },
                        child: Text('Tamam'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class isFirst {
  static bool isfirst = true;

  static late SharedPreferences _startup;

  static Future<void> createSharedPrefObject() async {
    _startup = await SharedPreferences.getInstance();
  }

  static void loadFirstFromSharedPref() {
    isfirst = _startup.getBool('startup') ?? true;
    print('First: $isfirst');
  }

  static saveFirsttoSharedPref(bool value) {
    _startup.setBool('startup', value);
    print('First: $isfirst');
  }
}
