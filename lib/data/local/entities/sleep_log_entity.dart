import 'package:objectbox/objectbox.dart';

@Entity()
class SleepLogEntity {
  SleepLogEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.hours = 0,
    this.quality = 'good',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  /// Date this sleep ENDED on (the morning the user woke up).
  @Property(type: PropertyType.date)
  DateTime date;

  /// Hours of sleep (e.g., 7.5).
  double hours;

  /// 'poor' | 'fair' | 'good' | 'excellent'
  String quality;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
