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
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'dart:ui' as ui;

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TimeData>(context, listen: false).updateTime();
        Provider.of<TimeData>(context, listen: false).updateDetailedTime();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        if (DateTime.now().hour == 00 &&
            DateTime.now().minute == 00 &&
            DateTime.now().second == 01) {
          Navigator.popAndPushNamed(context, '/');
        }
        Provider.of<TimeData>(context, listen: false).updateTime();
        Provider.of<TimeData>(context, listen: false).updateDetailedTime();
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  // Vakitlerin adlarını al (dinamik sıralama)
  String _getPrayerName(BuildContext context, int index) {
    final localizations = AppLocalizations.of(context)!;
    final prayerTimes = Provider.of<TimeData>(context, listen: false).getMainPrayerTimes();

    if (index < 0 || index >= prayerTimes.length) {
      return localizations.timeLeftImsak;
    }

    final prayerName = prayerTimes[index].name;

    // İsim çeviri map'i
    final nameMap = {
      'imsak': localizations.timeLeftImsak,
      'sabah': localizations.timeLeftSabah,
      'gunes': localizations.timeLeftGunes,
      'ogle': localizations.timeLeftOgle,
      'ikindi': localizations.timeLeftIkindi,
      'aksam': localizations.timeLeftAksam,
      'yatsi': localizations.timeLeftYatsi,
    };

    return nameMap[prayerName] ?? localizations.timeLeftImsak;
  }

  @override
  Widget build(BuildContext context) {
    return Provider.of<TimeData>(context).isClockEnabled == false
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SizedBox.expand(
                  child: AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: (Provider.of<TimeData>(context).mainDifference.inSeconds -
                                Provider.of<TimeData>(context).difference.inSeconds) /
                            Provider.of<TimeData>(context).mainDifference.inSeconds,
                        borderRadius: BorderRadius.circular(
                          Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
                        ),
                        backgroundColor: Colors.transparent,
                        valueColor: Provider.of<TimeData>(context).noPray
                            ? AlwaysStoppedAnimation<Color>(
                                Colors.red[600]!.withValues(alpha: _blinkAnimation.value))
                            : AlwaysStoppedAnimation<Color>(
                                Theme.of(context).cardTheme.color!.withValues(alpha: 0.6)),
                      );
                    },
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
                          _getPrayerName(context, Provider.of<TimeData>(context).nextPray),
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
