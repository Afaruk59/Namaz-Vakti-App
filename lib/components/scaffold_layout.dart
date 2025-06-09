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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class ScaffoldLayout extends StatelessWidget {
  const ScaffoldLayout(
      {super.key,
      required this.title,
      required this.actions,
      required this.body,
      this.background = false});
  final String title;
  final List<Widget> actions;
  final Widget body;
  final bool background;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        background
            ? ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Provider.of<ChangeSettings>(context).isDark == false
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              )
            : Container(),
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(title),
            actions: actions,
          ),
          body: body,
        )
      ],
    );
  }
}
