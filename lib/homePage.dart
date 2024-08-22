import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';

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
    _checkWifi();
  }

  void _checkWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (alertOpen == false) {
        _showWifiAlert();
        alertOpen = true;
      }
    } else {
      await SheetsApi.init();
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
        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 3.0 : 8.0),
        child: Column(
          children: [
            homeCard(
              title: 'Vakitler',
              route: '/times',
              img: 'clock.jpg',
            ),
            Expanded(
              child: Row(
                children: [
                  homeCard(
                    title: 'Kıble Pusulası',
                    route: '/qibla',
                    img: 'compass.png',
                  ),
                  homeCard(
                    title: 'Seferi Hesabı',
                    route: '/seferi',
                    img: 'world.jpg',
                  ),
                ],
              ),
            ),
            homeCard(
              title: 'Mübarek Gün ve Geceler',
              route: '/dates',
              img: 'mescidi-nebevi.jpg',
            ),
            homeCard(
              title: 'Faydalı Kitaplar',
              route: '/books',
              img: 'books.jpg',
            ),
            homeCard(
              title: 'Ayarlar',
              route: '/settings',
              img: 'settings.jpg',
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
  final String img;

  const homeCard({
    super.key,
    required this.title,
    required this.route,
    required this.img,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: MainApp.currentHeight! < 700.0 ? 1 : 3),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage('assets/img/$img'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: MainApp.currentHeight! < 700.0 ? 5.0 : 15.0,
                left: MainApp.currentHeight! < 700.0 ? 5.0 : 15.0,
                child: Stack(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: MainApp.currentHeight! < 700.0 ? 17 : 20,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..color = Colors.black,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MainApp.currentHeight! < 700.0 ? 17 : 20,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
