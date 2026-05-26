import 'package:uuid/uuid.dart';

import '../local/datasources/local_water_datasource.dart';
import '../local/entities/water_log_entity.dart';
import '../models/json_response.dart';
import '../models/water_log.dart';

/// [WaterRepository] — one [WaterLog] per date. `addAmount` is incremental;
/// `setGoal` updates the goal for the day's log.
abstract class WaterRepository {
  Stream<List<WaterLog>> watchAll();
  Future<JsonResponse> addAmount({required DateTime date, required int ml});
  Future<JsonResponse> setAmount({required DateTime date, required int ml});
  Future<JsonResponse> setGoal({required DateTime date, required int goalMl});
}

class WaterRepositoryImpl implements WaterRepository {
  WaterRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalWaterDataSource local;
  final Uuid _uuid;

  WaterLog _toModel(WaterLogEntity e) => WaterLog(
        id: e.id,
        date: e.date,
        amountMl: e.amountMl,
        goalMl: e.goalMl,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  WaterLogEntity? _findForDay(DateTime date) {
    final all = local.getAll();
    for (final e in all) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  WaterLogEntity _ensureForDay(DateTime date) {
    final existing = _findForDay(date);
    if (existing != null) return existing;
    final now = DateTime.now().toUtc();
    return WaterLogEntity(
      id: _uuid.v4(),
      date: DateTime(date.year, date.month, date.day),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<List<WaterLog>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> addAmount({
    required DateTime date,
    required int ml,
  }) async {
    try {
      final entity = _ensureForDay(date);
      entity.amountMl = (entity.amountMl + ml).clamp(0, 100000);
      entity.updatedAt = DateTime.now().toUtc();
      local.save(entity);
      return JsonResponse.success(message: 'Water added');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> setAmount({
    required DateTime date,
    required int ml,
  }) async {
    try {
      final entity = _ensureForDay(date);
      entity.amountMl = ml.clamp(0, 100000);
      entity.updatedAt = DateTime.now().toUtc();
      local.save(entity);
      return JsonResponse.success(message: 'Water updated');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> setGoal({
    required DateTime date,
    required int goalMl,
  }) async {
    try {
      final entity = _ensureForDay(date);
      entity.goalMl = goalMl.clamp(250, 10000);
      entity.updatedAt = DateTime.now().toUtc();
      local.save(entity);
      return JsonResponse.success(message: 'Goal updated');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
