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
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/calendar.dart';
import 'package:namaz_vakti_app/pages/timesPage/clock.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:namaz_vakti_app/pages/timesPage/daily.dart';
import 'package:namaz_vakti_app/pages/timesPage/detailed_times.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class BottomTimesCard extends StatelessWidget {
  const BottomTimesCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyleBold = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 20 : 25,
      fontWeight: FontWeight.bold,
    );
    TextStyle textStyle = TextStyle(
      fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 16 : 20,
      fontWeight: FontWeight.normal,
    );
    return Center(
      child: Card(
        child: Provider.of<TimeData>(context).isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Provider.of<ChangeSettings>(context).langCode == 'tr' &&
                            Provider.of<ChangeSettings>(context).currentHeight! > 700
                        ? const Expanded(flex: 1, child: Daily())
                        : const SizedBox.shrink(),
                    Expanded(
                      flex: Provider.of<ChangeSettings>(context).langCode == 'tr' &&
                              Provider.of<ChangeSettings>(context).currentHeight! > 700
                          ? 4
                          : 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Theme.of(context).cardColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.imsak,
                                    style: Provider.of<TimeData>(context).pray == 1
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.sabah,
                                    style: Provider.of<TimeData>(context).pray == 2
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.gunes,
                                    style: Provider.of<TimeData>(context).pray == 3
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.ogle,
                                    style: Provider.of<TimeData>(context).pray == 4
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.ikindi,
                                    style: Provider.of<TimeData>(context).pray == 5
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.aksam,
                                    style: Provider.of<TimeData>(context).pray == 6
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.yatsi,
                                    style: Provider.of<TimeData>(context).pray == 7
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              color: Theme.of(context).cardColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).imsak ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 1
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).sabah ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 2
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).gunes ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 3
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).ogle ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 4
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).ikindi ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 5
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).aksam ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 6
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(
                                        Provider.of<TimeData>(context).yatsi ?? DateTime.now()),
                                    style: Provider.of<TimeData>(context).pray == 7
                                        ? textStyleBold
                                        : textStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(flex: 1, child: CalendarBtn()),
                            Expanded(flex: 5, child: Clock()),
                            Expanded(flex: 1, child: DetailedTimesBtn()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
