# Feature 32 — Long-term Wellness Intelligence

## Goal

Surface **how the user's body and patterns evolve over months**.
Today's insights are short-window (last 7–30 days). This adds 3 / 6 /
12-month trend reports — the kind of long-arc narrative a doctor might
write up after a year of tracking.

## Inputs (existing)

- Every entity collection: cycles, symptoms, mood, sleep, water, weight
- `PredictionBloc.state.averageCycleLength`
- `OnboardingAnswers` (goals, age group)

## Logic

Three rolling windows: **3 months / 6 months / 12 months**. Each
window has:
- Cycle: mean length, σ, irregularity trajectory
- Top 5 symptoms by frequency and by avg severity (per Feature 29)
- Sleep: avg hours, % nights ≥ 7 h, quality distribution
- Hydration: avg ml/day, days above goal
- Mood: distribution histogram (amazing → awful), most common mood
- Weight: net change kg, trend slope

Compose this aggregate into a Gemini prompt and ask for a **narrative
recap** (200–350 words, 3rd-person friendly tone, evidence-based).

### Caching

Generating a long-arc report is expensive. Cache hard:
- One generation per window per **calendar week** (recompute on Monday)
- Store in new `WellnessReportEntity` (similar to `AIInsightEntity`)
- Read from cache instantly; refresh button forces regen

## UI surfaces

New screen `/wellness-reports` reachable from **Settings → "Wellness
reports"** tile.

Layout:
```
┌────────────────────────────────┐
│ Wellness Reports               │
│ Long-arc trends from your data │
├────────────────────────────────┤
│ [ 3 months ]                   │  ← tappable card, shows headline
│ "Your sleep improved 7→7.5h"  │
│ Generated Mon, Jun 3           │
├────────────────────────────────┤
│ [ 6 months ]                   │
│ ...                            │
├────────────────────────────────┤
│ [ 12 months ]                  │
│ ...                            │
└────────────────────────────────┘
```

Tap a card → full report screen with the narrative body + key stats
+ "Share as PDF" button (uses `pdf` + `printing` packages).

## Files affected

| Action | Path |
|---|---|
| CREATE | `lib/data/local/entities/wellness_report_entity.dart` |
| CREATE | `lib/data/models/wellness_report.dart` |
| CREATE | `lib/data/local/datasources/local_wellness_report_datasource.dart` |
| CREATE | `lib/data/repositories/wellness_report_repository.dart` |
| MODIFY | `lib/data/services/gemini_service.dart` (new `generateWellnessReport(window)` method) |
| CREATE | `lib/bloc/wellness_report/` (3-file Style A bloc) |
| CREATE | `lib/view/screens/wellness_reports/wellness_reports_page.dart` |
| CREATE | `lib/view/screens/wellness_reports/wellness_report_detail_page.dart` |
| MODIFY | `lib/core/route/routes.dart` + `app_router.dart` (new route) |
| MODIFY | `lib/view/screens/settings/settings_page.dart` (add tile) |

## Acceptance

- [ ] All three cards render with cached body when present
- [ ] First-ever generation only runs after user has ≥ 4 weeks of data
- [ ] Tap card → detail screen renders the full narrative
- [ ] "Share as PDF" produces a 1-2 page PDF
- [ ] Cache: never more than one Gemini call per window per week
- [ ] `flutter analyze` clean
