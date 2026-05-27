import '../../../objectbox.g.dart';
import '../entities/note_entity.dart';
import '../objectbox_store.dart';

class LocalNoteDataSource {
  LocalNoteDataSource({required this.store})
      : _box = store.store.box<NoteEntity>();

  final ObjectBoxStore store;
  final Box<NoteEntity> _box;

  List<NoteEntity> getAll() {
    final q = _box
        .query(NoteEntity_.deleted.equals(false))
        .order(NoteEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  NoteEntity? getById(String id) {
    final q = _box.query(NoteEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(NoteEntity entity) {
    final existing = getById(entity.id);
    if (existing != null) entity.obxId = existing.obxId;
    return _box.put(entity);
  }

  List<NoteEntity> getAllIncludingDeleted() => _box.getAll();

  void replaceAll(List<NoteEntity> items) {
    store.store.runInTransaction(TxMode.write, () {
      _box.removeAll();
      for (final i in items) {
        i.obxId = 0;
      }
      _box.putMany(items);
    });
  }

  Stream<List<NoteEntity>> watchAll() {
    final q = _box
        .query(NoteEntity_.deleted.equals(false))
        .order(NoteEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
