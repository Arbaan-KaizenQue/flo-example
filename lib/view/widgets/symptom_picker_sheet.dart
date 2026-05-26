import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/symptom/symptom_bloc.dart';

/// Bottom sheet for picking the symptoms felt on a given day.
/// Show it via [showSymptomPickerSheet] — handles state + save.
class SymptomPickerSheet extends StatefulWidget {
  const SymptomPickerSheet({
    super.key,
    required this.date,
    required this.initialSelection,
  });

  final DateTime date;
  final List<String> initialSelection;

  @override
  State<SymptomPickerSheet> createState() => _SymptomPickerSheetState();
}

class _SymptomPickerSheetState extends State<SymptomPickerSheet> {
  static const _all = <String>[
    'Cramps',
    'Headache',
    'Mood swings',
    'Fatigue',
    'Bloating',
    'Acne',
    'Tender breasts',
    'Backache',
    'Nausea',
    'Cravings',
    'Insomnia',
  ];

  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
  }

  void _toggle(String s) {
    setState(() {
      if (_selected.contains(s)) {
        _selected.remove(s);
      } else {
        _selected.add(s);
      }
    });
  }

  void _save() {
    context.read<SymptomBloc>().add(SaveSymptomsForDay(
          date: widget.date,
          symptoms: _selected.toList(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            Text(
              'Symptoms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              DateFormat('EEEE, MMM d').format(widget.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _all
                  .map((s) => FilterChip(
                        label: Text(s),
                        selected: _selected.contains(s),
                        onSelected: (_) => _toggle(s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }
}

Future<void> showSymptomPickerSheet(
  BuildContext context, {
  required DateTime date,
  required List<String> initialSelection,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetCtx) {
      // Re-provide the SymptomBloc so the sheet can dispatch save events.
      return BlocProvider.value(
        value: context.read<SymptomBloc>(),
        child: SymptomPickerSheet(
          date: date,
          initialSelection: initialSelection,
        ),
      );
    },
  );
}
