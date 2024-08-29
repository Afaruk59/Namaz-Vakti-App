import 'package:flutter/material.dart';

class Alarms extends StatelessWidget {
  const Alarms({super.key});

  static void alarmCallback() {
    print('Alarm Tetiklendi!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarmlar'),
      ),
    );
  }
}
