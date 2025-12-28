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
  int _currentPage = 0;

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
                _currentPage = index;
                // 6 sayfa var (0-5), her sayfada arka plan offset'i değişsin
                // Arapça için ters yönde hareket (RTL desteği)
                bool isRTL = Provider.of<ChangeSettings>(context, listen: false).langCode == 'ar';
                _backgroundOffset = isRTL ? (5 - index) * 0.2 : index * 0.2;
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
              size: const Size.square(8.0),
              activeSize: const Size(16.0, 8.0),
              spacing: const EdgeInsets.symmetric(horizontal: 3.0),
              color: Colors.white.withValues(alpha: 0.5),
              activeColor: Colors.white,
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            controlsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
        ),
      ],
    );
  }

  List<PageViewModel> _buildPages(BuildContext context) {
    return [
      // 1. Hoş Geldiniz + AppCard + Dil Seçici
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.startupTitle),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 0,
          currentPage: _currentPage,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.startupWelcome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                const AppCard(),
                const SizedBox(height: 30),
                // Dil seçiciyi alt kısma ekledik
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: LangSelector(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 2. Vakitler Kaynağı + Tenbih Kartı
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.importantInfo),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 1,
          currentPage: _currentPage,
          child: const SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Vakitler namazvakti.com'dan alınmıştır
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: TimeNote(),
                ),
                SizedBox(height: 10),
                // Tenbih Kartı
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: TenbihCard(),
                ),
              ],
            ),
          ),
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 3. Namaz Vakitleri Özellikleri
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.timesPageTitle),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 2,
          currentPage: _currentPage,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.access_time,
                  AppLocalizations.of(context)!.timesFeature1,
                  AppLocalizations.of(context)!.timesFeature1Desc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.alarm,
                  AppLocalizations.of(context)!.timesFeature2,
                  AppLocalizations.of(context)!.timesFeature2Desc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.calendar_today,
                  AppLocalizations.of(context)!.timesFeature3,
                  AppLocalizations.of(context)!.timesFeature3Desc,
                ),
              ],
            ),
          ),
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 4. Kıble & Zikir Özellikleri
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.spiritualFeatures),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 3,
          currentPage: _currentPage,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.explore,
                  AppLocalizations.of(context)!.qiblaFeature,
                  AppLocalizations.of(context)!.qiblaFeatureDesc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.map,
                  AppLocalizations.of(context)!.qiblaFeature2,
                  AppLocalizations.of(context)!.qiblaFeature2Desc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.mosque,
                  AppLocalizations.of(context)!.qiblaFeature3,
                  AppLocalizations.of(context)!.qiblaFeature3Desc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.timer,
                  AppLocalizations.of(context)!.zikirFeature,
                  AppLocalizations.of(context)!.zikirFeatureDesc,
                ),
              ],
            ),
          ),
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 5. Kitaplar & Dini Günler Özellikleri
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.contentFeatures),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 4,
          currentPage: _currentPage,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.auto_stories,
                  AppLocalizations.of(context)!.quranFeature,
                  AppLocalizations.of(context)!.quranFeatureDesc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.menu_book_rounded,
                  AppLocalizations.of(context)!.booksFeature,
                  AppLocalizations.of(context)!.booksFeatureDesc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.headphones,
                  AppLocalizations.of(context)!.audioFeature,
                  AppLocalizations.of(context)!.audioFeatureDesc,
                ),
                _buildFeatureCard(
                  context,
                  Icons.event,
                  AppLocalizations.of(context)!.datesFeature,
                  AppLocalizations.of(context)!.datesFeatureDesc,
                ),
              ],
            ),
          ),
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),

      // 6. Konum Seçimi (Değişiklik Yok)
      PageViewModel(
        titleWidget: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context)!.searchTitle),
        ),
        bodyWidget: AnimatedPageContent(
          pageIndex: 5,
          currentPage: _currentPage,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.location_on,
                  AppLocalizations.of(context)!.locationFeatureTitle,
                  AppLocalizations.of(context)!.locationDescription,
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
        ),
        decoration: const PageDecoration(
          contentMargin: EdgeInsets.symmetric(horizontal: 20),
          pageColor: Colors.transparent,
          bodyFlex: 3,
        ),
      ),
    ];
  }

  // Özellik kartı oluşturan yardımcı metod
  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
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

// Animasyonlu sayfa içeriği widget'ı
class AnimatedPageContent extends StatefulWidget {
  final Widget child;
  final int pageIndex;
  final int currentPage;

  const AnimatedPageContent({
    super.key,
    required this.child,
    required this.pageIndex,
    required this.currentPage,
  });

  @override
  State<AnimatedPageContent> createState() => _AnimatedPageContentState();
}

class _AnimatedPageContentState extends State<AnimatedPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.pageIndex == widget.currentPage) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage == widget.pageIndex && oldWidget.currentPage != widget.pageIndex) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
