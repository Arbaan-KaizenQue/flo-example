import 'package:uuid/uuid.dart';

import '../local/datasources/local_sleep_datasource.dart';
import '../local/entities/sleep_log_entity.dart';
import '../models/json_response.dart';
import '../models/sleep_log.dart';

/// [SleepRepository] — one [SleepLog] per date. `saveForDay` upserts.
abstract class SleepRepository {
  Stream<List<SleepLog>> watchAll();
  List<SleepLog> getAllIncludingDeleted();
  Future<JsonResponse> replaceAll(List<SleepLog> items);
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required double hours,
    required String quality,
  });
}

class SleepRepositoryImpl implements SleepRepository {
  SleepRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalSleepDataSource local;
  final Uuid _uuid;

  SleepLog _toModel(SleepLogEntity e) => SleepLog(
        id: e.id,
        date: e.date,
        hours: e.hours,
        quality: e.quality,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  SleepLogEntity? _findForDay(DateTime date) {
    for (final e in local.getAll()) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  SleepLogEntity _toEntity(SleepLog m) => SleepLogEntity(
        id: m.id,
        date: m.date,
        hours: m.hours,
        quality: m.quality,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        deleted: m.deleted,
      );

  @override
  Stream<List<SleepLog>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  List<SleepLog> getAllIncludingDeleted() =>
      local.getAllIncludingDeleted().map(_toModel).toList();

  @override
  Future<JsonResponse> replaceAll(List<SleepLog> items) async {
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
    required double hours,
    required String quality,
  }) async {
    try {
      final dayOnly = DateTime(date.year, date.month, date.day);
      final existing = _findForDay(dayOnly);
      final now = DateTime.now().toUtc();
      if (existing == null) {
        final entity = SleepLogEntity(
          id: _uuid.v4(),
          date: dayOnly,
          hours: hours,
          quality: quality,
          createdAt: now,
          updatedAt: now,
        );
        local.save(entity);
      } else {
        existing.hours = hours;
        existing.quality = quality;
        existing.updatedAt = now;
        existing.deleted = false;
        local.save(existing);
      }
      return JsonResponse.success(message: 'Sleep saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
