import 'package:objectbox/objectbox.dart';

/// [NoteEntity] — one note per date (journal entry). Title is optional.
@Entity()
class NoteEntity {
  NoteEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  @Property(type: PropertyType.date)
  DateTime date;

  String title;
  String body;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
