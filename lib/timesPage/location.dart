import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/timesPage/loading.dart';

Future<void> firstLoc() async {
  await _LocationState().getCurrentLocation();
}

class Location extends StatefulWidget {
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
                Navigator.popAndPushNamed(context, '/');
              },
            ),
            TextButton(
              child: Text("Konumu Aç"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.popAndPushNamed(context, '/');
                Geolocator.openLocationSettings();
              },
            ),
          ],
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
          builder: (context) => AlertDialog(
            title: Text("Konum İzni Gerekli"),
            content: Text("Bu uygulamanın düzgün çalışabilmesi için konum izni gereklidir."),
            actions: <Widget>[
              TextButton(
                child: Text("Tekrar Dene"),
                onPressed: () async {
                  if (mounted) {
                    Navigator.pop(context);
                    await getCurrentLocation(); // İzin tekrar isteniyor
                  }
                },
              ),
            ],
          ),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return showDialog(
        barrierDismissible: false,
        useRootNavigator: serviceEnabled,
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Konum İzni Gerekli"),
          content: Text(
              "Konum izni kalıcı olarak reddedildi. Devam edebilmek için lütfen ayarlardan izin verin."),
          actions: <Widget>[
            TextButton(
              child: Text("Ayarları Aç"),
              onPressed: () {
                ChangeSettings.isLocalized = true;
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
            ),
          ],
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
          MaterialPageRoute(builder: (context) => Loading()),
        );
        await getCurrentLocation();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: MainApp.currentHeight! < 700.0 ? 20.0 : 22.0),
          Text(
            'Güncelle',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 12.0 : 15.0),
          ),
        ],
      ),
    );
  }
}
