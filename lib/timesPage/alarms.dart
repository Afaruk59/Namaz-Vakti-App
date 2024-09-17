import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';

import '../settings.dart';

class Alarms extends StatefulWidget {
  const Alarms({super.key});

  @override
  State<Alarms> createState() => _AlarmsState();
}

class _AlarmsState extends State<Alarms> {
  @override
  void initState() {
    super.initState();
    FlutterBackgroundService().invoke('stopService');
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBackgroundService().startService();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade300
                : Provider.of<ChangeSettings>(context).color.shade900,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.01, 0.4],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Alarmlar'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
              child: ListView(
                children: [
                  Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: SwitchListTile(
                        title: Text('Bildirim Servisleri'),
                        value: Provider.of<ChangeSettings>(context).isOpen,
                        onChanged: (_) async {
                          Provider.of<ChangeSettings>(context, listen: false).toggleNot();
                          Provider.of<ChangeSettings>(context, listen: false).falseAll();
                        },
                      ),
                    ),
                  ),
                  AlarmSwitch(
                    title: 'İmsak Alarmı',
                    index: 0,
                  ),
                  AlarmSwitch(
                    title: 'Sabah Alarmı',
                    index: 1,
                  ),
                  AlarmSwitch(
                    title: 'Güneş Alarmı',
                    index: 2,
                  ),
                  AlarmSwitch(
                    title: 'Öğle Alarmı',
                    index: 3,
                  ),
                  AlarmSwitch(
                    title: 'İkindi Alarmı',
                    index: 4,
                  ),
                  AlarmSwitch(
                    title: 'Akşam Alarmı',
                    index: 5,
                  ),
                  AlarmSwitch(
                    title: 'Yatsı Alarmı',
                    index: 6,
                  ),
                ],
              ),
            ),
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
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: SwitchListTile(
          title: Text(title),
          value: Provider.of<ChangeSettings>(context).alarmList[index],
          onChanged: (_) async {
            Provider.of<ChangeSettings>(context, listen: false).toggleAlarm(index);
          },
        ),
      ),
    );
  }
}
