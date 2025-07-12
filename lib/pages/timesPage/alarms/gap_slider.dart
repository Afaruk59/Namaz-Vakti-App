import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class GapSlider extends StatelessWidget {
  const GapSlider({super.key, required this.index});
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
              title: Text(AppLocalizations.of(context)!.gapSliderTitle),
              subtitle: Text(
                '${Provider.of<ChangeSettings>(context).gaps[index].toString()} ${AppLocalizations.of(context)!.minuteAbbreviation}',
              ),
            ),
            Slider(
              value: Provider.of<ChangeSettings>(context).gaps[index].toDouble(),
              min: -60,
              max: 60,
              divisions: 24,
              secondaryTrackValue: 0,
              inactiveColor: Colors.transparent,
              label:
                  '${Provider.of<ChangeSettings>(context).gaps[index].toString()} ${AppLocalizations.of(context)!.minuteAbbreviation}',
              onChanged: (value) {
                Provider.of<ChangeSettings>(context, listen: false).saveGap(index, value.toInt());
              },
            )
          ],
        ),
      ),
    );
  }
}
