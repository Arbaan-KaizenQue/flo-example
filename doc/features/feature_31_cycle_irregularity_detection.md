# Feature 31 — Cycle Irregularity Detection

## Goal

Spot irregular cycles statistically and surface a calm, factual note
that helps the user understand it (without medicalising). Reasons cycles
shift: stress, weight change, travel, perimenopause, PCOS, postpartum
recovery, etc.

## Inputs (existing)

- `CycleLogRepository.getAllIncludingDeleted()` — full history
- `PredictionBloc` — already computes average length

## Detection logic

Run after every new cycle log. Compute over the **last 6–12 cycles**
(use whichever is available; minimum 3 for any flag):

1. **Mean** μ = avg of (start[i] - start[i-1]) in days
2. **Standard deviation** σ
3. **Per-cycle outliers** = any cycle where `|length - μ| > 2σ`

Flag as **irregular** when ANY of:

| Condition | Severity |
|---|---|
| σ > 7 days | `warning` |
| Any single cycle < 21 days or > 35 days | `warning` |
| Last cycle is more than 2σ from mean | `suggestion` |
| Pattern stable (σ ≤ 4) | suppress |

## UI surfaces

- **PredictionCard pill** — add a small "Cycle stability" pill next to
  the existing "Day X · Avg Yd" pills:
  - Stable (σ ≤ 4) → green dot + "Regular"
  - Mild variance (4 < σ ≤ 7) → amber dot + "Slight variance"
  - Irregular (σ > 7) → red dot + "Irregular"
- **Insights bubble** — when irregular, surface a
  `cycle_irregularity` type recommendation with the calm-explainer
  body
- **Settings → Reports** — link to feature_32 for context

## Recommendation body templates

- `irregular_stress`: "Your cycle varies by σ days. Stress, weight
  change, travel, and sleep disruption are common drivers — none of
  these are emergencies on their own."
- `irregular_perimenopause` (only if user is in age range 38+, from
  onboarding): adds a sentence about hormonal transition
- `cycle_too_short` (< 21d): suggests tracking spotting separately,
  recommends provider consult if persistent
- `cycle_too_long` (> 35d): same posture

## Files affected

| Action | Path |
|---|---|
| CREATE | `lib/data/services/cycle_irregularity_detector.dart` (pure) |
| MODIFY | `lib/data/models/recommendation.dart` (add `cycleIrregularity` enum value) |
| MODIFY | `lib/bloc/prediction/prediction_state.dart` (add `cycleVariance` + `stabilityLabel`) |
| MODIFY | `lib/bloc/prediction/prediction_bloc.dart` (compute σ in `_compute`) |
| MODIFY | `lib/view/widgets/prediction_card.dart` (new pill) |
| MODIFY | `lib/bloc/recommendation/recommendation_bloc.dart` (call detector, prepend result) |

## Acceptance

- [ ] σ pill is `Regular` for cycles within 4 days
- [ ] σ pill is `Irregular` when stddev > 7
- [ ] Insight bubble appears matching severity
- [ ] Detector is pure (no Gemini call) — runs on-device
- [ ] `flutter analyze` clean
