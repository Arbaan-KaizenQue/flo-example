import 'package:objectbox/objectbox.dart';

/// [SymptomEntryEntity] — one entry per calendar day. Multiple selected
/// symptoms are stored as a comma-separated string in [symptomsCsv]
/// (ObjectBox supports `List<String>` but CSV keeps it simple + JSON-portable
/// for Drive sync later).
@Entity()
class SymptomEntryEntity {
  SymptomEntryEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.symptomsCsv = '',
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

  String symptomsCsv;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
