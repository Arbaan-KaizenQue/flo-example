import '../local/datasources/local_ai_insight_datasource.dart';
import '../local/entities/ai_insight_entity.dart';
import '../models/json_response.dart';
import '../models/recommendation.dart';

abstract class AIInsightRepository {
  Stream<List<Recommendation>> watchAll();
  Future<JsonResponse> saveMany(List<Recommendation> insights);
}

class AIInsightRepositoryImpl implements AIInsightRepository {
  const AIInsightRepositoryImpl({required this.local});

  final LocalAIInsightDataSource local;

  static const int _maxStored = 50;

  Recommendation _toModel(AIInsightEntity e) => Recommendation(
        id: e.id,
        title: e.title,
        body: e.body,
        type: _safeType(e.typeIndex),
        severity: _safeSeverity(e.severityIndex),
        confidence: e.confidence,
        createdAt: e.createdAt,
      );

  AIInsightEntity _toEntity(Recommendation r) => AIInsightEntity(
        id: r.id,
        title: r.title,
        body: r.body,
        typeIndex: r.type.index,
        severityIndex: r.severity.index,
        confidence: r.confidence ?? 0.7,
        createdAt: r.createdAt ?? DateTime.now().toUtc(),
      );

  static RecommendationType _safeType(int idx) =>
      (idx >= 0 && idx < RecommendationType.values.length)
          ? RecommendationType.values[idx]
          : RecommendationType.general;

  static RecommendationSeverity _safeSeverity(int idx) =>
      (idx >= 0 && idx < RecommendationSeverity.values.length)
          ? RecommendationSeverity.values[idx]
          : RecommendationSeverity.info;

  @override
  Stream<List<Recommendation>> watchAll() =>
      local.watchAll().map((list) => list.map(_toModel).toList());

  @override
  Future<JsonResponse> saveMany(List<Recommendation> insights) async {
    try {
      local.upsertMany(insights.map(_toEntity).toList());
      local.pruneOlderThanCount(_maxStored);
      return JsonResponse.success(message: 'Saved');
    } catch (e) {
      return JsonResponse.failure(message: '$e');
    }
  }
}
