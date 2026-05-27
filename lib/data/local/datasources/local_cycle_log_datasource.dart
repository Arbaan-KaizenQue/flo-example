import '../../../objectbox.g.dart';
import '../entities/cycle_log_entity.dart';
import '../objectbox_store.dart';

class LocalCycleLogDataSource {
  LocalCycleLogDataSource({required this.store})
      : _box = store.store.box<CycleLogEntity>();

  final ObjectBoxStore store;
  final Box<CycleLogEntity> _box;

  List<CycleLogEntity> getAll() {
    final q = _box
        .query(CycleLogEntity_.deleted.equals(false))
        .order(CycleLogEntity_.startDate, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  CycleLogEntity? getById(String id) {
    final q = _box.query(CycleLogEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(CycleLogEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  List<CycleLogEntity> getAllIncludingDeleted() => _box.getAll();

  void replaceAll(List<CycleLogEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      _box.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      _box.putMany(items);
    });
  }

  Stream<List<CycleLogEntity>> watchAll() {
    final q = _box
        .query(CycleLogEntity_.deleted.equals(false))
        .order(CycleLogEntity_.startDate, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
