# 14 · Data Models — Drift (local) & Firestore (cloud)

Principle: **raw signals stay on device; the cloud holds aggregates and documents the user would expect to survive a phone swap.** HR sample streams never leave the device except as session-level aggregates + optional downsampled sparklines.

## Drift (SQLite) — source of truth

```sql
-- per-minute deduped energy (11)
minute_buckets(minute_utc PK, active_kcal REAL, steps INT?, avg_hr REAL?,
               winning_source TEXT, provenance TEXT)
-- raw ingest before dedup (ring buffer, 90 d retention)
raw_buckets(id PK, minute_utc, active_kcal, source, priority, external_id, UNIQUE(source, minute_utc))
hr_samples(session_id, ts, bpm, rr_ms?)          -- live sessions only; 180 d retention
sessions(id PK, type, sport?, start_utc, end_utc, kcal, avg_hr?, max_hr?,
         source, external_id?, alt_series_ref?, synced_at?)
strength_workouts(id PK, started_at, ended_at, body_weight_kg, json_exercises,
                  ai_kcal?, ai_ci_low?, ai_ci_high?, ai_model?, prompt_version?,
                  fallback_kcal, final_kcal, method, synced_at?)
weight_entries(id PK, ts, kg, source)
meals(id PK, ts, slot, name?, kcal, protein_g?, carbs_g?, fat_g?, source, barcode?, synced_at?)
sport_stats(sport PK, tag_count, last_tagged, median_start_min_weekday, median_start_min_weekend, median_duration_min)
day_summaries(date PK, active_kcal, basal_kcal, intake_kcal?, steps, sessions_count,
              milestones_fired, last_milestone_index, recalibrated BOOL)
integrations(vendor PK, status, last_sync, changes_token?)
ai_cache(payload_hash PK, estimate_json, created_at)
```

## Firestore — synced aggregates

```
users/{uid}
  profile: { dobMonthDay, birthYear, zodiac, arcana, element, sex?, heightCm?,
             currentWeightKg, rmrKcal, units, createdAt }
  settings: { milestoneStepKcal, flashEnabled, flashDuringSessions, hapticsEnabled,
              pulseMultiplier, activeGoalKcal, aiProvider, aiConsentAt?, nutritionMode,
              theme, calmMode }
users/{uid}/days/{yyyy-MM-dd}
  { activeKcal, basalKcal, intakeKcal?, netKcal?, steps, sessionsCount,
    milestonesFired, updatedAt }                     // aggregates only
users/{uid}/sessions/{id}
  { type, sport, startUtc, endUtc, kcal, avgHr, maxHr, source,
    sparkline: number[60]?,                           // downsampled, optional (privacy toggle)
    updatedAt }
users/{uid}/workouts/{id}     // strength: full structure (user expects it to survive device swap)
  { startedAt, endedAt, exercises: [...], bodyWeightKg, estimate {...}, updatedAt }
users/{uid}/meals/{id}        // only when nutritionMode == full
users/{uid}/weights/{id}      { ts, kg, source }
integrations/{uid}/vendors/{vendor}   // written ONLY by Cloud Functions
  { status, scopes, lastSync, encTokens (KMS-encrypted blob) }
ingest/{uid}/queue/{id}       // Functions → client handoff, TTL 7 d
```

## Firestore security rules (sketch — implement fully)

```
match /users/{uid}/{document=**} { allow read, write: if request.auth.uid == uid; }
match /integrations/{uid}/{document=**} {
  allow read: if request.auth.uid == uid;
  allow write: if false;                    // Functions only (Admin SDK)
}
match /ingest/{uid}/{document=**} { allow read, delete: if request.auth.uid == uid; allow write: if false; }
```
Plus App Check enforced on Firestore + Functions.

## Sync engine rules

- Push: Drift rows with `synced_at NULL`, debounced 5 s, batched ≤ 400 writes.
- Pull: on start + FCM silent push; last-write-wins on `updatedAt` per doc.
- Day summaries recompute locally from buckets, then upsert — Firestore day docs are never the calculation source, only a mirror (prevents cloud/local drift).
- Sign-in on new device: pull profile/settings/days/workouts/sessions/meals/weights; minute-level history does not restore (by design — state this in a "what syncs" Settings note).
- Account deletion: Function `gdpr/delete` wipes user tree + integrations + revokes vendor tokens (16).

## Retention

- `raw_buckets` 90 d, `hr_samples` 180 d (local pruning job, nightly). Firestore aggregates: indefinite until deletion. Export: Function `gdpr/export` bundles Firestore tree as JSON + tells user local raw data exports from Settings → Export (CSV of buckets/sessions).

## Acceptance criteria

- Fresh-install sign-in restores profile, settings, all workouts/sessions/meals/weights and day aggregates; Home renders historical days from day docs.
- Security rules tests (emulator): cross-uid read/write denied; client write to integrations denied.
- Nightly prune removes 91-day-old raw rows; day summaries unaffected.
- Airplane-mode week: everything functions locally; reconnect syncs all queued docs without duplicates.
