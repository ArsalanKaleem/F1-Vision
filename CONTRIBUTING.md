# Contributing to F1 Vision

Thanks for taking the time to contribute. This guide covers how the codebase is
organised, how to add a feature without breaking its architecture, and the
workflow for getting a change merged.

Whether you're fixing a typo or building the Circuit Explorer, you're welcome
here.

---

## Table of contents

- [Code of conduct](#code-of-conduct)
- [Ways to contribute](#ways-to-contribute)
- [Development setup](#development-setup)
- [Architecture](#architecture)
- [Adding a feature](#adding-a-feature)
- [Design system rules](#design-system-rules)
- [Coding style](#coding-style)
- [Commits and pull requests](#commits-and-pull-requests)
- [Testing and verification](#testing-and-verification)
- [Releasing](#releasing)

---

## Code of conduct

Be decent to people. Assume good faith, critique code rather than authors, and
keep discussion focused on the work. Harassment of any kind isn't tolerated —
report it to <arsalanabbasi.here@gmail.com>.

---

## Ways to contribute

| | |
|---|---|
| 🐛 **Report a bug** | [Open an issue](https://github.com/ArsalanKaleem/F1-Vision/issues/new?labels=bug) with steps to reproduce, your platform, and `flutter doctor -v` output |
| 💡 **Request a feature** | [Open an issue](https://github.com/ArsalanKaleem/F1-Vision/issues/new?labels=enhancement) describing the problem it solves, not just the solution |
| 📝 **Improve docs** | README, guides in `docs/`, or code comments — always welcome |
| 🎨 **Polish the UI** | Spacing, motion, accessibility and empty states all count |
| 🚀 **Build a roadmap item** | Check the [roadmap](README.md#-roadmap) and comment on the issue first so we don't duplicate work |

---

## Development setup

```bash
git clone https://github.com/ArsalanKaleem/F1-Vision.git
cd F1-Vision

# This repo ships Dart source only — generate platform folders once.
flutter create . --project-name f1_vision \
  --platforms=android,ios,web,windows,macos,linux

flutter pub get

# Required: Isar's schema is generated code. Nothing compiles without this.
dart run build_runner build --delete-conflicting-outputs

flutter run
```

**Requirements:** Flutter 3.27+ (the code uses `Color.withValues`), Dart 3.3+.

Optional extras:

- **Authentication** — see [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md).
  The app runs fine without it.
- **Windows builds** — see [`docs/WINDOWS_BUILD.md`](docs/WINDOWS_BUILD.md).
- **Offline cache internals** — see [`docs/OFFLINE_CACHE.md`](docs/OFFLINE_CACHE.md).

> Regenerate `*.g.dart` any time you touch an `@collection` class. Generated
> files are git-ignored and must never be committed.

---

## Architecture

Data flows in one direction, through five layers:

```
models  →  services  →  repositories  →  providers  →  features (UI)
```

| Layer | Folder | Responsibility |
|---|---|---|
| Models | `lib/models/` | Immutable data classes and `fromJson` parsing |
| Services | `lib/repositories/services/` | Raw API access (OpenF1, Jolpica, Firebase) |
| Repositories | `lib/repositories/` | Compose services, aggregate, return `Result<T>` |
| Providers | `lib/providers/` | Riverpod state, polling and caching decisions |
| Features | `lib/features/<name>/` | Screens and feature-local widgets **only** |

Shared foundations live in `lib/core/` (theme, networking, errors, reusable
widgets, responsive helpers); routing lives in `lib/routes/`.

### The five rules

1. **UI never calls Dio or parses JSON.** Screens only watch providers.
2. **Repositories never throw across their boundary.** They return `Result<T>`
   (`Success` / `Err<Failure>`) via a `_guard` helper.
3. **No hard-coded colours or text styles.** Everything comes from `AppColors`
   and `AppTextStyles` — this is precisely what makes light mode work.
4. **Every screen handles loading, empty and error states.** No blank frames.
5. **Don't refactor completed features while adding a new one.** Keep diffs
   reviewable.

---

## Adding a feature

Worked example — building the **Drivers** page:

<details>
<summary><b>1. Model</b></summary>

Add `lib/models/driver_profile.dart` with a `fromJson` factory. Use the `Json.*`
helpers (`Json.asInt`, `asDouble`, `asString`, `asDate`) — the upstream APIs are
loosely typed and these coerce safely.
</details>

<details>
<summary><b>2. Endpoint + service method</b></summary>

Add the path to `lib/core/constants/api_constants.dart`, then a typed fetch
method on the right service. Choose a cache TTL deliberately:

- `defaultCacheTtl` (30s) — live or in-session data
- `historicalCacheTtl` (6h) — completed seasons and races, which never change

If the endpoint paginates (Jolpica caps `limit` at 100), loop with a page guard.
</details>

<details>
<summary><b>3. Repository</b></summary>

Expose it through an existing repository or add a new one, wrapped in `_guard`
so it returns `Result<T>`. Heavy aggregation belongs **here**, not in widgets —
compute once and pass an immutable payload down.
</details>

<details>
<summary><b>4. Provider</b></summary>

A `FutureProvider` (or `.family` when keyed by season/round). Add `_poll(ref,
interval)` only if the data genuinely changes while on screen. Register any new
repository in `lib/providers/core_providers.dart`.
</details>

<details>
<summary><b>5. Screen</b></summary>

Create `lib/features/drivers/drivers_screen.dart` plus
`lib/features/drivers/widgets/`. Reuse what exists: `DataPanel`, `GlassCard`,
`SectionHeader`, `SkeletonBox`, the analytics chart widgets, `AppSpacing`.

Handle all three states, and check the layout at mobile, tablet and desktop
widths using `context.isMobile` / `isTablet` / `isDesktop`.
</details>

<details>
<summary><b>6. Route and navigation</b></summary>

In `lib/routes/app_router.dart`, replace the feature's `ComingSoonScreen` block
with `_fade(s, const DriversScreen())`. The nav entry already exists in
`nav_destinations.dart` — confirm its `NavSection` is right so it lands in the
correct drawer group.

⚠️ `_primaryIndices` in `app_shell.dart` holds **positional** indices into
`appDestinations`. If you reorder or insert destinations, update it.
</details>

<details>
<summary><b>7. Docs</b></summary>

Move the feature from "Scaffolded" to "Fully built" in `README.md`, and add a
`CHANGELOG.md` entry under `[Unreleased]`.
</details>

---

## Design system rules

| Concern | Use | Never |
|---|---|---|
| Colour | `AppColors.*` | `Color(0xFF...)` in a feature |
| Type | `AppTextStyles.*` (+ `.copyWith`) | Raw `TextStyle(fontSize: …)` |
| Spacing | `AppSpacing.*` | Arbitrary magic numbers |
| Motion | `AppDurations.*` | Ad-hoc `Duration(milliseconds: 237)` |
| Team colours | `TeamPalette.of(constructorId)` | Hand-picked hex per team |

**Watch out:** `AppColors` surface and text members are **getters**, not
constants, because they swap with the theme. That means an expression using them
can't be `const`:

```dart
// ✗ won't compile
const Icon(Icons.info, color: AppColors.textSecondary)

// ✓
Icon(Icons.info, color: AppColors.textSecondary)
```

Accent colours (`accent`, `positive`, `negative`, tyre compounds) *are* `const`
and are safe inside const expressions.

---

## Coding style

- `flutter analyze` must be clean — the repo uses `flutter_lints`
- Format with `dart format .` before committing
- Prefer `const` constructors wherever the design system allows
- **Document the why, not the what.** Explain non-obvious decisions (a cache
  TTL, a fallback path, an API quirk); skip comments that restate the code
- Keep widgets small and private (`_LikeThis`) unless genuinely reusable — if
  it's reusable, it belongs in `core/widgets/`
- No `dynamic` in public signatures; cast explicitly at the boundary
- Watch for `num` from `.clamp()` flowing into a `double` parameter — add
  `.toDouble()`

---

## Commits and pull requests

Commits follow [Conventional Commits](https://www.conventionalcommits.org):

```
feat: add drivers grid with season form
fix: prevent analytics header overflow on phones
docs: document the Windows CMake workaround
refactor: extract shared DataPanel
perf: reduce rebuilds in the replay leaderboard
chore: bump fl_chart to 0.70
```

Branch names: `feature/<name>`, `fix/<name>`, `docs/<name>`.

Open a pull request against `main`, keep it focused on one concern, and link the
issue it closes.

### PR checklist

- [ ] `flutter analyze` passes with no new warnings
- [ ] `dart format .` applied
- [ ] Runs on at least one platform — say which in the PR description
- [ ] Loading / empty / error states handled for any new data
- [ ] No hard-coded colours; checked in **both** light and dark mode
- [ ] Checked at mobile, tablet and desktop widths
- [ ] `README.md` / `CHANGELOG.md` updated if the change is user-facing
- [ ] Screenshots or a short clip for any UI change

---

## Testing and verification

There is no widget-test suite yet — **contributions here are especially
welcome**, starting with the pure aggregation logic in
`AnalyticsRepository` and `ReplayRepository`, which is well-isolated and easy to
test.

Until then, verify manually:

```bash
flutter analyze
dart format --set-exit-if-changed .
flutter run -d chrome          # web
flutter run -d windows         # desktop layout + keyboard shortcuts
flutter run                    # phone
```

Worth exercising by hand:

- Toggle Dark / Light / Auto and confirm nothing loses contrast
- Enable airplane mode after browsing to confirm the Isar cache serves content
- Open several seasons quickly to confirm rate-limit handling degrades cleanly
- Pick a pre-2023 race in the Replay Studio: telemetry-dependent panels should
  explain themselves rather than render empty

---

## Releasing

1. Bump `version:` in `pubspec.yaml` (minor for features, patch for fixes)
2. Update the version string in `lib/core/constants/app_info.dart`
3. Move `[Unreleased]` entries into a dated section in `CHANGELOG.md`
4. Tag and push:
   ```bash
   git tag v0.7.0 && git push --tags
   ```
5. Draft a GitHub release using the changelog section as the body

---

<div align="center">
<sub>Questions? Open a <a href="https://github.com/ArsalanKaleem/F1-Vision/discussions">discussion</a> or reach out at <a href="mailto:arsalanabbasi.here@gmail.com">arsalanabbasi.here@gmail.com</a>.</sub>
</div>
