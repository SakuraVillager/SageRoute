part of 'create_route_wizard.dart';

class _FormSectionHeading extends StatelessWidget {
  const _FormSectionHeading({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandWash,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.sageAccent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sageText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.sageMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 15, 16, 14)
          : const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: child,
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
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
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
