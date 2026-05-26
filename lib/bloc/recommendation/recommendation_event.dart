part of 'recommendation_bloc.dart';

abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();

  @override
  List<Object?> get props => [];
}

class WatchRecommendations extends RecommendationEvent {
  const WatchRecommendations();
}

/// Internal — fired by any source-stream listener after caching its slice.
class _RecomputeRecommendations extends RecommendationEvent {
  const _RecomputeRecommendations();
}
