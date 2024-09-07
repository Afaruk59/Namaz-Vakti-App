import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
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
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text("İnternet Bağlantısı Gerekli"),
        content: Row(
          children: [
            Expanded(
              child: Container(
                height: 100,
                child: Column(
                  children: [
                    Text("Devam etmek için lütfen Wi-Fi'yi yada Mobil Veri'yi etkinleştirin."),
                    SizedBox(
                      height: 20,
                    ),
                    Text('(Servisler internet olmadan düzgün çalışmayacaktır.)'),
                  ],
                ),
              ),
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
              Navigator.pop(context);
              alertOpen = false;
              _checkWifi();
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/times');
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
        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 0.0 : 5.0),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: homeCard(
                title: 'Vakitler',
                route: '/times',
                img: 'clock',
              ),
            ),
            Carousel(),
            Expanded(
              flex: 3,
              child: homeCard(
                title: 'Faydalı Kaynaklar',
                route: '/books',
                img: 'books',
              ),
            ),
            Expanded(
              flex: 3,
              child: homeCard(
                title: 'Ayarlar',
                route: '/settings',
                img: 'settings',
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Card(
                  child: SizedBox.expand(
                    child: Center(
                      child: Text('apk ver: 18'),
                    ),
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

class homeCard extends StatefulWidget {
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
  State<homeCard> createState() => _homeCardState();
}

class _homeCardState extends State<homeCard> {
  static String light = '';
  void _checkLight() {
    if (Provider.of<ChangeSettings>(context).isDark == false) {
      light = 'light';
    } else {
      light = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkLight();
    return Container(
      margin: EdgeInsets.symmetric(vertical: MainApp.currentHeight! < 700.0 ? 1 : 3),
      child: TextButton(
        style: ButtonStyle(
          // ignore: deprecated_member_use
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: () {
          Navigator.pushNamed(context, widget.route);
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage('assets/img/${widget.img}${light}.jpg'),
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
              child: Container(
                width: 160,
                child: Stack(
                  children: [
                    Text(
                      widget.title,
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
                      widget.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MainApp.currentHeight! < 700.0 ? 17 : 20,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Carousel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CarouselState();
  }
}

class _CarouselState extends State<Carousel> {
  final CarouselSliderController _controller = CarouselSliderController();

  List<Widget> list = [
    homeCard(
      title: 'Kıble Pusulası',
      route: '/qibla',
      img: 'compass',
    ),
    homeCard(
      title: 'Zikir',
      route: '/zikir',
      img: 'zikir',
    ),
    homeCard(
      title: 'Kaza Takibi',
      route: '/kaza',
      img: 'kaza',
    ),
    homeCard(
      title: 'Mübarek Günler ve Geceler',
      route: '/dates',
      img: 'mescidi-nebevi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: CarouselSlider(
        items: list,
        options: CarouselOptions(
          autoPlayInterval: Duration(seconds: 8),
          autoPlayAnimationDuration: Duration(seconds: 2),
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlay: true,
        ),
        carouselController: _controller,
      ),
    );
  }
}
