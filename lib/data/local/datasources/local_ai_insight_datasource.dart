import '../../../objectbox.g.dart';
import '../entities/ai_insight_entity.dart';
import '../objectbox_store.dart';

class LocalAIInsightDataSource {
  LocalAIInsightDataSource({required this.store})
      : _box = store.store.box<AIInsightEntity>();

  final ObjectBoxStore store;
  final Box<AIInsightEntity> _box;

  List<AIInsightEntity> getAll() {
    final q = _box
        .query(AIInsightEntity_.deleted.equals(false))
        .order(AIInsightEntity_.createdAt, flags: Order.descending)
        .build();
    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  AIInsightEntity? getById(String id) {
    final q = _box.query(AIInsightEntity_.id.equals(id)).build();
    try {
      return q.findFirst();
    } finally {
      q.close();
    }
  }

  void upsertMany(List<AIInsightEntity> insights) {
    for (final entity in insights) {
      final existing = getById(entity.id);
      if (existing != null) entity.obxId = existing.obxId;
    }
    _box.putMany(insights);
  }

  /// Soft-deletes everything older than [keep] most-recent rows.
  void pruneOlderThanCount(int keep) {
    final all = _box.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (all.length <= keep) return;
    final stale = all.sublist(keep);
    for (final e in stale) {
      e.deleted = true;
    }
    _box.putMany(stale);
  }

  Stream<List<AIInsightEntity>> watchAll() {
    final q = _box
        .query(AIInsightEntity_.deleted.equals(false))
        .order(AIInsightEntity_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true);
    return q.map((q) => q.find());
  }
}
