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

class _GenerationStarted extends RecommendationEvent {
  const _GenerationStarted();
}

class _GenerationFinished extends RecommendationEvent {
  const _GenerationFinished({this.recommendations, this.error});

  final List<Recommendation>? recommendations;
  final String? error;

  @override
  List<Object?> get props => [recommendations, error];
}
