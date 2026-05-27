import 'package:objectbox/objectbox.dart';

/// One mood entry per date. [mood] is one of:
/// 'amazing' | 'good' | 'okay' | 'low' | 'awful'.
@Entity()
class MoodEntryEntity {
  MoodEntryEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.mood = 'okay',
    this.note = '',
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

  String mood;
  String note;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
