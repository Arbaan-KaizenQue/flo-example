import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/onboarding/onboarding_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/sync/sync_bloc.dart';
import '../core/route/app_router.dart';
import '../data/local/datasources/local_item_datasource.dart';
import '../data/local/objectbox_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/drive_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/onboarding_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/drive_service.dart';

/// [Application] — root widget.
/// Wires shared singletons ([SharedPreferences], [ObjectBoxStore]) into
/// services → repositories → blocs, then registers every bloc in a single
/// [MultiBlocProvider] tree above [MaterialApp.router].
class Application extends StatelessWidget {
  const Application({
    super.key,
    required this.prefs,
    required this.store,
  });

  final SharedPreferences prefs;
  final ObjectBoxStore store;

  @override
  Widget build(BuildContext context) {
    // Services
    final authService = AuthService();
    final driveService = DriveService(authService: authService);
    final localItemDataSource = LocalItemDataSource(store: store);

    // Repositories
    final authRepository = AuthRepositoryImpl(
      authService: authService,
      prefs: prefs,
    );
    final itemRepository = ItemRepositoryImpl(local: localItemDataSource);
    final driveRepository = DriveRepositoryImpl(
      driveService: driveService,
      authService: authService,
      itemRepository: itemRepository,
      prefs: prefs,
    );
    final settingsRepository = SettingsRepositoryImpl(prefs: prefs);
    final onboardingRepository = OnboardingRepositoryImpl(prefs: prefs);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (_) => AuthBloc(authRepository: authRepository)
            ..add(const TryRestoreSession()),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(driveRepository: driveRepository),
        ),
        BlocProvider<OnboardingBloc>(
          lazy: false,
          create: (_) => OnboardingBloc(repository: onboardingRepository)
            ..add(const LoadOnboarding()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(
            settingsRepository: settingsRepository,
            authRepository: authRepository,
            driveRepository: driveRepository,
            itemRepository: itemRepository,
            onboardingRepository: onboardingRepository,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Sync App',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
