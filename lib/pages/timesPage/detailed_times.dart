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
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class DetailedTimesBtn extends StatelessWidget {
  const DetailedTimesBtn({super.key});

  // Detaylı vakitleri yerelleştirilmiş isimlerle döndür (kronolojik sıralı)
  List<Map<String, dynamic>> _getDetailedPrayerTimesWithNames(BuildContext context) {
    final timeData = Provider.of<TimeData>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    // İsim çeviri map'i
    final nameMap = {
      'geceYarisi': localizations.geceYarisi,
      'teheccud': localizations.teheccud,
      'seher': localizations.seher,
      'imsak': localizations.imsak,
      'sabah': localizations.sabah,
      'gunes': localizations.gunes,
      'israk': localizations.israk,
      'kerahat': localizations.kerahat,
      'ogle': localizations.ogle,
      'ikindi': localizations.ikindi,
      'asrisani': localizations.asrisani,
      'isfirar': localizations.isfirar,
      'aksam': localizations.aksam,
      'istibak': localizations.istibak,
      'yatsi': localizations.yatsi,
      'isaisani': localizations.isaisani,
      'imsak2': localizations.imsak,
    };

    // Sıralanmış vakitleri al ve map'e dönüştür
    final sortedTimes = timeData.getDetailedPrayerTimes().map((prayer) {
      return {
        'name': nameMap[prayer.name] ?? prayer.name,
        'time': prayer.time,
        'index': prayer.index,
      };
    }).toList();

    // Kıble vaktini en sona ekle (sıralamaya dahil edilmez, hiçbir zaman aktif olmaz)
    if (timeData.kible != null) {
      sortedTimes.add({
        'name': localizations.kible,
        'time': timeData.kible,
        'index': -1, // Kıble hiçbir zaman aktif olmayacak (-1 index kullanılmıyor)
      });
    }

    return sortedTimes;
  }

  @override
  Widget build(BuildContext context) {
    final timeData = Provider.of<TimeData>(context);
    final detailedPray = timeData.detailedPray;
    final time = timeData.miladi;
    final prayerTimes = _getDetailedPrayerTimesWithNames(context);
    TextStyle textStyleBold = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 20 : 22,
      fontWeight: FontWeight.bold,
    );
    TextStyle textStyle = TextStyle(
      fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 16 : 18,
      fontWeight: FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: SizedBox.expand(
        child: IconButton.filledTonal(
          iconSize: 25,
          style: IconButton.styleFrom(
            shape: Provider.of<ChangeSettings>(context).rounded == true
                ? const CircleBorder()
                : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
          ),
          icon: const Icon(Icons.menu),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              scrollControlDisabledMaxHeightRatio: 0.8,
              isScrollControlled:
                  Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0
                      ? true
                      : false,
              builder: (BuildContext context) {
                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        time,
                        textAlign: TextAlign.center,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(
                              Provider.of<ChangeSettings>(context).currentHeight! < 700.0
                                  ? 5.0
                                  : 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          Provider.of<ChangeSettings>(context).rounded == true
                                              ? 50
                                              : 10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: prayerTimes.map((prayer) {
                                        final isActive = detailedPray == prayer['index'];
                                        return Text(
                                          prayer['name'],
                                          style: isActive ? textStyleBold : textStyle,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          Provider.of<ChangeSettings>(context).rounded == true
                                              ? 50
                                              : 10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: prayerTimes.map((prayer) {
                                        final isActive = detailedPray == prayer['index'];
                                        final timeStr = prayer['time'] != null
                                            ? DateFormat('HH:mm').format(prayer['time'])
                                            : '-';
                                        return Text(
                                          timeStr,
                                          style: isActive ? textStyleBold : textStyle,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
