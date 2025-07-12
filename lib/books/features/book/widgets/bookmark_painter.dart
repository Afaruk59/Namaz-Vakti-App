import 'package:flutter/material.dart';

/// Yer işareti için özel painter
class BookmarkPainter extends CustomPainter {
  final Color color;
  final bool isBookmarked;

  BookmarkPainter({required this.color, required this.isBookmarked});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    // Gölge efekti için
    final shadowPaint = Paint()
      ..color = Colors.black12
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    // Standart bookmark ikonu şekli - tek parça
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width / 2, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    // Önce gölgeyi çiz
    canvas.drawPath(path, shadowPaint);
    // Sonra şekli çiz
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Tam yer işareti için clipper
class FullBookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 10);
    path.lineTo(size.width / 2, size.height - 4);
    path.lineTo(size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Yer işareti için clipper
class BookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width / 2, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Üçgen clipper
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
