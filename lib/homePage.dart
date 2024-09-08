import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/more.dart';
import 'package:namaz_vakti_app/qibla.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/timesPage/times.dart';
import 'package:namaz_vakti_app/zikir.dart';

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
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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
              Navigator.of(context).pushNamed('/');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          Times(),
          Qibla(),
          Zikir(),
          Settings(),
          More(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.transparent,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfalar arası geçişi PageView ile kontrol et
          _pageController.animateToPage(index,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.schedule),
            icon: Icon(Icons.schedule),
            label: 'Vakitler',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.navigation),
            icon: Icon(Icons.navigation_outlined),
            label: 'Kıble',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.timer),
            icon: Icon(Icons.timer_outlined),
            label: 'Zikir',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.more_horiz),
            icon: Icon(Icons.more_horiz),
            label: 'Daha Fazla',
          ),
        ],
      ),
    );
  }
}
