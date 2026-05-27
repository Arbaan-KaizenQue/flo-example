import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/settings/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.errorContainer,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) =>
          (prev.message != curr.message && curr.message.isNotEmpty) ||
          (prev.error != curr.error && curr.error.isNotEmpty),
      listener: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        if (state.error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: scheme.error,
            ),
          );
        } else if (state.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<SettingsBloc>();
        final isSignedIn = context.watch<AuthBloc>().state is AuthSignedIn;
        final lastSyncText = state.lastSyncedAt == null
            ? 'Never'
            : DateFormat.MMMd()
                .add_jm()
                .format(state.lastSyncedAt!.toLocal());
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              _PregnancyTile(state: state),
              const Divider(),
              SwitchListTile(
                title: const Text('Sync to Google Drive'),
                subtitle: Text(
                  isSignedIn
                      ? 'Back up your data to a hidden Drive folder.'
                      : 'Sign in on the Profile tab to enable backup.',
                ),
                value: state.driveEnabled,
                onChanged: (state.isLoading || !isSignedIn)
                    ? null
                    : (v) => cubit.add(ToggleDriveEnabled(enabled: v)),
              ),
              ListTile(
                title: const Text('Last synced'),
                subtitle: Text(lastSyncText),
                trailing: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sync now',
                        onPressed: state.driveEnabled
                            ? () => cubit.add(const SyncNowFromSettings())
                            : null,
                      ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.cloud_off,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete cloud backup'),
                subtitle: const Text(
                  'Removes backup.json from Drive. Local data is kept.',
                ),
                enabled: !state.isLoading && isSignedIn,
                onTap: () async {
                  final ok = await _confirm(
                    context,
                    title: 'Delete cloud backup?',
                    body:
                        'The remote backup will be deleted. Your local data '
                        'will remain.',
                    destructive: true,
                  );
                  if (ok == true && context.mounted) {
                    cubit.add(const DeleteCloudBackup());
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset onboarding'),
                subtitle: const Text(
                  'Clears your answers and walks you through onboarding again.',
                ),
                enabled: !state.isLoading,
                onTap: () async {
                  final ok = await _confirm(
                    context,
                    title: 'Reset onboarding?',
                    body:
                        'Your saved answers will be cleared. You will be '
                        'taken back to the onboarding flow on next launch.',
                  );
                  if (ok == true && context.mounted) {
                    cubit.add(const ResetOnboarding());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PregnancyTile extends StatelessWidget {
  const _PregnancyTile({required this.state});

  final SettingsState state;

  Future<DateTime?> _pickLmp(BuildContext context, DateTime? initial) {
    final today = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? today.subtract(const Duration(days: 56)),
      firstDate: today.subtract(const Duration(days: 280)),
      lastDate: today,
      helpText: 'Last menstrual period (LMP) start',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ctx = state.pregnancyContext;
    final lmpText = state.pregnancyLmp == null
        ? '—'
        : DateFormat('MMM d, yyyy').format(state.pregnancyLmp!.toLocal());

    return Column(
      children: [
        SwitchListTile(
          title: const Text("I'm pregnant"),
          subtitle: Text(
            ctx == null
                ? 'Switch the AI persona to pregnancy guidance.'
                : 'Week ${ctx.weeksPregnant} · '
                    'Due ${DateFormat('MMM d').format(ctx.dueDate.toLocal())}',
          ),
          value: state.pregnancyModeEnabled,
          onChanged: state.isLoading
              ? null
              : (v) async {
                  if (v) {
                    final picked = await _pickLmp(context, state.pregnancyLmp);
                    if (picked == null) return;
                    if (!context.mounted) return;
                    context.read<SettingsBloc>().add(
                          TogglePregnancyMode(enabled: true, lmp: picked),
                        );
                  } else {
                    context
                        .read<SettingsBloc>()
                        .add(const TogglePregnancyMode(enabled: false));
                  }
                },
        ),
        if (state.pregnancyModeEnabled)
          ListTile(
            leading: Icon(Icons.event_outlined, color: scheme.primary),
            title: const Text('Last period start (LMP)'),
            subtitle: Text(lmpText),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () async {
              final picked = await _pickLmp(context, state.pregnancyLmp);
              if (picked == null) return;
              if (!context.mounted) return;
              context.read<SettingsBloc>().add(SetPregnancyLmp(lmp: picked));
            },
          ),
      ],
    );
  }
}
