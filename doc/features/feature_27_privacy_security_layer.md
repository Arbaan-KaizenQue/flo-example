# Feature 27 — Privacy & Security Layer

## Goal

Implement the PDF's privacy-first architecture as a real, shippable
layer — **not aspirational**. Per the user's confirmation, AES-256
encryption, biometric auth, and HIPAA/GDPR alignment are first-class
requirements, scheduled for Phase 1 of this feature.

Pairs with feature_33 (anonymous AI learning) which owns the boundary
between local data and Gemini.

## Four pillars

### 1. AES-256 local encryption

Switch ObjectBox to its encrypted variant.

- Dependency change: `objectbox_flutter_libs` → `objectbox_flutter_libs`
  with `encryption` capability (currently bundles libobjectbox-sync if
  needed; use `Store(..., encryptionKey: keyBytes)` per the docs).
- Key derivation: 256-bit key generated on first launch, stored in
  **`flutter_secure_storage`** (already in pubspec) — backed by iOS
  Keychain / Android Keystore. Never in SharedPreferences.
- One-time migration: existing unencrypted DB is read, all entities
  exported via the existing `getAllIncludingDeleted()` methods, the
  unencrypted Store is closed and deleted, the encrypted Store is
  opened, entities are written back via `replaceAll()`.
- Migration runs in `start.dart` before `runApp`; show a "Securing your
  data…" splash if it takes > 200 ms.

### 2. Biometric authentication

- Dependency: `local_auth: ^2.x`
- New flag: `biometricLockEnabled` in `StorageKeys`
- Settings toggle: "Biometric lock"
- Lock surfaces:
  - Cold start → if enabled, full-screen `BiometricLockPage` before
    splash routes
  - On `AppLifecycleState.resumed` after the app was backgrounded
    for ≥ 5 minutes (configurable, default 5)
- Fallback: Android system PIN/pattern; iOS passcode. If hardware
  biometric is unavailable, the toggle is disabled with a tooltip.

### 3. HIPAA / GDPR alignment

This is mostly **process + UX**, not crypto. Spec the user-facing
controls:

- **Right to delete** — Settings → "Delete all my data" → wipes
  ObjectBox, SharedPrefs, secure storage, and (if signed in) the Drive
  `backup.json`. Confirms with a two-step prompt.
- **Right to export** — Settings → "Export my data" → produces a JSON
  file containing every entity (uses `BackupSnapshot.toJson()` and
  saves via the `share_plus` package).
- **Consent log** — every consent decision (welcome accept, drive
  toggle on, biometric on, AI on, notes-in-AI on) appended to a small
  `ConsentLogEntity` with timestamp + flag + previous value. Visible
  under Settings → "Privacy actions".
- **Data minimisation** — already in place (no IP/location/device-id
  ever stored). Document explicitly.
- **Lawful basis** — `consent` for AI + Drive; `legitimate interest`
  for on-device tracking. Add a short Privacy page already accessible
  via PrivacyPage; expand it to list every category of data + purpose.

### 4. Zero personal health data on servers

Re-affirm and enforce:
- Drive sync uses **`drive.appdata`** scope only — Google can't read
  it via the user-visible Drive UI.
- Gemini calls go through the sanitiser from feature_33 — no PII in
  payloads.
- Document Gemini's data policy: gemini-2.5-flash-lite payloads are
  **not used for model training** when called via API (per Google's
  paid/free-tier API terms — link in privacy page).

## Settings UI additions

```
Privacy & security
─────────────────────────────────
[ ●─── ]  Biometric lock
          Require biometrics to open the app.

[ ●─── ]  Encryption (AES-256)
          On.  Key stored in device Secure Storage.
          [ Re-key… ]  ← rotates the encryption key (rare)

── Your data ──
[  Export my data  ]  →  share JSON file
[  Delete my data  ]  →  irreversible wipe (2-step confirm)

── Activity log ──
Recent consent changes …
```

## Files affected

| Action | Path |
|---|---|
| MODIFY | `pubspec.yaml` (add `local_auth: ^2.2.0`; ensure `flutter_secure_storage` present) |
| MODIFY | `lib/data/local/objectbox_store.dart` (encryptionKey arg + first-run key gen + migration) |
| CREATE | `lib/data/services/encryption_key_service.dart` (key gen + secure-storage read/write) |
| CREATE | `lib/data/services/biometric_service.dart` (wraps local_auth) |
| CREATE | `lib/view/screens/lock/biometric_lock_page.dart` |
| CREATE | `lib/data/local/entities/consent_log_entity.dart` |
| CREATE | `lib/data/repositories/consent_log_repository.dart` |
| MODIFY | `lib/core/constants/storage_keys.dart` (`biometricLockEnabled`, `lockTimeoutMinutes`, `encryptionEnabled`) |
| MODIFY | `lib/bloc/settings/` (3 new events + handlers for biometric / encryption / export / delete) |
| MODIFY | `lib/view/screens/settings/settings_page.dart` (new section) |
| CREATE | `lib/view/screens/privacy/privacy_data_page.dart` (expanded privacy disclosure) |
| MODIFY | `lib/core/route/routes.dart` + `app_router.dart` (biometric-lock route, privacy-data route) |
| MODIFY | `lib/app/start.dart` (run migration before runApp) |

## Acceptance

- [ ] Fresh install creates a 256-bit key in secure storage; ObjectBox
      opens encrypted from day 1
- [ ] Existing install upgrade: data migrates losslessly (test with
      seed entries pre + post)
- [ ] Toggling biometric on → require biometric on next cold start
      and on resume-after-5-min
- [ ] "Export my data" produces a valid JSON file matching
      `BackupSnapshot.toJson` shape
- [ ] "Delete my data" wipes ObjectBox + SharedPrefs + secure storage
      + Drive file (if signed in)
- [ ] Privacy page lists every data category + purpose
- [ ] Consent log appends on every flag toggle
- [ ] `flutter analyze` clean
