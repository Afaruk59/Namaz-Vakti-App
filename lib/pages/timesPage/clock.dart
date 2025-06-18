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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'dart:ui' as ui;

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimeData>(context, listen: false).updateTime();
    });

    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        if (DateTime.now().hour == 00 &&
            DateTime.now().minute == 00 &&
            DateTime.now().second == 01) {
          Navigator.popAndPushNamed(context, '/');
        }
        Provider.of<TimeData>(context, listen: false).updateTime();
      }
    });
  }

  final List<String> _prayList = [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ];

  @override
  Widget build(BuildContext context) {
    _prayList[0] = AppLocalizations.of(context)!.timeLeftImsak;
    _prayList[1] = AppLocalizations.of(context)!.timeLeftSabah;
    _prayList[2] = AppLocalizations.of(context)!.timeLeftGunes;
    _prayList[3] = AppLocalizations.of(context)!.timeLeftOgle;
    _prayList[4] = AppLocalizations.of(context)!.timeLeftIkindi;
    _prayList[5] = AppLocalizations.of(context)!.timeLeftAksam;
    _prayList[6] = AppLocalizations.of(context)!.timeLeftYatsi;
    _prayList[7] = AppLocalizations.of(context)!.timeLeftImsak;
    return Provider.of<TimeData>(context).isEnabled == false
        ? IconButton.filledTonal(
            iconSize: 25,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            onPressed: () {
              Navigator.popAndPushNamed(context, '/');
            },
            icon: const Icon(Icons.replay_outlined),
          )
        : Stack(
            children: [
              Card(
                clipBehavior: Clip.hardEdge,
                color: Theme.of(context).cardColor,
                child: SizedBox.expand(
                  child: LinearProgressIndicator(
                    value: (Provider.of<TimeData>(context).mainDifference.inSeconds -
                            Provider.of<TimeData>(context).difference.inSeconds) /
                        Provider.of<TimeData>(context).mainDifference.inSeconds,
                    borderRadius: BorderRadius.circular(
                      Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
                    ),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).cardTheme.color!.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          _prayList[Provider.of<TimeData>(context).pray],
                          style: TextStyle(
                              fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700.0
                                  ? 15.0
                                  : 17.0),
                        ),
                        Provider.of<TimeData>(context).imsak != null
                            ? Directionality(
                                textDirection: ui.TextDirection.ltr,
                                child: Text(
                                  '${(Provider.of<TimeData>(context).difference.inHours).toString().padLeft(2, '0')} : ${(Provider.of<TimeData>(context).difference.inMinutes % 60).toString().padLeft(2, '0')} : ${(Provider.of<TimeData>(context).difference.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize:
                                          Provider.of<ChangeSettings>(context).currentHeight! <
                                                  700.0
                                              ? 15.0
                                              : 17.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : const Text('0'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
