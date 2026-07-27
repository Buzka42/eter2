# 11 · Wearable Integrations & Deduplication

Strategy: **hub-first, vendor-direct for precision**. The OS hubs (HealthKit / Health Connect) already receive data from virtually every brand's phone app — that's our universal fallback. Direct vendor APIs add finer granularity (intraday HR, richer sessions) for the brands that matter most.

> **Google Fit is dead.** Its REST API shut down June 30, 2025 (deprecated May 2024). Do not build against it. Health Connect is Google's replacement and our Android hub. If a user asks for "Google Fit", the Integrations screen explains: connect the watch's own app to Health Connect instead (all major vendor apps support it).

## Per-vendor integration table

| Brand | Primary path | Direct API (optional, adds precision) | Notes |
|---|---|---|---|
| Apple Watch | HealthKit (native, iOS) | — | Gold standard: background delivery, workouts, active/basal energy, HR |
| Samsung / Galaxy Watch | Health Connect (Samsung Health writes to HC) | — | HC covers it fully |
| Garmin | Vendor app → HC (Android) / HealthKit (iOS) | **Garmin Health API** — requires (free) developer-program approval; webhook push (Dailies, Activities, HR) | Apply for API access early — approval takes weeks |
| Polar | Vendor app → HC / HealthKit | **Polar AccessLink API** — open signup, OAuth2, webhooks for exercises + daily activity | Polar straps also pair directly via BLE (07) |
| Fitbit | Fitbit app → HC (Android) | **Fitbit Web API** — OAuth2; intraday HR needs Fitbit approval ("Personal" apps get own-account intraday immediately; production intraday requires request) | Google-owned; HC path improving but API still richer |
| Huawei / Honor | Huawei Health → HC (recent versions; region-dependent) | **Huawei Health Kit REST** via AppGallery Connect account | Prioritize HC path; direct API only if EU/CN user demand |
| Xiaomi / Redmi / Amazfit | Mi Fitness / Zepp app → HC | — (no practical public API) | HC-only |
| Anything else | Whatever writes to HC / HealthKit | — | Explicitly supported stance |

## What we read from hubs

- iOS HealthKit: `activeEnergyBurned`, `basalEnergyBurned`, `heartRate`, `stepCount`, `workouts`, `bodyMass`, `dietaryEnergyConsumed` (10). Anchored object queries + `enableBackgroundDelivery(.immediate)` for energy/HR.
- Android Health Connect: `ActiveCaloriesBurnedRecord`, `TotalCaloriesBurnedRecord`, `HeartRateRecord`, `StepsRecord`, `ExerciseSessionRecord`, `WeightRecord`, `NutritionRecord`. Poll via WorkManager every 15 min using **changes tokens** (differential sync); full re-read only on token expiry.

## Vendor OAuth (direct APIs) — all server-side

- Cloud Functions handle the OAuth dance; client opens a custom-tab to `https://<region>-<project>.cloudfunctions.net/connect/{vendor}` with Firebase Auth ID token; callback stores tokens in **Firestore `integrations/{uid}/{vendor}` encrypted via Cloud KMS** (never in the client, never in plaintext).
- Webhooks (Polar/Garmin/Fitbit subscriptions) hit Functions → normalize → write to `ingest/{uid}` queue → client pulls on FCM silent push. Function retries with exponential backoff; idempotent by `(vendor, payloadId)`.
- Token refresh in Functions on 401; broken integrations flag `status: reauth_needed` → amber dot on Home status strip.

## Normalization

Everything becomes one of two shapes in Drift:

```
MinuteBucket { minuteUtc, activeKcal, steps?, avgHr?, source, priority }
SessionRecord { externalId, source, sport?, startUtc, endUtc, activeKcal, avgHr?, maxHr?, raw? }
```

## Deduplication (the heart of "precise") — `core/energy/dedup.dart`

Per **minute bucket**, exactly one source wins. Priority (high→low):

1. `liveStrap` (07)
2. `liveWatchSession` (13/07)
3. `manualStrength` (08 — its kcal spread evenly across its minutes)
4. `vendorDirect` (Garmin/Polar/Fitbit/Huawei API)
5. `hub` (HealthKit/HC aggregate)
6. `phoneSensors` (steps-derived, only if literally nothing else)

Rules:
- Same priority, two sources (e.g. two watches wrote to HC): pick the source with higher `avgHr` sample density; tie → higher kcal is **not** the tiebreak (prevents inflation) — pick alphabetically stable source id and flag the day for the Sync Health screen.
- A session record claims its full minute range at its priority; minute-level leftovers from lower sources inside that range are discarded, not summed.
- Daily total = Σ winning buckets. Recompute idempotently on every ingest; if the total shrinks, emit recalibration event (06).
- Every bucket stores `provenance` so Sync Health can show "13:00–14:00 · Polar strap".

Worked test: hub says 300 kcal for 18:00–19:00; user also logged strength 18:00–19:00 with finalKcal 260 → day gets **260** for that hour (manual beats hub), not 560, not 300.

## Sync Health screen (Settings)

Per source: last sync time, records today, priority explainer, "re-sync now", disconnect. This screen is the answer to every "why is my number X?" support question.

## Acceptance criteria

- Dedup worked test passes; replaying the same vendor webhook twice changes nothing (idempotency).
- Disconnecting a vendor removes its future data but past days remain intact.
- HC changes-token flow: 15-min WorkManager cycle ingests new records with < 1 s CPU work (measured).
- Garmin/Polar/Fitbit sandbox accounts round-trip: activity done on watch → appears in Eter ≤ 20 min without opening the vendor app (webhook path).
