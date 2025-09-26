import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipCard extends StatefulWidget {
  final double height;
  final double width;
  final Color? borderColorOutside;
  final Color? borderColorInside;
  final Color? containerColor;
  final Widget child;
  final bool isFront;
  const FlipCard({
    super.key,
    required this.height,
    required this.width,
    this.borderColorOutside,
    this.borderColorInside,
    this.containerColor,
    required this.child,
    required this.isFront,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.containerColor,
            border: Border.all(width: 1, color: widget.borderColorOutside ?? Colors.blueAccent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget.isFront ? widget.child : CustomPaint(size: Size(widget.width, widget.height), painter: LinePainter(widget.borderColorInside), child: widget.child),
        ),
        if (widget.isFront) ...[
          Positioned(
            top: 10,
            left: 10,
            child: Transform.scale(
              scale: 0.3, // < 1.0 shrinks, > 1.0 enlarges
              alignment: Alignment.topLeft,
              child: widget.child,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Transform.scale(
              scale: 0.3, // < 1.0 shrinks, > 1.0 enlarges
              alignment: Alignment.bottomRight,
              child: Transform.rotate(angle: math.pi, child: widget.child),
            ),
          ),
        ],
      ],
    );
  }
}

class LinePainter extends CustomPainter {
  final Color? _color;

  LinePainter(this._color);

  @override
  void paint(Canvas canvas, Size size) {
    double height = size.height;
    double width = size.width;

    Paint paint = Paint()
      ..color = _color ?? Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    Path path = Path()
      ..moveTo(width * 0.05, height * 0.15)
      ..quadraticBezierTo(width * 0.15, height * 0.15, width * 0.15, height * 0.05)
      ..lineTo(width * 0.85, height * 0.05)
      ..quadraticBezierTo(width * 0.85, height * 0.15, width * 0.95, height * 0.15)
      ..lineTo(width * 0.95, height * 0.85)
      ..quadraticBezierTo(width * 0.85, height * 0.85, width * 0.85, height * 0.95)
      ..lineTo(width * 0.15, height * 0.95)
      ..quadraticBezierTo(width * 0.15, height * 0.85, width * 0.05, height * 0.85)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
