# Routing Flow

Routes:
- splashRoute
- privacyRoute
- onboardingRoute
- homeRoute
- settingsRoute
- profileRoute

## Flow

Splash
→ check accepted terms
→ check onboarding complete
→ route accordingly

## Redirect Rules

if terms not accepted:
→ privacy page

if onboarding incomplete:
→ onboarding page

else:
→ home page

## Guest Flow
Guest users:
- can access home
- can access settings
- profile page shows login
