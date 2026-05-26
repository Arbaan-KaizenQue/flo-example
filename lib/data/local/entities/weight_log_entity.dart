import 'package:objectbox/objectbox.dart';

@Entity()
class WeightLogEntity {
  WeightLogEntity({
    this.obxId = 0,
    required this.id,
    required this.date,
    this.weightKg = 0,
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

  double weightKg;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
