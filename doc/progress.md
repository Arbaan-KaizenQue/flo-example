# Aura — Project Progress (Handoff Document)

This file is the **single source of truth for what's been built** so a fresh AI
or developer can continue without re-reading the entire conversation history.
Read this top-to-bottom once; jump to a section for details.

Last updated: matches commit `98fa2ed` ("changed the app name and package name").

---

## 1. App identity

| | |
|---|---|
| **Name** | Aura |
| **Package** | renamed to `aura` (was `com.maidentech.sync_app`) |
| **Project root** | `/Users/arbaanq/Projects/Frontend/sync_app/` (folder name unchanged) |
| **Flutter** | 3.41.9 stable · Dart 3.11+ |
| **Theme** | Material 3, seeded from Material Pink 500 (`#E91E63`); complementary teal `#26A69A` reserved for ovulation markers |
| **Target platforms** | Android (primary), iOS configured. Web not supported (ObjectBox limitation) |

---

## 2. Non-negotiable architecture rules

These come from `doc/CLAUDE.md`. Any new feature MUST follow them or you
break consistency.

1. **Local-first.** No backend. No Firebase. Google Drive sync is optional and never blocks the UI.
2. **Folder layout** (see §3) is fixed. Don't invent new top-level dirs.
3. **Bloc files come in threes** with `part` / `part of`:
   - `<feature>_bloc.dart`
   - `<feature>_event.dart` (part of bloc)
   - `<feature>_state.dart` (part of bloc)
4. **Two bloc styles only** (see §6):
   - **Style A** — single state class with `isLoading/error/message` + `copyWith` (use when bloc holds list/data across many events)
   - **Style B** — abstract base + Initial/Loading/Success/Failure subclasses (use for single fire-and-forget actions)
5. **Repositories** = abstract class + `Impl` class in same file. Service goes in; bloc only sees the abstract.
6. **Services return `JsonResponse`** (the universal wrapper at `lib/data/models/json_response.dart`). Never raw response objects.
7. **Streams (`watchAll`) return raw streams**, not `JsonResponse` — they're persistent subscriptions, not one-shot calls.
8. **No GetIt.** Manual DI: shared deps (`SharedPreferences`, `ObjectBoxStore`) are constructed in `start.dart` and passed via `Application` constructor; services/repos are built inside `app.dart` `build()` and injected into `MultiBlocProvider`.
9. **Routing** uses GoRouter with **named routes only**. Define constant in `core/route/routes.dart`, register `GoRoute` in `core/route/app_router.dart`, navigate via `context.goNamed/pushNamed/...`. Never raw paths, never `Navigator.push`.
10. **Theme** — never hardcode `Colors.*` in screens. Use `Theme.of(context).colorScheme.*`. `AppTheme` exposes `AppTheme.pink` and `AppTheme.ovulationTeal` for brand-specific accents.

### The 4 files every new feature touches

```
core/route/routes.dart            ← new <feature>Route constant
core/route/app_router.dart        ← new GoRoute entry
app/app.dart                      ← new BlocProvider in MultiBlocProvider
doc/<relevant flow doc>.md        ← one-line note of what changed
```

---

## 3. Folder structure (as it is today)

