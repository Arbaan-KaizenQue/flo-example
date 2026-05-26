import 'package:objectbox/objectbox.dart';

/// Vestigial entity kept so the ObjectBox schema has at least one [Entity]
/// and existing on-device databases keep their UIDs (no schema reset).
/// Will be removed when Feature 02 (Cycle Logging) introduces real
/// data entities and there is something else to anchor the schema.
@Entity()
class ItemEntity {
  ItemEntity({this.obxId = 0});

  @Id()
  int obxId;
}
