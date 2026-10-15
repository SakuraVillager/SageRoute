import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/color_schemes.dart';

/// Shared by the inline planner and the browser's compact date dialog.
class RouteDateRangePicker extends StatefulWidget {
  const RouteDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelect,
    this.currentDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onSelect;
  final DateTime? currentDate;

  @override
  State<RouteDateRangePicker> createState() => _RouteDateRangePickerState();
}

class _RouteDateRangePickerState extends State<RouteDateRangePicker> {
  late final DateTime _today = DateUtils.dateOnly(
    widget.currentDate ?? DateTime.now(),
  );
  late DateTime _month = DateTime(
    (widget.startDate ?? _today).year,
    (widget.startDate ?? _today).month,
  );

  void _moveMonth(int offset) =>
      setState(() => _month = DateTime(_month.year, _month.month + offset));

  Future<void> _chooseMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (_) => _YearMonthDialog(month: _month),
    );
    if (selected != null && mounted) setState(() => _month = selected);
  }

  @override
  Widget build(BuildContext context) {
    final offset =
        DateTime(_month.year, _month.month).weekday - DateTime.monday;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = ((offset + days + 6) ~/ 7) * 7;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '上个月',
              onPressed: _month.year == 1 && _month.month == 1
                  ? null
                  : () => _moveMonth(-1),
              constraints: const BoxConstraints.tightFor(width: 32, height: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 22),
            ),
            Expanded(
              child: TextButton(
                key: const ValueKey('calendar-choose-month'),
                onPressed: _chooseMonth,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${_month.year}年 ${_month.month}月',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageText,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: '下个月',
              onPressed: _month.year == 9999 && _month.month == 12
                  ? null
                  : () => _moveMonth(1),
              constraints: const BoxConstraints.tightFor(width: 32, height: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_right, size: 22),
            ),
            IconButton(
              tooltip: '回到本月',
              onPressed: () =>
                  setState(() => _month = DateTime(_today.year, _today.month)),
              constraints: const BoxConstraints.tightFor(width: 32, height: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.today_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final day in ['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          key: ValueKey('calendar-grid-${_month.year}-${_month.month}'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: kIsWeb ? 34 : 40,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (_, index) {
            final day = index - offset + 1;
            if (day < 1 || day > days) return const SizedBox.shrink();
            final date = DateTime(_month.year, _month.month, day);
            return _CalendarDay(
              date: date,
              today: _today,
              start: widget.startDate,
              end: widget.endDate,
              onTap: () => widget.onSelect(date),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.today,
    required this.start,
    required this.end,
    required this.onTap,
  });
  final DateTime date;
  final DateTime today;
  final DateTime? start;
  final DateTime? end;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStart = DateUtils.isSameDay(date, start);
    final isEnd = DateUtils.isSameDay(date, end);
    final selected = isStart || isEnd;
    final connected =
        start != null && end != null && !DateUtils.isSameDay(start, end);
    final inside = connected && date.isAfter(start!) && date.isBefore(end!);
    return Semantics(
      label:
          '${date.year}年${date.month}月${date.day}日${isStart ? '，出发日期' : ''}${isEnd ? '，返程日期' : ''}',
      selected: selected,
      child: InkWell(
        key: ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (inside)
              const ColoredBox(color: Color(0x2996615A))
            else if (connected && selected)
              Align(
                alignment: isStart
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: const FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: ColoredBox(color: Color(0x2996615A)),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.sageAccent : Colors.transparent,
                border: DateUtils.isSameDay(date, today) && !selected
                    ? Border.all(color: AppColors.sageAccent)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.sageText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearMonthDialog extends StatefulWidget {
  const _YearMonthDialog({required this.month});
  final DateTime month;
  @override
  State<_YearMonthDialog> createState() => _YearMonthDialogState();
}

class _YearMonthDialogState extends State<_YearMonthDialog> {
  final _form = GlobalKey<FormState>();
  late final _year = TextEditingController(text: '${widget.month.year}');
  late int _month = widget.month.month;
  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, DateTime(int.parse(_year.text), _month));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('选择年月'),
    scrollable: true,
    content: SizedBox(
      width: 280,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('calendar-year-field'),
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: '年份',
                hintText: '例如 2027',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final year = int.tryParse(value ?? '');
                return year == null || year < 1 || year > 9999
                    ? '请输入 1–9999 的年份'
                    : null;
              },
              onFieldSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 172,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
                childAspectRatio: 1.3,
                children: [
                  for (var month = 1; month <= 12; month++)
                    TextButton(
                      key: ValueKey('calendar-month-$month'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: month == _month
                            ? AppColors.brandWash
                            : null,
                      ),
                      onPressed: () => setState(() => _month = month),
                      child: Text('$month月'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('确定年月')),
    ],
  );
}
