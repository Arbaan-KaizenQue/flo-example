import 'package:uuid/uuid.dart';

import '../local/datasources/local_weight_datasource.dart';
import '../local/entities/weight_log_entity.dart';
import '../models/json_response.dart';
import '../models/weight_log.dart';

/// [WeightRepository] — one [WeightLog] per date. `saveForDay` upserts.
abstract class WeightRepository {
  Stream<List<WeightLog>> watchAll();
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required double weightKg,
  });
}

class WeightRepositoryImpl implements WeightRepository {
  WeightRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalWeightDataSource local;
  final Uuid _uuid;

  WeightLog _toModel(WeightLogEntity e) => WeightLog(
        id: e.id,
        date: e.date,
        weightKg: e.weightKg,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  WeightLogEntity? _findForDay(DateTime date) {
    for (final e in local.getAll()) {
      if (_sameDay(e.date, date)) return e;
    }
    return null;
  }

  @override
  Stream<List<WeightLog>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> saveForDay({
    required DateTime date,
    required double weightKg,
  }) async {
    try {
      final dayOnly = DateTime(date.year, date.month, date.day);
      final existing = _findForDay(dayOnly);
      final now = DateTime.now().toUtc();
      if (existing == null) {
        final entity = WeightLogEntity(
          id: _uuid.v4(),
          date: dayOnly,
          weightKg: weightKg,
          createdAt: now,
          updatedAt: now,
        );
        local.save(entity);
      } else {
        existing.weightKg = weightKg;
        existing.updatedAt = now;
        existing.deleted = false;
        local.save(existing);
      }
      return JsonResponse.success(message: 'Weight saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
