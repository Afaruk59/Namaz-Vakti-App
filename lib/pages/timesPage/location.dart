/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:provider/provider.dart';

class Location extends StatefulWidget {
  const Location({super.key, required this.title});
  final String title;

  @override
  LocationState createState() => LocationState();
}

class LocationState extends State<Location> {
  double lat = 0;
  double long = 0;
  bool progress = false;
  static bool first = true;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Dünya'nın yarıçapı (kilometre)

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

// Dereceyi radyana çeviren yardımcı fonksiyon
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi etkin mi kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() {
        progress = false;
      });
      return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.locationMessageTitle),
            content: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(AppLocalizations.of(context)!.locationMessageBody),
                ),
                const Expanded(
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
                child: Text(AppLocalizations.of(context)!.leave),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.openLoc),
                onPressed: () {
                  Navigator.pop(context);
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
          return; // Eğer widget unmounted olduysa fonksiyonu terk et
        }
        return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(AppLocalizations.of(context)!.permissionMessageTitle),
              content: Text(AppLocalizations.of(context)!.permissionMessageBody),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.retry),
                  onPressed: () async {
                    if (mounted) {
                      setState(() {
                        progress = true;
                      });
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

    if (permission == LocationPermission.deniedForever && mounted) {
      return showDialog(
        barrierDismissible: false,
        useRootNavigator: serviceEnabled,
        context: context,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.permissionMessageTitle),
            content: Text(AppLocalizations.of(context)!.permissionDeniedBody),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.openSettings),
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
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
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      long = position.longitude;

      await findCity();
    }
  }

  Future<void> findCity() async {
    final String csvData = await rootBundle.loadString("assets/cities/cities.csv");

    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
      eol: '\n', // Satır sonu ayırıcı
      fieldDelimiter: ',',
    ).convert(csvData);

    List<dynamic> column1Data = [];
    List<dynamic> column2Data = [];
    List<dynamic> column3Data = [];
    List<dynamic> column5Data = [];
    List<dynamic> column6Data = [];

    for (var row in rowsAsListOfValues) {
      if (row.isNotEmpty) {
        column1Data.add(row[0]);
        column2Data.add(row[1]);
        column3Data.add(row[2]);
        column5Data.add(row[4]);
        column6Data.add(row[5]);
      }
    }

    int index = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < column5Data.length; i++) {
      double distance = calculateDistance(lat, long, double.parse(column5Data[i].toString()),
          double.parse(column6Data[i].toString()));

      if (distance < minDistance) {
        minDistance = distance;
        index = i;
      }
    }

    String cityId = column1Data[index].toString();
    String cityName = column2Data[index].toString();
    String stateName = column3Data[index].toString();

    if (mounted) {
      Provider.of<ChangeSettings>(context, listen: false)
          .saveLocaltoSharedPref(cityId, cityName, stateName);
      Provider.of<ChangeSettings>(context, listen: false).isfirst == true
          ? Navigator.pop(context)
          : Navigator.popAndPushNamed(context, '/');
      Provider.of<ChangeSettings>(context, listen: false).saveFirsttoSharedPref(false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (Provider.of<ChangeSettings>(context, listen: false).otoLocal && first == true) {
      searchLocation();
    }
  }

  void searchLocation() async {
    setState(() {
      progress = true;
      first = false;
    });
    await getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Provider.of<ChangeSettings>(context, listen: false).changeOtoLoc(true);
        searchLocation();
      },
      child: progress == true
          ? const CircularProgressIndicator()
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on),
                  Text(widget.title),
                ],
              ),
            ),
    );
  }
}
