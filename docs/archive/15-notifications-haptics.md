# 15 · Notifications, Haptics & the Milestone Flash

The milestone moment is Eter's signature feedback: **vibration + bright white screen flash tinted with the user's element color + Cloud burst.** It must feel magical and be strictly safe.

## Milestone trigger (from 06)

Every `milestoneStepKcal` active kcal (default 100; options 50/100/150/200/off). Fired once per crossing per day (persisted index), only while total is rising.

## Haptic pattern — "the breath"

| Platform | Implementation |
|---|---|
| iOS | Core Haptics `CHHapticPattern`: transient 0.40 intensity at 0 ms → transient 0.65 at 120 ms → continuous 0.9 intensity, 0.5 sharpness, 90 ms at 260 ms |
| Android | `VibrationEffect.createWaveform(timings=[0,40,80,60,120,90], amplitudes=[0,90,0,150,0,230], repeat=-1)` |

Rationale: two soft taps then a firm swell — an inhale/exhale, not an alarm. In-session (07) the same pattern at 70% amplitude. Expose in code as `EterHaptics.milestone()`, plus `light()` (chip taps 20 ms/60 amp) and `restDone()` (two 40 ms taps).

## Screen flash — exact sequence (total 900 ms)

Full-screen overlay above all UI (`flash.frag` or plain animated container):

| t (ms) | State |
|---|---|
| 0 → 90 | `mist0` white, opacity 0 → 92%, `easeAir` |
| 90 → 150 | hold white 92% |
| 150 → 380 | cross-fade white → user's element color at 45% opacity |
| 380 → 900 | fade to 0, during which 24 gold particles from the Cloud burst drift through the overlay |

Optional "true brightness" mode (off by default): raise system brightness to max for the 900 ms and restore precisely (`screen_brightness` package); skip if battery saver on.

## Safety rules (hard requirements, not settings)

1. **Never more than a single flash event per 60 s** — if milestones stack (big sync import), fire haptic per milestone but flash once, and skip flash entirely for retroactive/imported crossings (only real-time crossings flash).
2. No strobing ever: one rise-fall per event; nothing in the app may flash > 3 times/second (photosensitive epilepsy guideline, WCAG 2.3.1).
3. First-run flash education card with an explicit "Enable screen flash?" choice; independent toggles: flash / haptics / flash-during-sessions (default off, 07).
4. Respect OS reduce-motion → flash becomes a 500 ms soft glow at 25% opacity (still distinguishable, never disorienting), and Calm Mode disables flash outright.

## Notification catalog (all optional, granular toggles, quiet hours 22:00–08:00 default)

| Id | Trigger | Copy (tone: airy, brief, zero guilt) |
|---|---|---|
| `untagged_evening` | 20:30 if untagged blocks (09) | "2 efforts today await their card 🃏" |
| `goal_reached` | active goal hit | "Your cloud is full — {goal} kcal of pure motion ☁️" |
| `streak_gentle` | 3+ goal days, fires at first goal-hit of next day | "Third day riding the wind." |
| `sync_stale` | source silent > 48 h | "{Source} hasn't spoken in two days — reconnect?" |
| `weekly_card` | Sunday 18:00 | "Your week under {Arcana} is ready" → weekly summary |

Local notifications where possible; FCM only for webhook-driven freshness (11). No marketing pushes in v1. Android: channels per id; iOS: provisional auth first, full prompt after first milestone (better opt-in rates).

## Acceptance criteria

- Milestone at rest: haptic + flash + burst within 500 ms of the crossing computation; sequence timings match table ±10 ms (widget test with fake clock).
- Import of a day with 6 milestones → 1 flash max, haptics coalesced to ≤ 2 s total.
- Reduce-motion device: glow variant verified; brightness always restored (test kill-app mid-flash → brightness restored on next launch).
- Quiet hours suppress notifications but never suppress in-app milestone feedback.
