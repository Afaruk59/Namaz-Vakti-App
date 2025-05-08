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
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Alarms extends StatefulWidget {
  const Alarms({super.key});

  @override
  State<Alarms> createState() => _AlarmsState();
}

class _AlarmsState extends State<Alarms> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.notificationsPageTitle,
      actions: [],
      gradient: true,
      body: const AlarmsBody(),
    );
  }
}

class AlarmsBody extends StatefulWidget {
  const AlarmsBody({super.key});

  @override
  State<AlarmsBody> createState() => _AlarmsBodyState();
}

class _AlarmsBodyState extends State<AlarmsBody> {
  void _toggleNotificationService(bool enable) async {
    if (!Platform.isAndroid) return;

    if (enable) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        if (result.isDenied && mounted) {
          Provider.of<ChangeSettings>(context, listen: false).toggleNotifications(false);
          return;
        }
      }
    }

    const platform = MethodChannel('com.afaruk59.namaz_vakti_app/notifications');
    try {
      final methodName = enable ? 'startNotificationService' : 'stopNotificationService';
      await platform.invokeMethod(methodName);
    } on PlatformException catch (e) {
      debugPrint('Failed to toggle notification service: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(
              Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
          child: ListView(
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.enableNotifications),
                    subtitle: Text(AppLocalizations.of(context)!.notificationsSubtitle),
                    value: Provider.of<ChangeSettings>(context).notificationsEnabled,
                    onChanged: (value) {
                      Provider.of<ChangeSettings>(context, listen: false)
                          .toggleNotifications(value);
                      _toggleNotificationService(value);
                    },
                  ),
                ),
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.imsakAlarm,
                index: 0,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.morningAlarm,
                index: 1,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.sunriseAlarm,
                index: 2,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.noonAlarm,
                index: 3,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.afternoonAlarm,
                index: 4,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.sunsetAlarm,
                index: 5,
              ),
              AlarmSwitch(
                title: AppLocalizations.of(context)!.nightAlarm,
                index: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlarmSwitch extends StatelessWidget {
  const AlarmSwitch({
    super.key,
    required this.title,
    required this.index,
  });
  final String title;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Provider.of<ChangeSettings>(context).notificationsEnabled
        ? Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      title,
                    ),
                    value: Provider.of<ChangeSettings>(context).alarmList[index],
                    onChanged: (val) async {
                      Provider.of<ChangeSettings>(context, listen: false).toggleAlarm(index);
                    },
                  ),
                  Provider.of<ChangeSettings>(context).alarmList[index] == true
                      ? Slider(
                          value: Provider.of<ChangeSettings>(context).gaps[index].toDouble(),
                          min: -60,
                          max: 60,
                          divisions: 24,
                          secondaryTrackValue: 0,
                          label:
                              '${Provider.of<ChangeSettings>(context).gaps[index].toString()} ${AppLocalizations.of(context)!.minuteAbbreviation}',
                          onChanged: (value) {
                            Provider.of<ChangeSettings>(context, listen: false)
                                .saveGap(index, value.toInt());
                          },
                        )
                      : Container(),
                ],
              ),
            ),
          )
        : Container();
  }
}
