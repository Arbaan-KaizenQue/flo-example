import '../../../objectbox.g.dart';
import '../entities/water_log_entity.dart';
import '../objectbox_store.dart';

class LocalWaterDataSource {
  LocalWaterDataSource({required this.store})
      : _box = store.store.box<WaterLogEntity>();

  final ObjectBoxStore store;
  final Box<WaterLogEntity> _box;

  List<WaterLogEntity> getAll() {
    final q = _box
        .query(WaterLogEntity_.deleted.equals(false))
        .order(WaterLogEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  WaterLogEntity? getById(String id) {
    final q = _box.query(WaterLogEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(WaterLogEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  List<WaterLogEntity> getAllIncludingDeleted() => _box.getAll();

  void replaceAll(List<WaterLogEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      _box.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      _box.putMany(items);
    });
  }

  Stream<List<WaterLogEntity>> watchAll() {
    final q = _box
        .query(WaterLogEntity_.deleted.equals(false))
        .order(WaterLogEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
