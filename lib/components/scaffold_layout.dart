import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/components/gradient_background.dart';

class ScaffoldLayout extends StatelessWidget {
  const ScaffoldLayout(
      {super.key,
      required this.title,
      required this.actions,
      required this.body,
      required this.gradient});
  final String title;
  final List<Widget> actions;
  final Widget body;
  final bool gradient;
  @override
  Widget build(BuildContext context) {
    return gradient
        ? GradientBackground(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: Text(title),
                actions: actions,
              ),
              body: body,
            ),
          )
        : Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(title),
              actions: actions,
            ),
            body: body,
          );
  }
}
