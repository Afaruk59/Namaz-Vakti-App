import 'package:flutter/material.dart';

/// FloatingActionButton'un bottom bar ile bütünleşmesi için özel konum sınıfı
class QuranFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation location;
  final double offsetY;

  const QuranFloatingActionButtonLocation(this.location, {this.offsetY = 0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy + offsetY);
  }
}
