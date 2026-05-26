import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../bloc/cycle_log/cycle_log_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cycle_log.dart';

/// [CycleLogFormPage] — pick a start day on the calendar; the end day is
/// auto-derived from the selected flow intensity. Tapping a new day moves
/// the whole range. Changing flow recomputes the range length.
class CycleLogFormPage extends StatefulWidget {
  const CycleLogFormPage({super.key, this.seedDate});

  final DateTime? seedDate;

  @override
  State<CycleLogFormPage> createState() => _CycleLogFormPageState();
}

class _CycleLogFormPageState extends State<CycleLogFormPage> {
  /// Default range length in days for each flow intensity.
  static const Map<String, int> _flowDays = {
    'light': 4,
    'medium': 6,
    'heavy': 7,
  };
  static const _flows = ['light', 'medium', 'heavy'];

  late DateTime _startDate;
  late String _flow;
  CycleLog? _existing;
  late DateTime _focusedDay;

  DateTime get _endDate {
    final days = _flowDays[_flow] ?? 5;
    return _startDate.add(Duration(days: days - 1));
  }

  @override
  void initState() {
    super.initState();
    final seed = widget.seedDate ?? DateTime.now();
    _startDate = DateTime(seed.year, seed.month, seed.day);
    _flow = 'medium';
    _focusedDay = _startDate;

    // If a log already covers the seed date, pre-fill for edit.
    final state = context.read<CycleLogBloc>().state;
    final existing = state.logForDay(_startDate);
    if (existing != null) {
      _existing = existing;
      _startDate = DateTime(
        existing.startDate.year,
        existing.startDate.month,
        existing.startDate.day,
      );
      _flow = existing.flow;
      _focusedDay = _startDate;
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _startDate =
          DateTime(selected.year, selected.month, selected.day);
      _focusedDay = focused;
    });
  }

  void _save() {
    context.read<CycleLogBloc>().add(SaveCycleLog(
          startDate: _startDate,
          endDate: _endDate,
          flow: _flow,
          existing: _existing,
        ));
    context.pop();
  }

  void _delete() {
    if (_existing == null) return;
    context.read<CycleLogBloc>().add(DeleteCycleLog(id: _existing!.id));
    context.pop();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = _existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit period' : 'Log period'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Tap your period start day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'We\'ll mark the next ${_flowDays[_flow]} days based on '
              'your flow.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: TableCalendar<void>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: CalendarFormat.month,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  rangeStartDay: _startDate,
                  rangeEndDay: _endDate,
                  rangeSelectionMode: RangeSelectionMode.toggledOff,
                  onDaySelected: _onDaySelected,
                  selectedDayPredicate: (d) => _sameDay(d, _startDate),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: scheme.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: scheme.onSurface,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.pink, width: 1.2),
                    ),
                    todayTextStyle: TextStyle(color: scheme.onSurface),
                    rangeStartDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pink,
                    ),
                    rangeStartTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pink.withValues(alpha: 0.8),
                    ),
                    rangeEndTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    withinRangeDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pink.withValues(alpha: 0.25),
                    ),
                    withinRangeTextStyle:
                        TextStyle(color: scheme.onSurface),
                    rangeHighlightColor:
                        AppTheme.pink.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RangeSummary(
              start: _startDate,
              end: _endDate,
              days: _flowDays[_flow] ?? 5,
            ),
            const SizedBox(height: 20),
            Text(
              'Flow intensity',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _flows
                  .map((f) => ChoiceChip(
                        label: Text(
                          '${f[0].toUpperCase()}${f.substring(1)} '
                          '· ${_flowDays[f]}d',
                        ),
                        selected: _flow == f,
                        onSelected: (_) => setState(() => _flow = f),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.pink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _save,
              child: Text(isEdit ? 'Save changes' : 'Log period'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({
    required this.start,
    required this.end,
    required this.days,
  });

  final DateTime start;
  final DateTime end;
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('EEE, MMM d');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.pink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppTheme.pink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmt.format(start)}  →  ${fmt.format(end)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$days days',
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
