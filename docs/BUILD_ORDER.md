# Build Order — How to Actually Code This (vs. Phase A-D Journey Docs)

> **Note:** Phase A-D docs (in separate files) describe the app journey — what each part of the product does, screen by screen. This doc describes the *coding sequence* — the order you should actually write code in, which cuts across all 4 phases.

## Why build order ≠ phase order

Phase A-D follows the **user's journey** through the app (sign in → discover → plan → trip → wrap). That's the right structure for documentation, README narrative, and explaining the product to a recruiter.

But if you build strictly in that order — fully finishing Phase A (including Firebase auth + Firestore) before touching Phase B — you'll hit integration problems late, re-do UI work after wiring state, and have nothing demoable until everything is wired end-to-end.

Instead, build in **layers**, touching all 4 phases at each layer:

---

## Layer 1 — Full UI, All Screens, Static/Dummy Data

**Goal:** Every screen across Phase A-D exists, looks right, is responsive, and you can tap through the entire app — with hardcoded fake data standing in for Gemini/Firebase.

What this means concretely:
- Sign-in screen, onboarding quiz (5 steps), Home, destination cards, destination detail, itinerary view, trip dashboard, debrief card — **all built, all responsive**, using `MediaQuery`/`LayoutBuilder` so they work across phone sizes
- Dummy data lives in plain Dart constants or local JSON files (e.g., `mock_destinations.dart` with 5 hardcoded destination objects)
- Navigation between all screens works via `go_router`, even though nothing is "real" yet
- No `StateNotifier`/Riverpod logic yet beyond maybe a simple `useState`-style local widget state for things like "which onboarding step am I on"

**Why this first:** You get a fully clickable prototype almost immediately. Great for demos, great for catching UI bugs before they're entangled with data logic.

### Responsive / cross-device rules for Layer 1 (non-negotiable)

Since this needs to work on any device (small phones, large phones, tablets, foldables), every screen built in Layer 1 must follow these rules from the start — retrofitting responsiveness later is much more expensive than building it in:

- **Never hardcode pixel widths/heights** for layout containers. Use `MediaQuery.of(context).size`, `LayoutBuilder`, or `Flexible`/`Expanded` instead of fixed `SizedBox(width: 320)` style values.
- **Use `SafeArea`** on every screen to handle notches, status bars, and gesture areas across devices.
- **Text scales with `MediaQuery.textScaler`** — don't hardcode font sizes that ignore system accessibility settings.
- **Grid/chip layouts** (like the interests multi-select in onboarding) should use `Wrap` or `GridView.builder` with a responsive `crossAxisCount` calculated from screen width (e.g., 2 columns under 600px width, 3-4 columns above), not a fixed column count.
- **Cards and images** should scale proportionally (`AspectRatio` widget) rather than fixed dimensions, so destination cards/itinerary cards look right on both a small phone and a tablet.
- **Test breakpoints during Layer 1, not after:** at minimum, check each screen at ~360px width (small phone), ~412px (standard phone), and ~800px+ (tablet/foldable unfolded) using Flutter's device preview or by resizing the emulator.
- **Use `flutter_screenutil` or built-in `MediaQuery` consistently** — pick one approach project-wide rather than mixing responsive strategies screen to screen, so Copilot-generated screens stay consistent with each other.

---

## Layer 2 — Riverpod State Management (still no real backend)

**Goal:** Replace ad-hoc local widget state with proper Riverpod providers, but data sources are still mocked (now via repository interfaces that return fake data).

What this means concretely:
- Define the **abstract repository interfaces** for each domain (`AuthRepository`, `ProfileRepository`, `DestinationRepository`, `ItineraryRepository`, `CheckInRepository`, etc.)
- Write **fake/mock implementations** of each (`FakeAuthRepositoryImpl`, `FakeDestinationRepositoryImpl`) that return the same dummy data from Layer 1, but now routed through proper repository methods (`Future<List<Destination>> getDestinations()`)
- Wire these into Riverpod providers (`destinationRepositoryProvider`, `userProfileProvider`, `checkInProvider`, etc.)
- Screens now read from providers instead of hardcoded constants — UI doesn't change, but the data plumbing underneath does
- This is also where you build state logic that doesn't need a backend yet: the onboarding quiz's `StateNotifier` tracking answers across steps, the budget pacing calculation logic, the check-in countdown timer logic

**Why this matters:** Because you're coding against interfaces, swapping fake → real implementations in Layer 3 touches almost no UI code. This is the entire point of Clean Architecture's dependency inversion — you're paying that cost now for a clean swap later.

---

## Layer 3 — Firebase Integration (real backend, real Gemini calls)

**Goal:** Replace every fake repository implementation with a real one — Firebase Auth, Firestore, Gemini API calls — without touching UI or state management code.

What this means concretely:
- `FirebaseAuthRepositoryImpl` replaces `FakeAuthRepositoryImpl` — same interface, real Firebase calls
- `FirestoreProfileRepositoryImpl`, `GeminiDestinationRepositoryImpl`, etc. — same pattern
- Update Riverpod provider definitions to point at the real implementations instead of fakes (often just changing one line per provider)
- Write the actual Gemini prompts (structured JSON output) for: destination discovery, itinerary generation, re-plan, debrief synthesis
- Set up Firestore security rules, indexes if needed
- Test each repository swap independently — if Layer 2 was done properly, the UI shouldn't need any changes at all here

**Why this is safe to do third:** Bugs at this layer are now isolated to "is my Firebase call right / is my Gemini prompt returning good JSON" — not tangled with "is my UI broken" or "is my state management broken." You've already proven those work in Layers 1-2.

---

## Layer 4 — Advanced / Differentiating Features ("left important")

**Goal:** Add the features that make this stand out — once the skeleton is fully real and working end-to-end.

What this means concretely:
- **Advanced Features**: Background reliable offline syncing, background geolocator testing
- **Budget re-plan loop**: the threshold-triggered Gemini re-plan call, diff screen, accept/dismiss logic
- **Offline pack**: Drift/Hive caching, offline-first expense logging with background sync
- **Debrief card**: widget-to-image rendering, share_plus integration
- Polish: error states, loading skeletons, edge cases (no internet, Gemini returns malformed JSON, etc.)

**Why this is last:** These features are the hardest to get right and the most impressive in a demo — but they only matter if the foundation under them is solid.

---

## Quick Reference Table

| Layer | What's real | What's fake | Demoable? |
|---|---|---|---|
| 1 — UI | Layout, navigation, responsiveness | All data | Yes — looks done, nothing works |
| 2 — Riverpod | State logic, providers, timers/calculations | Data source (still mocked) | Yes — feels alive, still no backend |
| 3 — Firebase | Auth, Firestore, Gemini calls | Nothing | Yes — fully functional core app |
| 4 — Advanced | re-plan loop, offline, debrief | Nothing | Yes — full feature set, hackathon-ready |

---

## How this maps back to Phase A-D docs

Each layer above touches pieces of every phase. For example, "Layer 1 — UI" includes the onboarding quiz screens (Phase A), destination cards (Phase B), trip dashboard (Phase C), and debrief card (Phase D) — all built in the same pass, just with dummy data.

Use the **Phase A-D docs** to know *what* a given screen/feature needs to do and contain. Use **this doc** to know *when* in your coding timeline to build it.
