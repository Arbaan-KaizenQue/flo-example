import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/weight/weight_bloc.dart';
import '../../data/models/weight_log.dart';

class WeightLogSheet extends StatefulWidget {
  const WeightLogSheet({super.key, required this.date, required this.current});

  final DateTime date;
  final WeightLog? current;

  @override
  State<WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<WeightLogSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final v = widget.current?.weightKg ?? 60.0;
    _controller = TextEditingController(text: v.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return;
    context.read<WeightBloc>().add(SaveWeightForDay(
          date: widget.date,
          weightKg: parsed,
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
          Text('Weight', style: Theme.of(context).textTheme.titleLarge),
          Text(
            DateFormat('EEEE, MMM d').format(widget.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
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
    );
  }
}

Future<void> showWeightLogSheet(
  BuildContext context, {
  required DateTime date,
  required WeightLog? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<WeightBloc>(),
      child: WeightLogSheet(date: date, current: current),
    ),
  );
}
