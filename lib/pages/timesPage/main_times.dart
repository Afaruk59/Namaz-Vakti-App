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
import 'package:namaz_vakti_app/pages/timesPage/detailed_times.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class BottomTimesCard extends StatelessWidget {
  const BottomTimesCard({
    super.key,
  });

  // Ana vakitleri yerelleştirilmiş isimlerle döndür (kronolojik sıralı)
  List<Map<String, dynamic>> _getMainPrayerTimesWithNames(BuildContext context) {
    final timeData = Provider.of<TimeData>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    // İsim çeviri map'i
    final nameMap = {
      'imsak': localizations.imsak,
      'sabah': localizations.sabah,
      'gunes': localizations.gunes,
      'ogle': localizations.ogle,
      'ikindi': localizations.ikindi,
      'aksam': localizations.aksam,
      'yatsi': localizations.yatsi,
      'imsak2': localizations.imsak,
    };

    // Sıralanmış vakitleri al ve map'e dönüştür
    return timeData.getMainPrayerTimes().map((prayer) {
      return {
        'name': nameMap[prayer.name] ?? prayer.name,
        'time': prayer.time,
        'index': prayer.index,
      };
    }).toList();
  }

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

    final prayerTimes = _getMainPrayerTimesWithNames(context);
    final currentPray = Provider.of<TimeData>(context).pray;

    return Center(
      child: Card(
        child: Provider.of<TimeData>(context).isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: Provider.of<ChangeSettings>(context).langCode == 'tr' &&
                              Provider.of<ChangeSettings>(context).currentHeight! > 700
                          ? 4
                          : 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: prayerTimes.map((prayer) {
                                  // Sıralanmış vakitlerde index direkt karşılaştırılır
                                  final isActive = currentPray == prayer['index'];

                                  return Text(
                                    prayer['name'],
                                    style: isActive ? textStyleBold : textStyle,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: prayerTimes.map((prayer) {
                                  // Sıralanmış vakitlerde index direkt karşılaştırılır
                                  final isActive = currentPray == prayer['index'];

                                  return Text(
                                    DateFormat('HH:mm').format(prayer['time'] ?? DateTime.now()),
                                    style: isActive ? textStyleBold : textStyle,
                                  );
                                }).toList(),
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
