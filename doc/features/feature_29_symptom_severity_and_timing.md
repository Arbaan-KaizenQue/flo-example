# Feature 29 — Symptom Severity & Timing

## Goal

Move symptom tracking from binary (logged/not-logged) to **rich
per-symptom records** — severity (1–5), time of day, and optional
duration — so AI features can reason about magnitude and trajectory, not
just presence.

## Inputs (existing)

- `SymptomEntryEntity` — today, one row per date with a CSV of symptom
  names
- `SymptomRepository` — current upsert-by-day pattern
- 33-symptom catalogue from feature_23

## New data shape

Introduce a normalised per-symptom row entity:

```dart
@Entity()
class SymptomLogEntity {
  @Id() int obxId;
  @Unique() String id;                      // UUID v4
  @Property(type: PropertyType.date) DateTime date;
  String symptomName;                        // canonical from feature_23
  String category;                           // pain | mood | energy | …
  int severity;                              // 1..5  (3 = default)
  String timeOfDay;                          // morning | afternoon | evening | night | allDay
  double? durationHours;                     // optional, only for episodic symptoms
  @Property(type: PropertyType.date) DateTime createdAt;
  @Property(type: PropertyType.date) DateTime updatedAt;
  bool deleted;
}
```

- Replaces CSV-per-day for new entries
- One row per (date, symptomName) — upsert key is the pair
- Legacy `SymptomEntryEntity` rows remain readable via a compatibility
  shim in `SymptomRepository` (treats CSV entries as severity=3, time=allDay)

## Logic

### Severity scale

| Value | Label | Visual cue |
|---|---|---|
| 1 | Barely noticeable | thin grey bar |
| 2 | Mild | light pink |
| 3 | Moderate (default) | pink |
| 4 | Strong | deep pink |
| 5 | Severe | red |

### Time-of-day buckets

`morning` (06–12) · `afternoon` (12–18) · `evening` (18–22) · `night`
(22–06) · `allDay`

### Default behaviour

- Tap a chip in the picker → creates a row with severity=3, time=allDay.
- Long-press a chip → opens a small dialog with severity slider + time
  chips.
- Tapping an already-selected chip removes the entry (soft-delete via
  `deleted=true`).

## AI contract

The Gemini payload section becomes:

```json
"symptoms_last_30d": [
  {
    "date": "2026-05-12",
    "entries": [
      { "name": "Menstrual cramps", "category": "pain",
        "severity": 4, "timeOfDay": "morning", "durationHours": 6 },
      { "name": "Anxiety", "category": "mood",
        "severity": 2, "timeOfDay": "evening" }
    ]
  }
]
```

This is exactly the shape feature_23 specifies. Severity unlocks:
- PMDD detection (severity ≥ 4 on mood symptoms across 3+ cycles → feature_30)
- Symptom trajectory ("Your cramps have eased from avg 4 → 2 over 3 cycles")
- Triage tone ("Your headaches are severe (5) — consider tracking
  triggers")

## UI surfaces

- `lib/view/widgets/symptom_picker_sheet.dart` — chip → severity slider
  on long-press
- `lib/view/widgets/symptom_severity_chip.dart` (NEW) — chip variant
  that shows a coloured bar based on severity
- Selected-day card on dashboard — render top 3 symptoms with severity
  dots

## Files affected

| Action | Path |
|---|---|
| CREATE | `lib/data/local/entities/symptom_log_entity.dart` |
| CREATE | `lib/data/models/symptom_log.dart` |
| CREATE | `lib/data/local/datasources/local_symptom_log_datasource.dart` |
| MODIFY | `lib/data/repositories/symptom_repository.dart` (compat layer + new methods) |
| MODIFY | `lib/view/widgets/symptom_picker_sheet.dart` |
| CREATE | `lib/view/widgets/symptom_severity_chip.dart` |
| MODIFY | `lib/data/services/gemini_service.dart` (new payload shape) |
| MODIFY | `lib/bloc/symptom/symptom_state.dart` (`bySeverityForDay()` helper) |
| ObjectBox codegen | `dart run build_runner build` |

## Acceptance

- [ ] Long-pressing a chip opens severity + time dialog; saves
      immediately
- [ ] Default tap saves severity=3, time=allDay
- [ ] Legacy CSV entries still appear in the picker as selected
- [ ] Gemini payload carries severity + time per symptom
- [ ] `flutter analyze` clean
