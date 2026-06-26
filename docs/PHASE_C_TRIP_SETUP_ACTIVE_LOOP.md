# SoloReady — Phase C: Trip Setup & Active Trip Loop

> **Phase C of 4** · Goal: turn a saved itinerary into a live trip with two parallel safety loops on one dashboard — **financial** (budget pacing → Gemini re-plan) and **physical** (Return Signal check-ins → Twilio SMS if you go dark).

Builds on Phase A (auth + profile) and Phase B (itinerary with `{category, estCostInr}`-tagged items). Same **Clean Architecture** layering as A/B: `domain` (entities + repository interfaces) → `data` (implementations) → `presentation` (Riverpod providers + screens). By the end, a user can set a budget, log spend offline, get a re-planned itinerary when overspending, and arm a check-in that alerts a trusted contact if they don't return in time.

> **Model note:** all Gemini calls use `gemini-2.5-flash` / `gemini-2.5-pro` (update Phase B's `1.5` string to match — current generation is 2.5/3.x).

---

## Table of contents
1. [What this phase delivers](#1-what-this-phase-delivers)
2. [How this maps to the build layers](#2-how-this-maps-to-the-build-layers)
3. [Prerequisites](#3-prerequisites)
4. [New dependencies](#4-new-dependencies)
5. [Architecture additions](#5-architecture-additions)
6. [Part 1 — Trip Setup](#6-part-1--trip-setup)
7. [Part 2 — Budget Co-Pilot (offline-first)](#7-part-2--budget-co-pilot-offline-first)
8. [Part 3 — Gemini Re-planning](#8-part-3--gemini-re-planning)
9. [Part 4 — Return Signal (server-authoritative)](#9-part-4--return-signal-server-authoritative)
10. [The unified Active Trip dashboard](#10-the-unified-active-trip-dashboard)
11. [Firestore data model](#11-firestore-data-model)
12. [Security rules update](#12-security-rules-update)
13. [Cloud Functions & secrets](#13-cloud-functions--secrets)
14. [Provider map additions](#14-provider-map-additions)
15. [Run & verify](#15-run--verify)
16. [Definition of done](#16-definition-of-done)
17. [Out of scope (Phase D)](#17-out-of-scope-phase-d)

---

## 1. What this phase delivers

| Capability | Description |
|---|---|
| Trip setup | Set total budget → derive daily target; (optional) generate offline pack |
| Expense logging | Fast, **offline-first** spend entry (Drift local → Firestore sync) |
| Budget pacing | Live actual-vs-estimated bar; over-threshold detection |
| Re-planning | `replanItinerary` Cloud Function regenerates remaining days cheaper; accept/dismiss diff |
| Return Signal | Arm a check-in (AI-suggested or manual) → miss it → trusted contact gets an SMS with last location |
| Trusted contacts | One-time setup in Profile/settings |
| Unified dashboard | One screen, two loops: pacing + log spend, and active check-ins + return |

**Definition of done:** an active trip where logging spend over the threshold offers a re-plan, and an armed check-in that is *not* acknowledged fires a real SMS to a trusted contact — **even if the app is force-closed.**

---

## 2. How this maps to the build layers

(Per `BUILD_ORDER.md` — build in this order, not top-to-bottom of this doc.)

- **Layer 1 (UI):** `active_trip_screen`, `pacing_bar`, `log_spend_sheet`, `replan_diff_sheet`, `checkin_chip`, `return_signal_card`, `manual_checkin_screen`, `trusted_contacts_screen` — all with dummy data, responsive.
- **Layer 2 (Riverpod):** `budget_provider`, `replan_provider`, `check_in_provider` wired to mock repositories.
- **Layer 3 (Firebase):** Firestore reads/writes, the `replanItinerary` callable.
- **Layer 4 (Advanced):** offline-first Drift sync, geolocator, `flutter_local_notifications`, and the server-side Twilio scheduled function. **Return Signal's SMS path is the very last thing you wire** — it depends on everything else being stable.

---

## 3. Prerequisites

- **Phases A & B complete** — itinerary items reliably carry `category` + `estCostInr`.
- **Firebase Blaze plan** (already required from Phase B for Functions).
- **A Twilio account** — a trial account works for the demo; note trial accounts can only SMS *verified* numbers, so verify your own + your demo contact's number.
- **Location permission** strings configured (Android `AndroidManifest.xml`, iOS `Info.plist` `NSLocationWhenInUseUsageDescription`).

---

## 4. New dependencies

Client (`pubspec.yaml`):
```yaml
dependencies:
  drift: ^2.20.0                 # offline-first local DB for expenses
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.4
  path: ^1.9.0
  geolocator: ^13.0.1            # last-known location for check-ins
  flutter_local_notifications: ^18.0.1  # "tap I'm back" nudge
  intl: ^0.19.0                  # ₹ formatting

dev_dependencies:
  drift_dev: ^2.20.0             # drift codegen (runs under build_runner)
```

Backend (`functions/`):
```bash
cd functions && npm install twilio
```

---

## 5. Architecture additions

Three new features in Clean Architecture style, plus backend additions. Nothing in A/B changes except Phase B's Gemini model string.

```
lib/features/
├── budget/                              # NEW
│   ├── domain/
│   │   ├── entities/expense.dart
│   │   ├── entities/budget_summary.dart
│   │   └── repositories/expense_repository.dart      # interface
│   ├── data/
│   │   ├── datasources/expense_local_db.dart         # Drift
│   │   └── repositories/expense_repository_impl.dart # Drift + Firestore sync
│   └── presentation/
│       ├── providers/budget_provider.dart
│       └── widgets/{pacing_bar.dart, log_spend_sheet.dart}
│
├── replan/                              # NEW
│   ├── domain/repositories/replan_repository.dart
│   ├── data/repositories/replan_repository_impl.dart # calls callable
│   └── presentation/
│       ├── providers/replan_provider.dart
│       └── widgets/replan_diff_sheet.dart
│
├── return_signal/                       # NEW
│   ├── domain/
│   │   ├── entities/{check_in.dart, trusted_contact.dart}
│   │   └── repositories/check_in_repository.dart
│   ├── data/repositories/check_in_repository_impl.dart # Firestore + geolocator
│   └── presentation/
│       ├── providers/check_in_provider.dart
│       ├── widgets/{checkin_chip.dart, return_signal_card.dart}
│       └── screens/{manual_checkin_screen.dart, trusted_contacts_screen.dart}
│
└── active_trip/                         # NEW — the unified dashboard
    └── presentation/screens/active_trip_screen.dart

functions/src/
├── replan.ts                            # NEW callable (stateless Gemini re-plan)
└── return_signal/
    ├── check_missed_checkins.ts         # NEW scheduled function → Twilio
    └── twilio_client.ts
```

---

## 6. Part 1 — Trip Setup

When the user taps "Start trip," they set a total budget; you derive a daily target and flip `status` to `active`. The offline pack is **optional** (your second talking point) — generate it here if you're including it.

`budget_summary.dart` (domain entity):
```dart
class BudgetSummary {
  final int totalBudgetInr;
  final int dailyTargetInr;     // totalBudget / durationDays
  final int spentInr;           // sum of logged expenses
  final int estimatedToDateInr; // sum of estCostInr for elapsed days
  const BudgetSummary({
    required this.totalBudgetInr,
    required this.dailyTargetInr,
    required this.spentInr,
    required this.estimatedToDateInr,
  });

  /// Positive => over budget vs the plan so far.
  int get varianceInr => spentInr - estimatedToDateInr;
  double get variancePct =>
      estimatedToDateInr == 0 ? 0 : varianceInr / estimatedToDateInr;
  bool get isOverThreshold => variancePct > 0.15; // 15% over → offer re-plan
}
```

Trip setup writes `budgetInr` + `dailyTargetInr` to the trip doc and sets `status: "active"` (reuse `ItineraryRepository` from Phase B or add a small `TripRepository.activate()`).

> **Optional offline pack:** a callable `generateOfflinePack` returns `{phrases, emergencyNumbers, firstTwoDays}`; cache it in Drift, and download a Mapbox/MBTiles region for the area. Keep it out of the critical path — it's a stretch feature.

---

## 7. Part 2 — Budget Co-Pilot (offline-first)

The interview-grade part: spend is logged **locally first** (works with no signal) and synced to Firestore opportunistically.

`expense.dart` (domain entity):
```dart
class Expense {
  final String id;
  final String tripId;
  final int day;
  final String category;   // stay | food | activity | transport | other
  final int amountInr;
  final DateTime spentAt;
  final bool synced;       // false until pushed to Firestore
  const Expense({...});
}
```

`expense_repository.dart` (domain interface — UI/providers depend on this, never on Drift/Firestore directly):
```dart
abstract interface class ExpenseRepository {
  Future<void> logExpense(Expense e);          // writes local immediately
  Stream<List<Expense>> watchExpenses(String tripId);
  Future<void> syncPending();                  // pushes unsynced rows
  Future<BudgetSummary> summaryFor(String tripId);
}
```

`expense_local_db.dart` (Drift table — the local source of truth):
```dart
import 'package:drift/drift.dart';
part 'expense_local_db.g.dart';

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  IntColumn get day => integer()();
  TextColumn get category => text()();
  IntColumn get amountInr => integer()();
  DateTimeColumn get spentAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 1;
}
```

`expense_repository_impl.dart` (the sync logic — the part worth explaining in interviews):
```dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._db, this._firestore, this._uid);
  // ...
  @override
  Future<void> logExpense(Expense e) async {
    await _db.into(_db.expenses).insertOnConflictUpdate(e.toDrift()); // local FIRST
    unawaited(syncPending()); // best-effort push; failure is fine, retried later
  }

  @override
  Future<void> syncPending() async {
    final pending = await (_db.select(_db.expenses)
          ..where((t) => t.synced.equals(false)))
        .get();
    for (final row in pending) {
      try {
        await _firestore
            .collection('users').doc(_uid)
            .collection('trips').doc(row.tripId)
            .collection('expenses').doc(row.id)
            .set(row.toFirestore());
        await (_db.update(_db.expenses)..where((t) => t.id.equals(row.id)))
            .write(const ExpensesCompanion(synced: Value(true)));
      } catch (_) {/* stays unsynced; retried on next call / connectivity */}
    }
  }
}
```
Call `syncPending()` on app resume and when connectivity returns.

`budget_provider.dart` (Riverpod 3): an `AsyncNotifier<BudgetSummary>` that watches expenses + the trip's itinerary, recomputes the summary, and exposes `logSpend(...)`. The dashboard reads `summary.isOverThreshold` to decide whether to surface a re-plan.

`log_spend_sheet.dart`: a bottom sheet with category chips, an amount field, and a save button — designed for two-tap entry. (Voice / UPI-SMS parsing is a nice future add; keep it manual for the build.)

---

## 8. Part 3 — Gemini Re-planning

Stateless callable: give it the remaining days + the reduced budget, get cheaper days back. Reuses Phase B's `itinerarySchema`.

`functions/src/replan.ts`:
```ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { generateJson } from './gemini/client';
import { itinerarySchema } from './gemini/schemas';

export const replanItinerary = onCall(
  { region: 'asia-south1', enforceAppCheck: true },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const { destination, remainingDays, remainingBudgetInr } =
      request.data as { destination: string; remainingDays: any[]; remainingBudgetInr: number };

    const prompt = `The traveler is over budget in ${destination}.
Re-plan ONLY these remaining days to fit a remaining budget of ₹${remainingBudgetInr} total.
Keep the same day numbers. Prefer cheaper stays, cheaper food, and free/low-cost
activities (e.g., free walking tours) over paid ones. Preserve the trip's character.
Current remaining plan: ${JSON.stringify(remainingDays)}
Return ONLY JSON matching the schema.`;

    return await generateJson(prompt, itinerarySchema, 'gemini-2.5-flash', 0.6);
  },
);
```

`replan_provider.dart`: an `AsyncNotifier` exposing `requestReplan()` → calls the callable, holds the proposed `Itinerary`. The UI computes a **diff** (old day vs new day, per-item) and shows it in `replan_diff_sheet.dart` with **Accept** (write new days into the trip's itinerary, recompute target) or **Dismiss** (discard). The accept/dismiss choice is the demo beat — never silently rewrite the plan.

---

## 9. Part 4 — Return Signal (server-authoritative)

**The key correctness rule:** the SMS must fire even if the app is killed. So the client only *arms* a check-in and shows a local nudge; a **scheduled Cloud Function** owns the alert. Don't rely on a client background timer — iOS/Android suspend them, and a safety feature that silently dies is worse than none.

### 9.1 Domain
`trusted_contact.dart`:
```dart
class TrustedContact {
  final String name;
  final String phone;   // E.164, e.g. +9198XXXXXXXX
  const TrustedContact({required this.name, required this.phone});
}
```
`check_in.dart`:
```dart
enum CheckInStatus { active, completed, alertSent }

class CheckIn {
  final String id;
  final String activityName;
  final DateTime returnBy;
  final int graceMinutes;
  final CheckInStatus status;
  final ({double lat, double lng})? lastKnownLocation;
  const CheckIn({...});
}
```

### 9.2 Data (`check_in_repository_impl.dart`)
On **arm**: capture current location via `geolocator`, then write the check-in doc. Critically, precompute `deadlineWithGrace = returnBy + graceMinutes` as a Firestore `Timestamp` and **denormalize** `uid`, `contactName`, `contactPhone` into the doc so the scheduled function needs no extra reads.

```dart
Future<void> arm(CheckIn c, TrustedContact contact) async {
  final pos = await Geolocator.getCurrentPosition();
  await _firestore
      .collection('users').doc(_uid)
      .collection('activeCheckIns').doc(c.id)
      .set({
        'uid': _uid,
        'activityName': c.activityName,
        'returnBy': Timestamp.fromDate(c.returnBy),
        'deadlineWithGrace':
            Timestamp.fromDate(c.returnBy.add(Duration(minutes: c.graceMinutes))),
        'status': 'active',
        'lastKnownLocation': {'lat': pos.latitude, 'lng': pos.longitude},
        'contactName': contact.name,
        'contactPhone': contact.phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
Future<void> imBack(String id) => _firestore
    .collection('users').doc(_uid)
    .collection('activeCheckIns').doc(id)
    .update({'status': 'completed'});
```
While a check-in is active and the app is foregrounded, periodically update `lastKnownLocation` (a `geolocator` position stream) so the eventual SMS has a fresh fix.

### 9.3 Presentation
`check_in_provider.dart` (`Notifier`) tracks the active check-in, runs a **local** countdown, and at `returnBy` schedules a `flutter_local_notifications` nudge: *"Tap 'I'm back' or we'll notify {name} in {grace} min."* Tapping "I'm back" calls `imBack()`. This local timer is **only** the friendly nudge — it is not what fires the SMS.

UI pieces:
- `checkin_chip.dart` — sits next to each itinerary activity on the dashboard; pre-filled with an AI-suggested return-by time (see 9.5), editable, toggles arm/disarm.
- `manual_checkin_screen.dart` — start a check-in for an ad-hoc activity (name + return-by + contact).
- `trusted_contacts_screen.dart` — one-time setup, lives in **Profile/settings** (contacts are per-user, not per-trip). Store under `users/{uid}.trustedContacts`.

### 9.4 Server (`functions/src/return_signal/`)
`twilio_client.ts`:
```ts
import twilio from 'twilio';
import { defineSecret } from 'firebase-functions/params';

export const TWILIO_SID = defineSecret('TWILIO_ACCOUNT_SID');
export const TWILIO_TOKEN = defineSecret('TWILIO_AUTH_TOKEN');
export const TWILIO_FROM = defineSecret('TWILIO_FROM_NUMBER');

export async function sendSms(to: string, body: string) {
  const client = twilio(TWILIO_SID.value(), TWILIO_TOKEN.value());
  await client.messages.create({ to, from: TWILIO_FROM.value(), body });
}
```
`check_missed_checkins.ts` — runs every minute, scans **all** users' active check-ins via a collection-group query, alerts the overdue ones, marks them `alert_sent`:
```ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { sendSms, TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM } from './twilio_client';

export const checkMissedCheckIns = onSchedule(
  {
    schedule: 'every 1 minutes',
    region: 'asia-south1',
    secrets: [TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM],
  },
  async () => {
    const db = getFirestore();
    const overdue = await db
      .collectionGroup('activeCheckIns')
      .where('status', '==', 'active')
      .where('deadlineWithGrace', '<=', Timestamp.now())
      .get();

    await Promise.all(overdue.docs.map(async (doc) => {
      const d = doc.data();
      const loc = d.lastKnownLocation;
      const maps = loc ? `https://maps.google.com/?q=${loc.lat},${loc.lng}` : 'location unavailable';
      await sendSms(
        d.contactPhone,
        `SoloReady alert: your contact hasn't checked in from "${d.activityName}". Last known location: ${maps}`,
      );
      await doc.ref.update({ status: 'alert_sent' });
    }));
  },
);
```

> **Required index:** Firestore prompts for a **collection-group index** on `activeCheckIns` (`status` ASC, `deadlineWithGrace` ASC) the first time the query runs — click the link in the error, or define it in `firestore.indexes.json`.

> **Honest framing for the UI:** present Return Signal as peace-of-mind, not a guaranteed emergency service. A ~1-minute scan plus the grace window means the alert isn't instant, and SMS delivery isn't guaranteed. Say so in the copy; don't over-promise life-safety.

### 9.5 AI-suggested return-by times
Extend Phase B's `itinerarySchema` so each item can carry an optional `suggestedReturnMinutes` (how long the activity reasonably takes), and add a line to `buildItineraryPrompt`: *"For each item also give suggestedReturnMinutes — tighter for nightlife/markets, looser for museums."* The chip pre-fills `returnBy = now + suggestedReturnMinutes`. (This is the "AI pre-fills, user overrides" demo wow.)

---

## 10. The unified Active Trip dashboard

`active_trip_screen.dart` is the hero screen — **two parallel loops, one screen**:

- **Financial loop:** `pacing_bar` (spent vs target) + a **"+ Log spend"** button → `log_spend_sheet`. When `summary.isOverThreshold`, a banner offers **"Re-plan remaining days"** → `replan_diff_sheet`.
- **Physical loop:** today's activities each with a `checkin_chip`, plus a **"+ Check-in"** button → `manual_checkin_screen`. Active check-ins show a live countdown via `return_signal_card`.

Same trip document, same "today's plan" context — no new screen paradigm. In a demo: log an overspend → accept a re-plan → arm a check-in → let it lapse → the SMS lands. That's the whole story on one screen.

---

## 11. Firestore data model

```
users/{uid}
├── profile: {...}                         # Phase A
├── trustedContacts: [ {name, phone} ]      # NEW (set once in settings)
├── trips/{tripId}
│   ├── ...                                 # Phase B fields
│   ├── budgetInr: 30000                    # NEW
│   ├── dailyTargetInr: 6000                # NEW
│   ├── status: "active"                    # planning → active → completed
│   └── expenses/{expenseId}                # NEW sub-collection
│       └── { day, category, amountInr, spentAt }
└── activeCheckIns/{checkInId}              # NEW (user-level, denormalized)
    └── { uid, activityName, returnBy, deadlineWithGrace,
           status, lastKnownLocation, contactName, contactPhone, createdAt }
```

`activeCheckIns` lives at the user level (not under a trip) and carries denormalized `uid`/`contact` fields so the collection-group scan is a single cheap query.

---

## 12. Security rules update

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;

  match /trips/{tripId} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
  match /activeCheckIns/{checkInId} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
    // the scheduled function uses the Admin SDK and bypasses these rules
  }
}
```

---

## 13. Cloud Functions & secrets

Set Twilio secrets (stored in Secret Manager, not in code):
```bash
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_FROM_NUMBER
```
Export the new functions from `functions/src/index.ts`:
```ts
export { replanItinerary } from './replan';
export { checkMissedCheckIns } from './return_signal/check_missed_checkins';
```
Deploy:
```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

---

## 14. Provider map additions

| Provider | Type | Responsibility |
|---|---|---|
| `expenseRepositoryProvider` | `ExpenseRepository` | Drift local + Firestore sync |
| `budgetProvider` | `AsyncNotifier<BudgetSummary>` | pacing, threshold, `logSpend()` |
| `replanRepositoryProvider` | `ReplanRepository` | calls `replanItinerary` |
| `replanProvider` | `AsyncNotifier<Itinerary?>` | request + hold proposed re-plan |
| `checkInRepositoryProvider` | `CheckInRepository` | Firestore + geolocator |
| `checkInProvider` | `Notifier<CheckIn?>` | active check-in + local countdown |
| `trustedContactsProvider` | `AsyncNotifier<List<TrustedContact>>` | settings |

---

## 15. Run & verify

```bash
cd functions && npm run build && firebase deploy --only functions,firestore:rules,firestore:indexes
cd .. && dart run build_runner build -d && flutter run
```

Checklist:
- [ ] Set budget → daily target derived; trip flips to `active`.
- [ ] Log a spend with the device in airplane mode → it appears instantly (local), then syncs when back online (`synced: true`).
- [ ] Push spend past +15% → re-plan banner appears → accept rewrites remaining days, dismiss leaves them.
- [ ] Set trusted contact in settings → arm a 2-minute check-in → **force-close the app** → SMS still arrives after the deadline + grace.
- [ ] Tap "I'm back" before the deadline → status `completed`, no SMS.

---

## 16. Definition of done

- Expense logging works fully offline and syncs without losing data.
- Budget summary + threshold detection drive the re-plan banner correctly.
- Re-plan diff shows old-vs-new and respects accept/dismiss.
- **Return Signal fires the SMS server-side with the app closed** (the whole point).
- Trusted contacts persist per-user; collection-group index deployed.
- Location + notification permissions handled gracefully (denied → feature degrades, doesn't crash).

---

## 17. Out of scope (Phase D)

- **Trip completion → debrief card** (travel personality + ₹ saved vs estimate) — Phase D.
- **Share + archive UI** — Phase D.
- **Bottom-nav tab shell** (Home / Trips / Profile) — Phase D.
- Voice / UPI-SMS expense parsing, richer offline pack — future enhancements.

When the Phase C checklist is green — especially the closed-app SMS — you've got both differentiators working. Phase D wraps the trip and turns it into the shareable card.
```