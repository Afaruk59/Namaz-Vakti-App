import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/times.dart';

class DetailedTimes extends StatefulWidget {
  DetailedTimes({super.key});

  @override
  State<DetailedTimes> createState() => _DetailedTimesState();
}

class _DetailedTimesState extends State<DetailedTimes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tüm Zamanlar'),
      ),
      body: Padding(
        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
        child: Card(
          child: SizedBox.expand(
            child: Padding(
              padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
              child: Card(
                color: Theme.of(context).cardColor,
                child: detailedTimes(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
