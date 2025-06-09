import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/alarms/alarm_switch.dart';
import 'package:namaz_vakti_app/pages/timesPage/alarms/alarm_voice.dart';
import 'package:namaz_vakti_app/pages/timesPage/alarms/gap_slider.dart';
import 'package:provider/provider.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.title,
    required this.index,
  });
  final String title;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Provider.of<ChangeSettings>(context).notificationsEnabled
        ? Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
            child: Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: Provider.of<ChangeSettings>(context).alarmList[index]
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(title),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation, secondaryAnimation) => AlarmSettings(
                            index: index,
                            title: title,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.fastEaseInToSlowEaseOut;
                            var tween =
                                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ));
                  },
                ),
              ),
            ),
          )
        : Container();
  }
}

class AlarmSettings extends StatelessWidget {
  const AlarmSettings({super.key, required this.index, required this.title});
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      actions: const [],
      title: title,
      background: true,
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(
                Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 15.0),
            child: Provider.of<ChangeSettings>(context).alarmList[index]
                ? Column(
                    children: [
                      AlarmSwitch(index: index),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        child: Divider(
                          thickness: 2,
                          height: 30,
                        ),
                      ),
                      GapSlider(index: index),
                      AlarmVoice(index: index),
                    ],
                  )
                : Column(
                    children: [
                      AlarmSwitch(index: index),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
