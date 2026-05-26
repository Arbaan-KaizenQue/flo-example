import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bloc/cycle_log/cycle_log_bloc.dart';
import '../../../bloc/note/note_bloc.dart';
import '../../../bloc/onboarding/onboarding_bloc.dart';
import '../../../bloc/sleep/sleep_bloc.dart';
import '../../../bloc/symptom/symptom_bloc.dart';
import '../../../bloc/water/water_bloc.dart';
import '../../../bloc/weight/weight_bloc.dart';
import '../../../core/route/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cycle_log.dart';
import '../../../data/models/note.dart';
import '../../../data/models/sleep_log.dart';
import '../../../data/models/symptom_entry.dart';
import '../../../data/models/water_log.dart';
import '../../../data/models/weight_log.dart';
import '../../widgets/cycle_calendar.dart';
import '../../widgets/daily_metric_chip.dart';
import '../../widgets/sleep_log_sheet.dart';
import '../../widgets/symptom_picker_sheet.dart';
import '../../widgets/sync_status_indicator.dart';
import '../../widgets/water_log_sheet.dart';
import '../../widgets/weight_log_sheet.dart';

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
    context.pushNamed(
      cycleLogFormRoute,
      queryParameters: {'date': DateFormat('yyyy-MM-dd').format(day)},
    );
  }

  void _openNoteEditor(DateTime day) {
    context.pushNamed(
      noteEditorRoute,
      queryParameters: {'date': DateFormat('yyyy-MM-dd').format(day)},
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
            return BlocBuilder<SymptomBloc, SymptomState>(
              builder: (context, symptomState) {
                return BlocBuilder<WaterBloc, WaterState>(
                  builder: (context, waterState) {
                    return BlocBuilder<SleepBloc, SleepState>(
                      builder: (context, sleepState) {
                    return BlocBuilder<WeightBloc, WeightState>(
                      builder: (context, weightState) {
                    return BlocBuilder<NoteBloc, NoteState>(
                      builder: (context, noteState) {
                    return BlocBuilder<OnboardingBloc, OnboardingState>(
                      builder: (context, onboardState) {
                        final draft = onboardState.draft;
                        final logForDay = logState.logForDay(_selectedDay);
                        final symptomEntry =
                            symptomState.entryForDay(_selectedDay);
                        final waterLog =
                            waterState.logForDay(_selectedDay);
                        final sleepLog =
                            sleepState.logForDay(_selectedDay);
                        final weightLog =
                            weightState.logForDay(_selectedDay) ??
                                weightState.latest;
                        final noteForDay =
                            noteState.noteForDay(_selectedDay);

                        return ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                              symptomEntry: symptomEntry,
                              waterLog: waterLog,
                              sleepLog: sleepLog,
                              onLogPeriod: () => _openLogForm(_selectedDay),
                              onLogSymptoms: () => showSymptomPickerSheet(
                                context,
                                date: _selectedDay,
                                initialSelection:
                                    symptomEntry?.symptoms ?? const [],
                              ),
                              onLogWater: () => showWaterLogSheet(
                                context,
                                date: _selectedDay,
                                current: waterLog,
                              ),
                              onLogSleep: () => showSleepLogSheet(
                                context,
                                date: _selectedDay,
                                current: sleepLog,
                              ),
                              weightLog: weightLog,
                              onLogWeight: () => showWeightLogSheet(
                                context,
                                date: _selectedDay,
                                current:
                                    weightState.logForDay(_selectedDay),
                              ),
                              noteForDay: noteForDay,
                              onOpenNote: () =>
                                  _openNoteEditor(_selectedDay),
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
                    );
                    },
                    );
                    },
                    );
                  },
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
    required this.symptomEntry,
    required this.waterLog,
    required this.sleepLog,
    required this.weightLog,
    required this.noteForDay,
    required this.onLogPeriod,
    required this.onLogSymptoms,
    required this.onLogWater,
    required this.onLogSleep,
    required this.onLogWeight,
    required this.onOpenNote,
  });

  final DateTime selectedDay;
  final CycleLog? logForDay;
  final SymptomEntry? symptomEntry;
  final WaterLog? waterLog;
  final SleepLog? sleepLog;
  final WeightLog? weightLog;
  final Note? noteForDay;
  final VoidCallback onLogPeriod;
  final VoidCallback onLogSymptoms;
  final VoidCallback onLogWater;
  final VoidCallback onLogSleep;
  final VoidCallback onLogWeight;
  final VoidCallback onOpenNote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPeriod = logForDay != null;
    final hasSymptoms =
        symptomEntry != null && symptomEntry!.symptoms.isNotEmpty;

    final waterValue = waterLog == null
        ? '0 / 2.0L'
        : '${(waterLog!.amountMl / 1000).toStringAsFixed(1)}'
            ' / ${(waterLog!.goalMl / 1000).toStringAsFixed(1)}L';
    final sleepValue = sleepLog == null
        ? '—'
        : '${sleepLog!.hours.toStringAsFixed(1)}h • ${sleepLog!.quality}';
    final weightValue =
        weightLog == null ? '—' : '${weightLog!.weightKg.toStringAsFixed(1)} kg';
    final noteValue = noteForDay == null
        ? 'Tap to add'
        : (noteForDay!.title.isNotEmpty
            ? noteForDay!.title
            : noteForDay!.body);

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
                    color: hasPeriod
                        ? AppTheme.pink
                        : scheme.onPrimaryContainer,
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
                            : 'No period logged for this day.',
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
            if (hasSymptoms) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: symptomEntry!.symptoms
                    .map((s) => Chip(
                          label: Text(
                            s,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Quick-log row (notes lands here when Feature 08 ships).
            Row(
              children: [
                Expanded(
                  child: DailyMetricChip(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    value: waterValue,
                    onTap: onLogWater,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DailyMetricChip(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep',
                    value: sleepValue,
                    onTap: onLogSleep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DailyMetricChip(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: weightValue,
                    onTap: onLogWeight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DailyMetricChip(
                    icon: Icons.edit_note_outlined,
                    label: 'Notes',
                    value: noteValue,
                    onTap: onOpenNote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.pink,
                    ),
                    icon: Icon(
                      hasPeriod ? Icons.edit_outlined : Icons.add,
                    ),
                    label: Text(hasPeriod ? 'Edit period' : 'Log period'),
                    onPressed: onLogPeriod,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: Icon(
                      hasSymptoms ? Icons.edit_outlined : Icons.add,
                    ),
                    label:
                        Text(hasSymptoms ? 'Edit symptoms' : 'Log symptoms'),
                    onPressed: onLogSymptoms,
                  ),
                ),
              ],
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
