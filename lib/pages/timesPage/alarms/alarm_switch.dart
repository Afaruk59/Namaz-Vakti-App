import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/components/container_item.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:provider/provider.dart';

class AlarmSwitch extends StatelessWidget {
  const AlarmSwitch({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return ContainerItem(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: SwitchListTile(
          title: Text(
            Provider.of<ChangeSettings>(context).alarmList[index]
                ? AppLocalizations.of(context)!.on
                : AppLocalizations.of(context)!.off,
          ),
          value: Provider.of<ChangeSettings>(context).alarmList[index],
          onChanged: (val) async {
            Provider.of<ChangeSettings>(context, listen: false).toggleAlarm(index);
          },
        ),
      ),
    );
  }
}
