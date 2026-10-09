# آية — Ayah

**One Ayah. Every Day. Until You Memorize the Quran.**

A calm, ADHD-friendly Quran memorization app: one tiny task a day, active recall instead of
re-reading, gentle spaced review, and no punishment for forgetting or missing days.

## Run it

```bash
flutter create . --org com.yourcompany --project-name ayah --platforms android,ios
rm test/widget_test.dart          # generated counter test, not used
flutter pub get
flutter test
flutter run
```

Then apply the manifest / Info.plist snippets in [`docs/PLATFORM_SETUP.md`](docs/PLATFORM_SETUP.md)
(notifications + offline audio cache).

The first session needs internet once to download the surah's text (verified Uthmani text from
Tanzil via AlQuran Cloud) and audio. After that, memorization and review work offline.

## The core loop

```
Home ── "ابدأ الحفظ" ──▶ Listen ──▶ Repeat ×3 ──▶ Recall (ayah hidden)
                                       ▲               │ remembered ──▶ ما شاء الله ✓
                                       └── "لا بأس" ◀──┘ forgot / another try
Next day ──▶ Review: recall hidden → reveal → Easy / Okay / Hard / I forgot ──▶ rescheduled
```

## Where things are

- Architecture, domain models, navigation, design system, MVP status: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Spaced repetition: `lib/features/review/domain/services/review_scheduler.dart`
- Daily ayah selection: `lib/features/memorization/domain/services/memorization_path.dart`
- Missed-days policy: `lib/features/review/domain/services/review_queue_policy.dart`
- All copy (Arabic + English): `lib/core/l10n/app_strings.dart`
- Swappable infrastructure (audio, notifications, storage): `lib/core/services/`
- Composition root: `lib/app/di.dart`

## Tests

`flutter test` covers the scheduler, queue policy (missed days / caps), daily verse selection,
session state machine, use cases against real repositories over an in-memory store, Quran data
caching and validation, preferences + reminders, and the Home / Memorization / Review cubits.
Tests never contain Quran text — only Latin placeholders.

## Get an APK without installing Flutter

Push this folder to a GitHub repo. The workflow in `.github/workflows/build-apk.yml` builds a
release APK on every push to `main` (or run it manually from the **Actions** tab → *Build APK* →
*Run workflow*). When it finishes, download **ayah-apk** from the run's *Artifacts* section,
unzip it, and install `app-release.apk` on your phone (allow "install unknown apps").
