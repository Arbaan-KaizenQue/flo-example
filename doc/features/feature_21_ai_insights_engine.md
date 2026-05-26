# Feature: AI Insights Engine

## Goal

The app should feel AI-powered without behaving like a chatbot.

AI should generate personalized wellness recommendations based on:

* cycle logs
* symptoms
* sleep
* water
* onboarding profile

The AI must remain strictly inside women's wellness topics.

---

# Main AI Experience

The app shows AI recommendation bubbles.

Examples:

* AI Insight
* Sleep Pattern
* Hydration Pattern
* PMS Forecast
* Mood Trend
* Wellness Score
* Cycle Forecast
* Recovery Insight

User taps a bubble:
→ opens AI detail page/modal
→ shows detailed explanation

No chat screen.

No message input.

No conversation UI.

---

# Dashboard AI Section

Add an AI section on home dashboard.

Show:

* horizontal scroll bubbles/cards
* rotating insights
* wellness score card

Only show:

* important
* relevant
* recent insights

Do NOT show too many insights together.

---

# AI Recommendation Rules

AI recommendations must:

* feel personalized
* use user data patterns
* avoid generic advice
* stay short
* feel emotionally supportive
* feel like premium wellness insights

Bad:
"Drink more water."

Good:
"You tend to log headaches on lower hydration days."

---

# AI Restrictions

AI must NEVER:

* act like ChatGPT
* answer unrelated questions
* continue conversations
* generate long paragraphs
* diagnose diseases
* prescribe medications

AI only discusses:

* cycles
* symptoms
* sleep
* hydration
* mood
* wellness
* hormonal patterns

---

# AI Insight Types

Generate:

* cycle insights
* symptom insights
* hydration insights
* sleep insights
* mood insights
* forecast insights
* wellness summaries

---

# AI Wellness Score

Generate:
Today's Wellness Score

Based on:

* sleep
* hydration
* symptoms
* mood
* cycle health

Example:
82 / 100

---

# AI Monthly Summary

Generate:
Your Wellness This Month

Include:

* cycle trends
* sleep trends
* hydration trends
* mood trends
* symptom patterns

---

# AI Correlation Detection

Detect patterns like:

* low hydration + headaches
* poor sleep + fatigue
* PMS + mood changes
* recurring symptom timing

---

# AI Forecast Features

Generate:

* next cycle forecast
* PMS predictions
* low energy predictions
* recovery suggestions

---

# AI Bubble UX

Dashboard
→ AI bubble card
→ tap bubble
→ open detailed insight modal/page

Keep UI minimal initially.

Focus on functionality first.

---

# AI Storage

Store generated insights locally.

Store:

* title
* body
* type
* confidence
* created date

Reason:

* insight history
* monthly recap
* offline access

---

# AI Prompt Rules

The Gemini system prompt must:

* stay inside women's wellness
* avoid unrelated topics
* avoid chatbot behavior
* generate JSON only
* generate concise insight cards

---

# Important Rule

The AI should feel like:
"smart wellness guidance"

NOT:
"an AI chatbot"

---

# Phase 1

Build:

* AI recommendation bubbles
* AI detail page
* wellness score
* insight storage

---

# Phase 2

Build:

* monthly recap
* correlation engine
* cycle forecasting
* smart insight rotation

---

# Acceptance Checklist

* [ ] AI bubbles visible on dashboard
* [ ] Bubble tap opens detailed insight
* [ ] AI stays women-health focused
* [ ] No chatbot UI exists
* [ ] Insights generated from real user data
* [ ] Insights stored locally
* [ ] flutter analyze clean
