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

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:namaz_vakti_app/components/app_card.dart';
import 'package:namaz_vakti_app/components/lang_selector.dart';
import 'package:namaz_vakti_app/components/tenbih_card.dart';
import 'package:namaz_vakti_app/components/time_note.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

class Startup extends StatefulWidget {
  const Startup({super.key});

  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  double _backgroundOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Arka plan görseli - home_page.dart gibi animasyonlu
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
                    0,
                  ),
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
        // Introduction Screen
        PopScope(
          canPop: false,
          child: IntroductionScreen(
            globalBackgroundColor: Colors.transparent,
            pages: _buildPages(context),
            onChange: (index) {
              setState(() {
                // 5 sayfa var (0-4), her sayfada arka plan offset'i değişsin
                // Arapça için ters yönde hareket (RTL desteği)
                bool isRTL = Provider.of<ChangeSettings>(context, listen: false).langCode == 'ar';
                _backgroundOffset = isRTL ? (4 - index) * 0.25 : index * 0.25;
              });
            },
            onDone: () {
              Provider.of<ChangeSettings>(context, listen: false).saveFirsttoSharedPref(false);
              Navigator.pop(context);
              Navigator.popAndPushNamed(context, '/');
            },
            showSkipButton: true,
            showDoneButton: false,
            skip: Text(
              AppLocalizations.of(context)!.skip,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            next: const Icon(Icons.arrow_forward, color: Colors.white),
            dotsDecorator: DotsDecorator(
              size: const Size.square(10.0),
              activeSize: const Size(20.0, 10.0),
              color: Colors.white.withValues(alpha: 0.5),
              activeColor: Colors.white,
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            controlsPadding: const EdgeInsets.all(16.0),
          ),
        ),
      ],
    );
  }

  List<PageViewModel> _buildPages(BuildContext context) {
    return [
      // 1. Hoş Geldiniz + AppCard
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.startupTitle),
        ),
        bodyWidget: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Namaz Vakti uygulamasına hoş geldiniz. İslami yaşantınızı kolaylaştırmak için buradayız.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const AppCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        decoration: PageDecoration(
          contentMargin: const EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 2. Dil Seçimi
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.ln),
        ),
        bodyWidget: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Uygulamayı kullanmak istediğiniz dili seçin.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: LangSelector(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        decoration: PageDecoration(
          contentMargin: const EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 3. Zaman Notu Ayarları
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Vakit Hesaplama"),
        ),
        bodyWidget: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.startupDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TimeNote(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        decoration: PageDecoration(
          contentMargin: const EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 4. Bildirim Ayarları
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.notificationsPageTitle),
        ),
        bodyWidget: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Namaz vakitleri için bildirim ayarlarınızı yapın.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TenbihCard(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        decoration: PageDecoration(
          contentMargin: const EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 5. Konum Seçimi
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.searchTitle),
        ),
        bodyWidget: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Namaz vakitlerini doğru hesaplayabilmek için konumunuzu seçin.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Location(
                          title: AppLocalizations.of(context)!.locationButtonTextonStart,
                        ),
                      ),
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const SearchButton(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        decoration: PageDecoration(
          contentMargin: const EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),
    ];
  }
}
