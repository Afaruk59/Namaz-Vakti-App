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
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  Color lightenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    HSLColor hslColor = HSLColor.fromColor(color);
    HSLColor lighterHslColor =
        hslColor.withLightness((hslColor.lightness + amount).clamp(0.0, 1.0));
    return lighterHslColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? lightenColor(Provider.of<ChangeSettings>(context).color, 0.05)
                : Provider.of<ChangeSettings>(context).color,
            Theme.of(context).colorScheme.surfaceContainer,
            Provider.of<ChangeSettings>(context).isDark == false
                ? lightenColor(Provider.of<ChangeSettings>(context).color, 0.05)
                : Provider.of<ChangeSettings>(context).color,
          ],
          radius: 3,
          center: Alignment.topLeft,
          stops: const [0.01, 0.5, 1],
          tileMode: TileMode.mirror,
        ),
      ),
      child: child,
    );
  }
}
