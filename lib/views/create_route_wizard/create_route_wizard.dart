import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/mock_figures.dart';
import '../../models/new_route_draft.dart';
import '../../theme/color_schemes.dart';
import 'steps/step1_figure.dart';
import 'steps/step2_theme.dart';
import 'steps/step3_map.dart';

part 'create_route_wizard_widgets.dart';

enum _TheatrePhase {
  hidden,
  flyIn,
  zoomTitle,
  datePicker,
}

class CreateRouteWizard extends StatefulWidget {
  const CreateRouteWizard({super.key});

  @override
  State<CreateRouteWizard> createState() => _CreateRouteWizardState();
}

class _CreateRouteWizardState extends State<CreateRouteWizard> {
  // ── Colours shared with theatre widget part file ──
  static const _bgPage = Color(0xFFF5F3EC);
  static const _ticketLeft = Colors.white;
  static const _ticketRight = Color(0xFFEAE3DB);
  static const _textMain = Color(0xFF2D2926);
  static const _textSub = Color(0xFF8C8275);
  static const _accent = Color(0xFF926B62);
  static const _lineColor = Color(0xFFD6CFC7);
  static const _skeletonColor = Color(0xFFEDE9E0);
  static const _calendarRangeBg = Color(0x29926B62);

  // ── Step titles ──
  static const _stepTitles = ['行程规划', '选择人物', '选择主题', '探索地图'];

  // ── Step state ──
  int _currentStep = 1;
  int _previousStep = 1;

  // ── Theatre state (step 1) ──
  final _timers = <Timer>[];
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  _TheatrePhase _theatrePhase = _TheatrePhase.hidden;
  bool _showTheatrePanel = false;
  bool _showCalendar = false;

  String _title = '';
  String _dateRange = '';
  String _duration = '';
  String _distance = '';
  int? _startDay;
  int? _endDay;

  // ── Wizard state (steps 2–4) ──
  String? _selectedFigureId;
  String? _selectedThemeId;
  List<String> _selectedLocations = [];

  // ── Archive animation ──
  bool _archiving = false;

  // ── Computed ──

  MockFigure? get _selectedFigure =>
      _selectedFigureId != null ? findFigureById(_selectedFigureId!) : null;

  bool get _isNextDisabled {
    if (_currentStep == 2 && _selectedFigureId == null) return true;
    if (_currentStep == 3 && _selectedThemeId == null) return true;
    if (_currentStep == 4 && _selectedLocations.isEmpty) return true;
    return false;
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_syncTitle);
    _startTheatreIntro();
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

  // ── Theatre: intro animation ──

  void _startTheatreIntro() {
    _later(const Duration(milliseconds: 40), () {
      _setTheatrePhase(_TheatrePhase.flyIn);
    });
    _later(const Duration(milliseconds: 900), () {
      _setTheatrePhase(_TheatrePhase.zoomTitle);
    });
    _later(const Duration(milliseconds: 1750), () {
      if (!mounted) return;
      setState(() => _showTheatrePanel = true);
      _titleFocusNode.requestFocus();
    });
  }

  void _later(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    _timers.add(timer);
  }

  void _setTheatrePhase(_TheatrePhase phase) {
    if (!mounted) return;
    setState(() => _theatrePhase = phase);
  }

  void _syncTitle() {
    setState(() => _title = _titleController.text.trim());
  }

  // ── Theatre: title → calendar ──

