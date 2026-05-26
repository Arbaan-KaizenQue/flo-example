import '../../../objectbox.g.dart';
import '../entities/sleep_log_entity.dart';
import '../objectbox_store.dart';

class LocalSleepDataSource {
  LocalSleepDataSource({required this.store})
      : _box = store.store.box<SleepLogEntity>();

  final ObjectBoxStore store;
  final Box<SleepLogEntity> _box;

  List<SleepLogEntity> getAll() {
    final q = _box
        .query(SleepLogEntity_.deleted.equals(false))
        .order(SleepLogEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  SleepLogEntity? getById(String id) {
    final q = _box.query(SleepLogEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(SleepLogEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  Stream<List<SleepLogEntity>> watchAll() {
    final q = _box
        .query(SleepLogEntity_.deleted.equals(false))
        .order(SleepLogEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
