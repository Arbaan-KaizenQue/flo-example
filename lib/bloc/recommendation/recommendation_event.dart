part of 'recommendation_bloc.dart';

abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();

  @override
  List<Object?> get props => [];
}

class WatchRecommendations extends RecommendationEvent {
  const WatchRecommendations();
}

/// Manual refresh — bypasses debounce + cache.
class RefreshRecommendations extends RecommendationEvent {
  const RefreshRecommendations();
}

class _RecomputeRequested extends RecommendationEvent {
  const _RecomputeRequested();
}

class _StoredInsightsLoaded extends RecommendationEvent {
  const _StoredInsightsLoaded({required this.insights});

  final List<Recommendation> insights;

  @override
  List<Object?> get props => [insights];
}

class _GenerationStarted extends RecommendationEvent {
  const _GenerationStarted();
}

class _GenerationFinished extends RecommendationEvent {
  const _GenerationFinished({this.insights, this.wellnessScore, this.error});

  final List<Recommendation>? insights;
  final int? wellnessScore;
  final String? error;

  @override
  List<Object?> get props => [insights, wellnessScore, error];
}