```
lib/
├── main.dart                       — void main() => startApplication();
│
├── app/
│   ├── start.dart                  — bootstrap: WidgetsFlutterBinding,
│   │                                 dotenv.load('.env'),
│   │                                 SharedPreferences.getInstance(),
│   │                                 ObjectBoxStore.create(),
│   │                                 runApp(Application(prefs, store))
│   └── app.dart                    — root widget; builds services →
│                                     repositories → MultiBlocProvider →
│                                     MaterialApp.router
│
├── bloc/
│   ├── auth/                       — Style B (Google sign-in lifecycle)
│   ├── cycle_log/                  — Style A (period entries + dots)
│   ├── item_editor/                — DELETED
│   ├── item_list/                  — DELETED
│   ├── mood/                       — Style A (per-day mood entries)
│   ├── note/                       — Style A (per-day journal entries)
│   ├── onboarding/                 — Style A (5-step form + currentStep)
│   ├── prediction/                 — Style A (no entity; derives from cycle logs)
│   ├── recommendation/             — Style A (Gemini insights + wellness score)
│   ├── settings/                   — Style A (welcomeSeen, terms, drive,
│   │                                 onboardingComplete, pregnancy)
│   ├── sleep/                      — Style A
│   ├── symptom/                    — Style A
│   ├── sync/                       — Style B (manual Drive sync)
│   ├── water/                      — Style A
│   └── weight/                     — Style A
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      — backupFileName, syncDebounce,
│   │   │                             driveAppDataScope, etc.
│   │   └── storage_keys.dart       — all SharedPreferences keys (see §10)
│   ├── route/
│   │   ├── routes.dart             — named route constants
│   │   └── app_router.dart         — GoRouter config
│   └── theme/
│       └── app_theme.dart          — AppTheme.light, AppTheme.pink,
│                                     AppTheme.ovulationTeal
│
├── data/
│   ├── models/                     — immutable Equatable models +
│   │                                 fromJson/toJson/copyWith
│   │   ├── cycle_log.dart
│   │   ├── mood_entry.dart
│   │   ├── note.dart
│   │   ├── sleep_log.dart
│   │   ├── symptom_entry.dart
│   │   ├── water_log.dart
│   │   ├── weight_log.dart
│   │   ├── onboarding_answers.dart
│   │   ├── pregnancy_context.dart  — derived (LMP → weeks/trimester/due)
│   │   ├── recommendation.dart     — RecommendationType enum + severity
│   │   ├── backup_snapshot.dart    — Drive payload (currently metadata-only)
│   │   └── json_response.dart      — universal service return type
│   │
│   ├── entity/
│   │   └── (legacy; no params classes in active use yet)
│   │
│   ├── local/
│   │   ├── objectbox_store.dart    — singleton wrapping Store
│   │   ├── entities/               — @Entity classes for ObjectBox codegen
│   │   │   ├── cycle_log_entity.dart
│   │   │   ├── symptom_entry_entity.dart
│   │   │   ├── water_log_entity.dart
│   │   │   ├── sleep_log_entity.dart
│   │   │   ├── weight_log_entity.dart
│   │   │   ├── note_entity.dart
│   │   │   ├── mood_entry_entity.dart
│   │   │   └── ai_insight_entity.dart
│   │   └── datasources/             — thin sync wrappers per box
│   │       ├── local_cycle_log_datasource.dart
│   │       ├── local_symptom_datasource.dart
│   │       ├── local_water_datasource.dart
│   │       ├── local_sleep_datasource.dart
│   │       ├── local_weight_datasource.dart
│   │       ├── local_note_datasource.dart
│   │       ├── local_mood_datasource.dart
│   │       └── local_ai_insight_datasource.dart
│   │
│   ├── repositories/                — abstract + Impl pairs
│   │   ├── auth_repository.dart
│   │   ├── cycle_log_repository.dart
│   │   ├── drive_repository.dart    — pull/merge/push LWW
│   │   ├── mood_repository.dart
│   │   ├── note_repository.dart
│   │   ├── onboarding_repository.dart
│   │   ├── recommendation_repository.dart  — wraps GeminiService
│   │   ├── settings_repository.dart        — SharedPreferences typed wrapper
│   │   ├── sleep_repository.dart
│   │   ├── symptom_repository.dart
│   │   ├── water_repository.dart
│   │   ├── weight_repository.dart
│   │   └── ai_insight_repository.dart      — Drive-side cached insights
│   │
│   └── services/
│       ├── auth_service.dart        — wraps google_sign_in (drive.appdata)
│       ├── drive_service.dart       — wraps googleapis Drive v3
│       └── gemini_service.dart      — wraps google_generative_ai
│
└── view/
    ├── screens/
    │   ├── welcome/welcome_page.dart       — NEW (first-launch)
    │   ├── splash/splash_page.dart         — routing decision page
    │   ├── privacy/privacy_page.dart       — terms checkbox
    │   ├── onboarding/onboarding_page.dart — 5-step resumable form
    │   ├── shell/main_shell.dart           — bottom-nav (Home/Settings/Profile)
    │   ├── dashboard/dashboard_page.dart   — main home (Home tab)
    │   ├── settings/settings_page.dart
    │   ├── profile/profile_page.dart
    │   ├── cycle_log/cycle_log_form_page.dart — period range picker
    │   └── notes/note_editor_page.dart        — per-day journal entry
    │
    └── widgets/
        ├── cycle_calendar.dart       — table_calendar with period/predicted/fertile dots
        ├── prediction_card.dart      — "Period in X days" + pills
        ├── insights_card.dart        — Wellness score + horizontal bubble strip
        ├── insight_bubble.dart       — single AI insight tile
        ├── insight_detail_sheet.dart — modal expansion of a bubble
        ├── wellness_score_card.dart  — 0-100 score widget
        ├── ask_ai_dialog.dart        — bottom-right popup with streaming response
        ├── pregnancy_banner.dart     — pink banner shown when pregnancy mode on
        ├── daily_metric_chip.dart    — reusable tappable chip for daily metrics
        ├── water_log_sheet.dart      — circular progress + quick-add
        ├── sleep_log_sheet.dart      — slider + auto-derived quality badge
        ├── weight_log_sheet.dart     — numeric input
        ├── mood_picker_sheet.dart    — 5-emoji selector
        ├── symptom_picker_sheet.dart — multi-select chip sheet
        └── sync_status_indicator.dart — Drive sync icon on appbar
```

