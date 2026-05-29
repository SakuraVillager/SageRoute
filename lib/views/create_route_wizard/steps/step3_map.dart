import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/color_schemes.dart';

/// Step 3 of CreateRouteWizard — map exploration.
///
/// Matches the Web wizard step more closely:
/// - Large abstract map canvas with grid and contour-style lines
/// - Two prominent location markers
/// - Bottom information card describing the discovered locations
///
/// The map remains interaction-light and feeds selected location IDs back to
/// the parent wizard so the next button can still be gated.
class Step3Map extends StatelessWidget {
  final List<String> selectedLocations;
  final ValueChanged<List<String>> onLocationsChanged;

  const Step3Map({
    super.key,
    this.selectedLocations = const [],
    required this.onLocationsChanged,
  });

  void _toggleLocation(String id) {
    final updated = List<String>.from(selectedLocations);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    onLocationsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '探索地图',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.sageText,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMapSection(),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '可点击地图上的地点标记进行选择',
              style: TextStyle(fontSize: 14, color: AppColors.sageMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    // Two featured markers, mirroring the Web step.
    const markers = <_MapMarker>[
      _MapMarker(id: 'bai-causeway', name: '白堤', fx: 0.28, fy: 0.32),
      _MapMarker(id: 'lingyin-temple', name: '灵隐寺', fx: 0.72, fy: 0.50),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const mapH = 320.0;
        final mapW = constraints.maxWidth;

        return Container(
          height: mapH,
          width: mapW,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0EA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sageBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Grid background
              CustomPaint(size: Size(mapW, mapH), painter: _GridPainter()),
              // Contour-style decorative paths (web-like topographic lines)
              Positioned.fill(child: CustomPaint(painter: _ContourPainter())),
              // Map markers
              ...markers.map((m) {
                final isSel = selectedLocations.contains(m.id);
                final x = m.fx * mapW - 14;
                final y = m.fy * mapH - 30;
                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTap: () => _toggleLocation(m.id),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.sageBorder),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${m.name}${isSel ? ' · 选中' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sageText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFC37153)
                                  : const Color(0xFF84A98C),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=300',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '已为您找到相关地点',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sageText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '路线涵盖了历史名人的重要史迹，您可以点击地图上的标记进行预览。',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.sageMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lightweight model for a map marker position.
class _MapMarker {
  final String id;
  final String name;
  final double fx;
  final double fy;

  const _MapMarker({
    required this.id,
    required this.name,
    required this.fx,
    required this.fy,
  });
}

/// Paints subtle grid lines on the abstract map canvas.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sageBorder.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const cols = 4;
    const rows = 4;

    for (int i = 0; i <= cols; i++) {
      final x = size.width * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 0; i <= rows; i++) {
      final y = size.height * i / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gentle contour lines to mimic the Web map illustration.
class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sagePaint = Paint()
      ..color = const Color(0xFF84A98C).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final bronzePaint = Paint()
      ..color = const Color(0xFFA38D64).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // A few soft curves, similar to the web's SVG paths.
    canvas.drawPath(_curvedPath(size, 40, 84, true), bronzePaint);
    canvas.drawPath(_curvedPath(size, 110, 60, true), bronzePaint);
    canvas.drawPath(_curvedPath(size, 182, 42, true), bronzePaint);
    canvas.drawPath(_curvedPath(size, 248, 50, false), sagePaint);
    canvas.drawPath(_curvedPath(size, 286, 34, false), sagePaint);
  }

  Path _curvedPath(Size size, double y, double amp, bool upward) {
    final path = Path()..moveTo(-80, y);
    for (double x = -80; x <= size.width + 80; x += 24) {
      final normalized = (x + 80) / 120;
      final offset = amp * math.sin(normalized);
      path.lineTo(x, y + (upward ? offset : -offset));
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
