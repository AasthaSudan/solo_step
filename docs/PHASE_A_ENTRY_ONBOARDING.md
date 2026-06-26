# Phase A — Entry & Onboarding

## Overview

Phase A covers everything from app launch to a fully-populated user profile in Firestore. This phase has two screens: **Sign In** and **Vibe Onboarding (5-step quiz)**. By the end of Phase A, every Gemini call made later in the app (destination discovery, itinerary generation, re-planning, debrief) has access to a structured profile object that personalizes its output.

**Goal:** Get a user from zero to a usable profile in under 60 seconds, with zero typing required during onboarding.

---

## 1. Sign In Screen

### What the user sees
- App logo / splash branding
- "Continue with Google" button
- "Try without an account" (anonymous auth) — small text link below the main button
- Subtle tagline ("Your AI companion for solo travel")

### Why anonymous auth matters
This is a portfolio/hackathon project. Judges and recruiters will not want to create an account to demo your app. Anonymous auth via Firebase lets anyone tap one button and land straight into a working app. You can later add account linking (upgrade anonymous → Google account) if you want to preserve data across devices, but for now, treat both auth paths as equally valid entry points into the same downstream flow.

### What fires under the hood
1. `FirebaseAuth.instance.signInWithCredential()` for Google sign-in (using `google_sign_in` package), OR
2. `FirebaseAuth.instance.signInAnonymously()` for the guest path
3. On successful auth, check Firestore: does `users/{uid}` already exist?
   - **Yes** → user has already onboarded → route to **Home**
   - **No** → first-time user → route to **Vibe Onboarding**

### Routing logic (go_router)
```
/sign-in            → SignInScreen
/onboarding         → OnboardingFlow (5-step quiz, internally paged)
/home               → HomeScreen
```

A `redirect` callback in your `GoRouter` config checks auth state + Firestore profile existence on every navigation attempt, so deep links and app restarts always land the user in the right place.

---

## 2. Vibe Onboarding — 5-Step Quiz

This is a **single PageView-based flow**, not 5 separate routes. Each step is a full-screen card with large tappable chips/buttons — no text fields, no keyboard. The user taps through linearly, with a progress indicator (dots or a thin bar) at the top.

### Step 1 — Mood
**What the user sees:** 5 large illustrated cards, single-select:
- Chill
- Adventure
- Spiritual
- Culture
- Party

**Implementation:** Each card is a custom widget (`MoodCard`) with an icon/illustration, label, and selected-state border highlight. Tapping a card updates local state (Riverpod) and auto-advances to Step 2 after a short delay (300ms), OR shows a "Next" button — your call on UX feel, but auto-advance feels slicker for a demo.

### Step 2 — Budget Tier
**What the user sees:** 3-4 tiers with concrete ₹/day anchors so it doesn't feel abstract:
- Backpacker — ₹800–1500/day
- Comfort — ₹1500–3500/day
- Premium — ₹3500–7000/day
- Luxury — ₹7000+/day

**Why anchors matter:** "Budget" means different things to different people. Putting a real number next to each tier removes ambiguity and also gives Gemini a concrete constraint to work with later (rather than a vague label).

### Step 3 — Trip Duration
**What the user sees:** A simple stepper or chip-select:
- Weekend (2-3 days)
- Short trip (4-7 days)
- Extended (1-2 weeks)
- Long-term (2+ weeks)

### Step 4 — Interests (multi-select)
**What the user sees:** A chip grid, multi-select, e.g.:
- Nature & hiking
- Food & street eats
- History & monuments
- Nightlife
- Art & museums
- Beaches
- Offbeat/hidden gems
- Wellness & spirituality

User can select multiple. Minimum 1 selection required to proceed (validate before allowing "Next").

### Step 5 — Solo Experience Level
**What the user sees:** Two large cards:
- First-timer — "This is my first solo trip"
- Seasoned — "I've done this before"

**Why this matters:** This flag changes tone and depth of safety guidance later. A first-timer might get more explicit safety notes in the itinerary; a seasoned traveler gets leaner output.

### On quiz completion
Write the full profile object to Firestore:

```
users/{uid}/profile:
  mood: string              // "adventure"
  budgetTier: string        // "comfort"
  budgetPerDayMin: number   // 1500
  budgetPerDayMax: number   // 3500
  tripDuration: string      // "short_trip"
  interests: string[]       // ["food", "history", "offbeat"]
  experienceLevel: string   // "first_timer" | "seasoned"
  createdAt: timestamp
  updatedAt: timestamp
```

This profile object is then injected as context into **every** Gemini prompt for the rest of the app's lifecycle (discovery, itinerary, re-plan, debrief). Store it in a Riverpod provider (`userProfileProvider`) that's loaded once at app start and cached, so you're not re-fetching Firestore on every screen.

---

## File Structure (new files for Phase A)

```
lib/
  core/
    routing/
      app_router.dart                      // go_router config + redirect logic
  features/
    auth/
      data/
        repositories/
          auth_repository_impl.dart        // Firebase Auth wrapper
      domain/
        repositories/
          auth_repository.dart              // abstract interface
        entities/
          app_user.dart                     // uid, isAnonymous, email (nullable)
      presentation/
        providers/
          auth_provider.dart                 // Riverpod: current user stream
        screens/
          sign_in_screen.dart
        widgets/
          google_sign_in_button.dart
          guest_sign_in_link.dart

    onboarding/
      data/
        repositories/
          profile_repository_impl.dart       // Firestore write/read for profile
      domain/
        entities/
          user_profile.dart                  // the profile object above
        repositories/
          profile_repository.dart            // abstract interface
      presentation/
        providers/
          onboarding_provider.dart            // StateNotifier holding quiz answers as user progresses
          user_profile_provider.dart           // cached profile, loaded app-wide
        screens/
          onboarding_flow_screen.dart          // PageView container, 5 steps
          steps/
            mood_step.dart
            budget_step.dart
            duration_step.dart
            interests_step.dart
            experience_step.dart
        widgets/
          onboarding_progress_indicator.dart
          selectable_card.dart                 // reusable single-select card
          selectable_chip.dart                 // reusable multi-select chip
```

---

## Setup Requirements

### Firebase
1. Enable **Google Sign-In** and **Anonymous Auth** in Firebase Console → Authentication → Sign-in method
2. Add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) to the project
3. Firestore security rules — minimal starting point:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Dependencies (add to `pubspec.yaml`)
```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  google_sign_in: ^latest
  flutter_riverpod: ^latest
  go_router: ^latest
```

### Platform setup
- Android: SHA-1 fingerprint registered in Firebase Console for Google Sign-In to work
- iOS: URL scheme configured in `Info.plist` for Google Sign-In redirect

---

## What "done" looks like for Phase A

- [ ] User can sign in with Google OR continue as guest
- [ ] First-time users are routed to onboarding; returning users skip straight to Home
- [ ] All 5 quiz steps work with tap-only interaction, no keyboard
- [ ] Profile object is correctly written to Firestore on quiz completion
- [ ] `userProfileProvider` correctly loads and caches the profile for use by later phases
- [ ] App restart correctly remembers auth state and routes accordingly (no re-login required)

---

## Next Phase

**Phase B — Discover & Plan** picks up immediately after this: the Home screen, the first Gemini call (5 destination cards), and itinerary generation. The `userProfileProvider` built here is the direct input to that phase's first Gemini prompt.
