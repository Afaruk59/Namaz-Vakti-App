import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/timesPage/loading.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  double lat = 0;
  double long = 0;

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi etkin mi kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("Konum Erişimi Gerekli"),
            content: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Devam etmek için lütfen konumu etkinleştirin."),
                ),
                Expanded(
                  flex: 1,
                  child: Icon(
                    Icons.location_disabled,
                    size: 45,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Vazgeç"),
                onPressed: () {
                  Navigator.pop(context);
                  ChangeSettings.isfirst == true
                      ? Navigator.popAndPushNamed(context, '/startup')
                      : Navigator.popAndPushNamed(context, '/');
                },
              ),
              TextButton(
                child: const Text("Konumu Aç"),
                onPressed: () {
                  Navigator.pop(context);
                  ChangeSettings.isfirst == true
                      ? Navigator.popAndPushNamed(context, '/startup')
                      : Navigator.popAndPushNamed(context, '/');
                  Geolocator.openLocationSettings();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Konum izni kontrol et
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      // İzin tekrar reddedildiyse bir uyarı göster
      if (permission == LocationPermission.denied) {
        if (!mounted) {
          ChangeSettings.isLocalized = true;
          return; // Eğer widget unmounted olduysa fonksiyonu terk et
        }
        return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text("Konum İzni Gerekli"),
              content:
                  const Text("Bu uygulamanın düzgün çalışabilmesi için konum izni gereklidir."),
              actions: <Widget>[
                TextButton(
                  child: const Text("Tekrar Dene"),
                  onPressed: () async {
                    if (mounted) {
                      Navigator.pop(context);
                      await getCurrentLocation(); // İzin tekrar isteniyor
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return showDialog(
        barrierDismissible: false,
        useRootNavigator: serviceEnabled,
        context: context,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("Konum İzni Gerekli"),
            content: const Text(
                "Konum izni kalıcı olarak reddedildi. Devam edebilmek için lütfen ayarlardan izin verin."),
            actions: <Widget>[
              TextButton(
                child: const Text("Ayarları Aç"),
                onPressed: () {
                  ChangeSettings.isLocalized = true;
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Position position =
          // ignore: deprecated_member_use
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      lat = position.latitude;
      long = position.longitude;
      await SheetsApi().searchLoc(lat, long);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: ElevatedButton.styleFrom(elevation: 10),
      onPressed: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loading()),
        );
        await getCurrentLocation();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: MainApp.currentHeight! < 700.0 ? 20.0 : 22.0),
          Text(
            AppLocalizations.of(context)!.locationButtonText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 12.0 : 15.0),
          ),
        ],
      ),
    );
  }
}
