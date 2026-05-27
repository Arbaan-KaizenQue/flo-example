import '../../../objectbox.g.dart';
import '../entities/weight_log_entity.dart';
import '../objectbox_store.dart';

class LocalWeightDataSource {
  LocalWeightDataSource({required this.store})
      : _box = store.store.box<WeightLogEntity>();

  final ObjectBoxStore store;
  final Box<WeightLogEntity> _box;

  List<WeightLogEntity> getAll() {
    final q = _box
        .query(WeightLogEntity_.deleted.equals(false))
        .order(WeightLogEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  WeightLogEntity? getById(String id) {
    final q = _box.query(WeightLogEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(WeightLogEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  List<WeightLogEntity> getAllIncludingDeleted() => _box.getAll();

  void replaceAll(List<WeightLogEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      _box.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      _box.putMany(items);
    });
  }

  Stream<List<WeightLogEntity>> watchAll() {
    final q = _box
        .query(WeightLogEntity_.deleted.equals(false))
        .order(WeightLogEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
