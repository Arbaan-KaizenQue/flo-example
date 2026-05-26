part of 'recommendation_bloc.dart';

class RecommendationState extends Equatable {
  const RecommendationState({
    this.isLoading = true,
    this.error = '',
    this.message = '',
    this.recommendations = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<Recommendation> recommendations;

  RecommendationState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<Recommendation>? recommendations,
  }) =>
      RecommendationState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        recommendations: recommendations ?? this.recommendations,
      );

  @override
  List<Object> get props => [isLoading, error, message, recommendations];
}
