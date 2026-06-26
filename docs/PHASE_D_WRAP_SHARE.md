# SoloReady — Phase D: Wrap & Share

> **Phase D of 4** · Goal: close the trip, turn the logged data into a shareable "Trip Personality Card," and give the app its home — a bottom-nav shell with a trip archive. This is the growth loop: the card is what brings new users in.

Builds on A (auth/profile), B (itinerary), and C (budget + Return Signal). Same **Clean Architecture** layering, **Gemini 2.5**. By the end, completing a trip generates a card the user can share to WhatsApp/Instagram, every past trip lives in a Trips tab, and the whole app sits inside a proper three-tab shell.

> **Design rule for the card:** the **app** owns the hard numbers (₹ saved, days, spend), the **AI** only writes the flavor (personality, traits, caption). Never let Gemini invent statistics.

---

## Table of contents
1. [What this phase delivers](#1-what-this-phase-delivers)
2. [Build-layer mapping](#2-build-layer-mapping)
3. [Prerequisites & dependencies](#3-prerequisites--dependencies)
4. [Architecture additions](#4-architecture-additions)
5. [Part 1 — Trip completion](#5-part-1--trip-completion)
6. [Part 2 — The debrief card (AI + your data)](#6-part-2--the-debrief-card-ai--your-data)
7. [Part 3 — Render to image & share](#7-part-3--render-to-image--share)
8. [Part 4 — Trip archive](#8-part-4--trip-archive)
9. [Part 5 — The bottom-nav shell](#9-part-5--the-bottom-nav-shell)
10. [Firestore data model](#10-firestore-data-model)
11. [Security rules](#11-security-rules)
12. [Cloud Functions & provider map](#12-cloud-functions--provider-map)
13. [Run & verify](#13-run--verify)
14. [Definition of done](#14-definition-of-done)
15. [The complete /docs set](#15-the-complete-docs-set)

---

## 1. What this phase delivers

| Capability | Description |
|---|---|
| Trip completion | Mark a trip `completed` → trigger debrief generation |
| Debrief card | `generateDebrief` → travel personality + traits + caption (AI) over real stats (app) |
| Share | Render the card to a PNG and share via `share_plus` (the acquisition loop) |
| Archive | Trips tab listing past trips by status, opening their debrief |
| App shell | Bottom nav: Home / Trips / Profile, tying every phase together |

**Definition of done:** complete a trip → a card appears with the correct "₹ saved vs estimate" and an AI personality → share it as an image → it shows up in the Trips tab.

---

## 2. Build-layer mapping

(Per `BUILD_ORDER.md`.)
- **Layer 1 (UI):** `debrief_screen`, `debrief_card_widget`, `trips_screen`, `home_shell` — dummy data, responsive.
- **Layer 2 (Riverpod):** `debrief_provider`, `trips_provider` on mocks.
- **Layer 3 (Firebase):** the `generateDebrief` callable, trip reads/writes.
- **Layer 4 (Advanced):** render-to-image capture + share.

---

## 3. Prerequisites & dependencies

Phases A–C complete (you need `BudgetSummary` from C for the ₹-saved number).

Client (`pubspec.yaml`):
```yaml
dependencies:
  share_plus: ^10.1.2
  # path_provider + intl already added in Phase C
```
No new backend packages — `generateDebrief` reuses the Phase B Gemini client.

---

## 4. Architecture additions

```
lib/features/
├── debrief/                              # NEW
│   ├── domain/
│   │   ├── entities/debrief_card.dart
│   │   └── repositories/debrief_repository.dart
│   ├── data/repositories/debrief_repository_impl.dart   # callable + Firestore
│   └── presentation/
│       ├── providers/debrief_provider.dart
│       ├── screens/debrief_screen.dart
│       └── widgets/debrief_card_widget.dart             # the shareable visual
│
├── archive/                             # NEW
│   └── presentation/
│       ├── providers/trips_provider.dart
│       └── screens/trips_screen.dart
│
└── shell/                               # NEW
    └── presentation/screens/home_shell.dart            # bottom-nav scaffold

functions/src/
└── debrief.ts                           # NEW callable (Gemini 2.5)
```

---

## 5. Part 1 — Trip completion

The user marks the trip done (or `endDate` passes). Set `status: "completed"` and route to the debrief screen, which kicks off generation if no debrief exists yet.

```dart
Future<void> completeTrip(String tripId) =>
    _firestore.collection('users').doc(_uid)
      .collection('trips').doc(tripId)
      .update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
```

Also disarm any lingering `activeCheckIns` for the trip so they don't fire post-trip.

---

## 6. Part 2 — The debrief card (AI + your data)

### 6.1 Domain
```dart
class DebriefCard {
  // AI-generated flavor
  final String personality;        // "Budget Adventurer"
  final List<String> traits;       // ["Street Food Obsessed", "Early Riser"]
  final String caption;            // one-line shareable caption
  // App-computed facts (never from the AI)
  final int savedVsEstimateInr;    // estimated - actual (can be negative)
  final int totalSpentInr;
  final int daysCount;
  final String topCategory;
  final int checkInsCompleted;
  const DebriefCard({ ... });
}
```

### 6.2 Backend — `functions/src/debrief.ts`
The callable only returns flavor. High temperature for variety.
```ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { Type } from '@google/genai';
import { generateJson } from './gemini/client';

const debriefSchema = {
  type: Type.OBJECT,
  properties: {
    personality: { type: Type.STRING },
    traits: { type: Type.ARRAY, items: { type: Type.STRING } },
    caption: { type: Type.STRING },
  },
  required: ['personality', 'traits', 'caption'],
  propertyOrdering: ['personality', 'traits', 'caption'],
};

export const generateDebrief = onCall(
  { region: 'asia-south1', enforceAppCheck: true },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const { destination, daysCount, totalSpentInr, estimatedInr,
            categoryBreakdown, checkInsCompleted, mood, interests } = request.data;

    const prompt = `Create a fun, shareable solo-travel "personality" from this trip data.
Destination: ${destination}, ${daysCount} days. Mood: ${mood}. Interests: ${(interests||[]).join(', ')}.
Spent ₹${totalSpentInr} vs estimated ₹${estimatedInr}. By category: ${JSON.stringify(categoryBreakdown)}.
Check-ins completed: ${checkInsCompleted}.
Return: a 2-3 word personality title, 2-4 punchy traits, and one short caption.
Base everything ONLY on the data above. Do not invent numbers. JSON only.`;

    return await generateJson(prompt, debriefSchema, 'gemini-2.5-flash', 1.0);
  },
);
```
Export it from `functions/src/index.ts` and `firebase deploy --only functions`.

### 6.3 Provider — assemble flavor + facts
`debrief_provider.dart` (`AsyncNotifier<DebriefCard?>`):
```dart
Future<DebriefCard> generate(Trip trip) async {
  final summary = await ref.read(expenseRepositoryProvider).summaryFor(trip.id);
  final flavor = await ref.read(debriefRepositoryProvider).fetchFlavor(trip, summary);
  final card = DebriefCard(
    personality: flavor.personality,
    traits: flavor.traits,
    caption: flavor.caption,
    savedVsEstimateInr: summary.estimatedToDateInr - summary.spentInr, // APP owns this
    totalSpentInr: summary.spentInr,
    daysCount: trip.durationDays,
    topCategory: summary.topCategory,
    checkInsCompleted: summary.checkInsCompleted,
  );
  await ref.read(debriefRepositoryProvider).save(trip.id, card); // embed in trip doc
  return card;
}
```

---

## 7. Part 3 — Render to image & share

`debrief_card_widget.dart` is the visual, wrapped in a `RepaintBoundary` with a `GlobalKey`. To share, capture that boundary to a PNG and hand it to `share_plus`.

```dart
final _cardKey = GlobalKey();

// In build: RepaintBoundary(key: _cardKey, child: DebriefCardWidget(card: card))

Future<void> _share(DebriefCard card) async {
  final boundary =
      _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0); // crisp for socials
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final file = await File('${dir.path}/soloready_debrief.png').writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: card.caption);
}
```

> **Gotcha:** the widget must be laid out in the tree before you capture it — capture from the debrief screen where it's visible, not from an off-screen builder. Use `pixelRatio: 3.0` so the shared image isn't blurry on Instagram.

Design the card to be screenshot-worthy: big personality title, trait chips, and the hero number — **"₹X saved vs estimate"** — front and centre. That number is unique to your app (only you ran the budget loop), so make it the visual focal point.

> **Optional public link:** to make sharing pull non-users in, also write a public `tripStories/{slug}` doc and share a `https://yourapp.web.app/t/{slug}` URL backed by Firebase Hosting. Stretch goal — the image share alone is enough for the demo.

---

## 8. Part 4 — Trip archive

`trips_provider.dart` streams the user's trips newest-first:
```dart
@riverpod
Stream<List<Trip>> trips(Ref ref) {
  final uid = ref.read(authRepositoryProvider).currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('trips')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Trip.fromJson(d.data())).toList());
}
```
`trips_screen.dart` lists trip cards grouped/badged by `status` (planning / active / completed). Tapping a completed trip opens its saved debrief; tapping an active one returns to the Active Trip dashboard from Phase C.

---

## 9. Part 5 — The bottom-nav shell

Now that there's more than one destination, wrap the app in a three-tab shell using go_router's `StatefulShellRoute.indexedStack` (keeps each tab's state alive). Add this to `routing/app_router.dart`:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => HomeShell(shell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
      // discovery, detail, itinerary, active-trip live under the Home branch
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: Routes.trips, builder: (_, __) => const TripsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
      // trusted contacts (Phase C) live here
    ]),
  ],
),
```

`home_shell.dart` renders a `NavigationBar` driven by `navigationShell.currentIndex` / `goBranch(i)`. **Home** = plan + active trip, **Trips** = archive, **Profile** = vibe settings + trusted contacts (from Phase C) + sign-out.

---

## 10. Firestore data model

```
users/{uid}/trips/{tripId}
├── ...                                  # A–C fields
├── status: "completed"
├── completedAt: <serverTimestamp>
└── debrief: {                           # NEW (embedded)
      personality, traits[], caption,
      savedVsEstimateInr, totalSpentInr, daysCount,
      topCategory, checkInsCompleted, generatedAt
    }

# optional public sharing
tripStories/{slug}  →  { personality, caption, savedVsEstimateInr, ... }  # world-readable
```

---

## 11. Security rules

`trips` and `expenses` already covered in Phase C. If you add public stories:
```
match /tripStories/{slug} {
  allow read: if true;                                  // public
  allow write: if request.auth != null;                 // only signed-in users create
}
```

---

## 12. Cloud Functions & provider map

Deploy: `firebase deploy --only functions`.

| Provider | Type | Responsibility |
|---|---|---|
| `debriefRepositoryProvider` | `DebriefRepository` | calls `generateDebrief`, saves card |
| `debriefProvider` | `AsyncNotifier<DebriefCard?>` | assemble flavor + facts, share |
| `tripsProvider` | `Stream<List<Trip>>` | archive feed |

---

## 13. Run & verify

```bash
cd functions && npm run build && firebase deploy --only functions
cd .. && dart run build_runner build -d && flutter run
```

Checklist:
- [ ] Complete a trip → debrief generates; `savedVsEstimateInr` matches `estimated - spent` exactly.
- [ ] AI fields (personality/traits/caption) populate and vary across trips.
- [ ] Share → a crisp PNG opens the share sheet with the caption.
- [ ] Trips tab lists the trip as `completed`; reopening shows the saved card (no re-generation).
- [ ] Bottom nav switches Home / Trips / Profile and preserves each tab's state.

---

## 14. Definition of done

- Completing a trip produces a correct, shareable card with **app-owned numbers and AI-owned flavor**.
- Render-to-image yields a clean, social-ready PNG.
- Archive reads past trips and their debriefs without regenerating.
- Three-tab shell ties every phase together; Profile hosts trusted-contact setup from Phase C.
- Full end-to-end run works: onboard → discover → itinerary → budget loop + Return Signal → debrief → share.

---

## 15. The complete /docs set

With this, your documentation is complete and internally consistent:

```
docs/
├── PHASE_A_ENTRY_ONBOARDING.md      # auth, vibe quiz, profile
├── PHASE_B_DISCOVER_PLAN.md         # discovery + itinerary  (update Gemini 1.5 → 2.5)
├── PHASE_C_TRIP_SETUP_ACTIVE_LOOP.md# budget loop + Return Signal
├── PHASE_D_WRAP_SHARE.md            # debrief card + archive + shell  ← this file
└── BUILD_ORDER.md                   # UI → Riverpod → Firebase → advanced
```

**One consistency edit left:** bump Phase B's Gemini model string from `1.5` to `2.5` so all four phases agree.

**Now build, per `BUILD_ORDER.md`:** Layer 1 (all screens, dummy data, responsive) across A→B→C→D one screen at a time → Layer 2 (Riverpod) → Layer 3 (Firebase + callables) → Layer 4 (offline sync, geolocator, Twilio, render-to-image). Test each screen as you go.

That's the full app: a solo-travel planner that plans your trip, keeps you on budget with a live AI re-plan loop, watches your back with server-authoritative check-ins, and sends you home with a shareable card. Good luck — go ship it.
```