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
  static int? _detailedPray;
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
    _detailedPray = Provider.of<TimeData>(context).detailedPray;
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
                                        color: Provider.of<ChangeSettings>(context).isDark
                                            ? Colors.grey.withValues(alpha: 0.5)
                                            : Colors.white.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          Provider.of<ChangeSettings>(context).rounded == true
                                              ? 50
                                              : 10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.imsak,
                                          style: _detailedPray == 1 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.sabah,
                                          style: _detailedPray == 2 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.gunes,
                                          style: _detailedPray == 3 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.israk,
                                          style: _detailedPray == 4 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.kerahat,
                                          style: _detailedPray == 5 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.ogle,
                                          style: _detailedPray == 6 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.ikindi,
                                          style: _detailedPray == 7 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.asrisani,
                                          style: _detailedPray == 8 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.isfirar,
                                          style: _detailedPray == 9 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.aksam,
                                          style: _detailedPray == 10 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.istibak,
                                          style: _detailedPray == 11 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.yatsi,
                                          style: _detailedPray == 12 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.isaisani,
                                          style: _detailedPray == 13 || _detailedPray == 0
                                              ? textStyleBold
                                              : textStyle,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.kible,
                                          style: textStyle,
                                        ),
                                      ],
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
                                        color: Provider.of<ChangeSettings>(context).isDark
                                            ? Colors.grey.withValues(alpha: 0.5)
                                            : Colors.white.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          Provider.of<ChangeSettings>(context).rounded == true
                                              ? 50
                                              : 10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(_imsak!),
                                          style: _detailedPray == 1 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_sabah!),
                                          style: _detailedPray == 2 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_gunes!),
                                          style: _detailedPray == 3 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_israk!),
                                          style: _detailedPray == 4 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_kerahat!),
                                          style: _detailedPray == 5 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_ogle!),
                                          style: _detailedPray == 6 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_ikindi!),
                                          style: _detailedPray == 7 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_asrisani!),
                                          style: _detailedPray == 8 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_isfirar!),
                                          style: _detailedPray == 9 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_aksam!),
                                          style: _detailedPray == 10 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_istibak!),
                                          style: _detailedPray == 11 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_yatsi!),
                                          style: _detailedPray == 12 ? textStyleBold : textStyle,
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(_isaisani!),
                                          style: _detailedPray == 13 || _detailedPray == 0
                                              ? textStyleBold
                                              : textStyle,
                                        ),
                                        Text(
                                          _kible != null
                                              ? DateFormat('HH:mm').format(_kible!)
                                              : '-',
                                          style: textStyle,
                                        ),
                                      ],
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
