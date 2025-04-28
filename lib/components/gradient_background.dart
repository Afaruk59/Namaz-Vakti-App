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
