part of 'celebrity_selection_page.dart';

class _BottomCircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _BottomCircleRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _BottomCircleRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final Path? holePath;

  const _HoleClipper({required this.holePath});

  @override
  Path getClip(Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    if (holePath == null) {
      return overlayPath;
    }
    return Path.combine(PathOperation.difference, overlayPath, holePath!);
  }

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) {
    return holePath != oldClipper.holePath;
  }
}

class _OverlayMaskPainter extends CustomPainter {
  final Color overlayColor;
  final Path? holePath;

  const _OverlayMaskPainter({
    required this.overlayColor,
    required this.holePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (holePath == null) {
      canvas.drawPath(overlayPath, paint);
      return;
    }

    final maskedPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      holePath!,
    );
    canvas.drawPath(maskedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayMaskPainter oldDelegate) {
    return oldDelegate.overlayColor != overlayColor ||
        oldDelegate.holePath != holePath;
  }
}
