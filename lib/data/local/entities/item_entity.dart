import 'package:objectbox/objectbox.dart';

/// [ItemEntity] — ObjectBox row backing each [Item].
@Entity()
class ItemEntity {
  ItemEntity({
    this.obxId = 0,
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.syncedToDrive = false,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String title;
  String content;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
  bool syncedToDrive;
}
