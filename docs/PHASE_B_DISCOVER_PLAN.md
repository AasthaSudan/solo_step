# Phase B — Discover & Plan

## Overview

Phase B is where the app's core AI value proposition kicks in. This phase covers four screens: **Home**, **Destination Discovery**, **Destination Detail**, and **Itinerary Generation & View**. By the end of this phase, the user has a saved trip with a fully tagged, day-by-day itinerary sitting in Firestore — ready to move into Phase C's active trip loop.

**Goal:** Take the profile object built in Phase A and turn it into a concrete, personalized, bookable-feeling trip plan using two Gemini calls.

---

## 1. Home Screen

### What the user sees
- If the user has an active or upcoming trip: a trip summary card at the top (destination name, dates, a small progress/status indicator)
- If no active trip: an empty state — friendly illustration + "Plan a new trip" CTA, prompting straight into discovery
- Below: maybe a "Recent trips" or "Inspiration" section (optional, can be static/deferred)

### What fires under the hood
- On screen load, query Firestore: `trips/{uid}` where `status == "active"` or `status == "upcoming"`
- If found, render the trip card; if not, render empty state
- Tapping "Plan a new trip" navigates to Destination Discovery, carrying the cached `userProfileProvider` data forward

### Routing
```
/home                    → HomeScreen
/discover                → DestinationDiscoveryScreen
```

---

## 2. Destination Discovery Screen

### What the user sees
- A confirmation/tweak header: shows the user's profile-derived vibe, budget, and duration as editable chips (in case they want to adjust before generating — e.g., "Actually I have 5 days this time, not 7")
- A "Generate destinations" button
- **Loading state:** skeleton destination cards (NOT a spinner) — this is your first real "AI moment" in the app, so the loading state should feel intentional and premium, not like the app is stuck
- Once loaded: 5 swipeable destination cards, each showing name, tagline, ₹/day estimate, and a one-line safety note

### What fires under the hood (Gemini Call #1)
1. Build the prompt by merging: `userProfile` (mood, budget tier, interests, experience level) + any on-screen tweaks (duration override, etc.)
2. Call Gemini 1.5 Flash with **structured JSON output** requesting exactly 5 destinations:
```json
{
  "destinations": [
    {
      "name": "string",
      "tagline": "string",
      "dailyBudgetEstimate": number,
      "highlights": ["string", "string", "string"],
      "safetyNote": "string"
    }
  ]
}
```
3. Parse the response, render as swipeable cards (use a package like `flutter_card_swiper` or a custom `PageView` with peek effect)
4. **Do not** persist these to Firestore yet — they're ephemeral suggestions until the user picks one. Hold them in a Riverpod state (`discoveryResultsProvider`) for the duration of this session.

### Error handling
- If Gemini returns malformed JSON or fewer than 5 results: retry once automatically, then fall back to an error state with a "Try again" button — never show a broken/partial card list to the user.

### Navigation
Tapping a card → `Destination Detail` screen, passing the selected destination object.

---

## 3. Destination Detail Screen

### What the user sees
- Larger hero treatment of the destination (name, tagline prominent)
- "Why this fits you" — a short blurb connecting the destination to the user's specific vibe/interests (can be generated as part of Call #1's response, or composed client-side from the highlights + profile)
- Best time to visit, full highlights list, rough total cost estimate (daily estimate × trip duration)
- Primary CTA: **"Build my itinerary"**
- Secondary action: back to discovery to pick a different card

### What fires under the hood
- No new Gemini call here — this screen renders data already fetched in the discovery call
- Tapping "Build my itinerary" triggers Gemini Call #2 (see below) and navigates to the Itinerary screen, likely showing a loading/transition state during generation

---

## 4. Itinerary Generation & View Screen

