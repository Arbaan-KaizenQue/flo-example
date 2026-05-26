import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/recommendation.dart';

/// Dashboard section that renders the [RecommendationBloc]'s output.
/// Each tile expands on tap to show the full body. No chat — read-only.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationBloc, RecommendationState>(
      builder: (context, state) {
        if (state.isLoading && state.recommendations.isEmpty) {
          return const SizedBox.shrink();
        }
        if (state.recommendations.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Insights for you',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            for (final r in state.recommendations) ...[
              _InsightTile(recommendation: r),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _InsightTile extends StatefulWidget {
  const _InsightTile({required this.recommendation});

  final Recommendation recommendation;

  @override
  State<_InsightTile> createState() => _InsightTileState();
}

class _InsightTileState extends State<_InsightTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.recommendation;
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(r, scheme);
    final icon = _iconFor(r.type);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (r.severity == RecommendationSeverity.warning)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Heads up',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.error),
                            ),
                          ),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _expanded ? double.infinity : 36,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            r.body,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentColor(Recommendation r, ColorScheme scheme) {
    switch (r.type) {
      case RecommendationType.cycle:
        return AppTheme.pink;
      case RecommendationType.symptoms:
        return const Color(0xFFA855F7); // purple-500
      case RecommendationType.sleep:
        return const Color(0xFF6366F1); // indigo-500
      case RecommendationType.water:
        return const Color(0xFF06B6D4); // cyan-500
      case RecommendationType.profile:
        return AppTheme.ovulationTeal;
      case RecommendationType.general:
        return scheme.primary;
    }
  }

  IconData _iconFor(RecommendationType t) {
    switch (t) {
      case RecommendationType.cycle:
        return Icons.calendar_month_outlined;
      case RecommendationType.symptoms:
        return Icons.healing_outlined;
      case RecommendationType.sleep:
        return Icons.bedtime_outlined;
      case RecommendationType.water:
        return Icons.water_drop_outlined;
      case RecommendationType.profile:
        return Icons.person_outline;
      case RecommendationType.general:
        return Icons.tips_and_updates_outlined;
    }
  }
}
