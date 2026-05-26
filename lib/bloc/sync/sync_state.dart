part of 'sync_bloc.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  const SyncIdle({this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  List<Object?> get props => [lastSyncedAt];
}

class Syncing extends SyncState {
  const Syncing();
}

class SyncSuccess extends SyncState {
  const SyncSuccess({required this.at});

  final DateTime at;

  @override
  List<Object> get props => [at];
}

class SyncFailure extends SyncState {
  const SyncFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
