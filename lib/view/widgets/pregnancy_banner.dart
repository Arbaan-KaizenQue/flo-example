import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/settings/settings_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Pink-gradient banner shown on the dashboard when [pregnancyModeEnabled]
/// is true. Compact card with weeks pregnant + due date + trimester chip.
class PregnancyBanner extends StatelessWidget {
  const PregnancyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.pregnancyModeEnabled != curr.pregnancyModeEnabled ||
          prev.pregnancyLmp != curr.pregnancyLmp,
      builder: (context, state) {
        final ctx = state.pregnancyContext;
        if (ctx == null) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final due = DateFormat('MMM d, yyyy').format(ctx.dueDate.toLocal());
        final weekProgress = (ctx.weeksPregnant / 40).clamp(0.0, 1.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.pink.withValues(alpha: 0.22),
                AppTheme.pink.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.pink.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pink,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.child_care,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${ctx.weeksPregnant}'
                          ' · Trimester ${ctx.trimester}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Due $due',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(40 - ctx.weeksPregnant).clamp(0, 40)}w left',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: weekProgress,
                  minHeight: 6,
                  backgroundColor: AppTheme.pink.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.pink),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
