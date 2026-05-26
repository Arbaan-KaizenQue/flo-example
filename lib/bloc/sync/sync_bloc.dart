import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/drive_repository.dart';

part 'sync_event.dart';
part 'sync_state.dart';

/// [SyncBloc] — orchestrates manual Drive sync.
/// Style B — Idle / Syncing / Success / Failure.
/// After Success/Failure, falls back to Idle carrying the latest timestamp.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({required this.driveRepository})
      : super(SyncIdle(lastSyncedAt: driveRepository.lastSyncedAt)) {
    on<SyncNow>(_onSyncNow);
  }

  final DriveRepository driveRepository;

  FutureOr<void> _onSyncNow(SyncNow event, Emitter<SyncState> emit) async {
    if (state is Syncing) return;
    emit(const Syncing());
    final res = await driveRepository.performSync();
    if (res.success && res.data is DateTime) {
      final at = res.data as DateTime;
      emit(SyncSuccess(at: at));
      emit(SyncIdle(lastSyncedAt: at));
    } else if (res.success) {
      emit(SyncIdle(lastSyncedAt: driveRepository.lastSyncedAt));
    } else {
      emit(SyncFailure(message: res.message));
      emit(SyncIdle(lastSyncedAt: driveRepository.lastSyncedAt));
    }
  }
}
