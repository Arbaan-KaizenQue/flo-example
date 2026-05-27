import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/prediction/prediction_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Predicts PMS window (5 days before next period) and shows status
/// (Feature 22 — Hormonal Intelligence Engine).
class PmsPredictionCard extends StatelessWidget {
  const PmsPredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        if (state.pmsWindowStart == null || state.pmsWindowEnd == null) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final inPms = state.isInPmsWindow;
        final daysUntil = state.daysUntilPms ?? 0;
        final accent = inPms
            ? const Color(0xFFA855F7)
            : AppTheme.pink.withValues(alpha: 0.7);

        final title = inPms
            ? "You're in your PMS window"
            : daysUntil <= 0
                ? 'PMS expected soon'
                : daysUntil == 1
                    ? 'PMS expected tomorrow'
                    : 'PMS in $daysUntil days';

        final body = inPms
            ? 'Common symptoms — cramps, mood shifts, fatigue. '
                'Magnesium-rich food + sleep prep helps.'
            : 'Window: '
                '${DateFormat.MMMd().format(state.pmsWindowStart!.toLocal())}'
                ' – '
                '${DateFormat.MMMd().format(state.pmsWindowEnd!.toLocal())}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  inPms ? Icons.psychology_outlined : Icons.event_note_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
