# Feature 33 — Anonymous AI Learning & AI Call Hygiene

## Goal

Honour the PDF's "Privacy & Security Architecture" promise that **no
personal identifiers** ever reach Gemini, and give the user explicit
control + visibility over every AI call. Pairs with feature_27 (storage
& transport security); this one is specifically about the Gemini
payload boundary.

## Three pillars

### 1. Identifier stripping

Every call into `GeminiService` must pass through a sanitiser:

```dart
// lib/data/services/_payload_sanitiser.dart
Map<String, dynamic> sanitisePayload(Map<String, dynamic> raw) {
  // Strip: name, email, googleSub, photoUrl, deviceId, IP-likes
  // Allow:  pseudonymous patterns — cycle data, severity, dates
}
```

- Profile section drops `displayName`, `email`, `googleSub`, `photoUrl`
- Dates are **relative offsets from today**, not absolute (`day -3` not
  `2026-05-12`)
- No free-form notes — Note bodies are summarised to a category
  (`note_short_positive`, `note_long_neutral`) by an on-device rule

### 2. User toggle

In Settings, new section "AI privacy":

```
[ ● ] Use Gemini for personalised insights
       Anonymous data only. Switch off to use only the on-device rule
       engine for recommendations.

[ ▢ ] Include note bodies in AI payloads
       Off by default. Notes never leave your device unless this is on.
```

When the main toggle is OFF:
- `RecommendationBloc` falls back to the rule engine (revive the
  deleted `RecommendationEngine` from earlier — keep it in
  `lib/data/services/rule_recommendation_engine.dart` as the offline
  fallback)
- `Ask AI` FAB shows a quiet "AI is off" hint instead of streaming

### 3. Audit log

Append every Gemini call to a small rolling log shown in Settings:

```
Recent AI calls
─────────────────────────────────
4:32 PM   gemini-2.5-flash-lite   2.1 KB out, 1.4 KB in   ✓
4:08 PM   gemini-2.5-flash-lite   1.9 KB out, 1.1 KB in   ✓
12:14 PM  gemini-2.5-flash-lite   2.3 KB out, ─ quota     ⚠
─────────────────────────────────
Clear log    Export log
```

- Last 50 entries kept in SharedPreferences as a JSON list
- Each entry: timestamp, model, payload size, response size, status,
  call type (insights / focused / wellness-report)
- One-tap clear; one-tap export as JSON

## Data-hierarchy doc (also add to README + progress.md)

A clear list users / developers can point at:

```
1. Never logged       — biometric data, IP, exact location
2. Device-only        — every entity (cycle, mood, …) in ObjectBox
3. Optional Drive     — same entities, in a hidden appData folder
                        you own with your Google account
4. Optional Gemini    — anonymised aggregates, sent transiently, not
                        used for model training (per Google's
                        gemini-2.5-flash-lite policy)
```

## Files affected

| Action | Path |
|---|---|
| CREATE | `lib/data/services/_payload_sanitiser.dart` |
| RESURRECT | `lib/data/services/rule_recommendation_engine.dart` (pull from git history) |
| MODIFY | `lib/data/services/gemini_service.dart` (route every payload through sanitiser) |
| MODIFY | `lib/data/repositories/recommendation_repository.dart` (fallback selector) |
| MODIFY | `lib/core/constants/storage_keys.dart` (`aiEnabled`, `aiIncludeNotes`, `aiAuditLog`) |
| MODIFY | `lib/bloc/settings/` (toggles + audit-log feed) |
| CREATE | `lib/view/widgets/ai_privacy_section.dart` (Settings UI block) |

## Acceptance

- [ ] No `displayName` / `email` / `googleSub` ever appears in a
      payload (assert in unit test)
- [ ] Toggling "Use Gemini" off → next refresh falls back to rule
      engine; Insights still appear
- [ ] Audit log shows each call with size + status
- [ ] Clearing the log empties it; export returns valid JSON
- [ ] `flutter analyze` clean