  void _handleTheatreNext() {
    if (_title.isEmpty) {
      _showSnack('请先输入行程标题');
      _titleFocusNode.requestFocus();
      return;
    }

    setState(() {
      _showTheatrePanel = false;
      _theatrePhase = _TheatrePhase.datePicker;
    });

    _later(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _showCalendar = true;
        _showTheatrePanel = true;
      });
    });
  }

  // ── Theatre: calendar → step 2 ──

  void _handleTheatreDone() {
    if (_startDay == null || _endDay == null) {
      _showSnack('请选择完整日期区间');
      return;
    }

    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _titleFocusNode.unfocus();

    setState(() {
      _previousStep = _currentStep;
      _currentStep = 2;
    });
  }

  // ── Calendar ──

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

    String formatDay(int day) =>
        '2026.06.${day.toString().padLeft(2, '0')}';
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

  // ── Wizard navigation ──

  void _selectFigure(String id) {
    setState(() => _selectedFigureId = id);
  }

  void _selectTheme(String id) {
    setState(() => _selectedThemeId = id);
  }

  void _updateLocations(List<String> locations) {
    setState(() => _selectedLocations = locations);
  }

  void _handleNext() {
    if (_currentStep < 4) {
      setState(() {
        _previousStep = _currentStep;
        _currentStep++;
      });
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _previousStep = _currentStep;
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── Save (step 4) ──

  void _handleSave() {
    setState(() => _archiving = true);

    _later(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final draft = NewRouteDraft(
        id: 'new-route-${DateTime.now().microsecondsSinceEpoch}',
        title: _title,
        dateRange: _dateRange,
        duration: _duration,
        distance: _distance,
      );
      Navigator.of(context).pop(draft);
    });
  }

  // ── Snack bar ──

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

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildStepContent()),
                  _buildBottomButton(),
                ],
              ),
            ),
            if (_archiving) _buildArchiveOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Header: back button + step label + title ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sageBorder),
              ),
              child: const Icon(Icons.arrow_back, size: 18),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STEP $_currentStep OF 4',
                style: const TextStyle(
                  color: Color(0xFFC37153),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _stepTitles[_currentStep - 1],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2825),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Progress bar: 4 segments ──

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final step = index + 1;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: step <= _currentStep
                    ? const Color(0xFFC37153)
                    : const Color(0xFFE8E2D9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step content ──

  Widget _buildStepContent() {
    final goingForward = _currentStep > _previousStep;

    final allSteps = <Widget>[
      _buildTheatreStep(),
      Step1Figure(
        selectedFigureId: _selectedFigureId,
        onSelect: _selectFigure,
      ),
      Step2Theme(
        selectedThemeId: _selectedThemeId,
        onSelect: _selectTheme,
        figureName: _selectedFigure?.name ?? '',
      ),
      Step3Map(
        selectedLocations: _selectedLocations,
        onLocationsChanged: _updateLocations,
      ),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          final isOld = child.key != ValueKey(_currentStep);
          final Offset begin;
          if (isOld) {
            begin = goingForward ? const Offset(-1, 0) : const Offset(1, 0);
          } else {
            begin = goingForward ? const Offset(1, 0) : const Offset(-1, 0);
          }
          return SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentStep),
          child: allSteps[_currentStep - 1],
        ),
      ),
    );
  }

  // ── Theatre step (step 1) ──

  Widget _buildTheatreStep() {
    final isFirstTime = _previousStep == _currentStep &&
        _theatrePhase != _TheatrePhase.hidden;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey('theatre_$isFirstTime'),
            child: Stack(
              children: [
                _buildTheatreCard(size),
                _buildTheatreInputPanel(size),
              ],
            ),
          ),
        );
      },
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
    switch (_theatrePhase) {
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
    }
  }

  Widget _buildTheatreInputPanel(Size size) {
    final top =
        _showCalendar ? size.height * 0.5 - 38 : size.height * 0.5 + 35;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      top: top,
      left: 20,
      right: 20,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        offset: _showTheatrePanel ? Offset.zero : const Offset(0, 0.05),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 450),
          opacity: _showTheatrePanel ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showTheatrePanel,
            child:
                _showCalendar ? _buildCalendarPanel() : _buildTitlePanel(),
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
            onSubmitted: (_) => _handleTheatreNext(),
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
            onPressed: _handleTheatreNext,
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
          Transform.scale(
            scaleY: 0.9,
            alignment: Alignment.topCenter,
            child: GridView.builder(
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
          ),
          const SizedBox(height: 10),
          _ConfirmButton(
            label: '完成并开始规划',
            icon: Icons.arrow_forward,
            color: _accent,
            onPressed: _handleTheatreDone,
          ),
        ],
      ),
    );
  }

  // ── Bottom action button (steps 2–4) ──

  Widget _buildBottomButton() {
    // Step 1 (theatre) manages its own buttons inside the panels.
    if (_currentStep == 1) return const SizedBox.shrink();

    final isLastStep = _currentStep == 4;
    final buttonText = isLastStep ? '保存行程' : '下一步';
    final buttonHandler = isLastStep ? _handleSave : _handleNext;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(
          top: BorderSide(color: Color(0x80E8E2D9)),
        ),
      ),
      child: ElevatedButton(
        onPressed: _isNextDisabled ? null : buttonHandler,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C1A1A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8E2D9),
          disabledForegroundColor: const Color(0xFFA8A195),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isLastStep) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // ── Archive overlay ──

  Widget _buildArchiveOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _archiving ? 1 : 0,
      child: Container(
        color: const Color(0xCCF5F3EC),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, _) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: _CreateRouteWizardState._accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x20926B62),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '行程已保存',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
