import '../../../objectbox.g.dart';
import '../entities/item_entity.dart';
import '../objectbox_store.dart';

/// [LocalItemDataSource] — thin synchronous wrapper around the ObjectBox
/// [ItemEntity] box. Repositories call this; UI never touches it directly.
class LocalItemDataSource {
  LocalItemDataSource({required this.store});

  final ObjectBoxStore store;

  List<ItemEntity> getAll() {
    final q = store.itemBox
        .query(ItemEntity_.deleted.equals(false))
        .order(ItemEntity_.updatedAt, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  List<ItemEntity> getAllIncludingDeleted() => store.itemBox.getAll();

  ItemEntity? getById(String id) {
    final q = store.itemBox.query(ItemEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(ItemEntity item) {
    final existing = getById(item.id);
    if (existing != null) item.obxId = existing.obxId;
    return store.itemBox.put(item);
  }

  void replaceAll(List<ItemEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      store.itemBox.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      store.itemBox.putMany(items);
    });
  }

  void markAllSynced() {
    final all = store.itemBox.getAll();
    for (final i in all) {
      i.syncedToDrive = true;
    }
    store.itemBox.putMany(all);
  }

  void markAllUnsynced() {
    final all = store.itemBox.getAll();
    for (final i in all) {
      i.syncedToDrive = false;
    }
    store.itemBox.putMany(all);
  }

  List<ItemEntity> getPendingSync() {
    final q = store.itemBox
        .query(ItemEntity_.syncedToDrive.equals(false))
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  Stream<List<ItemEntity>> watchAll() {
    final q = store.itemBox
        .query(ItemEntity_.deleted.equals(false))
        .order(ItemEntity_.updatedAt, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
