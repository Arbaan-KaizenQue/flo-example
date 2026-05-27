# Feature 23 — Symptom Intelligence Framework

> Canonical 30+ symptom catalogue from `Aura_30Plus_Symptom_Tracking_Framework.pdf`.
> Every symptom carries a definition, the cycle phase it most often
> appears in, and how the AI engine uses it. This file is the single
> source of truth — the picker UI, the Gemini payload schema, and every
> downstream AI feature (PMDD detection, irregularity flagging, monthly
> recap, etc.) all reference symptom names from here.

## Goal

Expand the current per-day symptom CSV (~25 informal names) into a
**categorised, metadata-rich catalogue of 33 symptoms** so AI features
can reason about timing, cycle phase, and clinical relevance.

## Categories & symptoms

### 1. Pain & Physical

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Menstrual cramps | Pain in the lower abdomen caused by uterine contractions during menstruation. | Menstrual | Period prediction, PMS detection |
| Lower back pain | Pain or stiffness in the lower back associated with hormonal fluctuations. | Menstrual / Luteal | PMS detection |
| Breast tenderness | Breast soreness caused by estrogen and progesterone changes. | Ovulatory / Luteal | Ovulation & PMS prediction |
| Headaches | Hormonal headaches often linked with estrogen withdrawal. | Menstrual / Luteal | Hormonal pattern analysis |
| Pelvic pain | Pain around reproductive organs. | Ovulatory | Ovulation prediction |

### 2. Emotional & Mood

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Mood swings | Rapid emotional changes linked to progesterone fluctuations. | Luteal | PMS & PMDD intelligence |
| Anxiety | Heightened nervousness or stress sensitivity. | Luteal | Emotional wellness analysis |
| Depression / low mood | Persistent sadness or emotional heaviness. | Luteal | PMDD detection |
| Irritability | Increased frustration and emotional sensitivity. | Luteal | Hormonal emotional mapping |
| Stress levels | Mental and emotional strain impacting hormonal stability. | All phases | Cycle irregularity detection |

### 3. Energy & Sleep

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Fatigue | Persistent tiredness associated with hormonal shifts. | Menstrual / Luteal | Energy pattern intelligence |
| Low energy | Reduced physical or mental motivation. | Luteal | Lifestyle recommendations |
| Insomnia | Difficulty sleeping due to hormonal imbalance. | Luteal | Sleep intelligence |
| Excessive sleepiness | Higher sleep requirement caused by progesterone. | Luteal | Hormonal wellness analysis |
| Brain fog | Difficulty concentrating or mental cloudiness. | Luteal | Cognitive wellness tracking |

### 4. Dermatological

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Acne breakouts | Hormonal skin eruptions caused by androgen changes. | Luteal | Hormonal acne prediction |
| Oily skin | Excess sebum production. | Ovulatory | Ovulation tracking |
| Dry skin | Reduced hydration associated with estrogen decline. | Menstrual | Hormonal pattern detection |

### 5. Reproductive & Fertility

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Vaginal discharge changes | Changes in texture and amount of cervical mucus. | Ovulatory | Fertility prediction |
| Spotting | Light bleeding between periods. | All phases | Irregularity detection |
| Ovulation pain | Mid-cycle pain during egg release. | Ovulatory | Ovulation detection |
| Libido increase | Higher sexual desire due to ovulation hormones. | Ovulatory | Fertility window prediction |
| Vaginal dryness | Reduced lubrication associated with low estrogen. | Menstrual | Hormonal deficiency analysis |

### 6. Gastrointestinal & Metabolic

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Bloating | Abdominal swelling caused by water retention. | Luteal | PMS detection |
| Constipation | Reduced bowel movements due to progesterone. | Luteal | Hormonal tracking |
| Diarrhea | Loose bowel movements linked to prostaglandins. | Menstrual | Period onset prediction |
| Nausea | Feeling of sickness or urge to vomit. | Ovulatory / Menstrual | Hormonal sensitivity analysis |
| Food cravings | Strong desire for specific foods. | Luteal | PMS prediction |
| Increased appetite | Elevated hunger associated with hormonal changes. | Luteal | Metabolic intelligence |
| Weight fluctuation | Temporary water retention or hormonal weight changes. | Luteal | Hormonal tracking |

