import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/mood/mood_bloc.dart';
import '../../data/models/mood_entry.dart';

/// Five mood levels with emoji + color. Single-select per day.
class MoodOption {
  const MoodOption(this.value, this.label, this.emoji, this.color);
  final String value;
  final String label;
  final String emoji;
  final Color color;
}

const List<MoodOption> kMoods = [
  MoodOption('amazing', 'Amazing', '😄', Color(0xFF22C55E)),
  MoodOption('good', 'Good', '😊', Color(0xFF14B8A6)),
  MoodOption('okay', 'Okay', '😐', Color(0xFFF59E0B)),
  MoodOption('low', 'Low', '😔', Color(0xFF6366F1)),
  MoodOption('awful', 'Awful', '😢', Color(0xFFEF4444)),
];

MoodOption? moodOptionFor(String value) {
  for (final m in kMoods) {
    if (m.value == value) return m;
  }
  return null;
}

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key, required this.date, required this.current});

  final DateTime date;
  final MoodEntry? current;

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  late String _selected;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.current?.mood ?? 'okay';
    _noteCtrl = TextEditingController(text: widget.current?.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<MoodBloc>().add(SaveMoodForDay(
          date: widget.date,
          mood: _selected,
          note: _noteCtrl.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          Text('How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge),
          Text(
            DateFormat('EEEE, MMM d').format(widget.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: kMoods.map((m) {
              final selected = _selected == m.value;
              return GestureDetector(
                onTap: () => setState(() => _selected = m.value),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: selected ? 54 : 46,
                      height: selected ? 54 : 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? m.color.withValues(alpha: 0.20)
                            : scheme.surfaceContainerHighest,
                        border: Border.all(
                          color: selected ? m.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        m.emoji,
                        style: TextStyle(fontSize: selected ? 26 : 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: selected ? m.color : scheme.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.w600 : null,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showMoodPickerSheet(
  BuildContext context, {
  required DateTime date,
  required MoodEntry? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<MoodBloc>(),
      child: MoodPickerSheet(date: date, current: current),
    ),
  );
}
