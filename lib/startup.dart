import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:url_launcher/url_launcher.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          "Vakitler Namazvakti.com'dan alınmıştır.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          'Namaz Vakitleri Hakkında Mühim Tenbih',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: FilledButton.tonal(
                          style: ElevatedButton.styleFrom(elevation: 10),
                          onPressed: () async {
                            final Uri url = Uri.parse(
                                'https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
                            await launchUrl(url);
                          },
                          child: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
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
                                  Navigator.popAndPushNamed(context, '/startup');
                                  ChangeSettings.saveFirsttoSharedPref(false);
                                },
                              ),
                              TextButton(
                                child: Text("Konumu Aç"),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.popAndPushNamed(context, '/startup');
                                  Geolocator.openLocationSettings();
                                  ChangeSettings.saveFirsttoSharedPref(false);
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      await firstLoc();
                      ChangeSettings.saveFirsttoSharedPref(false);
                    },
                    child: Text('Devam Et'),
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
