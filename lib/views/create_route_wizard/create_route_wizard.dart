import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/celebrity_profile.dart';
import '../../models/new_route_draft.dart';
import '../../route_planning/models/route_place.dart';
import '../../route_planning/route_preview_coordinator.dart';
import '../../theme/color_schemes.dart';
import 'steps/step1_figure.dart';
import 'steps/step3_map.dart';

part 'create_route_wizard_widgets.dart';

enum _TheatrePhase { hidden, flyIn, zoomTitle, datePicker }

class CreateRouteWizard extends StatefulWidget {
  const CreateRouteWizard({super.key});

  @override
  State<CreateRouteWizard> createState() => _CreateRouteWizardState();
}

class _CreateRouteWizardState extends State<CreateRouteWizard> {
  // ── Colours shared with theatre widget part file ──
  static const _bgPage = AppColors.sageBg;
  static const _ticketLeft = Colors.white;
  static const _ticketRight = AppColors.brandLight;
  static const _textMain = AppColors.sageText;
  static const _textSub = AppColors.sageAccent;
  static const _accent = AppColors.sageAccent;
  static const _lineColor = AppColors.sageBorder;
  static const _skeletonColor = AppColors.brandLight;
  static const _calendarRangeBg = Color(0x29665B48);

  // ── Step titles ──
  static const _stepTitles = ['行程规划', '选择人物', '路线规划'];

  String get _currentStepTitle => _stepTitles[_currentStep - 1];

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

  // ── Wizard state (steps 2–3) ──
  String? _selectedFigureId;
  CelebrityProfile? _selectedFigure;
  List<RoutePlace> _selectedLocations = [];
  RoutePreviewStatus _routePreviewStatus = RoutePreviewStatus.insufficient;

  // ── Archive animation ──
  bool _archiving = false;

  // ── Computed ──

  bool get _isNextDisabled {
    if (_currentStep == 2 && _selectedFigureId == null) return true;
    if (_currentStep == 3) {
      return resolveRouteSaveAction(
            placesCount: _selectedLocations.length,
            previewStatus: _routePreviewStatus,
          ) ==
          RouteSaveAction.disabled;
    }
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
      // Let the card and panel finish compositing before the keyboard changes
      // the viewport. Overlapping those animations causes a visible frame drop.
      _later(const Duration(milliseconds: 450), () {
        if (mounted) _titleFocusNode.requestFocus();
      });
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

  // ── Wizard navigation ──

  void _selectFigure(String id, CelebrityProfile profile) {
    setState(() {
      _selectedFigureId = id;
      _selectedFigure = profile;
      _selectedLocations = [];
      _routePreviewStatus = RoutePreviewStatus.insufficient;
    });
  }

  void _handleNext() {
    if (_currentStep >= 3) return;
    setState(() {
      _previousStep = _currentStep;
      _currentStep++;
    });
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _previousStep = _currentStep;
        _currentStep--;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  // ── Save (step 3) ──

  Future<void> _handleSave() async {
    final saveAction = resolveRouteSaveAction(
      placesCount: _selectedLocations.length,
      previewStatus: _routePreviewStatus,
    );
    if (saveAction == RouteSaveAction.disabled) return;

    if (saveAction == RouteSaveAction.confirmFailure) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('路线预览失败'),
          content: const Text('暂未生成可预览路线，仍要保存当前行程吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('继续调整'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('仍然保存'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

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
        backgroundColor: AppColors.sageBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopBarSection(),
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

  // ── Compact top bar: header + progress ──

  Widget _buildTopBarSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildProgressBar(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Header: back button + step label + title ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppColors.sageBg,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.sageBorder),
            ),
            child: InkWell(
              onTap: _handleBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x14665B48),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$_currentStep / 3',
                    style: const TextStyle(
                      color: AppColors.sageAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _currentStepTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sageText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          minHeight: 3,
          value: _currentStep / 3,
          backgroundColor: AppColors.brandLight,
          valueColor: const AlwaysStoppedAnimation(AppColors.sageAccent),
        ),
      ),
    );
  }

