import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/recommendation.dart';
import 'insight_bubble.dart';

/// Detail view for a single insight, opened by tapping a bubble.
/// Modal bottom sheet — no chat, no input, dismiss-only.
class InsightDetailSheet extends StatelessWidget {
  const InsightDetailSheet({super.key, required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final scheme = Theme.of(context).colorScheme;
    final accent = InsightBubble.accentColor(r, scheme);
    final icon = InsightBubble.iconFor(r.type);
    final typeLabel = InsightBubble.labelFor(r.type);

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              r.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (r.createdAt != null)
                  _MetaChip(
                    icon: Icons.schedule,
                    label: 'Generated ${_fmt(r.createdAt!)}',
                  ),
                if (r.confidence != null)
                  _MetaChip(
                    icon: Icons.bolt_outlined,
                    label: 'Confidence ${(r.confidence! * 100).round()}%',
                  ),
                if (r.severity == RecommendationSeverity.warning)
                  _MetaChip(
                    icon: Icons.priority_high,
                    label: 'Worth a closer look',
                    accent: scheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final local = t.toLocal();
    final today = DateTime.now();
    if (today.year == local.year &&
        today.month == local.month &&
        today.day == local.day) {
      return 'today ${DateFormat.jm().format(local)}';
    }
    return DateFormat.MMMd().add_jm().format(local);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.accent});

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> showInsightDetailSheet(
  BuildContext context, {
  required Recommendation recommendation,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => InsightDetailSheet(recommendation: recommendation),
  );
}
