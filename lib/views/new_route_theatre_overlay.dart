import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/new_route_draft.dart';

part 'new_route_theatre_widgets.dart';

enum _TheatrePhase {
  hidden,
  flyIn,
  zoomTitle,
  datePicker,
  archiveTop,
  archiveSlot,
}

class NewRouteTheatreOverlay extends StatefulWidget {
  const NewRouteTheatreOverlay({super.key, required this.onComplete});

  final ValueChanged<NewRouteDraft> onComplete;

  @override
  State<NewRouteTheatreOverlay> createState() => _NewRouteTheatreOverlayState();
}

class _NewRouteTheatreOverlayState extends State<NewRouteTheatreOverlay> {
  static const _bgPage = Color(0xFFF5F3EC);
  static const _ticketLeft = Colors.white;
  static const _ticketRight = Color(0xFFEAE3DB);
  static const _textMain = Color(0xFF2D2926);
  static const _textSub = Color(0xFF8C8275);
  static const _accent = Color(0xFF926B62);
  static const _lineColor = Color(0xFFD6CFC7);
  static const _skeletonColor = Color(0xFFEDE9E0);
  static const _calendarRangeBg = Color(0x29926B62);

  final _timers = <Timer>[];
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  _TheatrePhase _phase = _TheatrePhase.hidden;
  bool _showPanel = false;
  bool _showCalendar = false;
  bool _fadeBackground = false;

  String _title = '';
  String _dateRange = '';
  String _duration = '';
  String _distance = '';
  int? _startDay;
  int? _endDay;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_syncTitle);
    _startIntro();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _startIntro() {
    _later(const Duration(milliseconds: 40), () {
      _setPhase(_TheatrePhase.flyIn);
    });
    _later(const Duration(milliseconds: 900), () {
      _setPhase(_TheatrePhase.zoomTitle);
    });
    _later(const Duration(milliseconds: 1750), () {
      if (!mounted) return;
      setState(() => _showPanel = true);
      _titleFocusNode.requestFocus();
    });
  }

  void _later(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    _timers.add(timer);
  }

  void _setPhase(_TheatrePhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  void _syncTitle() {
    setState(() => _title = _titleController.text.trim());
  }

  void _handleNext() {
    if (_title.isEmpty) {
      _showSnack('请先输入行程标题');
      _titleFocusNode.requestFocus();
      return;
    }

    setState(() {
      _showPanel = false;
      _phase = _TheatrePhase.datePicker;
    });

    _later(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _showCalendar = true;
        _showPanel = true;
      });
    });
  }

  void _handleDone() {
    if (_startDay == null || _endDay == null) {
      _showSnack('请选择完整日期区间');
      return;
    }

    setState(() {
      _showPanel = false;
      _fadeBackground = true;
      _phase = _TheatrePhase.archiveTop;
    });

    _later(const Duration(milliseconds: 550), () {
      _setPhase(_TheatrePhase.archiveSlot);

      _later(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        widget.onComplete(
          NewRouteDraft(
            id: 'new-route-${DateTime.now().microsecondsSinceEpoch}',
            title: _title,
            dateRange: _dateRange,
            duration: _duration,
            distance: _distance,
          ),
        );
      });
    });
  }

  void _selectDay(int day) {
    setState(() {
      if (_startDay == null || _endDay != null) {
        _startDay = day;
        _endDay = null;
      } else if (day >= _startDay!) {
        _endDay = day;
      } else {
        _startDay = day;
      }
      _syncDateToTicket();
    });
  }

  void _syncDateToTicket() {
    final start = _startDay;
    if (start == null) return;

    String formatDay(int day) => '2026.06.${day.toString().padLeft(2, '0')}';
    final end = _endDay;
    if (end == null) {
      _dateRange = '${formatDay(start)} - 待选择';
      _duration = '1天0晚';
      _distance = '2.50 KM';
      return;
    }

    final days = end - start + 1;
    _dateRange = '${formatDay(start)} - ${formatDay(end)}';
    _duration = '$days天${math.max(0, days - 1)}晚';
    _distance = '${(days * 3.1 + 2.5).toStringAsFixed(2)} KM';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                color: _fadeBackground ? _bgPage.withValues(alpha: 0) : _bgPage,
              ),
              _buildTheatreCard(size),
              _buildInputPanel(size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTheatreCard(Size size) {
    final geometry = _cardGeometry(size);
    return AnimatedPositioned(
      duration: geometry.duration,
      curve: geometry.curve,
      left: 20,
      right: 20,
      top: geometry.top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        opacity: geometry.opacity,
        child: AnimatedScale(
          duration: geometry.duration,
          curve: geometry.curve,
          scale: geometry.scale,
          child: _TheatreTicketCard(
            title: _title,
            dateRange: _dateRange,
            duration: _duration,
            distance: _distance,
          ),
        ),
      ),
    );
  }

  _CardGeometry _cardGeometry(Size size) {
    final focusScale = size.width < 390 ? 1.34 : 1.48;
    switch (_phase) {
      case _TheatrePhase.hidden:
        return const _CardGeometry(
          top: -180,
          scale: 0.9,
          opacity: 0,
          duration: Duration(milliseconds: 850),
          curve: Curves.easeOutBack,
        );
      case _TheatrePhase.flyIn:
        return const _CardGeometry(
          top: 64,
          scale: 1,
          opacity: 1,
          duration: Duration(milliseconds: 850),
          curve: Curves.easeOutBack,
        );
      case _TheatrePhase.zoomTitle:
        return _CardGeometry(
          top: size.height * 0.27,
          scale: focusScale,
          opacity: 1,
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeOutCubic,
        );
      case _TheatrePhase.datePicker:
        return _CardGeometry(
          top: size.height * 0.18,
          scale: focusScale,
          opacity: 1,
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
        );
      case _TheatrePhase.archiveTop:
        return const _CardGeometry(
          top: 20,
          scale: 1,
          opacity: 1,
          duration: Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        );
      case _TheatrePhase.archiveSlot:
        return const _CardGeometry(
          top: 64,
          scale: 1,
          opacity: 1,
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
        );
    }
  }

  Widget _buildInputPanel(Size size) {
    final top = _showCalendar ? size.height * 0.5 - 38 : size.height * 0.5 + 35;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      top: top,
      left: 20,
      right: 20,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        offset: _showPanel ? Offset.zero : const Offset(0, 0.05),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 450),
          opacity: _showPanel ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showPanel,
            child: _showCalendar ? _buildCalendarPanel() : _buildTitlePanel(),
          ),
        ),
      ),
    );
  }

  Widget _buildTitlePanel() {
    return _PanelFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: Icons.edit_note, text: '行程标题'),
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleNext(),
            style: const TextStyle(fontSize: 15, color: _textMain),
            decoration: const InputDecoration(
              hintText: '请输入行程短标题...',
              filled: true,
              fillColor: Color(0xFFFAFAFA),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: _lineColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ConfirmButton(
            label: '继续选取日期',
            icon: Icons.arrow_forward,
            color: _textMain,
            onPressed: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPanel() {
    return _PanelFrame(
      compact: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '6月',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 10),
          const _WeekHeader(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) => _DayCell(
              day: index + 1,
              startDay: _startDay,
              endDay: _endDay,
              onTap: () => _selectDay(index + 1),
            ),
          ),
          const SizedBox(height: 10),
          _ConfirmButton(
            label: '完成并归档',
            icon: Icons.check,
            color: _accent,
            onPressed: _handleDone,
          ),
        ],
      ),
    );
  }
}
