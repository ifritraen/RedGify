import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NeonVectorIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  final VoidCallback? onTap;
  final String? label;
  final Color glowColor;

  const NeonVectorIcon({
    super.key,
    required this.painter,
    this.size = 28,
    this.onTap,
    this.label,
    this.glowColor = AppTheme.primaryNeon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size + 24,
            height: size + 24,
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withAlpha(38),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size, size),
                painter: painter,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// Heart Painter
class HeartPainter extends CustomPainter {
  final bool filled;
  final Color color;

  HeartPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height / 4);
    path.cubicTo(width * 0.2, 0, 0, height * 0.3, width / 2, height);
    path.cubicTo(width, height * 0.3, width * 0.8, 0, width / 2, height / 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Playlist Painter
class PlaylistPainter extends CustomPainter {
  final Color color;

  PlaylistPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Draw three bullet lines
    canvas.drawLine(Offset(width * 0.3, height * 0.3), Offset(width * 0.9, height * 0.3), paint);
    canvas.drawLine(Offset(width * 0.3, height * 0.55), Offset(width * 0.9, height * 0.55), paint);
    canvas.drawLine(Offset(width * 0.3, height * 0.8), Offset(width * 0.65, height * 0.8), paint);

    // Draw points/bullets
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(width * 0.12, height * 0.3), 2.5, dotPaint);
    canvas.drawCircle(Offset(width * 0.12, height * 0.55), 2.5, dotPaint);
    
    // Draw playlist play arrow
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(width * 0.75, height * 0.72)
      ..lineTo(width * 0.9, height * 0.8)
      ..lineTo(width * 0.75, height * 0.88)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Download Painter
class DownloadPainter extends CustomPainter {
  final Color color;

  DownloadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    // Draw tray at the bottom
    canvas.drawLine(Offset(width * 0.1, height * 0.85), Offset(width * 0.1, height * 0.95), paint);
    canvas.drawLine(Offset(width * 0.1, height * 0.95), Offset(width * 0.9, height * 0.95), paint);
    canvas.drawLine(Offset(width * 0.9, height * 0.85), Offset(width * 0.9, height * 0.95), paint);

    // Draw download arrow body
    canvas.drawLine(Offset(width * 0.5, height * 0.1), Offset(width * 0.5, height * 0.65), paint);

    // Draw arrow head
    final headPath = Path()
      ..moveTo(width * 0.3, height * 0.45)
      ..lineTo(width * 0.5, height * 0.65)
      ..lineTo(width * 0.7, height * 0.45);
    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Share Painter
class SharePainter extends CustomPainter {
  final Color color;

  SharePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Draw nodes
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Line from left node to top right
    canvas.drawLine(Offset(width * 0.25, height * 0.5), Offset(width * 0.75, height * 0.25), paint);
    // Line from left node to bottom right
    canvas.drawLine(Offset(width * 0.25, height * 0.5), Offset(width * 0.75, height * 0.75), paint);

    // Draw node circles
    canvas.drawCircle(Offset(width * 0.25, height * 0.5), 4.5, dotPaint);
    canvas.drawCircle(Offset(width * 0.75, height * 0.25), 4.5, dotPaint);
    canvas.drawCircle(Offset(width * 0.75, height * 0.75), 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
