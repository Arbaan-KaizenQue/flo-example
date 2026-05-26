import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bloc/note/note_bloc.dart';
import '../../../data/models/note.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, required this.date});

  final DateTime date;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  Note? _existing;

  @override
  void initState() {
    super.initState();
    final existing = context.read<NoteBloc>().state.noteForDay(widget.date);
    _existing = existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _bodyCtrl = TextEditingController(text: existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<NoteBloc>().add(SaveNote(
          date: widget.date,
          title: _titleCtrl.text,
          body: _bodyCtrl.text,
        ));
    context.pop();
  }

  void _delete() {
    if (_existing == null) return;
    context.read<NoteBloc>().add(DeleteNote(id: _existing!.id));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d').format(widget.date)),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'How are you feeling today?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