  // ── Step content ──

  Widget _buildStepContent() {
    final goingForward = _currentStep > _previousStep;
    final involvesMap = _currentStep >= 3 || _previousStep >= 3;

    final allSteps = <Widget>[
      _buildTheatreStep(),
      Step1Figure(selectedFigureId: _selectedFigureId, onSelect: _selectFigure),
      Step3Map(
        figure: _selectedFigure,
        selectedPlaces: _selectedLocations,
        onLocationsChanged: (locations) {
          setState(() => _selectedLocations = locations);
        },
        onPreviewStatusChanged: (status) {
          if (_routePreviewStatus == status) return;
          setState(() => _routePreviewStatus = status);
        },
        onSaveRequested: _handleSave,
      ),
    ];

    final currentChild = KeyedSubtree(
      key: ValueKey(_currentStep),
      child: allSteps[_currentStep - 1],
    );

    // Never animate two Android platform map views at the same time. Hybrid
    // composition plus a slide transform is substantially more expensive than
    // swapping the map surface directly.
    if (_currentStep != _previousStep &&
        _currentStep >= 3 &&
        _previousStep >= 3) {
      return Align(alignment: Alignment.topCenter, child: currentChild);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: involvesMap ? 180 : 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          if (involvesMap) {
            return FadeTransition(opacity: animation, child: child);
          }
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
        child: currentChild,
      ),
    );
  }

  // ── Theatre step (step 1) ──

  Widget _buildTheatreStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [_buildTheatreCard(size), _buildTheatreInputPanel(size)],
        );
      },
    );
  }

  Widget _buildTheatreCard(Size size) {
    final geometry = _cardGeometry(size);
    return Positioned(
      left: 20,
      right: 20,
      top: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        opacity: geometry.opacity,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: geometry.top, end: geometry.top),
          duration: geometry.duration,
          curve: geometry.curve,
          child: AnimatedScale(
            duration: geometry.duration,
            curve: geometry.curve,
            scale: geometry.scale,
            child: RepaintBoundary(
              child: _TheatreTicketCard(
                title: _title,
                dateRange: _dateRange,
                duration: _duration,
                distance: _distance,
              ),
            ),
          ),
          builder: (context, top, child) =>
              Transform.translate(offset: Offset(0, top), child: child),
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
    final top = _showCalendar ? size.height * 0.5 - 38 : size.height * 0.5 + 35;
    return Positioned(
      top: 0,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: top, end: top),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          offset: _showTheatrePanel ? Offset.zero : const Offset(0, 0.05),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 450),
            opacity: _showTheatrePanel ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_showTheatrePanel,
              child: _showCalendar ? _buildCalendarPanel() : _buildTitlePanel(),
            ),
          ),
        ),
        builder: (context, animatedTop, child) =>
            Transform.translate(offset: Offset(0, animatedTop), child: child),
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
              fillColor: Color(0xFFFFFFFF),
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
          const SizedBox(height: 2),
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

  // ── Bottom action button (steps 2–3) ──

  Widget _buildBottomButton() {
    // Steps 1 and 3 manage their actions inside their own panels.
    if (_currentStep == 1 || _currentStep == 3) {
      return const SizedBox.shrink();
    }

    const buttonText = '下一步';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.sageCard,
        border: Border(top: BorderSide(color: Color(0x80FFEBC8))),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _isNextDisabled ? null : _handleNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sageDeep,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.brandLight,
            disabledForegroundColor: AppColors.sageMuted,
            elevation: 0,
            minimumSize: const Size(double.infinity, 38.4),
            tapTargetSize: MaterialTapTargetSize.padded,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 7),
              Icon(Icons.arrow_forward, size: 17),
            ],
          ),
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
        color: const Color(0xCCFFF2DA),
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
                            color: Color(0x20665B48),
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
