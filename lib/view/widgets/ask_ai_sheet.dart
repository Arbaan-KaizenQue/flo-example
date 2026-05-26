import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet that lets the user pick **focus chips** and ask Gemini for
/// 2–3 insights scoped to those topics. No text input — the chips are the
/// "question". Dismisses on Generate; new bubbles appear in the dashboard
/// strip a moment later.
class AskAISheet extends StatefulWidget {
  const AskAISheet({super.key});

  @override
  State<AskAISheet> createState() => _AskAISheetState();
}

class _AskAISheetState extends State<AskAISheet> {
  /// Display label → API value sent to Gemini in the focus prompt.
  static const List<_FocusOption> _options = [
    _FocusOption('Cycle', 'cycle', Icons.calendar_month_outlined),
    _FocusOption('PMS', 'pms_forecast', Icons.event_note_outlined),
    _FocusOption('Sleep', 'sleep', Icons.bedtime_outlined),
    _FocusOption('Hydration', 'water', Icons.water_drop_outlined),
    _FocusOption('Symptoms', 'symptoms', Icons.healing_outlined),
    _FocusOption('Mood', 'mood_trend', Icons.sentiment_satisfied_outlined),
    _FocusOption('Recovery', 'recovery', Icons.spa_outlined),
    _FocusOption('Overall', 'wellness_summary', Icons.insights_outlined),
  ];

  final Set<String> _selected = <String>{};

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  void _generate() {
    if (_selected.isEmpty) return;
    context.read<RecommendationBloc>().add(
          GenerateFocusedInsights(focusAreas: _selected.toList()),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask for insight',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Pick what you want guidance on.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((opt) {
                final selected = _selected.contains(opt.value);
                return FilterChip(
                  label: Text(opt.label),
                  avatar: Icon(
                    opt.icon,
                    size: 16,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  selected: selected,
                  onSelected: (_) => _toggle(opt.value),
                  showCheckmark: false,
                  selectedColor: scheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              _selected.isEmpty
                  ? 'Pick at least one focus area.'
                  : '${_selected.length} area${_selected.length == 1 ? '' : 's'} selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.pink,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate'),
                    onPressed: _selected.isEmpty ? null : _generate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusOption {
  const _FocusOption(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

Future<void> showAskAISheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<RecommendationBloc>(),
      child: const AskAISheet(),
    ),
  );
}
