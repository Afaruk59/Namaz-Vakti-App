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
import 'package:namaz_vakti_app/components/app_card.dart';
import 'package:namaz_vakti_app/components/lang_selector.dart';
import 'package:namaz_vakti_app/components/tenbih_card.dart';
import 'package:namaz_vakti_app/components/time_note.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
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
      PopScope(
        canPop: false,
        child: Scaffold(
          extendBody: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(AppLocalizations.of(context)!.startupTitle),
          ),
          body: const StartupCard(),
        ),
      ),
    ]);
  }
}

class StartupCard extends StatelessWidget {
  const StartupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MediaQuery.of(context).orientation == Orientation.portrait
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppCard(blur: true),
                SizedBox(
                  height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 0 : 20,
                ),
                const StartupSecondCard(),
              ],
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: AppCard(blur: true)),
                    Expanded(child: StartupSecondCard()),
                  ],
                ),
              ],
            ),
    );
  }
}

class StartupSecondCard extends StatelessWidget {
  const StartupSecondCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: TimeNote(blur: true),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: TenbihCard(pageIndex: 3),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: LangSelector(pageIndex: 4),
        ),
        SizedBox.square(
          dimension: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 0 : 20,
        ),
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
      ],
    );
  }
}
