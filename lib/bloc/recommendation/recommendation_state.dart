part of 'recommendation_bloc.dart';

class RecommendationState extends Equatable {
  const RecommendationState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.recommendations = const [],
    this.hasApiKey = false,
    this.lastUpdatedAt,
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<Recommendation> recommendations;
  final bool hasApiKey;
  final DateTime? lastUpdatedAt;

  RecommendationState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<Recommendation>? recommendations,
    bool? hasApiKey,
    DateTime? lastUpdatedAt,
  }) =>
      RecommendationState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        recommendations: recommendations ?? this.recommendations,
        hasApiKey: hasApiKey ?? this.hasApiKey,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );

  @override
  List<Object?> get props => [
        isLoading,
        error,
        message,
        recommendations,
        hasApiKey,
        lastUpdatedAt,
      ];
}
