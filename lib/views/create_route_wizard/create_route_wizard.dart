import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/user_route_repository.dart';
import '../../models/celebrity_profile.dart';
import '../../models/saved_route.dart';
import '../../route_planning/models/route_place.dart';
import '../../route_planning/models/transport_type.dart';
import '../../route_planning/route_preview_coordinator.dart';
import '../../theme/color_schemes.dart';
import '../../utils/route_save_diagnostics.dart';
import 'steps/step1_figure.dart';
import 'steps/step3_map.dart';

part 'create_route_wizard_widgets.dart';

class CreateRouteWizard extends StatefulWidget {
  const CreateRouteWizard({super.key});

  @override
  State<CreateRouteWizard> createState() => _CreateRouteWizardState();
}

class _CreateRouteWizardState extends State<CreateRouteWizard> {
  // ── Colours shared with step-one widgets ──
  static const _textMain = AppColors.sageText;
  static const _textSub = AppColors.sageAccent;
  static const _accent = AppColors.sageAccent;
  static const _lineColor = AppColors.sageBorder;
  static const _calendarRangeBg = Color(0x2996615A);

  // ── Step titles ──
  static const _stepTitles = ['行程规划', '选择人物', '路线规划'];

  String get _currentStepTitle => _stepTitles[_currentStep - 1];

  // ── Step state ──
  int _currentStep = 1;
  int _previousStep = 1;

  // ── Basic information (step 1) ──
  final _timers = <Timer>[];
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

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
  Map<String, TransportType> _segmentTransportTypes = <String, TransportType>{};

  final UserRouteRepository _routeRepository = const UserRouteRepository();

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

  void _later(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    _timers.add(timer);
  }

  void _syncTitle() {
    setState(() => _title = _titleController.text.trim());
  }

  // ── Basic information → step 2 ──

  void _handlePlanDetailsDone() {
    if (_title.isEmpty) {
      _showSnack('请先输入行程名称');
      _titleFocusNode.requestFocus();
      return;
    }
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

    try {
      final waypoints = <RouteWaypoint>[
        for (var i = 0; i < _selectedLocations.length; i++)
          RouteWaypoint.fromRoutePlace(
            _selectedLocations[i],
            transportToNext: i < _selectedLocations.length - 1
                ? _segmentTransportTypes[Step3Map.segmentKey(
                        _selectedLocations[i],
                        _selectedLocations[i + 1],
                      )] ??
                      TransportType.driving
                : null,
          ),
      ];
      final draft = SavedRoute(
        id: '',
        title: _title,
        dateRange: _dateRange,
        duration: _duration,
        distance: _distance,
        figureId: _selectedFigure?.id,
        figureName: _selectedFigure?.name,
        waypoints: waypoints,
      );
      final routeId = await _routeRepository.createRoute(draft);
      if (!mounted) return;
      // 保留短暂的归档动画再返回，与旧交互节奏一致。
      _later(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.of(context).pop(draft.copyWith(id: routeId));
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _archiving = false);
      await showRouteSaveDiagnostics(
        context,
        error: error,
        stackTrace: stackTrace,
      );
    }
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
                    color: const Color(0x1496615A),
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
      _buildPlanDetailsStep(),
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
        onTransportTypesChanged: (types) => _segmentTransportTypes = types,
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

  // ── Basic information form (step 1) ──

  Widget _buildPlanDetailsStep() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FormSectionHeading(
            number: '01',
            title: '行程名称',
            description: '取一个方便辨认的名字，之后仍可修改',
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('route-title-field'),
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            onSubmitted: (_) => _titleFocusNode.unfocus(),
            style: const TextStyle(fontSize: 15, color: _textMain),
            decoration: InputDecoration(
              hintText: '例如：苏轼的杭州三日行',
              counterText: '',
              prefixIcon: const Icon(
                Icons.edit_outlined,
                size: 19,
                color: _textSub,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _lineColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _FormSectionHeading(
            number: '02',
            title: '出行日期',
            description: '依次选择出发日和返程日',
          ),
          const SizedBox(height: 10),
          _buildCalendarPanel(),
          const SizedBox(height: 14),
          _ConfirmButton(
            label: '下一步 · 选择同行人物',
            icon: Icons.arrow_forward,
            color: _accent,
            onPressed: _handlePlanDetailsDone,
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
            '2026年 6月',
            style: TextStyle(
              fontSize: 17,
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
        border: Border(top: BorderSide(color: Color(0x80D8D8DC))),
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
        color: const Color(0xCCF0F0F2),
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
                            color: Color(0x2096615A),
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
