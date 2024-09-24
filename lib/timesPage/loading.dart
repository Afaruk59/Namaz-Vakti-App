import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:provider/provider.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    ChangeSettings.isLocalized = false;
    //FlutterBackgroundService().invoke('stopService');
    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (ChangeSettings.isLocalized) {
        if (mounted) {
          Navigator.pop(context);
          ChangeSettings.isfirst
              ? Navigator.popAndPushNamed(context, '/')
              : Navigator.pushNamed(context, '/');
          Provider.of<ChangeSettings>(context, listen: false).saveFirsttoSharedPref(false);
          //FlutterBackgroundService().startService();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const GradientBack(
      child: PopScope(
        canPop: false,
        child: Scaffold(
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
        ),
      ),
    );
  }
}
