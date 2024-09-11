import 'dart:async';

import 'package:flutter/material.dart';
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
    Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (ChangeSettings.isLocalized) {
        if (mounted) {
          if (ChangeSettings.isfirst == true) {
            Navigator.pop(context);
            Navigator.popAndPushNamed(context, '/');
            Provider.of<ChangeSettings>(context, listen: false).saveFirsttoSharedPref(false);
          } else {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/');
            Provider.of<ChangeSettings>(context, listen: false).saveFirsttoSharedPref(false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }
}