### 7. Behavioral & Lifestyle

| Symptom | Definition | Cycle phase | AI contribution |
|---|---|---|---|
| Motivation changes | Variations in productivity and enthusiasm. | All phases | Behavioral AI modeling |
| Social withdrawal | Reduced interest in social interaction. | Luteal | Emotional intelligence |
| Sleep quality | Overall quality of sleep. | All phases | Recovery & wellness intelligence |
| Exercise tolerance | Ability to sustain physical activity. | All phases | Lifestyle optimization |
| Energy stability | Consistency of energy throughout the day. | All phases | Hormonal pattern analysis |

## UI rules

- **Grouped chips** — symptom picker shows section headers per category;
  chips inside each section. Long, scrollable bottom sheet.
- **Instant local save** — selecting/deselecting a chip writes to
  ObjectBox immediately (no Save button); a `MoodEntry`-style upsert by
  day.
- **Tap-and-hold to set severity** — per Feature 29; default 3/5 on
  first tap.
- **Search bar at the top** of the sheet for quick lookup once the list
  grows past one screen.
- **Pinned shortcuts** — last 5 most-used symptoms appear at the top of
  the sheet for one-tap logging.

## AI contract

Every Gemini payload (`generateInsights` / `streamFocusedInsight` in
`lib/data/services/gemini_service.dart`) sends symptoms as:

```json
"symptoms_last_30d": [
  {
    "date": "2026-05-12",
    "entries": [
      { "name": "Menstrual cramps", "category": "pain", "severity": 4 },
      { "name": "Fatigue",          "category": "energy", "severity": 3 }
    ]
  }
]
```

- Names are **canonical** (column 1 above). Don't send free-form text.
- `category` is the lowercase section name (`pain`, `mood`, `energy`,
  `derm`, `reproductive`, `gi`, `lifestyle`).
- `severity` is optional (added by Feature 29); omit when absent.

## Migration from current implementation

Today the symptom set lives in `mood_picker_sheet.dart` (mood) and
`symptom_picker_sheet.dart` (~11 hard-coded chips). Existing entries
store `symptomsCsv` (pipe-separated names) in `SymptomEntryEntity`.

Migration steps:
1. Replace `_all` list in `symptom_picker_sheet.dart` with the full
   catalogue grouped by category.
2. Map legacy names (case-insensitive) to canonical names on read in
   `SymptomRepositoryImpl._toModel`. Examples: `Cramps` → `Menstrual
   cramps`, `Mood swings` already canonical, `Tender breasts` →
   `Breast tenderness`.
3. New entries write canonical names from the start.
4. Picker UI rebuild = Feature 29 work (severity + timing).

## Files affected (for implementer)

| File | Change |
|---|---|
| `lib/view/widgets/symptom_picker_sheet.dart` | Replace flat chip list with `ExpansionTile`-per-category + search + pinned recents |
| `lib/data/models/symptom_entry.dart` | Add `categoriesIndex()` helper |
| `lib/data/local/entities/symptom_entry_entity.dart` | No schema change (CSV still works); Feature 29 introduces severity |
| `lib/data/services/gemini_service.dart` | Update `_buildUserPrompt` symptoms section to category-tagged shape |
| `lib/data/repositories/symptom_repository.dart` | Add legacy-name remap in `_toModel` |

## Acceptance

- [ ] All 33 symptoms from the PDF appear in the picker, grouped by
      the 7 categories
- [ ] Selecting a symptom saves immediately to ObjectBox (no Save
      button)
- [ ] Legacy entries (pre-feature) still render with their old names
- [ ] Gemini payload uses canonical names + category tags
- [ ] `flutter analyze` clean
