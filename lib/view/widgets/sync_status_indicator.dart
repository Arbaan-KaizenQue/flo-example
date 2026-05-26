import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/sync/sync_bloc.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return IconButton(
          tooltip: _tooltip(state),
          onPressed: state is Syncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncNow()),
          icon: switch (state) {
            Syncing() => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            SyncFailure() => Icon(
                Icons.cloud_off,
                color: Theme.of(context).colorScheme.error,
              ),
            SyncSuccess() => const Icon(Icons.cloud_done),
            SyncIdle() => const Icon(Icons.cloud_sync_outlined),
            _ => const Icon(Icons.cloud_outlined),
          },
        );
      },
    );
  }

  String _tooltip(SyncState state) {
    return switch (state) {
      Syncing() => 'Syncing…',
      SyncFailure(:final message) => 'Sync failed: $message',
      SyncSuccess(:final at) => 'Last synced ${_fmt(at)}',
      SyncIdle(:final lastSyncedAt) => lastSyncedAt == null
          ? 'Tap to sync'
          : 'Last synced ${_fmt(lastSyncedAt)}',
      _ => 'Sync',
    };
  }

  String _fmt(DateTime t) => DateFormat.MMMd().add_jm().format(t.toLocal());
}
