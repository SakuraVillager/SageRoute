import 'package:flutter/material.dart';

import '../../data/mock_figures.dart';
import '../../models/figure.dart';
import '../../theme/color_schemes.dart';
import 'steps/step1_figure.dart';
import 'steps/step2_theme.dart';
import 'steps/step3_map.dart';
import 'steps/step4_plan.dart';
import 'steps/step5_preview.dart';
class CreateRouteWizard extends StatefulWidget {
  const CreateRouteWizard({super.key, this.onComplete, this.onExit});

  /// Called when the user taps "保存行程" on step 5.
  final VoidCallback? onComplete;

  /// Called when the user taps back on step 1.
  final VoidCallback? onExit;

  @override
  State<CreateRouteWizard> createState() => _CreateRouteWizardState();
}

class _CreateRouteWizardState extends State<CreateRouteWizard> {
  static const List<String> _stepTitles = [
    '选择人物',
    '选择主题',
    '行程规划',
    '探索地图',
    '路线预览',
  ];

  int _currentStep = 1;
  int _previousStep = 1;
  String? _selectedFigureId;
  String? _selectedThemeId;
  List<String> _selectedLocations = [];

  MockFigure? get _selectedFigure =>
      _selectedFigureId != null ? findFigureById(_selectedFigureId!) : null;

  Figure? get _selectedModelFigure {
    final mf = _selectedFigure;
    if (mf == null) return null;
    return Figure(
      id: mf.id,
      name: mf.name,
      pinyinName: mf.pinyinName,
      dynasty: mf.dynasty,
      role: mf.role,
      years: mf.years,
      shortDesc: mf.shortDesc,
      description: mf.description,
      imageUrl: mf.imageUrl,
      locationsCount: mf.locationsCount,
      routesCount: mf.routesCount,
      poemsCount: mf.poemsCount,
      rating: mf.rating,
    );
  }

  bool get _isNextDisabled {
    if (_currentStep == 1 && _selectedFigureId == null) return true;
    if (_currentStep == 2 && _selectedThemeId == null) return true;
    if (_currentStep == 4 && _selectedLocations.isEmpty) return true;
    return false;
  }

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
    if (_currentStep < 5) {
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
      widget.onExit?.call();
    }
  }

  void _handleComplete() {
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
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
    );
  }

  // ── Header: back button + step label + title ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Back button (circular, light background)
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
          // Step indicator + title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STEP $_currentStep OF 5',
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
          // Right spacer for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Progress bar: 5 segments with terracotta / light fills ──

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(5, (index) {
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

  // ── Step content: actual step widgets via IndexedStack ──

  Widget _buildStepContent() {
    final goingForward = _currentStep > _previousStep;

    final steps = [
      Step1Figure(
        selectedFigureId: _selectedFigureId,
        onSelect: _selectFigure,
      ),
      Step2Theme(
        selectedThemeId: _selectedThemeId,
        onSelect: _selectTheme,
        figureName: _selectedFigure?.name ?? '',
      ),
      Step4Plan(figure: _selectedModelFigure),
      Step3Map(
        selectedLocations: _selectedLocations,
        onLocationsChanged: _updateLocations,
      ),
      Step5Preview(
        figure: _selectedFigure,
        onSave: _handleComplete,
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        final isOld = child.key != ValueKey(_currentStep);
        final Offset begin;
        if (isOld) {
          // Old page exits toward the opposite of the incoming direction
          begin = goingForward ? const Offset(-1, 0) : const Offset(1, 0);
        } else {
          // New page enters from the direction of travel
          begin = goingForward ? const Offset(1, 0) : const Offset(-1, 0);
        }
        return SlideTransition(
          position: Tween(begin: begin, end: Offset.zero).animate(animation),
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_currentStep),
        child: steps[_currentStep - 1],
      ),
    );
  }

  // ── Bottom action button: "下一步" / "保存行程" ──

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 5;
    final buttonText = isLastStep ? '保存行程' : '下一步';
    final buttonHandler = isLastStep ? _handleComplete : _handleNext;

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
}
