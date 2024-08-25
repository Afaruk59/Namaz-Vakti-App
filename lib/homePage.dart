import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';

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
  String light = '';
  @override
  void initState() {
    super.initState();
    _checkWifi();
  }

  void _checkLight() {
    if (Provider.of<changeTheme>(context).isDark == false) {
      light = 'light';
    } else {
      light = '';
    }
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
    _checkLight();
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
              img: 'clock$light',
            ),
            Expanded(
              child: Row(
                children: [
                  homeCard(
                    title: 'Kıble Pusulası',
                    route: '/qibla',
                    img: 'compass$light',
                  ),
                  homeCard(
                    title: 'Seferi Hesabı',
                    route: '/seferi',
                    img: 'world$light',
                  ),
                ],
              ),
            ),
            homeCard(
              title: 'Mübarek Gün ve Geceler',
              route: '/dates',
              img: 'mescidi-nebevi$light',
            ),
            homeCard(
              title: 'Faydalı Kitaplar',
              route: '/books',
              img: 'books$light',
            ),
            homeCard(
              title: 'Ayarlar',
              route: '/settings',
              img: 'settings$light',
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
                    image: AssetImage('assets/img/$img.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Gölge rengi ve opaklığı
                      spreadRadius: 5, // Gölgenin yayılma alanı
                      blurRadius: 10, // Gölgenin bulanıklığı
                      offset: Offset(0, 5), // Gölgenin yatay ve dikey kayması
                    ),
                  ],
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