### Protected (do not modify per CLAUDE.md)

Listed in CLAUDE.md as "pre-built by the developer". They don't all exist yet
but if/when they do, **never touch**: `core/utils/`, `core/interceptors/`,
`core/exceptions/`, `core/environments/`, `debug/`.

---

## 4. App boot flow

```
main() → startApplication()
  ├─ WidgetsFlutterBinding.ensureInitialized()
  ├─ dotenv.load('.env')             ← optional; fails silently if missing
  ├─ SharedPreferences.getInstance()
  ├─ ObjectBoxStore.create()         ← opens DB at app docs dir
  └─ runApp(Application(prefs, store))
      └─ MultiBlocProvider (in app.dart)
          └─ MaterialApp.router(routerConfig: appRouter, theme: AppTheme.light)
              └─ SplashPage (700ms spinner)
                  ├─ if !welcomeSeen      → /welcome
                  ├─ else if !acceptedTerms  → /privacy
                  ├─ else if !onboardingComplete  → /onboarding (resumes from saved step)
                  └─ else                  → /dashboard
                                            (+ fires SyncBloc.SyncNow if driveEnabled)
```

---

## 5. Routing flow

**All named routes** (`core/route/routes.dart`):

| Constant | Path | Page |
|---|---|---|
| `splashRoute` | `/` | `SplashPage` |
| `welcomeRoute` | `/welcome` | `WelcomePage` |
| `privacyRoute` | `/privacy` | `PrivacyPage` |
| `onboardingRoute` | `/onboarding` | `OnboardingPage` |
| `cycleLogFormRoute` | `/cycle-log?date=YYYY-MM-DD` | `CycleLogFormPage` |
| `noteEditorRoute` | `/note?date=YYYY-MM-DD` | `NoteEditorPage` |
| `dashboardRoute` | `/dashboard` | `DashboardPage` (inside ShellRoute) |
| `settingsRoute` | `/settings` | `SettingsPage` (inside ShellRoute) |
| `profileRoute` | `/profile` | `ProfilePage` (inside ShellRoute) |

Bottom nav (Home / Settings / Profile) is implemented as a `ShellRoute`
wrapping the three child routes with `MainShell`. Each ShellRoute child
uses `NoTransitionPage` for instant tab switching.

---

## 6. Bloc inventory

