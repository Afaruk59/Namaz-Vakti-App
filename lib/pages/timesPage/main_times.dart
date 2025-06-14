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
import 'package:namaz_vakti_app/components/container_item.dart';
import 'package:namaz_vakti_app/pages/timesPage/calendar.dart';
import 'package:namaz_vakti_app/pages/timesPage/clock.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:namaz_vakti_app/pages/timesPage/detailed_times.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class MainTimes extends StatelessWidget {
  const MainTimes({
    super.key,
  });

  final TextStyle style = const TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: ContainerItem(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.imsak,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.sabah,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.gunes,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.ogle,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.ikindi,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.aksam,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.yatsi,
                          style: style,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ContainerItem(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).imsak ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).sabah ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).gunes ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ogle ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ikindi ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).aksam ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).yatsi ?? DateTime.now()),
                          style: style,
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
                  Expanded(flex: 1, child: DetailedTimesBtn()),
                  Expanded(flex: 5, child: Clock()),
                  Expanded(flex: 1, child: CalendarBtn()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
