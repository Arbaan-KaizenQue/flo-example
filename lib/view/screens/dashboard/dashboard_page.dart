import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bloc/cycle_log/cycle_log_bloc.dart';
import '../../../bloc/onboarding/onboarding_bloc.dart';
import '../../../core/route/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cycle_log.dart';
import '../../widgets/cycle_calendar.dart';
import '../../widgets/sync_status_indicator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
      _focusedDay = focused;
    });
  }

  void _openLogForm(DateTime day) {
    final isoDate = DateFormat('yyyy-MM-dd').format(day);
    context.pushNamed(
      cycleLogFormRoute,
      queryParameters: {'date': isoDate},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [SyncStatusIndicator()],
      ),
      body: SafeArea(
        child: BlocBuilder<CycleLogBloc, CycleLogState>(
          builder: (context, logState) {
            return BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, onboardState) {
                final draft = onboardState.draft;
                final logForDay = logState.logForDay(_selectedDay);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Greeting(),
                    const SizedBox(height: 16),
                    CycleCalendar(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onDaySelected: _onDaySelected,
                      periodDays: logState.periodDays,
                    ),
                    const SizedBox(height: 12),
                    _SelectedDayCard(
                      selectedDay: _selectedDay,
                      logForDay: logForDay,
                      onLogPeriod: () => _openLogForm(_selectedDay),
                    ),
                    const SizedBox(height: 20),
                    if (draft.cycleLength.isNotEmpty ||
                        draft.symptoms.isNotEmpty ||
                        draft.goals.isNotEmpty)
                      ..._summaryCards(context, draft),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _summaryCards(BuildContext context, dynamic draft) {
    final tiles = <_MiniCardData>[
      if (draft.cycleLength.isNotEmpty)
        _MiniCardData(
          icon: Icons.favorite_border,
          label: 'Cycle',
          value: draft.cycleLength,
        ),
      if (draft.symptoms.isNotEmpty)
        _MiniCardData(
          icon: Icons.healing_outlined,
          label: 'Symptoms',
          value: '${draft.symptoms.length} tracked',
        ),
      if (draft.goals.isNotEmpty)
        _MiniCardData(
          icon: Icons.flag_outlined,
          label: 'Goals',
          value: '${draft.goals.length} active',
        ),
    ];
    return [
      Text('Your profile', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: tiles
            .map((d) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: tiles.last == d ? 0 : 8),
                    child: _MiniCard(data: d),
                  ),
                ))
            .toList(),
      ),
    ];
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.pink.withValues(alpha: 0.15),
            scheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTheme.pink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.favorite, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salutation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.selectedDay,
    required this.logForDay,
    required this.onLogPeriod,
  });

  final DateTime selectedDay;
  final CycleLog? logForDay;
  final VoidCallback onLogPeriod;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPeriod = logForDay != null;
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
                    color: hasPeriod
                        ? AppTheme.pink.withValues(alpha: 0.18)
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasPeriod
                        ? Icons.water_drop
                        : Icons.calendar_today_outlined,
                    color: hasPeriod ? AppTheme.pink : scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(selectedDay),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPeriod
                            ? 'Period • ${logForDay!.flow[0].toUpperCase()}${logForDay!.flow.substring(1)} flow'
                            : 'No logs for this day yet.',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.pink,
              ),
              icon: Icon(hasPeriod ? Icons.edit_outlined : Icons.add),
              label: Text(hasPeriod ? 'Edit period' : 'Log period'),
              onPressed: onLogPeriod,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCardData {
  const _MiniCardData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.data});

  final _MiniCardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: scheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