| Bloc | Style | What it owns | Subscribes to |
|---|---|---|---|
| `AuthBloc` | B | Google Sign-In session, `driveEnabled` flag | google_sign_in stream |
| `OnboardingBloc` | A | 5-step form draft + currentStep | onboarding_repository (SharedPreferences) |
| `CycleLogBloc` | A | list of CycleLogs (period entries) | cycle_log_repository stream |
| `SymptomBloc` | A | list of SymptomEntries (per-day) | symptom_repository stream |
| `WaterBloc` | A | list of WaterLogs (per-day) | water_repository stream |
| `SleepBloc` | A | list of SleepLogs (per-day) | sleep_repository stream |
| `WeightBloc` | A | list of WeightLogs + `weightOnOrBefore(day)` helper | weight_repository stream |
| `NoteBloc` | A | list of Notes (per-day) | note_repository stream |
| `MoodBloc` | A | list of MoodEntries (per-day) | mood_repository stream |
| `PredictionBloc` | A | predicted period start/end, days-until-next, day-of-cycle, ovulation, fertile window | **derived** — cycle_log_repository stream |
| `RecommendationBloc` | A | Gemini insights + wellness score (0-100); also exposes `streamFocusedInsight(focusAreas)` for the Ask-AI dialog | all 5 data repos + onboarding + settings (for pregnancy context); 5s debounce + input-hash cache |
| `SyncBloc` | B | Drive push/pull lifecycle, lastSyncedAt | drive_repository |
| `SettingsBloc` | A | welcomeSeen, acceptedTerms, driveEnabled, onboardingComplete, pregnancyModeEnabled, pregnancyLmp, lastSyncedAt | settings_repository (SharedPreferences) |

All blocs registered in `app.dart`'s `MultiBlocProvider`, most are
`lazy: false` so initial Watch* events fire on boot.

---

## 7. Features delivered (chronological)

Use this to know what's done and where it lives. **All merged to local `main`. No `git push` has been performed.**

### Foundation
- **F0 Bootstrap** — CLAUDE.md folder structure, MaterialApp.router, MultiBlocProvider
- **F0 Onboarding flow** — Welcome → Privacy → 5-step Onboarding → Dashboard
- **F0 Bottom-nav shell** — Home / Settings / Profile (`MainShell` + ShellRoute)

### Tracking features
| # | Feature | Branch | Key files |
|---|---|---|---|
| 01 | **Cycle Calendar** | `feat/feature_01_cycle_calendar` | `view/widgets/cycle_calendar.dart`, pink theme applied |
| 02 | **Cycle Logging** | `feat/feature_02_cycle_logging` | `cycle_log_entity.dart`, `cycle_log_form_page.dart` (calendar-based range picker — flow intensity sets default length: light=4d, medium=6d, heavy=7d) |
| 03 | **Symptom Tracking** | `feat/feature_03_symptom_tracking` | `symptom_entry_entity.dart`, `symptom_picker_sheet.dart` (multi-select chips, 11 options) |
| 04 | **Mood Tracking + AI Coach** | `feat/feature_04_mood_coach` | `mood_entry_entity.dart`, `mood_picker_sheet.dart` (5 emojis), mood data also fed to Gemini payload |
| 05 | **Water Tracking** | `feat/feature_05_water_tracking` | `water_log_entity.dart`, `water_log_sheet.dart` (live-rebuilding circular ring, +200/+330/+500/+750 ml quick-add) |
| 06 | **Sleep Tracking** | `feat/feature_06_sleep_tracking` | `sleep_log_entity.dart`, `sleep_log_sheet.dart` — quality is **auto-derived** from hours (<5=poor, 5-7=fair, 7-9=good, ≥9=excellent) |
| 07 | **Weight Tracking** | `feat/feature_07_weight_tracking` | `weight_log_entity.dart`, `weight_log_sheet.dart` — `WeightState.weightOnOrBefore(day)` gives **carry-forward** (one weigh-in shows month-long) |
| 08 | **Notes Journal** | `feat/feature_08_notes_journal` | `note_entity.dart`, `note_editor_page.dart` (full-page route, edit/delete, empty body soft-deletes) |
| 09 | **Cycle Prediction** | `feat/feature_09_cycle_prediction` | `bloc/prediction/` — no entity; derives from cycle logs. Outlined pink ring on calendar = predicted period days |
| 10 | **Fertility Window** | `feat/feature_10_fertility_window` | extends `PredictionState` with `ovulationDay`/`fertileWindowStart`/`fertileWindowEnd`. Teal dots on calendar |
| 11 | **AI Health Assistant (Gemini)** | `feat/feature_11_gemini_ai` | replaced an earlier rule-based engine; full Gemini integration via `.env` key |
| 21 | **AI Insights Engine (Phase 1)** | `feat/feature_21` | structured JSON insights with `wellness_score`, bubble strip, persistence via `ai_insight_entity.dart` |
| 21b | **Ask AI FAB + chips** | `feat/feature_21b_ask_ai_fab` | first version: bottom-sheet picker → results into main insights list |
| — | **Ask AI dialog rework** | `fix/ask-ai-inline-dialog` | bottom-right floating popup; **streams tokens** in-place; doesn't pollute the main insights strip |
| 20 | **Pregnancy Mode** | `feat/feature_20_pregnancy_mode` | Settings toggle → LMP picker; `PregnancyContext` derived (weeks/trimester/due); pink banner on dashboard; **Gemini swaps to pregnancy persona** for ALL calls when active |
| — | **Welcome page** | `feat/welcome_page` | first-launch greeting with gradient hero + Get Started; gated by `welcomeSeen` SharedPref flag |

