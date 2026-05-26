import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/settings/settings_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => curr is AuthFailure,
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          if (state is AuthSignedIn) {
            return _SignedInView(state: state, busy: loading);
          }
          return _GuestView(busy: loading);
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'You are using the app as a guest',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with Google to back up your data to a private Drive folder.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () =>
                    context.read<AuthBloc>().add(const SignInRequested()),
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.state, required this.busy});

  final AuthSignedIn state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            backgroundImage:
                user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
            child: user.photoUrl == null
                ? Text(
                    (user.displayName ?? user.email).characters.first
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      color: scheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.displayName ?? user.email,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Center(
          child: Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: busy
              ? null
              : () => context
                  .read<SettingsBloc>()
                  .add(const SignOutFromSettings()),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
