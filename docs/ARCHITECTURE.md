# Ayah — آية · Architecture

> One Ayah. Every Day. Until You Memorize the Quran.

## 1. Product analysis → engineering constraints

| Product requirement | Engineering consequence |
|---|---|
| Tiny daily task (1 ayah, 3–5 min) | `DailyPlan` = `goal − memorizedToday`. Missed days never accumulate *new* ayahs. |
| Active recall, not re-reading | `MemorizationSession` state machine forces Listen → Repeat → **hidden** Recall. |
| No punishment | `RecallOutcome.forgot` loops back to Listen; it never ends a session or resets history. No "wrong" string exists in `AppStrings`. |
| Spaced repetition, replaceable | `ReviewScheduler` interface; `LadderReviewScheduler` default, fully configurable via `ReviewSchedulerConfig`. |
| Returning after a break must feel easy | `ReviewQueuePolicy` caps daily reviews (default 10), weakest-first; "Welcome back" via `ActivityStats`. "Days of memorizing" is a total that **never resets**. |
| Offline core | All progress is local (`LocalStore`); Quran text cached per surah after first fetch; audio cached on first play. |
| Never invent Quran text | No Quran text in code or tests. Text comes from Tanzil (via AlQuran Cloud), validated (ayah count must match metadata) before caching. Tests use Latin placeholders. |
| Swap packages later | Audio, notifications, storage, speech evaluation are all behind interfaces in `core/services` or domain. DI is the only place that names concrete classes. |

## 2. Layers

```
Widget ──▶ Cubit ──▶ UseCase ──▶ Repository (interface) ◀── RepositoryImpl ──▶ DataSource ──▶ Hive / HTTP
                         └──▶ Domain services (pure): ReviewScheduler, ReviewQueuePolicy,
                                                      MemorizationPath, ActivityStats,
                                                      MemorizationSession (state machine)
```

Rules enforced by structure:
- Cubits receive **only use cases** in their constructors.
- Widgets contain no business logic — they render state and call cubit methods.
- Domain has no Flutter imports (only `equatable`). Every rule worth testing is a pure function or pure class.
- JSON mapping lives in `data/models/*_mappers.dart`, never in entities.

## 3. Folder structure

```
lib/
  main.dart                     # bootstrap: DI → load prefs → runApp
  app/                          # composition root
    ayah_app.dart               # MaterialApp, theme, locale, RTL
    app_cubit.dart              # app-wide preferences (locale, onboarding flag)
    di.dart                     # get_it registrations — the ONLY place naming impls
    router.dart                 # named routes + per-route BlocProvider
  core/
    constants/                  # AppConstants, QuranSourceConstants, ReminderCopy
    errors/                     # Failure (sealed), data exceptions
    extensions/                 # DateTime helpers (DST-safe day math)
    utils/                      # Clock, Result<T>
    services/
      audio/                    # AudioPlayerService + just_audio impl
      notifications/            # ReminderService + flutter_local_notifications impl
      storage/                  # LocalStore + Hive impl + in-memory impl
    theme/                      # tokens, AppTheme (light/dark), QuranTypography
    l10n/                       # AppStrings (ar/en), no codegen
    widgets/                    # CalmPage, VerseCard, AudioControls, StepIndicator, …
  features/
    quran/        data/ domain/ presentation/   # content + audio use cases
    onboarding/   data/ domain/ presentation/   # preferences, reminders, settings
    home/                       presentation/   # composes other features' use cases
    memorization/       domain/ presentation/   # session, path, evaluator, chain model
    review/             domain/ presentation/   # scheduler, queue policy
    progress/     data/ domain/ presentation/   # verse/daily progress, surah progress
test/
  helpers/                      # fakes + TestEnv (real use cases over in-memory store)
  features/…                    # unit + use case + cubit tests
```

`home` and `memorization` have no `data/` layer by design: they own no storage — they compose
repositories owned by `quran`, `progress` and `onboarding`.

## 4. Domain models

| Entity | Purpose |
|---|---|
| `VerseKey` | `surah:ayah` value object; stable key across storage/review. `nextInSurah` for chain mode. |
| `Verse` | key, surahName, globalNumber (1..6236), arabicText, audioUrl. |
| `Surah` | id, Arabic + transliterated name, ayahCount (static metadata, verified = 6236). |
| `UserPreferences` | dailyGoal, preferredTime, startingPoint (+surah), reminder on/time, locale, onboarding flag. |
| `VerseProgress` | status, stage, repetitionCount, lapses, confidence, difficulty, memorizedAt, lastReviewedAt, nextReviewAt. |
| `ReviewSchedule` / `ReviewSchedulerConfig` / `ReviewRating` | scheduler output, tunables, `forgot/hard/good/easy`. |
| `ReviewItem` / `ReviewQueue` | verse + progress; today's capped queue with `totalDue`, `deferredCount`, `isReturningAfterBreak`. |
| `MemorizationSession` | immutable state machine (listen/repeat/recall/completed) + `MemorizationSessionRecord` for history. |
| `DailyPlan` | today's remaining ayahs, goal, `isQuranComplete`. |
| `DailyProgress` / `UserProgressSummary` | per-day activity; Home's three numbers. |
| `SurahProgress` / `SurahProgressDetail` | memorized / needs review / not started; per-ayah states. |
| `ChainSegment` / `ChainLink` | contiguous run of ayahs and the transitions to test (P1 Chain mode). |
| `RecitationEvaluator` | `SelfAssessmentEvaluator` today; speech/Quran-specific evaluators later. |

## 5. Spaced repetition (default `LadderReviewScheduler`)

