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
import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/pages/more.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

class GradientBack extends StatelessWidget {
  const GradientBack({super.key, required this.child});
  final Widget child;

  Color lightenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    HSLColor hslColor = HSLColor.fromColor(color);
    HSLColor lighterHslColor =
        hslColor.withLightness((hslColor.lightness + amount).clamp(0.0, 1.0));
    return lighterHslColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? lightenColor(Provider.of<ChangeSettings>(context).color, 0.05)
                : Provider.of<ChangeSettings>(context).color,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.01, 0.9],
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
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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
              selectedIcon: const Icon(Icons.access_time_filled_sharp),
              icon: const Icon(Icons.access_time),
              label: AppLocalizations.of(context)!.nav1,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.explore),
              icon: const Icon(Icons.explore_outlined),
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
