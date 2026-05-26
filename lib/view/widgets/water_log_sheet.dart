import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/water/water_bloc.dart';
import '../../data/models/water_log.dart';

class WaterLogSheet extends StatelessWidget {
  const WaterLogSheet({super.key, required this.date, required this.current});

  final DateTime date;
  final WaterLog? current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = current?.amountMl ?? 0;
    final goal = current?.goalMl ?? 2000;
    final progress = current?.progress ?? 0;

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
            Text('Water', style: Theme.of(context).textTheme.titleLarge),
            Text(
              DateFormat('EEEE, MMM d').format(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(amount / 1000).toStringAsFixed(1)}L',
                          style:
                              Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'of ${(goal / 1000).toStringAsFixed(1)}L',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick add',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAddChip(label: '+200 ml', ml: 200, date: date),
                _QuickAddChip(label: '+330 ml', ml: 330, date: date),
                _QuickAddChip(label: '+500 ml', ml: 500, date: date),
                _QuickAddChip(label: '+750 ml', ml: 750, date: date),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove 200 ml'),
                    onPressed: () => context
                        .read<WaterBloc>()
                        .add(AddWater(date: date, ml: -200)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({
    required this.label,
    required this.ml,
    required this.date,
  });

  final String label;
  final int ml;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.water_drop_outlined, size: 18),
      label: Text(label),
      onPressed: () =>
          context.read<WaterBloc>().add(AddWater(date: date, ml: ml)),
    );
  }
}

Future<void> showWaterLogSheet(
  BuildContext context, {
  required DateTime date,
  required WaterLog? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<WaterBloc>(),
      child: WaterLogSheet(date: date, current: current),
    ),
  );
}
