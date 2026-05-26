import 'package:equatable/equatable.dart';

/// [RecommendationType] — drives icon + accent color in the UI.
enum RecommendationType { cycle, symptoms, sleep, water, profile, general }

/// Visual weight of the recommendation.
/// `info` is neutral; `suggestion` nudges the user; `warning` flags something
/// that probably needs attention (e.g., very low sleep / hydration).
enum RecommendationSeverity { info, suggestion, warning }

class Recommendation extends Equatable {
  const Recommendation({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.severity = RecommendationSeverity.info,
  });

  /// Stable string id so the UI can dedupe / animate list changes.
  final String id;
  final String title;
  final String body;
  final RecommendationType type;
  final RecommendationSeverity severity;

  @override
  List<Object?> get props => [id, title, body, type, severity];
}
