import 'package:uuid/uuid.dart';

import '../local/datasources/local_note_datasource.dart';
import '../local/entities/note_entity.dart';
import '../models/json_response.dart';
import '../models/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchAll();
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required String title,
    required String body,
  });
  Future<JsonResponse> softDelete(String id);
}

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalNoteDataSource local;
  final Uuid _uuid;

  Note _toModel(NoteEntity e) => Note(
        id: e.id,
        date: e.date,
        title: e.title,
        body: e.body,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  NoteEntity? _findForDay(DateTime date) {
    for (final e in local.getAll()) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  @override
  Stream<List<Note>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required String title,
    required String body,
  }) async {
    try {
      final dayOnly = DateTime(date.year, date.month, date.day);
      final existing = _findForDay(dayOnly);
      final now = DateTime.now().toUtc();
      final cleanTitle = title.trim();
      final cleanBody = body.trim();
      final isEmpty = cleanTitle.isEmpty && cleanBody.isEmpty;

      if (existing == null) {
        if (isEmpty) return JsonResponse.success(message: 'Nothing to save');
        final entity = NoteEntity(
          id: _uuid.v4(),
          date: dayOnly,
          title: cleanTitle,
          body: cleanBody,
          createdAt: now,
          updatedAt: now,
        );
        local.save(entity);
      } else {
        existing.title = cleanTitle;
        existing.body = cleanBody;
        existing.updatedAt = now;
        existing.deleted = isEmpty; // soft-delete on empty
        local.save(existing);
      }
      return JsonResponse.success(message: 'Note saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> softDelete(String id) async {
    try {
      final e = local.getById(id);
      if (e == null) {
        return JsonResponse.failure(message: 'Not found', statusCode: 404);
      }
      e.deleted = true;
      e.updatedAt = DateTime.now().toUtc();
      local.save(e);
      return JsonResponse.success(message: 'Deleted');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
