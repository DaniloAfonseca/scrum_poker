import 'dart:math' show pi;
import 'package:flutter/material.dart';

class FlipCardAnimation extends StatelessWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final Function()? onTap;

  const FlipCardAnimation({super.key, required this.front, required this.back, required this.isFlipped, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          final isFlipOver = value >= pi / 2;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(value);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFlipOver ? Transform(transform: Matrix4.identity()..rotateY(pi), alignment: Alignment.center, child: back) : front,
          );
        },
      ),
    );
  }
}
