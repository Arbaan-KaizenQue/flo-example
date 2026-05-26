import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';

/// [ObjectBoxStore] — singleton holder for the ObjectBox [Store].
/// Per-entity boxes are obtained via `store.box<EntityType>()` directly
/// from datasources as features add their entities.
class ObjectBoxStore {
  ObjectBoxStore._(this.store);

  final Store store;

  static Future<ObjectBoxStore> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(dir.path, 'objectbox'));
    return ObjectBoxStore._(store);
  }
}
