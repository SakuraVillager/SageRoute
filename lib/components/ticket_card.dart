import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 行程票据卡片 — 左白主体 + 右侧存根 + 剪票缺口 + 文化印章。
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.title,
    required this.dateRange,
    required this.memberText,
    required this.duration,
    required this.distance,
    this.stampLine1 = 'MY TRIP',
    this.stampLine2 = 'PASSED',
    this.onTap,
  });

  final String title;
  final String dateRange;
  final String memberText;
  final String duration;
  final String distance;
  final String stampLine1;
  final String stampLine2;
  final VoidCallback? onTap;

  // ── Colors ──
  static const _ticketLeftBg = Colors.white;
  static const _ticketRightBg = Color(0xFFEAE3DB);
  static const _textMain = Color(0xFF2D2926);
  static const _textSub = Color(0xFF8C8275);
  static const _accent = Color(0xFF926B62);
  static const _lineColor = Color(0xFFD6CFC7);
  static const _stampColor = Color(0x1F926B62); // accent @ 12%
  static const _stubSlogan = Color(0xFFA3998E);
  static const _punchBg = Color(0xFFF5F3EC);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 136,
        child: Stack(
          children: [
            // 主体卡片（左 + 右）
            Positioned.fill(
              child: Row(
                children: [
                  // ── 左侧主体 ──
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _ticketLeftBg,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 20, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部：定位图标 + 标题（同行居中对齐）
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: _accent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _textMain,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 日期：缩进与标题对齐
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Text(
                              dateRange,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textSub,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // 底部：成员信息
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 13,
                                color: _textSub,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                memberText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSub,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── 右侧存根 ──
                  Container(
                    width: 108,
                    decoration: const BoxDecoration(
                      color: _ticketRightBg,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TRAVEL JOURNAL + globe
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'TRAVEL\nJOURNAL',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _stubSlogan,
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                            ),
                            Icon(
                              Icons.public,
                              size: 12,
                              color: _stubSlogan,
                            ),
                          ],
                        ),
                        // 虚线分隔
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: _DashedLinePainter(color: _lineColor),
                          ),
                        ),
                        const Spacer(),
                        // 时长
                        _StubInfo(label: '时长', value: duration),
                        const SizedBox(height: 4),
                        // 里程
                        _StubInfo(label: '里程', value: distance),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── 剪票缺口 ──
            const _PunchHole(position: _PunchPosition.top),
            const _PunchHole(position: _PunchPosition.bottom),
            // ── 文化印章 ──
            Positioned(
              right: 64,
              bottom: 10,
              child: _CulturalStamp(
                line1: stampLine1,
                line2: stampLine2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 存根信息项 ──

class _StubInfo extends StatelessWidget {
  const _StubInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: TicketCard._textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TicketCard._textMain,
          ),
        ),
      ],
    );
  }
}

// ── 剪票缺口 ──

enum _PunchPosition { top, bottom }

class _PunchHole extends StatelessWidget {
  const _PunchHole({required this.position});

  final _PunchPosition position;

  @override
  Widget build(BuildContext context) {
    final top = position == _PunchPosition.top;
    return Positioned(
      right: 99,
      top: top ? -9 : null,
      bottom: top ? null : -9,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: TicketCard._punchBg,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── 文化印章 ──

class _CulturalStamp extends StatelessWidget {
  const _CulturalStamp({required this.line1, required this.line2});

  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -15 * math.pi / 180,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(color: TicketCard._stampColor),
          shape: BoxShape.circle,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: TicketCard._stampColor),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$line1\n$line2',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: TicketCard._stampColor,
              letterSpacing: 1,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 虚线绘制器 ──

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
