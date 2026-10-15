import '../../components/web/web_back_button.dart';
import '../../components/route_date_range_picker.dart';
import 'package:flutter/foundation.dart';
import '../../components/adaptive_content.dart';
import '../../components/draft_exit_guard.dart';
import '../../navigation/app_navigation.dart';
import '../../services/database_service.dart';
import '../../services/route_draft_storage.dart';
import '../../services/guest_session.dart';
import '../../auth/login_page.dart';
import 'package:go_router/go_router.dart';
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
part 'create_route_web_workspace.dart';

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
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Wizard state (steps 2–3) ──
  String? _selectedFigureId;
  CelebrityProfile? _selectedFigure;
  List<RoutePlace> _selectedLocations = [];
  RoutePreviewStatus _routePreviewStatus = RoutePreviewStatus.insufficient;
  Map<String, TransportType> _segmentTransportTypes = <String, TransportType>{};

  final UserRouteRepository _routeRepository = const UserRouteRepository();

  // ── Archive animation ──
  bool _archiving = false;
  bool _saved = false;
  bool _leavingForLogin = false;
  RouteDraftStorage? _draft;
  bool get _dirty =>
      !_saved &&
      (_title.isNotEmpty ||
          _startDate != null ||
          _selectedFigure != null ||
          _selectedLocations.isNotEmpty);

  void _persistDraft() {
    if (_saved) return;
    _draft?.save({
      'step': _currentStep,
      'title': _titleController.text,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'figure': _selectedFigure?.toMap(),
      'places': _selectedLocations.map((p) => p.toJson()).toList(),
      'transports': _segmentTransportTypes.map(
        (key, value) => MapEntry(key, value.name),
      ),
    });
  }

  void _restoreDraft() {
    if (!kIsWeb) return;
    final user = DatabaseService.client.auth.currentUser;
    if (user == null && !GuestSession.isActive) return;
    _draft = RouteDraftStorage(
      userId: user?.id ?? GuestSession.draftUserId,
      draftId: 'new',
    );
    final data = _draft!.load();
    if (data == null) return;
    try {
      _titleController.text = data['title'] as String? ?? '';
      _title = _titleController.text.trim();
      DateTime? restoreDate(String key, String legacyKey) {
        final value = data[key];
        if (value is String) return DateUtils.dateOnly(DateTime.parse(value));
        // Older drafts stored day numbers for the fixed June 2026 calendar.
        final legacy = data[legacyKey];
        if (legacy is int && legacy >= 1 && legacy <= 30) {
          return DateTime(2026, 6, legacy);
        }
        return null;
      }

      _startDate = restoreDate('startDate', 'startDay');
      _endDate = restoreDate('endDate', 'endDay');
      if (_startDate == null ||
          (_endDate != null && _endDate!.isBefore(_startDate!))) {
        _endDate = null;
      }
      if (data['figure'] is Map) {
        _selectedFigure = CelebrityProfile.fromMap(
          Map<String, dynamic>.from(data['figure'] as Map),
        );
        _selectedFigureId = _selectedFigure!.id.toString();
      }
      _selectedLocations = (data['places'] as List? ?? [])
          .map((p) => RoutePlace.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      _segmentTransportTypes = (data['transports'] as Map? ?? {}).map(
        (key, value) => MapEntry(
          key as String,
          TransportType.values.byName(value as String),
        ),
      );
      _currentStep = ((data['step'] as int? ?? 1).clamp(1, 3));
      if (_currentStep == 3 && _selectedFigure == null) _currentStep = 2;
      _previousStep = _currentStep;
      _syncDateToTicket();
    } catch (_) {
      _draft!.clear();
      _titleController.clear();
      _title = '';
      _startDate = null;
      _endDate = null;
      _selectedFigure = null;
      _selectedFigureId = null;
      _selectedLocations = [];
      _segmentTransportTypes = {};
      _currentStep = 1;
      _previousStep = 1;
    }
  }

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
    _restoreDraft();
    _titleController.addListener(_syncTitle);
  }

  @override
  void dispose() {
    if (!_saved) _persistDraft();
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
    _persistDraft();
  }

  // ── Basic information → step 2 ──

  void _handlePlanDetailsDone() {
    if (_title.isEmpty) {
      _showSnack('请先输入行程名称');
      _titleFocusNode.requestFocus();
      return;
    }
    if (_startDate == null || _endDate == null) {
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

  void _selectDate(DateTime date) {
    setState(() {
      if (_startDate == null || _endDate != null) {
        _startDate = date;
        _endDate = null;
      } else if (!date.isBefore(_startDate!)) {
        _endDate = date;
      } else {
        _startDate = date;
      }
      _syncDateToTicket();
    });
    _persistDraft();
  }

  void _syncDateToTicket() {
    final start = _startDate;
    if (start == null) {
      _dateRange = '';
      _duration = '';
      _distance = '';
      return;
    }
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final end = _endDate;
    if (end == null) {
      _dateRange = '${formatDate(start)} - 待选择';
      _duration = '1天0晚';
      _distance = '2.50 KM';
      return;
    }
    // Count calendar days independently of local daylight-saving transitions.
    final days =
        DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
    _dateRange = '${formatDate(start)} - ${formatDate(end)}';
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

  void _setWebStep(int step) {
    setState(() {
      _previousStep = _currentStep;
      _currentStep = step;
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
    if (kIsWeb && _dirty) {
      requestDraftDiscard(
        context,
        () {
          _draft?.clear();
          setState(() => _saved = true);
        },
        () => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) finishAppPage(context);
        }),
      );
    } else {
      finishAppPage(context);
    }
  }

  // ── Save (step 3) ──

  Future<void> _handleSave() async {
    if (GuestSession.isActive &&
        DatabaseService.client.auth.currentUser == null) {
      final login = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('登录后保存行程'),
          content: const Text('游客可以浏览和规划路线。登录后即可保存，当前规划会为你保留。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('继续编辑'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
      if (login != true || !mounted) return;
      if (kIsWeb) {
        _persistDraft();
        setState(() => _leavingForLogin = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login?from=%2Froutes%2Fnew');
        });
        return;
      }
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (loginContext) => LoginPage(
            onAuthenticated: () => Navigator.pop(loginContext, true),
          ),
        ),
      );
      if (loggedIn != true || !mounted) return;
    }
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
      _saved = true;
      _draft?.clear();
      if (!mounted) return;
      // 保留短暂的归档动画再返回，与旧交互节奏一致。
      _later(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        finishAppPage(context, draft.copyWith(id: routeId));
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
    _persistDraft();
    return DraftExitGuard(
      dirty: kIsWeb && _dirty && !_archiving && !_leavingForLogin,
      onDiscard: () {
        _saved = true;
        _draft?.clear();
      },
      child: kIsWeb && MediaQuery.sizeOf(context).width >= 1024
          ? _buildWebPlanningWorkspace()
          : AdaptiveContent(
              maxWidth: _currentStep == 3 ? double.infinity : 800,
              child: PopScope(
                canPop: kIsWeb || _currentStep == 1,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop && !kIsWeb) _handleBack();
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
          WebBackButton(
            onPressed: _handleBack,
            size: 36,
            mobileChild: Material(
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
      _buildMapStep(),
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

  Widget _buildMapStep() => Step3Map(
    figure: _selectedFigure,
    selectedPlaces: _selectedLocations,
    onLocationsChanged: (locations) {
      setState(() => _selectedLocations = locations);
    },
    onPreviewStatusChanged: (status) {
      if (_routePreviewStatus == status) return;
      setState(() => _routePreviewStatus = status);
    },
    onTransportTypesChanged: (types) {
      _segmentTransportTypes = types;
      _persistDraft();
    },
    initialSegmentTransports: [
      for (var i = 0; i < _selectedLocations.length - 1; i++)
        _segmentTransportTypes[Step3Map.segmentKey(
              _selectedLocations[i],
              _selectedLocations[i + 1],
            )] ??
            TransportType.driving,
    ],
    onSaveRequested: _handleSave,
  );

  // ── Basic information form (step 1) ──

  Widget _buildPlanDetailsStep({bool desktop = false}) {
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
          if (kIsWeb) _buildDateField() else _buildCalendarPanel(),
          if (!desktop) ...[
            const SizedBox(height: 14),
            _ConfirmButton(
              label: '下一步 · 选择同行人物',
              icon: Icons.arrow_forward,
              color: _accent,
              onPressed: _handlePlanDetailsDone,
            ),
          ],
          if (desktop) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('旅程摘要', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              _duration.isEmpty ? '选择日期后显示行程天数' : _duration,
              style: const TextStyle(color: AppColors.sageMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFigure == null ? '尚未选择人物' : _selectedFigure!.name,
              style: const TextStyle(color: AppColors.sageMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarPanel({ValueChanged<DateTime>? onSelect}) => _PanelFrame(
    compact: true,
    child: RouteDateRangePicker(
      startDate: _startDate,
      endDate: _endDate,
      onSelect: onSelect ?? _selectDate,
    ),
  );

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
