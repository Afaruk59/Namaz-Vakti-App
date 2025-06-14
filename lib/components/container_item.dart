import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class ContainerItem extends StatelessWidget {
  const ContainerItem({super.key, required this.child, this.color = Colors.transparent});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10,
            ),
            border: Border.all(
                color: Provider.of<ChangeSettings>(context).isDark == false
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}
