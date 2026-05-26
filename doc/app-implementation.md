# Implementation Plan

## Phase 0 — Bootstrap
- Create project
- Add dependencies
- Configure GoRouter
- Configure MultiBlocProvider
- Configure HydratedBloc

## Phase 1 — Splash + Routing
- Splash screen
- Route guards
- Guest flow
- Redirect logic

## Phase 2 — Privacy & Terms
- Simple text page
- Checkbox
- Continue button
- Persist accepted terms locally

## Phase 3 — Onboarding Local Persistence
- Create onboarding model
- Store onboarding progress locally
- Save current step

## Phase 4 — Multi-Step Forms
- Simple selectable forms
- Minimal UI
- Save after every step

## Phase 5 — Resume Incomplete Forms
- Restore current step
- Continue unfinished onboarding

## Phase 6 — Home Dashboard
- Flo-style dashboard
- Local data display
- Simple cards

## Phase 7 — Bottom Navigation
- Home
- Settings
- Profile

## Phase 8 — Guest / Profile Logic
Guest:
- local only

Logged user:
- Google Drive backup

## Phase 9 — Google Sign-In
- Google login only
- No email/password
- Optional sign in

## Phase 10 — Google Drive Backup
- Push local data
- Pull local data
- Merge local + remote

## Phase 11 — Settings
- Logout
- Backup toggle
- Clear backup
- Last sync time

## Phase 12 — Production Cleanup
- Refactor
- Remove debug code
- Improve UI
- Optimize rebuilds
