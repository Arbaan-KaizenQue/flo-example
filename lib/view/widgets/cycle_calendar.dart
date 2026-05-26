import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';

/// [CycleCalendar] — monthly calendar styled for the cycle-tracking app.
///
/// Feature 01 wires up the visual shell only:
///   - month grid with swipe-to-change-month
///   - today highlighted with a pink ring
///   - selected day painted solid pink
///   - day-cell builder hook ready for period / ovulation dots
///     (will receive real data from Features 02 / 09 / 10)
class CycleCalendar extends StatelessWidget {
  const CycleCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    this.periodDays = const {},
    this.ovulationDays = const {},
  });

  /// The month currently visible.
  final DateTime focusedDay;

  /// The currently selected day inside [focusedDay]'s month.
  final DateTime selectedDay;

  /// Fired when the user taps a day.
  final void Function(DateTime selected, DateTime focused) onDaySelected;

  /// Days that should be marked as period days (Feature 02 will populate).
  final Set<DateTime> periodDays;

  /// Days that should be marked as predicted ovulation days
  /// (Features 09 / 10 will populate).
  final Set<DateTime> ovulationDays;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _containsDay(Set<DateTime> set, DateTime day) =>
      set.any((d) => _sameDay(d, day));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: TableCalendar<void>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => _sameDay(day, selectedDay),
          onDaySelected: onDaySelected,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600) ??
                const TextStyle(),
            leftChevronIcon:
                Icon(Icons.chevron_left, color: scheme.onSurface),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: scheme.onSurface),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: scheme.onSurfaceVariant),
            weekendStyle: TextStyle(color: scheme.onSurfaceVariant),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pink, width: 1.5),
            ),
            todayTextStyle: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            selectedDecoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.pink,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          calendarBuilders: CalendarBuilders<void>(
            markerBuilder: (context, day, _) {
              final isPeriod = _containsDay(periodDays, day);
              final isOvulation = _containsDay(ovulationDays, day);
              if (!isPeriod && !isOvulation) return const SizedBox.shrink();
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPeriod)
                      const _Dot(color: AppTheme.pink),
                    if (isPeriod && isOvulation) const SizedBox(width: 3),
                    if (isOvulation)
                      const _Dot(color: AppTheme.ovulationTeal),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
