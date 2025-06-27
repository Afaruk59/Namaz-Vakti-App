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
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarBtn extends StatelessWidget {
  const CalendarBtn({super.key});
  static String? _day;
  static String? _word;
  static String? _calendar;
  static String? _miladi;

  @override
  Widget build(BuildContext context) {
    _day = Provider.of<TimeData>(context).day;
    _word = Provider.of<TimeData>(context).word;
    _calendar = Provider.of<TimeData>(context).calendar;
    _miladi = Provider.of<TimeData>(context).miladi;
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
          icon: const Icon(Icons.date_range_rounded),
          onPressed: () async {
            showModalBottomSheet(
              context: context,
              isScrollControlled:
                  Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0
                      ? true
                      : false,
              enableDrag: true,
              scrollControlDisabledMaxHeightRatio: 0.8,
              builder: (context) {
                return Scrollbar(
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: EdgeInsets.all(
                          Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
                      child: ListView(
                        children: [
                          Text(
                            _miladi!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            _day!,
                          ),
                          const SizedBox(
                            height: 30,
                            child: Divider(
                              thickness: 3,
                            ),
                          ),
                          Text(
                            _word!,
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Provider.of<ChangeSettings>(context).isDark
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(
                                  Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                _calendar!,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: FilledButton.tonal(
                              onPressed: () async {
                                final Uri url = Uri.parse('https://www.turktakvim.com/');
                                await launchUrl(url);
                              },
                              child: const Text('Turktakvim.com'),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
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
