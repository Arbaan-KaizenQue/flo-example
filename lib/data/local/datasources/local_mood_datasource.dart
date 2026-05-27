import '../../../objectbox.g.dart';
import '../entities/mood_entry_entity.dart';
import '../objectbox_store.dart';

class LocalMoodDataSource {
  LocalMoodDataSource({required this.store})
      : _box = store.store.box<MoodEntryEntity>();

  final ObjectBoxStore store;
  final Box<MoodEntryEntity> _box;

  List<MoodEntryEntity> getAll() {
    final q = _box
        .query(MoodEntryEntity_.deleted.equals(false))
        .order(MoodEntryEntity_.date, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  MoodEntryEntity? getById(String id) {
    final q = _box.query(MoodEntryEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  int save(MoodEntryEntity e) {
    final existing = getById(e.id);
    if (existing != null) e.obxId = existing.obxId;
    return _box.put(e);
  }

  Stream<List<MoodEntryEntity>> watchAll() {
    final q = _box
        .query(MoodEntryEntity_.deleted.equals(false))
        .order(MoodEntryEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
