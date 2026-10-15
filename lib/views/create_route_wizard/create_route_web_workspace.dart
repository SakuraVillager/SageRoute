part of 'create_route_wizard.dart';

extension _WebPlanningLayout on _CreateRouteWizardState {
  void _continueWebPlan() {
    if (_title.isEmpty || _startDate == null || _endDate == null) {
      _handlePlanDetailsDone();
      return;
    }
    if (_selectedFigure == null) {
      _showSnack('请选择一位同行人物');
      return;
    }
    _titleFocusNode.unfocus();
    _setWebStep(3);
  }

  Future<void> _openDatePopover() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, refresh) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            key: const ValueKey('web-date-popover'),
            width: 320,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '选择出行日期',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          tooltip: '关闭日期选择',
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    _buildCalendarPanel(
                      onSelect: (date) {
                        _selectDate(date);
                        refresh(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startDate != null && _endDate != null
                            ? () => Navigator.pop(dialogContext)
                            : null,
                        child: const Text('确定日期'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() => OutlinedButton(
    key: const ValueKey('web-date-field'),
    onPressed: _openDatePopover,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: AppColors.sageBorder),
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _dateRange.isEmpty ? '选择出发与返程日期' : _dateRange,
            style: const TextStyle(fontSize: 12, color: AppColors.sageText),
          ),
        ),
        const Icon(Icons.expand_more, size: 17),
      ],
    ),
  );

  Widget _buildWebPlanningWorkspace() => Scaffold(
    backgroundColor: AppColors.neutralSoft,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.sageBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '规划行程',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sageText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentStep == 3
                              ? '$_title  ·  $_dateRange  ·  ${_selectedFigure?.name ?? ''}'
                              : '填写旅程信息，选择人物，再把地点串成路线。',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sageMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _setWebStep(1),
                    child: Text(
                      '01  旅程信息',
                      style: TextStyle(
                        color: _currentStep < 3
                            ? AppColors.brand
                            : AppColors.sageMuted,
                      ),
                    ),
                  ),
                  const Text(
                    ' / ',
                    style: TextStyle(color: AppColors.sageBorder),
                  ),
                  TextButton(
                    onPressed: _continueWebPlan,
                    child: Text(
                      '02  地点与路线',
                      style: TextStyle(
                        color: _currentStep == 3
                            ? AppColors.brand
                            : AppColors.sageMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _currentStep == 3
                  ? _buildMapStep()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 320,
                            child: _PanelFrame(
                              child: _buildPlanDetailsStep(desktop: true),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _PanelFrame(
                              child: Step1Figure(
                                selectedFigureId: _selectedFigureId,
                                onSelect: _selectFigure,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_currentStep < 3)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.sageBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFigure == null
                            ? '请选择一位同行人物'
                            : '与${_selectedFigure!.name}同行',
                        style: const TextStyle(
                          color: AppColors.sageMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _continueWebPlan,
                      child: const Text('选择地点与规划路线  →'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (_archiving) _buildArchiveOverlay(),
      ],
    ),
  );
}
