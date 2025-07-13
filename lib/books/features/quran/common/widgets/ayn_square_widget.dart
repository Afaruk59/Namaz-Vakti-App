import 'package:flutter/material.dart';

/// A widget that displays the Arabic letter 'Ayn' (ع) inside a rounded square.
class AynSquareWidget extends StatelessWidget {
  /// The size of the square container.
  final double size;
  
  /// The color of the square container.
  final Color backgroundColor;
  
  /// The color of the text.
  final Color textColor;
  
  /// The border radius of the square container.
  final double borderRadius;
  
  /// The font size of the 'Ayn' letter.
  final double fontSize;

  /// Creates an AynSquareWidget.
  ///
  /// The [size] defaults to 40.0.
  /// The [backgroundColor] defaults to Colors.amber[100].
  /// The [textColor] defaults to Colors.brown[800].
  /// The [borderRadius] defaults to 8.0.
  /// The [fontSize] defaults to 24.0.
  const AynSquareWidget({
    Key? key,
    this.size = 40.0,
    this.backgroundColor = const Color(0xFFFFECB3), // Colors.amber[100]
    this.textColor = const Color(0xFF4E342E), // Colors.brown[800]
    this.borderRadius = 8.0,
    this.fontSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'ع', // Arabic letter 'Ayn'
          style: TextStyle(
            fontFamily: 'ShaikhHamdullahBasicVolt',
            fontSize: fontSize,
            color: textColor,
            height: 1.0, // Adjust line height for better vertical centering
          ),
        ),
      ),
    );
  }
}