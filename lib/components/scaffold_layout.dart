/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
