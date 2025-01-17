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

class CityNameCard extends StatefulWidget {
  const CityNameCard({super.key});

  @override
  State<CityNameCard> createState() => _CityNameCardState();
}

class _CityNameCardState extends State<CityNameCard> {
  static String? cityName;
  @override
  void initState() {
    super.initState();
    cityName = ChangeSettings.cityName;
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<TimeData>(context).cityState = ChangeSettings.cityState;
    Provider.of<TimeData>(context).city = ChangeSettings.cityName;
    return Padding(
      padding:
          EdgeInsets.all(Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${Provider.of<TimeData>(context).cityState}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(
            width: 100.0,
            child: Divider(
              height: 20.0,
            ),
          ),
          Text(
            '$cityName',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
