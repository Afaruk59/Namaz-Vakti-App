import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings.dart';

class Alarms extends StatelessWidget {
  const Alarms({super.key});

  static void alarmCallback() {
    print('Alarm Tetiklendi!');
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
      ),
    );
  }
}
