import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/prediction/prediction_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Card rendered on the dashboard summarizing the user's cycle prediction.
/// Reads [PredictionBloc.state] — no inputs.
class PredictionCard extends StatelessWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        if (!state.hasPrediction) {
          return _EmptyCard();
        }
        final scheme = Theme.of(context).colorScheme;
        final days = state.daysUntilNextPeriod ?? 0;
        final headline = days <= 0
            ? 'Period expected soon'
            : days == 1
                ? 'Period in 1 day'
                : 'Period in $days days';
        final subhead = state.nextPredictedPeriodStart == null
            ? ''
            : DateFormat('EEEE, MMM d')
                .format(state.nextPredictedPeriodStart!.toLocal());

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.pink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.pink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (subhead.isNotEmpty)
                            Text(
                              subhead,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      label: state.dayOfCycle == null
                          ? '—'
                          : 'Day ${state.dayOfCycle}',
                      icon: Icons.timelapse,
                    ),
                    _Pill(
                      label: 'Avg ${state.averageCycleLength}d',
                      icon: Icons.repeat,
                    ),
                    if (state.isFertileToday)
                      const _Pill(
                        label: 'Fertile today',
                        icon: Icons.spa_outlined,
                        accent: AppTheme.ovulationTeal,
                      )
                    else if (state.fertileWindowStart != null)
                      _Pill(
                        label:
                            'Fertile ${DateFormat.MMMd().format(state.fertileWindowStart!.toLocal())}'
                            '–${DateFormat.MMMd().format(state.fertileWindowEnd!.toLocal())}',
                        icon: Icons.spa_outlined,
                        accent: AppTheme.ovulationTeal,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.insights_outlined,
                  color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log your first period to unlock predictions.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, this.accent});

  final String label;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = accent == null
        ? scheme.primaryContainer
        : accent!.withValues(alpha: 0.18);
    final fg = accent ?? scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
