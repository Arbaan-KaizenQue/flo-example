import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/prediction/prediction_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Compact card showing current cycle phase + a one-line hormonal note
/// (Feature 22 — Hormonal Intelligence Engine).
class PhaseIntelligenceCard extends StatelessWidget {
  const PhaseIntelligenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        if (!state.hasPrediction || state.currentPhase == CyclePhase.unknown) {
          return const SizedBox.shrink();
        }
        final info = _phaseInfo(state.currentPhase);
        final scheme = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: info.color.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: info.color.withValues(alpha: 0.18),
                ),
                alignment: Alignment.center,
                child: Icon(info.icon, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.label} phase',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      info.tagline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (state.dayOfCycle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${state.dayOfCycle}',
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _PhaseInfo _phaseInfo(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:
        return const _PhaseInfo(
          label: 'Menstrual',
          tagline: 'Low energy is normal — iron + rest help most.',
          color: AppTheme.pink,
          icon: Icons.water_drop,
        );
      case CyclePhase.follicular:
        return const _PhaseInfo(
          label: 'Follicular',
          tagline: 'Energy rising. Great window for harder workouts.',
          color: Color(0xFFFF6B9D),
          icon: Icons.local_florist_outlined,
        );
      case CyclePhase.ovulatory:
        return const _PhaseInfo(
          label: 'Ovulatory',
          tagline: 'Peak energy + libido. Fertile window is now.',
          color: AppTheme.ovulationTeal,
          icon: Icons.spa_outlined,
        );
      case CyclePhase.luteal:
        return const _PhaseInfo(
          label: 'Luteal',
          tagline: 'Slow down — protein + magnesium ease PMS later.',
          color: Color(0xFF8B5CF6),
          icon: Icons.nightlight_outlined,
        );
      case CyclePhase.unknown:
        return const _PhaseInfo(
          label: 'Cycle',
          tagline: 'Keep logging to unlock phase intelligence.',
          color: AppTheme.pink,
          icon: Icons.timelapse,
        );
    }
  }
}

class _PhaseInfo {
  const _PhaseInfo({
    required this.label,
    required this.tagline,
    required this.color,
    required this.icon,
  });

  final String label;
  final String tagline;
  final Color color;
  final IconData icon;
}
