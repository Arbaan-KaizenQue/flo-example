import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/recommendation.dart';

/// Dashboard section that renders Gemini's recommendations.
/// Read-only. Tap a card to expand its body. Refresh icon in the header
/// bypasses the cache.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationBloc, RecommendationState>(
      builder: (context, state) {
        if (!state.hasApiKey) return const _NoKeyHint();
        if (state.isLoading && state.recommendations.isEmpty) {
          return const _LoadingSkeleton();
        }
        if (state.error.isNotEmpty && state.recommendations.isEmpty) {
          return _ErrorCard(message: state.error);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(state: state),
            const SizedBox(height: 8),
            for (final r in state.recommendations) ...[
              _InsightTile(recommendation: r),
              const SizedBox(height: 8),
            ],
            if (state.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last refresh failed: ${state.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final RecommendationState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = state.lastUpdatedAt;
    final subtitle = state.isLoading
        ? 'Generating…'
        : last == null
            ? 'Tap refresh to generate'
            : 'Updated ${DateFormat.jm().format(last.toLocal())}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            'Insights for you',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            onPressed: state.isLoading
                ? null
                : () => context
                    .read<RecommendationBloc>()
                    .add(const RefreshRecommendations()),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              'Insights for you',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NoKeyHint extends StatelessWidget {
  const _NoKeyHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.key_off_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI insights are off',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Add a Gemini API key to `.env` at the project root, '
                  'then restart the app.',
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
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Couldn\'t generate insights',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<RecommendationBloc>()
                .add(const RefreshRecommendations()),
          ),
        ],
      ),
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
                          _expanded ? Icons.expand_less : Icons.expand_more,
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
        return const Color(0xFFA855F7);
      case RecommendationType.sleep:
        return const Color(0xFF6366F1);
      case RecommendationType.water:
        return const Color(0xFF06B6D4);
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
