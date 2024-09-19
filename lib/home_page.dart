import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/api/sheets_api.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/more.dart';
import 'package:namaz_vakti_app/qibla.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/timesPage/times.dart';
import 'package:namaz_vakti_app/zikir.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("İnternet Bağlantısı Gerekli"),
          content: const Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
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
              ),
              Expanded(
                flex: 1,
                child: Icon(
                  Icons.wifi_off,
                  size: 45,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Tekrar Dene"),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GradientBack(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            Times(),
            Qibla(),
            Zikir(),
            More(),
            Settings(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: MainApp.currentHeight! < 700.0 ? 55 : 65,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfalar arası geçişi PageView ile kontrol et
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
            selectedIcon: Icon(Icons.more_horiz),
            icon: Icon(Icons.more_horiz),
            label: 'Daha Fazla',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
