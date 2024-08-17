import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class homePage extends StatefulWidget {
  const homePage({
    super.key,
  });

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  Timer? timer;
  static bool alertOpen = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (mounted) {
        _checkWifi();
      }
    });
  }

  void _checkWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (alertOpen == false) {
        _showWifiAlert();
        alertOpen = true;
      }
    }
  }

  void _showWifiAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("İnternet Bağlantısı Gerekli"),
        content: Row(
          children: [
            Expanded(
              child: Text("Devam etmek için lütfen Wi-Fi'yi yada Mobil Veri'yi etkinleştirin."),
              flex: 3,
            ),
            Expanded(
              child: Icon(
                Icons.wifi_off,
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
              alertOpen = false;
              _checkWifi();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Namaz Vakti App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            homeCard(
              title: 'Vakitler',
              route: '/times',
            ),
            Expanded(
              child: Row(
                children: [
                  homeCard(
                    title: 'Kıble Pusulası',
                    route: '/qibla',
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  homeCard(
                    title: 'Seferi Hesabı',
                    route: '/seferi',
                  ),
                ],
              ),
            ),
            homeCard(
              title: 'Mübarek Gün ve Geceler',
              route: '/dates',
            ),
            homeCard(
              title: 'Faydalı Kitaplar',
              route: '/books',
            ),
            homeCard(
              title: 'Ayarlar',
              route: '/settings',
            ),
          ],
        ),
      ),
    );
  }
}

class homeCard extends StatelessWidget {
  final String title;
  final String route;

  const homeCard({
    super.key,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Card(
                child: TextButton(
                  style: ButtonStyle(
                    // ignore: deprecated_member_use
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, route);
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 15,
                        left: 15,
                        child: Text(
                          title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
    );
  }
}
