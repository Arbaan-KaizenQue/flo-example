import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/cycle_log/cycle_log_bloc.dart';
import '../bloc/onboarding/onboarding_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/symptom/symptom_bloc.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/water/water_bloc.dart';
import '../core/route/app_router.dart';
import '../core/theme/app_theme.dart';
import '../data/local/datasources/local_cycle_log_datasource.dart';
import '../data/local/datasources/local_symptom_datasource.dart';
import '../data/local/datasources/local_water_datasource.dart';
import '../data/local/objectbox_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cycle_log_repository.dart';
import '../data/repositories/drive_repository.dart';
import '../data/repositories/onboarding_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/symptom_repository.dart';
import '../data/repositories/water_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/drive_service.dart';

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
    final authService = AuthService();
    final driveService = DriveService(authService: authService);

    final cycleLogDataSource = LocalCycleLogDataSource(store: store);
    final symptomDataSource = LocalSymptomDataSource(store: store);
    final waterDataSource = LocalWaterDataSource(store: store);

    final authRepository = AuthRepositoryImpl(
      authService: authService,
      prefs: prefs,
    );
    final driveRepository = DriveRepositoryImpl(
      driveService: driveService,
      authService: authService,
      prefs: prefs,
    );
    final settingsRepository = SettingsRepositoryImpl(prefs: prefs);
    final onboardingRepository = OnboardingRepositoryImpl(prefs: prefs);
    final cycleLogRepository =
        CycleLogRepositoryImpl(local: cycleLogDataSource);
    final symptomRepository =
        SymptomRepositoryImpl(local: symptomDataSource);
    final waterRepository = WaterRepositoryImpl(local: waterDataSource);

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
        BlocProvider<CycleLogBloc>(
          lazy: false,
          create: (_) => CycleLogBloc(repository: cycleLogRepository)
            ..add(const WatchCycleLogs()),
        ),
        BlocProvider<SymptomBloc>(
          lazy: false,
          create: (_) => SymptomBloc(repository: symptomRepository)
            ..add(const WatchSymptoms()),
        ),
        BlocProvider<WaterBloc>(
          lazy: false,
          create: (_) => WaterBloc(repository: waterRepository)
            ..add(const WatchWater()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(
            settingsRepository: settingsRepository,
            authRepository: authRepository,
            driveRepository: driveRepository,
            onboardingRepository: onboardingRepository,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Sync App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