### Drive backup (built, but not currently transporting user data)
- Sign-in flow via Profile tab (`AuthService` + drive.appdata scope)
- Toggle in Settings, sync indicator on appbar
- `DriveRepository.performSync()` — Completer-locked, pull → merge (LWW on `updatedAt`) → push
- `BackupSnapshot` is **currently metadata-only** (`{version, lastSyncedAt}`) — entity data NOT yet round-tripped to Drive. See §13.

### Skipped from the original 20-feature roadmap
Features 12 (Home Insights), 13 (Stats), 14 (Export/Backup),
15 (Profile Mgmt), 16 (Multi-Device Sync), 17 (Period History),
18 (Calendar Heatmap), 19 (Notifications & Reminders) are **not yet built**.

---

## 8. AI integration (Gemini)

### Key location

```
.env at project root (gitignored):
  GEMINI_API_KEY="..."
  GEMINI_MODEL="gemini-2.5-flash-lite"   # optional; default is gemini-2.0-flash
```

### Two methods on `GeminiService`

1. **`generateInsights(...)`** — structured JSON bundle for the dashboard
   - Returns `JsonResponse` with `data: AIInsightsBundle { wellnessScore: int?, insights: List<Recommendation> }`
   - Uses `responseMimeType: 'application/json'`
   - System prompt: cycle persona OR pregnancy persona (auto-switched if `PregnancyContext` is non-null)
   - Output: 3-5 recommendations with `type`, `severity`, `confidence`, plus a 0-100 wellness score

2. **`streamFocusedInsight(focusAreas, ...)`** — prose stream for the Ask AI dialog
   - Returns `Stream<String>` of token chunks
   - Same persona-swap logic
   - Used only by the bottom-right popup; doesn't touch the dashboard insights list

### Payload shape sent to Gemini

```json
{
  "today": "YYYY-MM-DD",
  "profile":            { age_group, cycle_length_pref, tracked_symptoms,
                          goals, pregnancy_status },
  "cycles_last_90d":    [...],
  "symptoms_last_30d":  [...],
  "sleep_last_14d":     [...],
  "water_last_14d":     [...],
  "mood_last_30d":      [...],
  "pregnancy":          { lmp, dueDate, weeksPregnant, daysPregnant,
                          trimester }    // ONLY when mode is on
}
```

### Quota safety

- `RecommendationBloc` debounces 5 s before generating
- Input-hash cache prevents identical-data refreshes
- Header refresh button bypasses cache
- Persona swap (pregnancy on/off) invalidates the hash → forces regen
- On 429 / quota errors, Gemini returns plain text; UI shows it in an error card. Recommend `gemini-2.5-flash-lite` for highest free-tier RPM.