### What the user sees
- **Loading state** while Gemini generates (again: skeleton day-cards, not a spinner)
- Once loaded: expandable day-by-day cards (Day 1, Day 2, ... Day N)
- Each day expands to show: morning/afternoon/evening activities, suggested stay, food recommendations — each line item visually tagged with its category and ₹ estimate (e.g., a small colored chip: "Food · ₹400")
- Actions: "Regenerate" (re-runs Call #2), inline edit (swap a specific activity — optional/stretch), and **"Save & Start Planning"** which persists everything to Firestore and moves toward Phase C's budget setup

### What fires under the hood (Gemini Call #2)
1. Prompt merges: selected destination + user profile + trip duration
2. Request structured JSON for the full itinerary:
```json
{
  "days": [
    {
      "dayNumber": 1,
      "activities": [
        {
          "time": "morning",
          "title": "string",
          "category": "sightseeing | food | transport | stay | activity",
          "estimatedCost": number,
          "notes": "string"
        }
      ],
      "staySuggestion": { "name": "string", "estimatedCost": number },
      "foodSuggestions": ["string"]
    }
  ]
}
```

### Why the `{category, estimatedCost}` tagging is load-bearing
This is the single most important data structure in the entire app. Phase C's budget pacing bar and re-plan logic **diff against these tags** — they compare what the user actually spent vs. what was estimated, per category, per day. If this tagging is loose, inconsistent, or treated as cosmetic now, the budget loop in Phase C will not work reliably later. Validate that every single activity line item has both fields populated before accepting the Gemini response — reject and retry if any are missing.

### On "Save & Start Planning"
Write to Firestore:
```
trips/{uid}/{tripId}:
  destination: { name, tagline, dailyBudgetEstimate, ... }
  itinerary: { days: [...] }   // full tagged itinerary from Call #2
  status: "planning"            // becomes "active" once budget is set in Phase C
  createdAt: timestamp
  tripDuration: number
```

---

## File Structure (new files for Phase B)

```
lib/
  features/
    home/
      presentation/
        screens/
          home_screen.dart
        widgets/
          trip_summary_card.dart
          empty_state_widget.dart
        providers/
          active_trip_provider.dart          // Riverpod: queries Firestore for active/upcoming trip

    discovery/
      domain/
        entities/
          destination.dart                    // name, tagline, dailyBudgetEstimate, highlights, safetyNote
        repositories/
          destination_repository.dart         // abstract interface
      data/
        repositories/
          gemini_destination_repository_impl.dart  // builds prompt, calls Gemini, parses JSON
      presentation/
        providers/
          discovery_results_provider.dart      // StateNotifier: holds the 5 generated destinations
        screens/
          destination_discovery_screen.dart
          destination_detail_screen.dart
        widgets/
          destination_card.dart
          destination_card_skeleton.dart        // loading state
          profile_tweak_chip.dart                // editable mood/budget/duration chips

    itinerary/
      domain/
        entities/
          itinerary.dart                        // days: List<ItineraryDay>
          itinerary_day.dart                     // dayNumber, activities, staySuggestion, foodSuggestions
          itinerary_activity.dart                // time, title, category, estimatedCost, notes
        repositories/
          itinerary_repository.dart              // abstract interface
      data/
        repositories/
          gemini_itinerary_repository_impl.dart  // builds prompt, calls Gemini, validates tags, parses JSON
      presentation/
        providers/
          itinerary_provider.dart                 // StateNotifier: current itinerary generation state
        screens/
          itinerary_view_screen.dart
        widgets/
          day_card.dart                            // expandable
          day_card_skeleton.dart
          activity_line_item.dart                  // renders the category + ₹ chip
```

---

## Setup Requirements

### Gemini API
- Ensure your Gemini API key is configured (likely via `.env` + `flutter_dotenv`, or Firebase Remote Config if you want to avoid shipping the key client-side — **prefer routing Gemini calls through a Firebase Cloud Function** rather than calling Gemini directly from the Flutter client, so your API key never ships in the app binary)
- Set `responseMimeType: "application/json"` and provide a JSON schema in the Gemini request config to maximize structured output reliability

### Firestore
- New collection: `trips/{uid}/{tripId}` — make sure security rules extend to this collection, scoped to the authenticated user
```
match /trips/{tripId} {
  allow read, write: if request.auth != null && resource.data.uid == request.auth.uid;
}
```

### Dependencies (add to `pubspec.yaml` if not already present)
```yaml
dependencies:
  cloud_functions: ^latest        # if routing Gemini calls server-side
  flutter_dotenv: ^latest          # if calling Gemini directly (less secure, faster to prototype)
```

---

## What "done" looks like for Phase B

- [ ] Home screen correctly shows empty state vs. active trip card
- [ ] Discovery screen generates exactly 5 destinations with all required fields populated
- [ ] Skeleton loading states feel intentional, not broken
- [ ] Destination detail screen correctly renders the selected card's full data
- [ ] Itinerary generation produces a day-by-day plan where **every activity has both `category` and `estimatedCost` populated** — no exceptions
- [ ] Malformed Gemini responses are caught and retried, never shown broken to the user
- [ ] "Save & Start Planning" correctly persists the full trip + itinerary object to Firestore

---

## Next Phase

**Phase C — Trip Setup & Active Trip Loop** picks up immediately after this: the user sets a total budget (deriving a daily target from the tagged itinerary built here), optionally generates an offline pack, and then enters the "hero loop" — the active trip dashboard with budget pacing and Return Signal check-ins. The `{category, estimatedCost}` tags from this phase are the direct input to that phase's budget diffing logic.
