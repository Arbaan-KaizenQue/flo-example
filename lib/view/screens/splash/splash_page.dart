import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/settings/settings_bloc.dart';
import '../../../bloc/sync/sync_bloc.dart';
import '../../../core/route/routes.dart';

/// [SplashPage] — reads [SettingsBloc.state] and routes the user:
/// 1) `!acceptedTerms` → `/privacy`
/// 2) `!onboardingComplete` → `/onboarding` (resumes from saved step)
/// 3) else → `/dashboard`, and if Drive is enabled, fires a background sync.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final settings = context.read<SettingsBloc>().state;

    if (!settings.acceptedTerms) {
      context.goNamed(privacyRoute);
      return;
    }
    if (!settings.onboardingComplete) {
      context.goNamed(onboardingRoute);
      return;
    }

    if (settings.driveEnabled) {
      context.read<SyncBloc>().add(const SyncNow());
    }
    context.goNamed(dashboardRoute);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
