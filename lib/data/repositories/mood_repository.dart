import 'package:uuid/uuid.dart';

import '../local/datasources/local_mood_datasource.dart';
import '../local/entities/mood_entry_entity.dart';
import '../models/json_response.dart';
import '../models/mood_entry.dart';

abstract class MoodRepository {
  Stream<List<MoodEntry>> watchAll();
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required String mood,
    String note = '',
  });
}

class MoodRepositoryImpl implements MoodRepository {
  MoodRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalMoodDataSource local;
  final Uuid _uuid;

  MoodEntry _toModel(MoodEntryEntity e) => MoodEntry(
        id: e.id,
        date: e.date,
        mood: e.mood,
        note: e.note,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  MoodEntryEntity? _findForDay(DateTime date) {
    for (final e in local.getAll()) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  @override
  Stream<List<MoodEntry>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required String mood,
    String note = '',
  }) async {
    try {
      final dayOnly = DateTime(date.year, date.month, date.day);
      final existing = _findForDay(dayOnly);
      final now = DateTime.now().toUtc();
      if (existing == null) {
        local.save(MoodEntryEntity(
          id: _uuid.v4(),
          date: dayOnly,
          mood: mood,
          note: note,
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        existing.mood = mood;
        existing.note = note;
        existing.updatedAt = now;
        existing.deleted = false;
        local.save(existing);
      }
      return JsonResponse.success(message: 'Mood saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
