import 'package:flutter/material.dart';

/// Custom Arabic letter icon widget for the Quran app
class ArabicLetterIcon extends StatelessWidget {
  final String letter;
  final double size;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const ArabicLetterIcon({
    Key? key,
    required this.letter,
    this.size = 24.0,
    this.color = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onPressed,
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontFamily: 'ShaikhHamdullahBasicVolt',
                fontSize: size,
                color: color,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}