# Feature 30 — PMDD Detection Engine

## Goal

Distinguish **Premenstrual Dysphoric Disorder (PMDD)** from ordinary
PMS so the app can surface a calm, evidence-based heads-up
("…consider speaking to a healthcare provider") when the pattern is
strong. PMDD is a clinical condition affecting ~5 % of menstruating
people and is regularly under-diagnosed.

## Inputs (existing + new)

- `CycleLogRepository` — full cycle history with start/end dates
- `SymptomLogRepository` (Feature 29) — severity-tagged mood symptoms
- `PredictionBloc` — derives cycle phase + last-period boundary
- `MoodRepository` — daily mood entries

## Detection logic

A row is flagged as **PMDD-pattern** when ALL of:

1. The user has **≥ 3 consecutive logged cycles** of severity data
2. In the **last 7 days of each cycle** (i.e. luteal-late window), at
   least ONE of the following mood symptoms has severity **≥ 4/5**:
   - Anxiety
   - Depression / low mood
   - Irritability
   - Mood swings
3. The same severe symptom drops to **≤ 2/5** within 3 days after
   period onset (follicular remission) — this is the key PMDD signature
4. The pattern repeats across at least 3 of the last 3 cycles

Output strength:
- **Strong (3/3 cycles match)** → severity=`warning`, body suggests
  professional consultation
- **Possible (2/3 cycles match)** → severity=`suggestion`, body
  suggests "keep logging to improve confidence"
- **None (0 or 1 cycle)** → suppress

The detector runs after every cycle end (soft-delete or new period
log triggers re-eval) — implement as a pure static method
`PmddDetector.evaluate(cycles, symptomLogs)` returning a
`Recommendation?`.

## AI integration

Add new enum value:

```dart
// lib/data/models/recommendation.dart
enum RecommendationType {
  // ...existing...
  pmddSignal,
}
```

The detector emits a `Recommendation` of type `pmddSignal` and feeds it
into `RecommendationBloc.state.recommendations` alongside Gemini-sourced
insights. **This rule runs on-device** — it is not delegated to Gemini
(too risky to let an LLM diagnose). Gemini can still be asked to
elaborate when the user taps the bubble.

## UI surfaces

- **Dashboard insight bubble** — purple accent (`#A855F7`), heads-up
  pill, never auto-dismissed
- **Detail sheet** — opens on bubble tap, lists which cycles matched +
  which symptoms dominated, with the clinical disclaimer block
- **Settings** — a "Reset PMDD detection" button (clears the flag if
  the user wants to start over)

## Files affected

| Action | Path |
|---|---|
| CREATE | `lib/data/services/pmdd_detector.dart` (pure compute) |
| MODIFY | `lib/data/models/recommendation.dart` (add `pmddSignal`) |
| MODIFY | `lib/bloc/recommendation/recommendation_bloc.dart` (call detector after every recompute, prepend output) |
| MODIFY | `lib/view/widgets/insights_card.dart` + `insight_bubble.dart` (purple accent for `pmddSignal`) |
| CREATE | `lib/view/widgets/pmdd_disclaimer_sheet.dart` |

## Acceptance

- [ ] Test fixture: 3 cycles with mood-severity ≥ 4 in late luteal +
      remission post-period → bubble appears
- [ ] Test fixture: only 1 cycle matching → no bubble
- [ ] Tap bubble → opens detail sheet with "Consult a provider" CTA
- [ ] Bubble never auto-dismisses; only the Reset button clears it
- [ ] `flutter analyze` clean
- [ ] Disclaimer copy explicitly avoids diagnosis ("This is a pattern,
      not a diagnosis…")
