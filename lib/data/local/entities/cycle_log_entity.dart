import 'package:objectbox/objectbox.dart';

/// [CycleLogEntity] — one logged period (start → end + flow intensity).
/// Soft-delete pattern via [deleted] so the row survives for future Drive
/// sync (Feature 14 / 16).
@Entity()
class CycleLogEntity {
  CycleLogEntity({
    this.obxId = 0,
    required this.id,
    required this.startDate,
    this.endDate,
    this.flow = 'medium',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  @Property(type: PropertyType.date)
  DateTime startDate;

  @Property(type: PropertyType.date)
  DateTime? endDate;

  /// 'light' | 'medium' | 'heavy'
  String flow;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;
}
