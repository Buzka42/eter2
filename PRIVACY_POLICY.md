# Eter privacy policy — pre-release draft

**Status:** internal draft. Do not publish until the product owner supplies the
legal entity/contact details, confirms the Firebase region and AI provider, and
the released application matches every statement below.

## What Eter stores

Eter may store profile details, journal entries, nutrition and activity logs,
sleep and recovery signals, weight history, selected symbolic settings, and
the guidance created from those inputs.

The local Drift database on the user's device is the source of truth. Raw
minute-level movement and heart-rate series remain device-local. If cloud
continuity is both available and explicitly allowed, eligible aggregates and
documents may be mirrored to the user's account. The application must describe
the exact cloud scope before that feature is enabled.

## AI processing

AI guidance is optional and disabled by default. General AI processing and
journal-prose processing are separate permissions. A user can mark any journal
entry **Keep local**, in which case the client excludes it before building AI
context.

The production policy must name the selected AI processor and its processing
region before release. AI requests must omit account identifiers, name and
full date of birth; age may be sent as an integer where needed for health
context. Application-provided processing must not log health payloads.

## Retention

- Raw imported movement buckets: 90 days on device.
- Raw live heart-rate series: 180 days on device; session aggregates remain.
- Other local records: until the user removes them or deletes local data.
- Cloud records: until account deletion, subject to any shorter operational
  retention documented at release.

## User choices and rights

Users can use the local Journal, deterministic symbolic calculations and
available local health features without AI or cloud continuity. The Sanctum
shows the current AI, journal-prose and cloud permissions and allows
revocation.

Eter can prepare a complete JSON snapshot of the local database plus CSV files
for movement and session records. The authenticated cloud export and complete
account-deletion Function must be available before cloud continuity is
released.

Depending on applicable law, users may request access, correction, portability,
restriction or deletion of personal data and may withdraw consent at any time.

## Age

Eter is currently for people aged 16 and over. The client blocks completion of
onboarding for a younger date of birth.

## Service providers

The release version may use Google Firebase for authentication, cloud storage,
messaging, crash reporting and server Functions, plus the AI processor named in
the final in-app policy. HealthKit and Health Connect data is read only after
the operating-system permission flow.

Eter does not use health data for advertising and must not include third-party
advertising or behavioral-tracking SDKs.

## Security and international processing

Network traffic uses TLS. Vendor OAuth tokens must be encrypted using Cloud KMS
and remain accessible only to server Functions. Firebase App Check is required
on production backend surfaces. The final policy must state the confirmed
storage and processing regions.

## Contact

Data controller/legal entity: **[TO BE PROVIDED BEFORE RELEASE]**

Privacy contact email: **[TO BE PROVIDED BEFORE RELEASE]**

Postal address: **[TO BE PROVIDED BEFORE RELEASE]**
