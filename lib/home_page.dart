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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:namaz_vakti_app/books/screens/book_screen.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/pages/more.dart';
import 'package:namaz_vakti_app/pages/qibla.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:namaz_vakti_app/pages/zikir.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
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
  double _backgroundOffset = 0.5;

  @override
  void initState() {
    super.initState();
    Platform.isAndroid ? _checkForUpdate() : null;
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await _update();
      }
    } on PlatformException catch (e) {
      // Hata kodlarını işle
      if (e.code == 'TASK_FAILURE') {
        final errorCode = e.message;
        if (errorCode != null && errorCode.contains('-6')) {
          // ERROR_INSTALL_NOT_ALLOWED: Düşük batarya, düşük disk alanı vb.
          debugPrint(
              'Güncelleme şu an yapılamıyor: Cihaz durumu uygun değil (düşük batarya/disk alanı)');
        } else {
          debugPrint('Güncelleme hatası: ${e.message}');
        }
      }
    } catch (e) {
      debugPrint('Güncelleme kontrolü hatası: $e');
    }
  }

  Future<void> _update() async {
    try {
      debugPrint('Güncelleme başlatılıyor...');
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      debugPrint('Güncelleme tamamlandı');
    } on PlatformException catch (e) {
      debugPrint('Güncelleme hatası: ${e.message}');
    } catch (e) {
      debugPrint('Güncelleme beklenmeyen hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: OverflowBox(
            maxWidth: double.infinity,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCirc,
              tween: Tween<double>(begin: _backgroundOffset, end: _backgroundOffset),
              builder: (context, animatedOffset, child) {
                return Transform.translate(
                  offset: Offset(
                      (0.5 - animatedOffset) *
                          (MediaQuery.of(context).size.width >= MediaQuery.of(context).size.height
                              ? 0
                              : (MediaQuery.of(context).size.height * 0.6)),
                      0),
                  child: Transform.scale(
                    scale: 4.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            Provider.of<ChangeSettings>(context).isDark
                                ? 'assets/img/wallpaperdark.png'
                                : 'assets/img/wallpaper.png',
                          ),
                          colorFilter: ColorFilter.mode(
                            Provider.of<ChangeSettings>(context).color,
                            BlendMode.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: Center(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  bool isRTL = Provider.of<ChangeSettings>(context, listen: false).langCode == 'ar';
                  _backgroundOffset = isRTL ? (4 - index) * 0.25 : index * 0.25;
                });
              },
              children: const [
                SafeArea(
                  top: false,
                  child: Zikir(),
                ),
                SafeArea(
                  top: false,
                  child: Qibla(),
                ),
                SafeArea(
                  top: false,
                  child: Times(),
                ),
                SafeArea(
                  top: false,
                  child: BookScreen(),
                ),
                SafeArea(
                  top: false,
                  child: More(),
                ),
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
              SizedBox(
                height: (Provider.of<ChangeSettings>(context).currentHeight)! < 700 ? 45 : 55,
                child: _currentIndex == 2
                    ? IconButton.filledTonal(
                        tooltip: AppLocalizations.of(context)!.nav1,
                        iconSize: 28,
                        onPressed: () {
                          _pageController.animateToPage(2,
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        icon: const Icon(Icons.access_time_filled_rounded),
                      )
                    : IconButton.outlined(
                        tooltip: AppLocalizations.of(context)!.nav1,
                        iconSize: 28,
                        onPressed: () {
                          _pageController.animateToPage(2,
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        icon: const Icon(Icons.access_time_rounded),
                      ),
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.menu_book_rounded),
                icon: const Icon(Icons.menu_book_rounded),
                label: AppLocalizations.of(context)!.nav5,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.more_horiz),
                icon: const Icon(Icons.more_horiz),
                label: AppLocalizations.of(context)!.nav4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
