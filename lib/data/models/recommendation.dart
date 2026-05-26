import 'package:equatable/equatable.dart';

/// [RecommendationType] — drives icon + accent color in the UI.
/// Feature 21 expanded the set with pattern/forecast/summary types.
enum RecommendationType {
  // Original feature-11 set
  cycle,
  symptoms,
  sleep,
  water,
  profile,
  general,
  // Feature 21 — pattern + forecast + summary types
  pmsForecast,
  hydrationPattern,
  sleepPattern,
  moodTrend,
  recovery,
  wellnessSummary,
}

/// Visual weight.
enum RecommendationSeverity { info, suggestion, warning }

class Recommendation extends Equatable {
  const Recommendation({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.severity = RecommendationSeverity.info,
    this.confidence,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final RecommendationType type;
  final RecommendationSeverity severity;

  /// Optional 0.0–1.0 confidence reported by Gemini.
  final double? confidence;

  /// When this insight was generated.
  final DateTime? createdAt;

  Recommendation copyWith({
    String? title,
    String? body,
    RecommendationType? type,
    RecommendationSeverity? severity,
    double? confidence,
    DateTime? createdAt,
  }) =>
      Recommendation(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        severity: severity ?? this.severity,
        confidence: confidence ?? this.confidence,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, body, type, severity, confidence, createdAt];
}