### Where AI lives in UI

| UI element | Triggered by |
|---|---|
| Wellness Score card (top of Insights section) | `generateInsights` |
| Horizontal bubble strip + tap-to-expand detail sheet | `generateInsights` |
| **Ask AI FAB** (pink, bottom-right) → bottom-right popup → chip picker → streaming response | `streamFocusedInsight` |
| Refresh icon (in Insights header) | manual `RefreshRecommendations` event |

---

## 9. Drive sync rules (LWW)

- **Scope**: `https://www.googleapis.com/auth/drive.appdata` (hidden app folder, invisible in drive.google.com)
- **Single file**: `appDataFolder/backup.json`
- **Merge algorithm** (`DriveRepositoryImpl.merge`):
  1. Map all local items by UUID `id`
  2. For each remote item: if missing locally OR `remoteItem.updatedAt > localItem.updatedAt` → take remote
  3. On timestamp tie → keep local (deterministic tiebreak)
  4. Soft deletes (`deleted: true`) propagate via the same comparison
- **Lock**: `Completer` prevents concurrent `performSync()` runs
- **Triggers currently wired**: app launch (splash), manual ("Sync Now" in Settings, refresh icon, etc.)
- **Triggers NOT yet wired**: debounce-on-write, connectivity-restored, lifecycle-resumed (deferred — would need a `SyncTriggerManager` class)

⚠️ **Important caveat**: `BackupSnapshot` currently carries no entity
data (only `version` + `lastSyncedAt`). So when you press "Sync Now"
right now, Drive gets a metadata blob; entities don't actually back up.
This is deferred to a future Feature 14/16. See §13.

---

## 10. Persistence model

### ObjectBox entities (each in `lib/data/local/entities/`)

Common fields on every per-day or per-entry entity:
- `obxId` (int auto-increment, internal to ObjectBox)
- `id` (UUID v4 string, `@Unique` — stable across devices for Drive sync)
- `createdAt`, `updatedAt` (UTC)
- `deleted` (bool, soft delete)

Entity-specific fields:
- `CycleLogEntity` — startDate, endDate (nullable), flow ('light'|'medium'|'heavy')
- `SymptomEntryEntity` — date (day), symptomsCsv (`|`-separated)
- `WaterLogEntity` — date, amountMl, goalMl
- `SleepLogEntity` — date, hours (double), quality
- `WeightLogEntity` — date, weightKg (double)
- `NoteEntity` — date, title, body
- `MoodEntryEntity` — date, mood ('amazing'|'good'|'okay'|'low'|'awful'), note
- `AIInsightEntity` — id, title, body, type, severity, confidence, createdAt

**Schema file**: `lib/objectbox-model.json` — MUST be committed to git.
Codegen: `dart run build_runner build` (NEVER `--delete-conflicting-outputs`
on an existing install — wipes UIDs and crashes user devices).

### SharedPreferences keys (in `core/constants/storage_keys.dart`)

| Key | Type | Purpose |
|---|---|---|
| `welcome_seen` | bool | hide welcome page after first dismissal |
| `accepted_terms` | bool | gate before showing onboarding |
| `onboarding_complete` | bool | gate before showing dashboard |
| `onboarding_step` | int | resume mid-onboarding |
| `onboarding_answers` | JSON string | hydrate OnboardingBloc on launch |
| `drive_sync_enabled` | bool | toggle Drive backup |
| `last_synced_at` | ISO string | shown in sync indicator |
| `pregnancy_mode_enabled` | bool | Feature 20 |
| `pregnancy_lmp_iso` | ISO string | LMP for due-date calc |

### .env (gitignored)

| Key | Default if absent | Purpose |
|---|---|---|
| `GEMINI_API_KEY` | (none) | when missing, AI insights show "AI is off" hint |
| `GEMINI_MODEL` | `gemini-2.0-flash` | override the model |

---

## 11. Conventions to keep consistent

