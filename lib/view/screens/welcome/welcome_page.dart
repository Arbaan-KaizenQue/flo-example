import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../../core/route/routes.dart';
import '../../../core/theme/app_theme.dart';

/// First-launch welcome.
///
/// Two paths:
///   • Sign in with Google → if a Drive backup exists, restore it and jump
///     straight to the dashboard. If no backup, fall into Privacy →
///     Onboarding like a guest, but with Drive already enabled.
///   • Continue as guest → mark welcomeSeen and start the normal Privacy →
///     Onboarding flow.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _signInInFlight = false;
  bool _restoring = false;

  Future<void> _onSignIn() async {
    if (_signInInFlight || _restoring) return;
    setState(() => _signInInFlight = true);
    context.read<AuthBloc>().add(const SignInRequested());
  }

  void _onGuest() {
    if (_signInInFlight || _restoring) return;
    context.read<SettingsBloc>().add(const MarkWelcomeSeen());
    context.goNamed(privacyRoute);
  }

  Future<void> _handleSignedIn() async {
    if (_restoring) return;
    setState(() {
      _signInInFlight = false;
      _restoring = true;
    });
    final settings = context.read<SettingsBloc>();
    final restored = await settings.attemptRestoreOnSignIn();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (restored) {
      // Skip privacy/onboarding — user already set those up before.
      context.goNamed(dashboardRoute);
    } else {
      // No backup found; treat them as a new user with Drive already on.
      context.goNamed(privacyRoute);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (!_signInInFlight && !_restoring) return;
          if (state is AuthSignedIn) {
            _handleSignedIn();
          } else if (state is AuthFailure) {
            setState(() => _signInInFlight = false);
            _showError(state.message);
          } else if (state is AuthSignedOut && _signInInFlight) {
            // User cancelled the Google account picker.
            setState(() => _signInInFlight = false);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.pink.withValues(alpha: 0.18),
                scheme.surface,
                AppTheme.ovulationTeal.withValues(alpha: 0.10),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                children: [
                  const Spacer(),
                  _Hero(),
                  const SizedBox(height: 28),
                  Text(
                    'Hello, welcome to Aura',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _restoring
                        ? 'Restoring your data from Google Drive…'
                        : 'Your private, local-first wellness companion.\n'
                            'Sign in to restore your data, or start fresh as a guest.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(flex: 2),
                  _GradientButton(
                    label: _signInInFlight
                        ? 'Opening Google…'
                        : _restoring
                            ? 'Restoring…'
                            : 'Sign in with Google',
                    icon: Icons.login,
                    loading: _signInInFlight || _restoring,
                    onTap: _onSignIn,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _signInInFlight || _restoring ? null : _onGuest,
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      foregroundColor: scheme.onSurface,
                    ),
                    child: const Text(
                      'Continue as guest',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your data stays on your device either way.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.pink.withValues(alpha: 0.30),
            AppTheme.pink.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.pink,
              Color(0xFFFF6B9D),
            ],
          ),
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppTheme.pink,
              Color(0xFFFF6B9D),
              Color(0xFFC2185B),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pink.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
