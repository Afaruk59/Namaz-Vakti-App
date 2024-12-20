/*
Copyright [2024] [Afaruk59]

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

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/pages/more.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/time_data.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/change_settings.dart';

class GradientBack extends StatelessWidget {
  const GradientBack({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade300
                : Provider.of<ChangeSettings>(context).color.shade800,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.01, 0.6],
        ),
      ),
      child: child,
    );
  }
}

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
      Provider.of<TimeData>(context, listen: false).switchClock(true);
      Provider.of<TimeData>(context, listen: false).loadPrayerTimes(DateTime.now());
    }
  }

  void _showWifiAlert() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(AppLocalizations.of(context)!.wifiMessageTitle),
          content: Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context)!.wifiMessageBody),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(AppLocalizations.of(context)!.wifiMessageBody2),
                    ],
                  ),
                ),
              ),
              const Expanded(
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
              child: Text(AppLocalizations.of(context)!.retry),
              onPressed: () {
                Navigator.pop(context);
                alertOpen = false;
                _checkWifi();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageView(
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
            // Sayfalar arası geçişi PageView ile kontrol et
            _pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: const Icon(Icons.schedule),
              icon: const Icon(Icons.schedule),
              label: AppLocalizations.of(context)!.nav1,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.navigation),
              icon: const Icon(Icons.navigation_outlined),
              label: AppLocalizations.of(context)!.nav2,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.timer),
              icon: const Icon(Icons.timer_outlined),
              label: AppLocalizations.of(context)!.nav3,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.more_horiz),
              icon: const Icon(Icons.more_horiz),
              label: AppLocalizations.of(context)!.nav4,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.settings),
              icon: const Icon(Icons.settings_outlined),
              label: AppLocalizations.of(context)!.nav5,
            ),
          ],
        ),
      ),
    );
  }
}
