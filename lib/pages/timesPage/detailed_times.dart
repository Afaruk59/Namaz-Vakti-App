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
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class DetailedTimesBtn extends StatelessWidget {
  const DetailedTimesBtn({super.key});

  static DateTime? _imsak;
  static DateTime? _sabah;
  static DateTime? _gunes;
  static DateTime? _ogle;
  static DateTime? _ikindi;
  static DateTime? _aksam;
  static DateTime? _yatsi;
  static DateTime? _israk;
  static DateTime? _kerahat;
  static DateTime? _asrisani;
  static DateTime? _isfirar;
  static DateTime? _istibak;
  static DateTime? _isaisani;
  static DateTime? _kible;
  static String? _time;
  final TextStyle style = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    _imsak = Provider.of<TimeData>(context).imsak;
    _sabah = Provider.of<TimeData>(context).sabah;
    _gunes = Provider.of<TimeData>(context).gunes;
    _ogle = Provider.of<TimeData>(context).ogle;
    _ikindi = Provider.of<TimeData>(context).ikindi;
    _aksam = Provider.of<TimeData>(context).aksam;
    _yatsi = Provider.of<TimeData>(context).yatsi;
    _israk = Provider.of<TimeData>(context).israk;
    _kerahat = Provider.of<TimeData>(context).kerahat;
    _asrisani = Provider.of<TimeData>(context).asrisani;
    _isfirar = Provider.of<TimeData>(context).isfirar;
    _istibak = Provider.of<TimeData>(context).istibak;
    _isaisani = Provider.of<TimeData>(context).isaisani;
    _kible = Provider.of<TimeData>(context).kible;
    _time = Provider.of<TimeData>(context).miladi;
    return IconButton(
      iconSize: 25,
      icon: const Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          backgroundColor: Theme.of(context).cardTheme.color,
          context: context,
          showDragHandle: true,
          scrollControlDisabledMaxHeightRatio: 0.8,
          elevation: 10,
          isScrollControlled:
              Provider.of<ChangeSettings>(context, listen: false).currentHeight! < 700.0
                  ? true
                  : false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Provider.of<ChangeSettings>(context, listen: false).rounded == true ? 50 : 10,
            ),
          ),
          builder: (BuildContext context) {
            return Card(
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    _time!,
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(
                          Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
                                ),
                              ),
                              color: Theme.of(context).cardColor,
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
                                    AppLocalizations.of(context)!.israk,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.kerahat,
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
                                    AppLocalizations.of(context)!.asrisani,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.isfirar,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.aksam,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.istibak,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.yatsi,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.isaisani,
                                    style: style,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.kible,
                                    style: style,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
                                ),
                              ),
                              color: Theme.of(context).cardColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(_imsak!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_sabah!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_gunes!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_israk!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_kerahat!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_ogle!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_ikindi!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_asrisani!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_isfirar!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_aksam!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_istibak!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_yatsi!),
                                    style: style,
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(_isaisani!),
                                    style: style,
                                  ),
                                  Text(
                                    _kible != null ? DateFormat('HH:mm').format(_kible!) : '-',
                                    style: style,
                                  ),
                                ],
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
    );
  }
}
