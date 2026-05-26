import 'package:uuid/uuid.dart';

import '../local/datasources/local_item_datasource.dart';
import '../local/entities/item_entity.dart';
import '../models/item.dart';
import '../models/json_response.dart';

/// [ItemRepository] — local CRUD + sync-flag operations.
/// `watchAll()` returns a raw stream (not wrapped in [JsonResponse])
/// because streams represent a persistent subscription, not a one-shot call.
abstract class ItemRepository {
  Stream<List<Item>> watchAll();
  Future<JsonResponse> getAll();
  Future<JsonResponse> getAllIncludingDeleted();
  Future<JsonResponse> getById(String id);
  Future<JsonResponse> create({required String title, required String content});
  Future<JsonResponse> update(Item item);
  Future<JsonResponse> softDelete(String id);
  Future<JsonResponse> replaceAll(List<Item> items);
  Future<JsonResponse> markAllSynced();
  Future<JsonResponse> markAllUnsynced();
  Future<JsonResponse> getPendingSync();
}

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl({required this.local, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LocalItemDataSource local;
  final Uuid _uuid;

  Item _toItem(ItemEntity e) => Item(
        id: e.id,
        title: e.title,
        content: e.content,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deleted: e.deleted,
        syncedToDrive: e.syncedToDrive,
      );

  ItemEntity _toEntity(Item i) => ItemEntity(
        id: i.id,
        title: i.title,
        content: i.content,
        createdAt: i.createdAt,
        updatedAt: i.updatedAt,
        deleted: i.deleted,
        syncedToDrive: i.syncedToDrive,
      );

  @override
  Stream<List<Item>> watchAll() =>
      local.watchAll().map((list) => list.map(_toItem).toList());

  @override
  Future<JsonResponse> getAll() async {
    try {
      return JsonResponse.success(
        data: local.getAll().map(_toItem).toList(),
      );
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> getAllIncludingDeleted() async {
    try {
      return JsonResponse.success(
        data: local.getAllIncludingDeleted().map(_toItem).toList(),
      );
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> getById(String id) async {
    try {
      final e = local.getById(id);
      return JsonResponse.success(data: e == null ? null : _toItem(e));
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> create({
    required String title,
    required String content,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final item = Item(
        id: _uuid.v4(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      local.save(_toEntity(item));
      return JsonResponse.success(message: 'Created', data: item);
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> update(Item item) async {
    try {
      final updated = item.copyWith(
        updatedAt: DateTime.now().toUtc(),
        syncedToDrive: false,
      );
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
      e.syncedToDrive = false;
      local.save(e);
      return JsonResponse.success(message: 'Deleted');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> replaceAll(List<Item> items) async {
    try {
      local.replaceAll(items.map(_toEntity).toList());
      return JsonResponse.success(message: 'Replaced');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> markAllSynced() async {
    try {
      local.markAllSynced();
      return JsonResponse.success();
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> markAllUnsynced() async {
    try {
      local.markAllUnsynced();
      return JsonResponse.success();
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }

  @override
  Future<JsonResponse> getPendingSync() async {
    try {
      return JsonResponse.success(
        data: local.getPendingSync().map(_toItem).toList(),
      );
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
