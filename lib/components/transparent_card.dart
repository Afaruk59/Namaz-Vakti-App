import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

class TransparentCard extends StatelessWidget {
  const TransparentCard({super.key, required this.child, this.elevation = false});
  final Widget child;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: Provider.of<ChangeSettings>(context).isDark == false
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1), // Şeffaf beyaz
              borderRadius: BorderRadius.circular(
                  Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
