import 'package:objectbox/objectbox.dart';

/// [AIInsightEntity] — persisted AI-generated insight. Lets us show
/// stale insights when offline and build a monthly recap later (Phase 2).
@Entity()
class AIInsightEntity {
  AIInsightEntity({
    this.obxId = 0,
    required this.id,
    required this.title,
    required this.body,
    required this.typeIndex,
    required this.severityIndex,
    this.confidence = 0.7,
    required this.createdAt,
    this.deleted = false,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String title;
  String body;

  /// Index into [RecommendationType.values].
  int typeIndex;

  /// Index into [RecommendationSeverity.values].
  int severityIndex;

  double confidence;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  bool deleted;
}
