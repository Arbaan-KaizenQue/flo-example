import 'package:uuid/uuid.dart';

import '../local/datasources/local_symptom_datasource.dart';
import '../local/entities/symptom_entry_entity.dart';
import '../models/json_response.dart';
import '../models/symptom_entry.dart';

/// [SymptomRepository] — one [SymptomEntry] per date. `saveForDay` is the
/// canonical write op: if an entry exists for that date, update it; else
/// create a new one. Passing an empty list soft-deletes the entry.
abstract class SymptomRepository {
  Stream<List<SymptomEntry>> watchAll();
  List<SymptomEntry> getAllIncludingDeleted();
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required List<String> symptoms,
  });
  Future<JsonResponse> softDeleteForDay(DateTime date);
  Future<JsonResponse> replaceAll(List<SymptomEntry> items);
}

class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalSymptomDataSource local;
  final Uuid _uuid;

  SymptomEntry _toModel(SymptomEntryEntity e) => SymptomEntry(
        id: e.id,
        date: e.date,
        symptoms: e.symptomsCsv.isEmpty
            ? const []
            : e.symptomsCsv.split('|'),
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  SymptomEntryEntity? _findForDay(DateTime date) {
    final all = local.getAll();
    for (final e in all) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  SymptomEntryEntity _toEntity(SymptomEntry m) => SymptomEntryEntity(
        id: m.id,
        date: m.date,
        symptomsCsv: m.symptoms.join('|'),
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        deleted: m.deleted,
      );

  @override
  Stream<List<SymptomEntry>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  List<SymptomEntry> getAllIncludingDeleted() =>
      local.getAllIncludingDeleted().map(_toModel).toList();

  @override
  Future<JsonResponse> replaceAll(List<SymptomEntry> items) async {
    try {
      local.replaceAll(items.map(_toEntity).toList());
      return JsonResponse.success(message: 'Replaced ${items.length} items');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required List<String> symptoms,
  }) async {
    try {
      final dayOnly = DateTime(date.year, date.month, date.day);
      final csv = symptoms.join('|');
      final existing = _findForDay(dayOnly);
      final now = DateTime.now().toUtc();
      if (existing == null) {
        if (symptoms.isEmpty) {
          return JsonResponse.success(message: 'Nothing to save');
        }
        final entity = SymptomEntryEntity(
          id: _uuid.v4(),
          date: dayOnly,
          symptomsCsv: csv,
          createdAt: now,
          updatedAt: now,
        );
        local.save(entity);
      } else {
        existing.symptomsCsv = csv;
        existing.updatedAt = now;
        existing.deleted = symptoms.isEmpty; // soft-delete on clear
        local.save(existing);
      }
      return JsonResponse.success(message: 'Symptoms saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> softDeleteForDay(DateTime date) async {
    try {
      final entity = _findForDay(date);
      if (entity == null) return JsonResponse.success(message: 'Nothing');
      entity.deleted = true;
      entity.updatedAt = DateTime.now().toUtc();
      local.save(entity);
      return JsonResponse.success(message: 'Deleted');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
