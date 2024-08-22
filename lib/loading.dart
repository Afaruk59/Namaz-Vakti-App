import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/location.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    ChangeLocation.isLocalized = false;
    Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (ChangeLocation.isLocalized) {
        if (mounted) {
          Navigator.popAndPushNamed(context, '/times');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Konum Aranıyor'),
            SizedBox(
              height: 20,
            ),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
