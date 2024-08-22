import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Location extends StatefulWidget {
  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  double lat = 0;
  double long = 0;

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Konum servisi etkin mi kontrol et
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
              child: Text("Tekrar Dene"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.popAndPushNamed(context, '/times');
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
      if (permission == LocationPermission.denied) {
        return _getCurrentLocation();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _getCurrentLocation();
    }

    // ignore: deprecated_member_use
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    lat = position.latitude;
    long = position.longitude;
    await SheetsApi().searchLoc(lat, long);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () async {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/loading');
        await _getCurrentLocation();
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

class ChangeLocation {
  static String? id;
  static String? cityName;
  static String? cityState;
  static bool isLocalized = false;

  static late SharedPreferences _local;

  Future<void> createSharedPrefObject() async {
    _local = await SharedPreferences.getInstance();
  }

  void loadLocalFromSharedPref() {
    id = _local.getString('location') ?? '16741';
    cityName = _local.getString('name') ?? 'İstanbul Merkez';
    cityState = _local.getString('state') ?? 'İstanbul';
    print('Loaded: $id');
  }

  void saveLocaltoSharedPref(String value, String name, String state) {
    _local.setString('location', value);
    _local.setString('name', name);
    _local.setString('state', state);
    id = value;
    cityName = name;
    cityState = state;
    print('Saved: $id');
    isLocalized = true;
  }
}
