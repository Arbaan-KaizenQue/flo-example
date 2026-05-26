# Cubit Architecture

## Cubits

### AppCubit
Handles:
- app startup
- routing checks

### AuthCubit
Handles:
- Google login
- logout

### OnboardingCubit
HydratedCubit

Handles:
- onboarding forms
- current step
- local persistence

### DashboardCubit
Handles:
- dashboard data

### DriveSyncCubit
Handles:
- Drive sync

## Important Rule
Use Style A states for:
- onboarding
- dashboard

Use Style B states for:
- auth
- sync
