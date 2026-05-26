import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bloc/cycle_log/cycle_log_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cycle_log.dart';

/// [CycleLogFormPage] — create or edit a single [CycleLog].
/// Routed via path: `/cycle-log?date=YYYY-MM-DD` (date is the seed for
/// `startDate`). If a log already covers that date, opens in edit mode.
class CycleLogFormPage extends StatefulWidget {
  const CycleLogFormPage({super.key, this.seedDate});

  final DateTime? seedDate;

  @override
  State<CycleLogFormPage> createState() => _CycleLogFormPageState();
}

class _CycleLogFormPageState extends State<CycleLogFormPage> {
  late DateTime _startDate;
  DateTime? _endDate;
  String _flow = 'medium';
  CycleLog? _existing;

  static const _flows = ['light', 'medium', 'heavy'];

  @override
  void initState() {
    super.initState();
    final seed = widget.seedDate ?? DateTime.now();
    _startDate = DateTime(seed.year, seed.month, seed.day);

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
      _endDate = existing.endDate;
      _flow = existing.flow;
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
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

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16),
          children: [
            _DateRow(
              label: 'Start date',
              value: _startDate,
              onTap: _pickStart,
            ),
            const SizedBox(height: 12),
            _DateRow(
              label: 'End date',
              value: _endDate,
              hint: 'Ongoing',
              onTap: _pickEnd,
              onClear: _endDate == null
                  ? null
                  : () => setState(() => _endDate = null),
            ),
            const SizedBox(height: 24),
            Text(
              'Flow intensity',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _flows
                  .map((f) => ChoiceChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: _flow == f,
                        onSelected: (_) => setState(() => _flow = f),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.pink,
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

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final String? hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.calendar_today_outlined, color: scheme.primary),
        title: Text(label),
        subtitle: Text(
          value == null
              ? (hint ?? 'Pick a date')
              : DateFormat('EEE, MMM d, yyyy').format(value!),
        ),
        trailing: onClear == null
            ? const Icon(Icons.chevron_right)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
      ),
    );
  }
}
