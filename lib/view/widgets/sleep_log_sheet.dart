import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/sleep/sleep_bloc.dart';
import '../../data/models/sleep_log.dart';

class SleepLogSheet extends StatefulWidget {
  const SleepLogSheet({super.key, required this.date, required this.current});

  final DateTime date;
  final SleepLog? current;

  @override
  State<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<SleepLogSheet> {
  late double _hours;
  late String _quality;

  static const _qualities = ['poor', 'fair', 'good', 'excellent'];

  @override
  void initState() {
    super.initState();
    _hours = widget.current?.hours ?? 7.5;
    _quality = widget.current?.quality ?? 'good';
  }

  void _save() {
    context.read<SleepBloc>().add(SaveSleepForDay(
          date: widget.date,
          hours: _hours,
          quality: _quality,
        ));
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
            Text('Sleep', style: Theme.of(context).textTheme.titleLarge),
            Text(
              DateFormat('EEEE, MMM d').format(widget.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_hours.toStringAsFixed(1)} hours',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Slider(
              value: _hours,
              min: 0,
              max: 14,
              divisions: 28,
              label: '${_hours.toStringAsFixed(1)}h',
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Quality',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _qualities
                  .map((q) => ChoiceChip(
                        label: Text(q[0].toUpperCase() + q.substring(1)),
                        selected: _quality == q,
                        onSelected: (_) => setState(() => _quality = q),
                      ))
                  .toList(),
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
