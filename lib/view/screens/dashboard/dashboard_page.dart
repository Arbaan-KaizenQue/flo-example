import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/onboarding/onboarding_bloc.dart';
import '../../widgets/sync_status_indicator.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [SyncStatusIndicator()],
      ),
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final draft = state.draft;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                icon: Icons.favorite_border,
                title: 'Your cycle',
                body: draft.cycleLength.isEmpty
                    ? 'No cycle data yet'
                    : 'Typical length: ${draft.cycleLength}',
              ),
              _SummaryCard(
                icon: Icons.healing_outlined,
                title: 'Symptoms you track',
                body: draft.symptoms.isEmpty
                    ? 'None yet'
                    : draft.symptoms.join(' • '),
              ),
              _SummaryCard(
                icon: Icons.flag_outlined,
                title: 'Goals',
                body: draft.goals.isEmpty
                    ? 'No goals set'
                    : draft.goals.join(' • '),
              ),
              _SummaryCard(
                icon: Icons.person_outline,
                title: 'Profile',
                body: [
                  if (draft.ageGroup.isNotEmpty) 'Age: ${draft.ageGroup}',
                  if (draft.pregnancyStatus.isNotEmpty)
                    'Status: ${draft.pregnancyStatus}',
                ].join(' • '),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body.isEmpty ? '—' : body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
