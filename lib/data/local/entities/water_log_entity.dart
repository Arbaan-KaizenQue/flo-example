import 'package:objectbox/objectbox.dart';

/// [WaterLogEntity] — accumulating daily water intake.
/// One row per date. [amountMl] is the running total for that day.
@Entity()
class WaterLogEntity {
  WaterLogEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.amountMl = 0,
    this.goalMl = 2000,
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

  int amountMl;
  int goalMl;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
