import 'package:flutter/material.dart';
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
