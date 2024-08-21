import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
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
                Navigator.of(context).pop();
                _getCurrentLocation();
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
    SheetsApi.searchLat(lat, long);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/loading');
        _getCurrentLocation();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on),
          Text('Güncelle'),
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
    cityName = _local.getString('name') ?? 'Istanbul/Merkez';
    cityState = _local.getString('state') ?? 'Istanbul';
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
