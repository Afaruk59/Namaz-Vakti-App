import 'package:blurrycontainer/blurrycontainer.dart';
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
    return Padding(
      padding: padding ? const EdgeInsets.all(2) : EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: BlurryContainer(
          blur: blur ? 15 : 0,
          elevation: 0,
          padding: const EdgeInsets.all(0),
          color: Provider.of<ChangeSettings>(context).isDark == false
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.15),
          borderRadius:
              BorderRadius.circular(Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
          child: child,
        ),
      ),
    );
  }
}
