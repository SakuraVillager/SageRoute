part of 'create_route_wizard.dart';

class _CardGeometry {
  const _CardGeometry({
    required this.top,
    required this.scale,
    required this.opacity,
    required this.duration,
    required this.curve,
  });

  final double top;
  final double scale;
  final double opacity;
  final Duration duration;
  final Curve curve;
}

class _TheatreTicketCard extends StatelessWidget {
  const _TheatreTicketCard({
    required this.title,
    required this.dateRange,
    required this.duration,
    required this.distance,
  });

  final String title;
  final String dateRange;
  final String duration;
  final String distance;

  static const _ticketLeft = _CreateRouteWizardState._ticketLeft;
  static const _ticketRight = _CreateRouteWizardState._ticketRight;
  static const _textMain = _CreateRouteWizardState._textMain;
  static const _textSub = _CreateRouteWizardState._textSub;
  static const _accent = _CreateRouteWizardState._accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: _ticketLeft,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F332E24),
                      blurRadius: 36,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildLeftSide()),
                    _buildRightStub(),
                  ],
                ),
              ),
            ),
          ),
          const _PunchHole(top: -9),
          const _PunchHole(bottom: -9),
        ],
      ),
    );
  }

  Widget _buildLeftSide() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: _accent, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TicketTextOrSkeleton(
                      text: title,
                      width: 130,
                      height: 16,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TicketTextOrSkeleton(
                      text: dateRange,
                      width: 150,
                      height: 11,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSub,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.person_outline, color: _textSub, size: 14),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  '新创建的行程',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _textSub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightStub() {
    return Container(
      width: 124,
      color: _ticketRight,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRAVEL\nJOURNAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sageMuted,
                      height: 1.2,
                    ),
                  ),
                  Icon(Icons.public, size: 13, color: AppColors.sageMuted),
                ],
              ),
              SizedBox(height: 10),
              CustomPaint(
                size: Size(double.infinity, 1),
                painter: _StubDividerPainter(),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StubInfo(label: '时长', value: duration),
              const SizedBox(height: 8),
              _StubInfo(label: '里程', value: distance),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketTextOrSkeleton extends StatelessWidget {
  const _TicketTextOrSkeleton({
    required this.text,
    required this.width,
    required this.height,
    required this.style,
  });

  final String text;
  final double width;
  final double height;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return _SkeletonLine(width: width, height: height);
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

class _StubInfo extends StatelessWidget {
  const _StubInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const textSub = _CreateRouteWizardState._textSub;
    const textMain = _CreateRouteWizardState._textMain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: textSub)),
        const SizedBox(height: 3),
        value.isEmpty
            ? const _SkeletonLine(width: 50, height: 13)
            : Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
              ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _CreateRouteWizardState._skeletonColor,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

class _PunchHole extends StatelessWidget {
  const _PunchHole({this.top, this.bottom});

  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 115,
      top: top,
      bottom: bottom,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: _CreateRouteWizardState._bgPage,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StubDividerPainter extends CustomPainter {
  const _StubDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _CreateRouteWizardState._lineColor
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(18, 16, 18, 12)
          : const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10332E24),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _CreateRouteWizardState._textSub),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _CreateRouteWizardState._textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  static const _days = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in _days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _CreateRouteWizardState._textSub,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.startDay,
    required this.endDay,
    required this.onTap,
  });

  final int day;
  final int? startDay;
  final int? endDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStart = day == startDay;
    final isEnd = day == endDay;
    final inRange =
        startDay != null && endDay != null && day > startDay! && day < endDay!;
    final isSelected = isStart || isEnd;
    final hasConnectedRange =
        startDay != null && endDay != null && startDay != endDay;

    Widget? rangeBackground;
    if (hasConnectedRange && inRange) {
      rangeBackground = const Positioned.fill(
        child: ColoredBox(color: _CreateRouteWizardState._calendarRangeBg),
      );
    } else if (hasConnectedRange && isStart) {
      rangeBackground = const Positioned.fill(
        child: Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            alignment: Alignment.centerRight,
            child: ColoredBox(color: _CreateRouteWizardState._calendarRangeBg),
          ),
        ),
      );
    } else if (hasConnectedRange && isEnd) {
      rangeBackground = const Positioned.fill(
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: ColoredBox(color: _CreateRouteWizardState._calendarRangeBg),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (rangeBackground != null) rangeBackground,
          DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? _CreateRouteWizardState._accent
                  : Colors.transparent,
              shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : _CreateRouteWizardState._textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
