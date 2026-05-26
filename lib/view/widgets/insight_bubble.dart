import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/recommendation.dart';

/// Compact horizontally-scrolling "bubble" for an AI insight.
/// Owner widget handles tap → detail modal.
class InsightBubble extends StatelessWidget {
  const InsightBubble({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  final Recommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor(r, scheme);
    final icon = iconFor(r.type);
    final typeLabel = labelFor(r.type);

    return SizedBox(
      width: 220,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accent, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                    if (r.severity == RecommendationSeverity.warning)
                      Icon(Icons.priority_high,
                          size: 14, color: scheme.error),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Shared lookups (used here AND in the detail sheet)
  // ============================================================

  static Color accentColor(Recommendation r, ColorScheme scheme) {
    switch (r.type) {
      case RecommendationType.cycle:
      case RecommendationType.pmsForecast:
        return AppTheme.pink;
      case RecommendationType.symptoms:
        return const Color(0xFFA855F7);
      case RecommendationType.sleep:
      case RecommendationType.sleepPattern:
        return const Color(0xFF6366F1);
      case RecommendationType.water:
      case RecommendationType.hydrationPattern:
        return const Color(0xFF06B6D4);
      case RecommendationType.moodTrend:
        return const Color(0xFFEC4899);
      case RecommendationType.recovery:
        return AppTheme.ovulationTeal;
      case RecommendationType.wellnessSummary:
        return const Color(0xFF22C55E);
      case RecommendationType.profile:
      case RecommendationType.general:
        return scheme.primary;
    }
  }

  static IconData iconFor(RecommendationType t) {
    switch (t) {
      case RecommendationType.cycle:
        return Icons.calendar_month_outlined;
      case RecommendationType.symptoms:
        return Icons.healing_outlined;
      case RecommendationType.sleep:
      case RecommendationType.sleepPattern:
        return Icons.bedtime_outlined;
      case RecommendationType.water:
      case RecommendationType.hydrationPattern:
        return Icons.water_drop_outlined;
      case RecommendationType.profile:
        return Icons.person_outline;
      case RecommendationType.pmsForecast:
        return Icons.event_note_outlined;
      case RecommendationType.moodTrend:
        return Icons.sentiment_satisfied_outlined;
      case RecommendationType.recovery:
        return Icons.spa_outlined;
      case RecommendationType.wellnessSummary:
        return Icons.insights_outlined;
      case RecommendationType.general:
        return Icons.tips_and_updates_outlined;
    }
  }

  static String labelFor(RecommendationType t) {
    switch (t) {
      case RecommendationType.cycle:
        return 'CYCLE';
      case RecommendationType.symptoms:
        return 'SYMPTOMS';
      case RecommendationType.sleep:
        return 'SLEEP';
      case RecommendationType.sleepPattern:
        return 'SLEEP PATTERN';
      case RecommendationType.water:
        return 'HYDRATION';
      case RecommendationType.hydrationPattern:
        return 'HYDRATION PATTERN';
      case RecommendationType.profile:
        return 'PROFILE';
      case RecommendationType.pmsForecast:
        return 'PMS FORECAST';
      case RecommendationType.moodTrend:
        return 'MOOD TREND';
      case RecommendationType.recovery:
        return 'RECOVERY';
      case RecommendationType.wellnessSummary:
        return 'WELLNESS SUMMARY';
      case RecommendationType.general:
        return 'INSIGHT';
    }
  }
}
