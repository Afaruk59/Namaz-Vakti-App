import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class AlarmVoice extends StatelessWidget {
  const AlarmVoice({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.notificationSoundTitle),
              subtitle: Text(
                Provider.of<ChangeSettings>(context).alarmVoices[index] == 0
                    ? AppLocalizations.of(context)!.defaultNotificationSound
                    : Provider.of<ChangeSettings>(context).alarmVoices[index] == 1
                        ? AppLocalizations.of(context)!.defaultAlarmSound
                        : AppLocalizations.of(context)!.ezanSound,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SegmentedButton(
                segments: [
                  const ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.notifications_active_rounded, size: 24),
                  ),
                  const ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.alarm_rounded, size: 24),
                  ),
                  ButtonSegment(
                    value: 2,
                    icon: SvgPicture.asset(
                      'assets/svg/voice_selection.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).buttonTheme.colorScheme!.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
                emptySelectionAllowed: false,
                selected: {Provider.of<ChangeSettings>(context).alarmVoices[index]},
                onSelectionChanged: (Set<int> selected) {
                  Provider.of<ChangeSettings>(context, listen: false)
                      .saveVoice(index, selected.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
