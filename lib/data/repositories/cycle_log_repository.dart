import 'package:uuid/uuid.dart';

import '../local/datasources/local_cycle_log_datasource.dart';
import '../local/entities/cycle_log_entity.dart';
import '../models/cycle_log.dart';
import '../models/json_response.dart';

/// [CycleLogRepository] — local CRUD for cycle logs. [watchAll] returns a
/// raw stream because it's a long-lived subscription, not a one-shot call.
abstract class CycleLogRepository {
  Stream<List<CycleLog>> watchAll();
  Future<JsonResponse> getAll();
  List<CycleLog> getAllIncludingDeleted();
  Future<JsonResponse> getById(String id);
  Future<JsonResponse> create({
    required DateTime startDate,
    DateTime? endDate,
    String flow = 'medium',
  });
  Future<JsonResponse> update(CycleLog log);
  Future<JsonResponse> softDelete(String id);
  Future<JsonResponse> replaceAll(List<CycleLog> items);
}

class CycleLogRepositoryImpl implements CycleLogRepository {
  CycleLogRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalCycleLogDataSource local;
  final Uuid _uuid;

  CycleLog _toModel(CycleLogEntity e) => CycleLog(
        id: e.id,
        startDate: e.startDate,
        endDate: e.endDate,
        flow: e.flow,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
      );

  CycleLogEntity _toEntity(CycleLog m) => CycleLogEntity(
        id: m.id,
        startDate: m.startDate,
        endDate: m.endDate,
        flow: m.flow,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        deleted: m.deleted,
      );

  @override
  Stream<List<CycleLog>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> getAll() async {
    try {
      return JsonResponse.success(
        data: local.getAll().map(_toModel).toList(),
      );
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  List<CycleLog> getAllIncludingDeleted() =>
      local.getAllIncludingDeleted().map(_toModel).toList();

  @override
  Future<JsonResponse> replaceAll(List<CycleLog> items) async {
    try {
      local.replaceAll(items.map(_toEntity).toList());
      return JsonResponse.success(message: 'Replaced ${items.length} items');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> getById(String id) async {
    try {
      final e = local.getById(id);
      return JsonResponse.success(data: e == null ? null : _toModel(e));
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> create({
    required DateTime startDate,
    DateTime? endDate,
    String flow = 'medium',
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final log = CycleLog(
        id: _uuid.v4(),
        startDate: startDate,
        endDate: endDate,
        flow: flow,
        createdAt: now,
        updatedAt: now,
      );
      local.save(_toEntity(log));
      return JsonResponse.success(message: 'Period logged', data: log);
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> update(CycleLog log) async {
    try {
      final updated = log.copyWith(updatedAt: DateTime.now().toUtc());
      local.save(_toEntity(updated));
      return JsonResponse.success(message: 'Updated', data: updated);
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
