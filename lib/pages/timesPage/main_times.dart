import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/pages/timesPage/clock.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class MainTimes extends StatelessWidget {
  const MainTimes({
    super.key,
  });

  final TextStyle style = const TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Colors.grey, // Kenar rengini belirleyin
                        width: 1.0, // Kenar kalınlığını belirleyin
                      ),
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
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
                          AppLocalizations.of(context)!.ogle,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.ikindi,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.aksam,
                          style: style,
                        ),
                        Text(
                          AppLocalizations.of(context)!.yatsi,
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
                        color: Colors.grey, // Kenar rengini belirleyin
                        width: 1.0, // Kenar kalınlığını belirleyin
                      ),
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
                    ),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).imsak ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).sabah ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).gunes ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ogle ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ikindi ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).aksam ?? DateTime.now()),
                          style: style,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).yatsi ?? DateTime.now()),
                          style: style,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Clock(),
          ),
        ],
      ),
    );
  }
}
