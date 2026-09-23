import 'package:flutter/material.dart';

import '../models/travel_preferences.dart';
import '../services/profile_preferences.dart';
import '../theme/color_schemes.dart';

/// 旅行偏好页：选择偏好朝代、主题、节奏与常用交通方式。
///
/// Phase 1 仅保存在本机，用于后续路线推荐；云端同步见
/// `docs/supabase_profile_schema.md`。
class TravelPreferencesPage extends StatefulWidget {
  const TravelPreferencesPage({super.key, this.preferences});

  final ProfilePreferences? preferences;

  @override
  State<TravelPreferencesPage> createState() => _TravelPreferencesPageState();
}

class _TravelPreferencesPageState extends State<TravelPreferencesPage> {
  late final ProfilePreferences _preferences;
  TravelPreferences _value = TravelPreferences.defaults;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? ProfilePreferences();
    _load();
  }

  Future<void> _load() async {
    final state = await _preferences.load();
    if (!mounted) return;
    setState(() {
      _value = state.travelPreferences;
      _loading = false;
    });
  }

  void _toggleDynasty(String dynasty) {
    final next = Set<String>.from(_value.dynasties);
    if (!next.remove(dynasty)) next.add(dynasty);
    setState(() => _value = _value.copyWith(dynasties: next));
  }

  void _toggleTheme(String theme) {
    final next = Set<String>.from(_value.themes);
    if (!next.remove(theme)) next.add(theme);
    setState(() => _value = _value.copyWith(themes: next));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _preferences.saveTravelPreferences(_value);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('旅行偏好已保存')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      appBar: AppBar(
        backgroundColor: AppColors.sageBg,
        foregroundColor: AppColors.sageText,
        elevation: 0,
        title: const Text('旅行偏好'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: <Widget>[
                  _buildLocalOnlyBanner('偏好暂存于本机，将用于后续路线推荐；云端同步将在后续版本提供。'),
                  const SizedBox(height: 24),
                  _buildSectionTitle('偏好朝代'),
                  const SizedBox(height: 12),
                  _buildMultiSelect(
                    options: TravelPreferences.dynastyOptions,
                    selected: _value.dynasties,
                    keyPrefix: 'travel-dynasty',
                    onToggle: _toggleDynasty,
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('偏好主题'),
                  const SizedBox(height: 12),
                  _buildMultiSelect(
                    options: TravelPreferences.themeOptions,
                    selected: _value.themes,
                    keyPrefix: 'travel-theme',
                    onToggle: _toggleTheme,
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('旅行节奏'),
                  const SizedBox(height: 12),
                  _buildSingleSelect<TravelPace>(
                    values: TravelPace.values,
                    selected: _value.pace,
                    keyPrefix: 'travel-pace',
                    labelOf: (pace) => pace.label,
                    idOf: (pace) => pace.name,
                    onSelected: (pace) =>
                        setState(() => _value = _value.copyWith(pace: pace)),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('常用交通方式'),
                  const SizedBox(height: 12),
                  _buildSingleSelect<TravelTransport>(
                    values: TravelTransport.values,
                    selected: _value.transport,
                    keyPrefix: 'travel-transport',
                    labelOf: (transport) => transport.label,
                    idOf: (transport) => transport.name,
                    onSelected: (transport) => setState(
                      () => _value = _value.copyWith(transport: transport),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('travel-save-button'),
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageDeep,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存偏好'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMultiSelect({
    required List<String> options,
    required Set<String> selected,
    required String keyPrefix,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final option in options)
          FilterChip(
            key: Key('$keyPrefix-$option'),
            label: Text(option),
            selected: selected.contains(option),
            onSelected: (_) => onToggle(option),
            selectedColor: AppColors.brandLight,
            checkmarkColor: AppColors.sageAccent,
            backgroundColor: AppColors.sageCard,
            side: const BorderSide(color: AppColors.sageBorder),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.sageText,
            ),
          ),
      ],
    );
  }

  Widget _buildSingleSelect<T>({
    required List<T> values,
    required T selected,
    required String keyPrefix,
    required String Function(T value) labelOf,
    required String Function(T value) idOf,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final value in values)
          ChoiceChip(
            key: Key('$keyPrefix-${idOf(value)}'),
            label: Text(labelOf(value)),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.brandLight,
            checkmarkColor: AppColors.sageAccent,
            backgroundColor: AppColors.sageCard,
            side: const BorderSide(color: AppColors.sageBorder),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.sageText,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.sageAccent,
      ),
    );
  }

  Widget _buildLocalOnlyBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandLight),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: AppColors.sageAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.sageMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
