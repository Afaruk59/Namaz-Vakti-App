import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class TransparentCard extends StatelessWidget {
  const TransparentCard({super.key, required this.child, this.padding = true, this.blur = true});
  final Widget child;
  final bool padding;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return Provider.of<ChangeSettings>(context).blur
        ? Padding(
            padding: padding ? const EdgeInsets.all(3) : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              child: BackdropFilter(
                enabled: blur ? true : false,
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Provider.of<ChangeSettings>(context).isDark == false
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                        Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: child,
                ),
              ),
            ),
          )
        : Card(
            color: Provider.of<ChangeSettings>(context).color,
            child: child,
          );
  }
}
