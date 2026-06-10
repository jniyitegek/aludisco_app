import 'package:flutter/material.dart';
import 'app_theme.dart';

class AludiscoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkText;

  const AludiscoLogo({
    super.key,
    required this.size,
    this.showText = false,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.aluCrimson,
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: CustomPaint(
              painter: _LogoNodePainter(),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'ALUDISCO',
            style: TextStyle(
              color: darkText ? AppTheme.aluNavy : Colors.white,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: size * 0.03),
          Text(
            'GROWING PUBLICLY',
            style: TextStyle(
              color: darkText ? AppTheme.aluRed : Colors.white.withOpacity(0.8),
              fontSize: size * 0.12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
        ]
      ],
    );
  }
}

class _LogoNodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.11; // Dot radius

    // Node locations: 1 center, 5 surrounding
    final center = Offset(cx, cy);
    final nodes = [
      Offset(cx, cy - size.height * 0.35), // Top
      Offset(cx - size.width * 0.32, cy - size.height * 0.11), // Top-Left
      Offset(cx + size.width * 0.32, cy - size.height * 0.11), // Top-Right
      Offset(cx - size.width * 0.20, cy + size.height * 0.26), // Bottom-Left
      Offset(cx + size.width * 0.20, cy + size.height * 0.26), // Bottom-Right
    ];

    // Draw lines connecting center to all outer nodes
    for (var node in nodes) {
      canvas.drawLine(center, node, linePaint);
    }

    // Draw center circle
    canvas.drawCircle(center, r * 1.3, paint);

    // Draw outer circles
    for (var node in nodes) {
      canvas.drawCircle(node, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