Ladder (days): `1, 3, 7, 14, 30, 60, 120`. A fresh ayah sits at stage 0 and is due tomorrow.

| Rating | Stage change | Fresh ayah → |
|---|---|---|
| forgot | → 0, `lapses+1`, confidence 0 | again in 10 min (and once more at end of the session) |
| hard | −1 (min 0) | 1 day |
| good ("Okay") | +1 | 3 days |
| easy | +2 | 7 days |

Consistent success then walks 14 → 30 → 60 → 120 days. Day intervals are normalized to local
midnight and computed by calendar days (DST-safe). Status: `learning` (stage < 2) → `reviewing`
→ `mastered` (interval ≥ 30 days). Every number is in `ReviewSchedulerConfig`; swapping in
SM-2/FSRS means implementing `ReviewScheduler` and changing one DI line.

**Daily queue** (`ReviewQueuePolicy`): due items sorted weakest-first then most-overdue, capped at
`maxDailyReviews − reviewedToday`. A 50-ayah backlog drains 10/day — never dumped at once.

## 6. Navigation

Named routes (no leading `/` — avoids Flutter stacking `/` under the initial route).
Each route creates its cubit with `BlocProvider`, so lifetime = screen lifetime.

```
onboarding ──(finish)──▶ home
home ──▶ memorize [MemorizeArgs(extraVerse)] ──(pop)──▶ home.refresh()
home ──▶ review                               ──(pop)──▶ home.refresh()
home ──▶ progress ──▶ surah [id] ──▶ review [ReviewArgs(surahTestId)]   (Full Surah Test)
home ──▶ settings
```

Initial route is decided before the first frame (prefs loaded in `main`) — no splash flicker.
Moving to go_router later only touches `router.dart`.

## 7. Design system

- **Tokens** (`core/theme/app_tokens.dart`): 4-pt spacing, radii, durations, palette. Durations go
  through `AppDurations.of(context, …)` which returns zero under OS "reduce motion".
- **Palette**: warm paper + ink with deep green primary; dark mode is low-glare (`#101513`).
  Semantic extras (`quranInk`, `inkMuted`, `surfaceMuted`, `accent`, `divider`) via `AyahColors`
  `ThemeExtension`.
- **Typography**: UI in IBM Plex Sans Arabic; Quran in Amiri Quran (fallback Amiri), line-height
  2.1, size scaled to width (26–40) and then by the OS text scale. Quran text is always RTL,
  even in the English UI, and carries a semantics label ("Surah X, Ayah N").
- **Components**: `CalmPage` (one scrollable body + one pinned primary action, max width 560),
  `VerseCard` (shown / hidden-with-hints), `AudioControls`, `StepIndicator` (labels + check icons),
  `RepetitionDots`, `ChoiceTile`, `SupportiveMessage`, `FailureView`.
- **Accessibility**: 48dp+ targets, state never by color alone (icons + text), live regions on
  instructions, `Semantics(selected/header)`, dynamic type respected everywhere.

## 8. MVP plan & status

| # | P0 item | Status |
|---|---|---|
| 1 | Onboarding (4 steps + language toggle) | ✅ |
| 2 | Home (one primary action, quiet summary, welcome back) | ✅ |
| 3 | Quran data abstraction (repo, local cache, remote, metadata) | ✅ |
| 4 | Daily ayah selection (paths, goal, extra ayah) | ✅ |
| 5 | Audio abstraction (play/pause/replay/slow, offline cache) | ✅ |
| 6–7 | Memorization + recall flow, "I forgot" experience | ✅ |
| 8 | Local progress (Hive behind `LocalStore`) | ✅ |
| 9 | Review system (scheduler, capped queue, review screen) | ✅ |
| 10 | Notifications (rotating supportive copy, configurable time) | ✅ |
| P1 | Surah progress screen | ✅ (basic) |
| P1 | Full Surah test | ✅ (reuses review flow) |
| P1 | Chain mode | Domain model only (`ChainSegment`) |
| P1 | Better recitation evaluation | Interface ready (`RecitationEvaluator`) |
| P2 | AI, family mode, cloud sync, analytics | Not started. Sync = decorator around `ProgressRepositoryImpl`; session records are already stored. |

## 9. Decisions worth knowing

- **Hive with JSON strings, not adapters** → zero build_runner; engine swappable behind `LocalStore`.
- **Hand-written `AppStrings`** instead of gen-l10n → no codegen, compile-time-checked copy, plurals done properly for Arabic (1 / 2 / 3–10 / 11+).
- **Named routes over go_router** → one fewer dependency for 7 screens; isolated in `router.dart`.
- **`Result<T>` + sealed `Failure`** → use cases never throw into the UI; UI maps failures to kind copy.
- **Clock injected everywhere** → missed days, DST, and schedules are deterministic in tests.
- **Weekly-rotating reminders** (7 notifications, `dayOfWeekAndTime`) → varied copy without background work; inexact scheduling so no exact-alarm permission.
- **Basmala stripping** → the text source prefixes ayah 1 with the basmala; it is removed (except Al-Fatihah and At-Tawbah) after normalized comparison, before caching.
- **Incomplete surah never cached** → ayah count must match metadata.

## 10. Known follow-ups before store release

1. Bundle a verified Tanzil text asset so the first launch is fully offline (add an asset data source in front of the cache; no other layer changes).
2. Bundle fonts (`Amiri Quran`, `IBM Plex Sans Arabic`) and set `GoogleFonts.config.allowRuntimeFetching = false`.
3. Choose reciter(s) and confirm audio licensing; reciter is a single constant today.
4. Widget/golden tests per screen (font loading must be stubbed first).
5. Crash reporting + privacy-respecting analytics (P2).
