import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Location extends StatefulWidget {
  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  double lat = 0;
  double long = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

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
    setState(() {
      lat = position.latitude;
      long = position.longitude;
    });
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konum'),
      ),
      body: Center(
        child: isLoading
            ? Center(
                child: Column(
                  children: [
                    Text('Konum Aranıyor'),
                    CircularProgressIndicator(),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$lat'),
                  Text('$long'),
                  SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
