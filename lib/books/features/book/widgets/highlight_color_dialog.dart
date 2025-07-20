// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HighlightColorDialog extends StatelessWidget {
  // Varsayılan renk seçenekleri
  static const List<Color> defaultColors = [
    Color(0xFFFFD700), // Altın sarısı
    Color(0xFF90EE90), // Açık yeşil
    Color(0xFFADD8E6), // Açık mavi
  ];

  final Function(Color) onColorSelected;
  final Offset? position; // Ekranda gösterilecek pozisyon (isteğe bağlı)
  final VoidCallback? onClose; // Dışarı tıklanınca çağrılır
  final double maxWidth;

  const HighlightColorDialog({
    super.key,
    required this.onColorSelected,
    this.position,
    this.onClose,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    double left = position?.dx ?? (screenSize.width / 2 - maxWidth / 2);
    double top = position?.dy ?? (screenSize.height / 2 - 100);
    const double bubbleWidth = 220;
    const double bubbleHeight = 100;
    // Sağdan taşarsa sola kaydır
    if (left + bubbleWidth > screenSize.width) {
      left = screenSize.width - bubbleWidth - 8;
    }
    // Soldan taşarsa sağa kaydır
    if (left < 8) left = 8;
    // Alttan taşarsa yukarı aç
    bool openUp = false;
    if (top + bubbleHeight > screenSize.height) {
      top = (position?.dy ?? screenSize.height / 2) - bubbleHeight - 32;
      openUp = true;
      if (top < 8) top = 8;
    }
    return Stack(
      children: [
        // Dışarı tıklayınca kapansın
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose ?? () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!openUp)
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      CustomPaint(
                        size: const Size(24, 12),
                        painter: _BubbleArrowPainter(),
                      ),
                    ],
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Vurgu Rengi Seçin',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: defaultColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              onColorSelected(color);
                              if (onClose != null) {
                                onClose!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (openUp)
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      Transform.rotate(
                        angle: 3.1416, // 180 derece döndür
                        child: CustomPaint(
                          size: const Size(24, 12),
                          painter: _BubbleArrowPainter(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawShadow(path, Colors.black26, 4, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
