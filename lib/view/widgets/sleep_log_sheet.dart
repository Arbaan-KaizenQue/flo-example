import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/sleep/sleep_bloc.dart';
import '../../data/models/sleep_log.dart';

/// Quality is derived from hours — user no longer picks it manually.
/// Brackets:
///   < 5h         → poor
///   5h to <7h    → fair
///   7h to <9h    → good
///   ≥ 9h         → excellent
String _qualityForHours(double h) {
  if (h < 5) return 'poor';
  if (h < 7) return 'fair';
  if (h < 9) return 'good';
  return 'excellent';
}

Color _colorForQuality(String q, ColorScheme scheme) {
  switch (q) {
    case 'poor':
      return scheme.error;
    case 'fair':
      return const Color(0xFFF59E0B); // amber-500
    case 'good':
      return const Color(0xFF22C55E); // green-500
    case 'excellent':
      return const Color(0xFF14B8A6); // teal-500
  }
  return scheme.primary;
}

class SleepLogSheet extends StatefulWidget {
  const SleepLogSheet({super.key, required this.date, required this.current});

  final DateTime date;
  final SleepLog? current;

  @override
  State<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<SleepLogSheet> {
  late double _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.current?.hours ?? 7.5;
  }

  void _save() {
    context.read<SleepBloc>().add(SaveSleepForDay(
          date: widget.date,
          hours: _hours,
          quality: _qualityForHours(_hours),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quality = _qualityForHours(_hours);
    final color = _colorForQuality(quality, scheme);
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
            Text('Sleep', style: Theme.of(context).textTheme.titleLarge),
            Text(
              DateFormat('EEEE, MMM d').format(widget.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '${_hours.toStringAsFixed(1)} hours',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  _QualityBadge(quality: quality, color: color),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _hours,
              min: 0,
              max: 14,
              divisions: 28,
              label: '${_hours.toStringAsFixed(1)}h',
              activeColor: color,
              onChanged: (v) => setState(() => _hours = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                  Text('14h',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
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

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.quality, required this.color});

  final String quality;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            quality[0].toUpperCase() + quality.substring(1),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSleepLogSheet(
  BuildContext context, {
  required DateTime date,
  required SleepLog? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<SleepBloc>(),
      child: SleepLogSheet(date: date, current: current),
    ),
  );
}
