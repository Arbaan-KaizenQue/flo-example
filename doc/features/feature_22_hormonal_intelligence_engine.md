# Feature 22 — Hormonal Intelligence Engine

## Goal

Transform symptom tracking into AI-powered hormonal intelligence. This
engine is the **umbrella** capability — it owns the dashboard's "cycle
phase" thinking and feeds the AI prompt with hormonal context. Specific
detection rules (PMDD, irregularity) live in their own feature MDs and
are called by this engine, not duplicated here.

## What the engine produces

- **PMS patterns** — recurring symptom clusters in late luteal
- **Hormonal changes** — phase-aware insight tone
- **Recurring symptom timing** — "your headaches cluster 3 days before
  period"
- **Lifestyle ↔ symptom correlations** — e.g. low-sleep weeks predict
  worse cramps
- **Phase-specific guidance** — different advice in menstrual vs
  follicular vs ovulatory vs luteal

## Inputs

- `CycleLogRepository` — period history
- `SymptomLogRepository` (Feature 29) — severity-tagged symptoms
- `MoodRepository` — daily mood entries
- `SleepRepository`, `WaterRepository` — lifestyle context
- `PredictionBloc.state.currentPhase` — already shipped in Feature 22
  Phase 1

## Hand-offs

This engine **delegates** to:

| Capability | Owner feature |
|---|---|
| PMDD pattern detection (severe luteal mood + remission) | feature_30 |
| Statistical cycle irregularity (σ-based) | feature_31 |
| 3 / 6 / 12-month long-arc narrative | feature_32 |
| Symptom severity & timing schema | feature_29 |
| 33-symptom canonical catalogue | feature_23 |

The hormonal engine itself owns: phase-aware Gemini prompt tuning, the
dashboard `PhaseIntelligenceCard`, and the `PmsPredictionCard` (both
already shipped). New work here is mostly **prompt + bubble taxonomy**,
not new detection rules.

## Dashboard integration (shipped + to-do)

Shipped (Feature 22 Phase 1):
- ✅ `PhaseIntelligenceCard` — current phase + day-of-cycle pill
- ✅ `PmsPredictionCard` — countdown / in-window status

To-do (Phase 2 — depends on feature_29):
- [ ] Symptom-cluster bubble — when ≥ 3 symptoms cluster around the
      same cycle day across cycles, surface as a `hormonalInsight`
      type recommendation
- [ ] Lifestyle correlation bubble — "Low-sleep weeks correlate with
      stronger cramps" (requires severity data → feature_29)
- [ ] Phase-tuned Gemini system prompt suffix — when the user is in
      luteal, gently tilt insights toward PMS prep; in follicular,
      tilt toward energy/exercise

## Acceptance

- [ ] Phase card + PMS card render whenever cycle history exists
      (already shipped)
- [ ] When feature_29 lands, hormonal engine consumes severity scores
- [ ] PMDD signals appear via feature_30, not via this engine
      directly
- [ ] Irregularity flags appear via feature_31, not via this engine
      directly
- [ ] `flutter analyze` clean
