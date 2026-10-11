import 'package:flutter/material.dart';
import '../../theme/color_schemes.dart';

/// A local, resolution-independent landscape: no external image dependency.
class WebBrandPanel extends StatelessWidget {
  const WebBrandPanel({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.brandWash,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _LandscapePainter()),
        Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sage — Route',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandInk,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '循着足迹，读懂一座城。',
                style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
              ),
              Spacer(),
              Text(
                '山水之间\n与历史同行',
                style: TextStyle(
                  fontSize: 44,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandInk,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '从一位人物出发，把故事串成你的旅程。',
                style: TextStyle(fontSize: 15, color: AppColors.brandDark),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w * .76, h * .25),
      w * .08,
      Paint()..color = AppColors.brandSoft,
    );
    for (final layer in [
      (.45, AppColors.brandLight),
      (.56, AppColors.brandSoft),
      (.67, AppColors.brandPale),
    ]) {
      final y = h * layer.$1;
      final path = Path()
        ..moveTo(0, y + h * .08)
        ..cubicTo(w * .2, y - h * .12, w * .3, y + h * .14, w * .48, y)
        ..cubicTo(w * .65, y - h * .15, w * .83, y + h * .09, w, y - h * .05)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.$2);
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * .8, h * .58)
        ..cubicTo(w * .35, h * .68, w * .98, h * .8, w * .55, h),
      Paint()
        ..color = AppColors.brandWash.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) => false;
}