| Concern | Pattern |
|---|---|
| **Per-day entries** | Always upsert by date. The repo has `_findForDay(date)` → either update or create. Day-only DateTime (no hours). |
| **Soft delete** | Set `deleted=true`, bump `updatedAt`. Never hard-delete (Drive sync needs the row). |
| **Lookups** | Repos expose `getById`, `getAll`, `getAllIncludingDeleted`, `watchAll`. Datasources mirror those. |
| **Date-only normalization** | `DateTime(d.year, d.month, d.day)` — drop hours/minutes for all per-day stuff. |
| **Sleep quality mapping** | <5h=poor, 5-7h=fair, 7-9h=good, ≥9h=excellent (in `sleep_log_sheet.dart`) |
| **Flow→days** | light=4, medium=6, heavy=7 (in `cycle_log_form_page.dart`'s `_flowDays`) |
| **Mood enum (string)** | `amazing`/`good`/`okay`/`low`/`awful` |
| **Recommendation types** | `cycle`, `symptoms`, `sleep`, `water`, `profile`, `general`, `pmsForecast`, `hydrationPattern`, `sleepPattern`, `moodTrend`, `recovery`, `wellnessSummary` |
| **Naming** | Files = `snake_case`. Classes = `PascalCase`. Route consts = `camelCaseRoute`. Bloc event handlers = `_on<Event>Name`. |
| **Empty states** | Always handle in BlocBuilder; never show a blank screen if state is initial. |
| **Color usage** | `Theme.of(context).colorScheme.*` for everything except brand-specific (`AppTheme.pink`, `AppTheme.ovulationTeal`). |

---

## 12. Build & dev commands

```bash
# Standard run
flutter run

# After modifying any ObjectBox @Entity (NO --delete-conflicting-outputs)
dart run build_runner build

# Hot restart (R = full restart; r = hot reload — use R after .env / new Bloc)
R

# When schema changes and on-device DB is incompatible
adb uninstall com.maidentech.aura && flutter run

# Static analysis
flutter analyze

# Tests (none currently)
flutter test
```

**Dependency overrides** (in `pubspec.yaml`):

```yaml
dependency_overrides:
  source_gen: ^4.0.0   # objectbox_generator 5.x needs it; transitively pinned to 3.x by something
```

**ObjectBox bumped to ^5.0.0** (deviation from `doc/dependencies.md` which
pinned 4.0.3) because the 4.x generator is incompatible with current analyzer.

---

## 13. Known limitations / open work

1. ~~**Drive backup doesn't include entity data yet.**~~ ✅ FIXED in
   the `feat/full_sync_and_welcome_auth` branch. `BackupSnapshot` v2 now
   carries every entity collection and `DriveRepository.performSync()`
   does per-collection LWW merge.
2. **Background sync triggers** (debounce-on-write, connectivity-restored,
   lifecycle-resumed) are NOT wired. Currently only app launch + manual.
3. **No tests** in the new structure. Original sync_app had merge-logic
   tests; deleted during the restructure.
4. **Features 12, 13, 15, 17, 18, 19** from the original spec are not
   built. See spec MDs at `doc/features/feature_*.md`.
5. **Mood Coach is implicit** — mood data is fed to Gemini but there's
   no dedicated "mood coach" UI; insights just naturally include mood
   patterns under the existing `moodTrend` recommendation type.
6. **Pregnancy mode UI is minimal** — banner + AI persona swap. No
   dedicated "baby this week" card, no trimester checklist, no swap of
   bottom nav.
7. **No code-side guard against ObjectBox schema mismatch.** If the user
   uninstalls + reinstalls between major changes, fine; if a property is
   removed without care, the app will crash on launch with "Incoming
   entity ID does not match existing UID". Use `@Property(uid: <old>)`
   on renames to keep UIDs stable.
8. **30+ Symptom Framework (Aura PDF) not yet implemented.** Specs
   exist at `doc/features/feature_22..33.md`. Priority order to build:
   - feature_23 — full 33-symptom catalogue with grouping
   - feature_29 — per-symptom severity & timing (unlocks 30 + 31)
   - feature_30 — PMDD detection
   - feature_31 — cycle irregularity detection
   - feature_27 — privacy & security (AES-256, biometric, GDPR)
   - feature_32 — long-term wellness reports
   - feature_33 — anonymous AI hygiene + rule-engine fallback
9. **Old original Phase plan partially abandoned.** The first sync_app
   plan had 8 phases (ObjectBox local layer → tests). All initially
   built, then the project pivoted to Flo-style health tracking with a
   new CLAUDE.md structure. The new structure was rebuilt from scratch;
   the original phase-plan completion list in this project's task
   history reflects the old plan.

---

## 14. How to add a new feature (cheat sheet)

For any new feature, follow this order. Read CLAUDE.md §16 for the official checklist.

```
1. Branch
   git checkout main && git checkout -b feat/feature_NN_<slug>

2. Entity (if persisted)
   lib/data/local/entities/<feature>_entity.dart  (with @Entity, @Id, @Unique id)
   dart run build_runner build   ← preserves objectbox-model.json

3. Model
   lib/data/models/<feature>.dart   (Equatable, fromJson/toJson/copyWith)

4. Datasource
   lib/data/local/datasources/local_<feature>_datasource.dart   (sync wrappers)

5. Repository
   lib/data/repositories/<feature>_repository.dart   (abstract + Impl)

6. Service (only if remote/Google API call)
   lib/data/services/<feature>_service.dart

7. Bloc (Style A or B — see §6)
   lib/bloc/<feature>/<feature>_bloc.dart   + part event + part state

8. UI
   lib/view/screens/<feature>/<page>.dart   or
   lib/view/widgets/<sheet>.dart

9. Wire into the 4 integration points
   core/route/routes.dart           — new route constant
   core/route/app_router.dart       — new GoRoute
   app/app.dart                     — new BlocProvider in MultiBlocProvider
   doc/<flow>.md                    — one-line note

10. Verify
    flutter analyze   (MUST be clean)

11. Commit + merge
    git add -A && git commit -m "feat(...): ..."
    git checkout main && git merge feat/feature_NN_<slug> --ff-only

12. (Never push without permission.)
```

### Common gotchas

- **Adding mood data to Gemini?** Already done — `gemini_service.dart`
  takes `mood` in both methods. New data types: add to the payload
  builder + extend the system prompt.
- **Adding a daily metric chip on dashboard?** Wrap a new BlocBuilder
  in `dashboard_page.dart`'s nested builders, add the field to
  `_SelectedDayCard`, append a `DailyMetricChip` in the chip rows.
- **Adding a new SharedPreferences flag?** Define in
  `storage_keys.dart`, add getter/setter on `SettingsRepository`,
  add field + copyWith + props on `SettingsState`, add an event +
  handler on `SettingsBloc`. (Mirror the pattern of `welcomeSeen`
  or `pregnancyModeEnabled`.)
- **AI quota exceeded?** Switch `GEMINI_MODEL` in `.env` to a less-loaded
  variant; the input-hash cache + 5s debounce should prevent runaway.

---

## 15. Open questions / decisions waiting on user

1. **Drive backup of entity data** — block on a decision: ship as
   Feature 14 (export/import buttons in Settings) OR Feature 16
   (transparent multi-device sync) first?
2. **Pregnancy Mode depth** — current is passive (AI persona swap +
   banner). Should it become its own mode with dedicated tab / week-card?
3. **Tests** — port the original merge-algorithm tests to the new
   `DriveRepository.merge()` location? (Pure static method.)
4. **Background sync** — wire debounce-on-write + lifecycle observer?
5. **Voice / multimodal AI** — extend Ask AI to accept voice input
   (`speech_to_text`) or photo (Gemini Vision)?

---

## End

If you're a new AI being handed this project: read §1–6 once and §11 carefully.
For any concrete task, jump to the relevant section, then follow §14 for the
mechanics. Don't push without explicit permission. Don't run
`build_runner --delete-conflicting-outputs` casually.
