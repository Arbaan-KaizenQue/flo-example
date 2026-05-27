import '../../../objectbox.g.dart';
import '../entities/symptom_entry_entity.dart';
import '../objectbox_store.dart';

class LocalSymptomDataSource {
  LocalSymptomDataSource({required this.store})
      : _box = store.store.box<SymptomEntryEntity>();

  final ObjectBoxStore store;
  final Box<SymptomEntryEntity> _box;

  List<SymptomEntryEntity> getAll() {
    final q = _box
        .query(SymptomEntryEntity_.deleted.equals(false))
        .order(SymptomEntryEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  SymptomEntryEntity? getById(String id) {
    final q = _box.query(SymptomEntryEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(SymptomEntryEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  List<SymptomEntryEntity> getAllIncludingDeleted() => _box.getAll();

  void replaceAll(List<SymptomEntryEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      _box.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      _box.putMany(items);
    });
  }

  Stream<List<SymptomEntryEntity>> watchAll() {
    final q = _box
        .query(SymptomEntryEntity_.deleted.equals(false))
        .order(SymptomEntryEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
