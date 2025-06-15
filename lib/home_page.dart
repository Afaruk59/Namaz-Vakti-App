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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/components/transparent_card.dart';
import 'package:namaz_vakti_app/pages/more.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? timer;
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          _update();
        }
      });
    }).catchError((e) {
      print(e.toString());
    });
  }

  void _update() async {
    print('Updating');
    await InAppUpdate.startFlexibleUpdate();
    InAppUpdate.completeFlexibleUpdate().then((_) {}).catchError((e) {
      print(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Provider.of<ChangeSettings>(context).color.withValues(alpha: 1),
              BlendMode.color,
            ),
            child: Image.asset(
              Provider.of<ChangeSettings>(context).isDark
                  ? 'assets/img/wallpaperdark.png'
                  : 'assets/img/wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          extendBody: false,
          resizeToAvoidBottomInset: false,
          body: Center(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                Zikir(pageIndex: _currentIndex),
                Qibla(pageIndex: _currentIndex),
                Times(pageIndex: _currentIndex),
                More(pageIndex: _currentIndex),
                Settings(pageIndex: _currentIndex),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
              _pageController.animateToPage(index,
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: const Icon(Icons.timer),
                icon: const Icon(Icons.timer_outlined),
                label: AppLocalizations.of(context)!.nav3,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.explore),
                icon: const Icon(Icons.explore_outlined),
                label: AppLocalizations.of(context)!.nav2,
              ),
              TransparentCard(
                blur: _currentIndex == 2 ? true : false,
                child: SizedBox(
                  height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 50 : 60,
                  child: IconButton(
                    iconSize: 28,
                    onPressed: () {
                      _pageController.animateToPage(2,
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    icon: _currentIndex == 2
                        ? const Icon(Icons.access_time_filled_rounded)
                        : const Icon(Icons.access_time_rounded),
                  ),
                ),
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
      ],
    );
  }
}
