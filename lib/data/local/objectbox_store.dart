import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';
import 'entities/item_entity.dart';

/// [ObjectBoxStore] — singleton holder for the ObjectBox [Store] and
/// per-entity [Box] handles. Created once during app bootstrap and
/// passed into every datasource via constructor.
class ObjectBoxStore {
  ObjectBoxStore._(this.store) {
    itemBox = store.box<ItemEntity>();
  }

  final Store store;
  late final Box<ItemEntity> itemBox;

  static Future<ObjectBoxStore> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(dir.path, 'objectbox'));
    return ObjectBoxStore._(store);
  }
}
