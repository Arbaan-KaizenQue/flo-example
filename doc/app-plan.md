# Flo Style Local First App — Main Plan

## Core Architecture
- Local-first architecture
- Offline-first app
- Google Drive backup optional
- No Firebase
- No backend
- Cubit/BLoC architecture
- GoRouter navigation
- Dio structure from CLAUDE.md

## Main Flow

Splash
→ Privacy & Terms
→ Multi-step onboarding
→ Dashboard
→ Bottom navigation

## Important Rules

### 1. Resume Onboarding
If onboarding is incomplete:
- restore last completed step
- continue remaining forms

### 2. Guest Flow
Guest users can:
- use the full app locally
- access dashboard
- access settings

Profile page:
- shows Google Sign In button

### 3. UI Rule
Keep UI minimal.
Functionality first.
Avoid complex design initially.

### 4. Storage
HydratedBloc:
- onboarding progress
- dashboard state

SharedPreferences:
- accepted terms
- onboarding completed
- current onboarding step

ObjectBox:
- logs
- symptoms
- health data
