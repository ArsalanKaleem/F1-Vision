# Changelog

All notable changes to **F1 Vision** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- **Circuit Explorer** — interactive track maps, DRS zones, elevation profiles
  and speed traps
- Drivers and Teams detail pages
- Calendar with countdowns and circuit profiles
- Favourites synced per account

---

## [0.6.0] — 2026-07-23

The polish release: a second flagship analysis screen, real offline support,
and the finishing work that takes the project from "impressive demo" to
"shippable product".

### Added
- **Driver Comparison Studio** — head-to-head analysis of any two drivers.
  Profile overview, season head-to-head bars, normalised performance radar and
  championship progress; when a race is selected it adds lap-time, position,
  sector, speed, tyre-strategy, pit-stop and pace-vs-tyre-age panels. Composes
  the already-cached Analytics and Replay payloads, so switching drivers
  triggers no network I/O.
- **About screen** — developer profile over a theme-aware hero image with
  brand-tinted social buttons; Support section (Rate App, Report a Bug, Request
  a Feature, Privacy Policy, Terms & Conditions); Open Source section listing
  technologies, libraries with their licences and Flutter's full licence page;
  and a "Made with ❤️" footer. Every value is configured in one file,
  `lib/core/constants/app_info.dart`.
- **Navigation drawer** — all destinations grouped by section (Race Weekend,
  Analysis, Explore, App) with a brand header, active-route marker and a quick
  Dark / Light / Auto theme switch in the footer.
- **Offline caching with Isar** — a two-tier cache (memory L1 → Isar L2) behind
  the existing `CacheStore` seam, so previously-viewed screens work with no
  connection. Requires a one-time `build_runner` step; falls back to in-memory
  automatically when Isar can't open. See `docs/OFFLINE_CACHE.md`.
- **Keyboard shortcuts** in the Replay Studio — space play/pause, ←/→ lap step,
  R restart, Home/End jump, 1–4 replay speed — with an on-screen legend.
- **App icon and splash screen** assets, plus `flutter_launcher_icons` and
  `flutter_native_splash` configuration.
- Design tokens (`AppSpacing`, `AppDurations`) for consistent spacing, radii and
  motion across every screen.
- `docs/WINDOWS_BUILD.md` covering desktop build issues and auth limitations.

### Changed
- `AnalyticsPanel` and `StudioPanel` now delegate to a single shared `DataPanel`
  in `core/widgets`, removing three near-identical implementations and
  guaranteeing identical spacing and typography everywhere.
- Settings gained an **Offline data** card with cached-response count and a
  manual purge, plus an entry point to the new About screen.
- Mobile bottom bar reduced to four primary destinations; the drawer now covers
  everything else, replacing the earlier "More" sheet.

### Fixed
- **Windows builds failed under CMake 4** because the bundled Firebase C++ SDK
  still declared a pre-3.5 minimum. Upgraded to `firebase_core ^4.6.0` /
  `firebase_auth ^6.3.0`, which bundle C++ SDK 13.5.0 with the upstream fix.
- **Finish and retirement rates were wrong.** They were derived from the display
  status slices, which fold the long tail into "Other", so lapped-but-classified
  finishers ("+2 Laps", "+3 Laps", …) were counted as retirements. Rates now
  come from the full status table.
- **Analytics header overflowed on phones** — the overline text ran under the
  season selector. The header is now responsive, with controls wrapping to
  their own row on mobile.
- **Mobile navigation only exposed 5 of 12 destinations**, leaving Standings,
  Telemetry, Comparison and About unreachable on a phone.
- Type-inference error in `JolpicaService.raceResults` where a `dynamic`
  receiver produced a record field that clashed with the declared return type.
- Long circuit and session names could overflow the Live Race header.
- Accessibility: panels, comparison rows and navigation items expose semantic
  labels; the footer heart respects the OS reduce-motion setting.

---

## [0.5.0] — 2026-07-22

### Added
- **Race Replay & Strategy Simulator** *(signature feature)* — replay any
  completed Grand Prix or Sprint lap by lap, back to 1996:
  - Race selection by season / Grand Prix / session, with circuit, date,
    winner, pole and fastest-lap headers
  - Transport controls: play, pause, restart, previous/next lap, 0.5×–5× speed
    and a jump-to-lap scrubber
  - Horizontal **race timeline** of safety cars, VSC, flags, weather changes,
    fastest laps and retirements — tap any marker to jump
  - **Animated leaderboard** where rows slide between positions rather than
    rebuilding, with live gaps, tyre compounds, pit and grid-delta indicators
  - **Tyre-strategy timeline** with per-stint duration and pit position deltas
  - Interactive position-history, lap-time / sector / delta and speed analysis
    charts, a synchronised auto-scrolling race feed and a live statistics panel
  - Three-column desktop layout, two-column tablet, adaptive mobile stack
- **Pluggable telemetry providers** — a `ReplayEnrichmentSource` seam (OpenF1
  implementation included) lets new data providers contribute tyre, sector,
  speed and event detail without any UI or model changes.

---

## [0.4.0] — 2026-07-04

### Added
- **Authentication** — email/password sign-in and registration plus **Sign in
  with Google** (Firebase Auth), with guest mode, password reset, friendly
  error messages and router redirects. Entirely optional: without a Firebase
  config the app runs exactly as before.
- **Light mode** — a full light palette behind the same design system, with a
  Dark / Light / System selector. System follows the OS live; the choice is
  persisted with `shared_preferences`.
- **Settings screen** — appearance selector, account card and about section,
  replacing the placeholder.
- GitHub project files: `LICENSE` (MIT), `CONTRIBUTING.md`, `CHANGELOG.md`, a
  full Flutter `.gitignore`, and `docs/FIREBASE_SETUP.md`.

### Changed
- **Live Race** now detects whether a session is actually running. Outside a
  live session it presents "Race Result — latest classification": a clean
  ordered list of finishing positions without the pulsing badge, gaps, DRS or
  tyre decorations, and polls far less often.
- Router converted to a Riverpod provider with auth-aware redirects.

### Fixed
- Bottom navigation labels disappeared when a tab was tapped — the theme now
  defines explicit selected and unselected label and icon styles for
  `NavigationBar` instead of relying on Material 3 defaults.

---

## [0.3.0] — 2026-07-03

### Added
- **Analytics Command Center** *(flagship)* — 14 season panels built from 9
  reusable chart widgets:
  - Driver and constructor rankings, championship progress, team trends
  - Fastest laps, poles, podiums, average finish, DNFs and reliability
  - Race pace, pit stops, driver form and a head-to-head radar
  - Charts: animated line and area with zoom/pan, horizontal bars, pie, donut,
    radar, scatter, sparklines and progress rings
  - Responsive 3 → 2 → 1-column masonry, shimmer / empty / error states, and
    90-second auto-refresh for the current season
- Season-wide Jolpica feeds (paginated results, poles, status, pit stops) and an
  `AnalyticsRepository` aggregating them into one immutable payload.

---

## [0.2.0] — 2026-06-30

### Added
- **Telemetry Dashboard** — animated speed and RPM gauges, a
  gear / DRS / throttle / brake status rail, three synchronised traces sharing
  one crosshair with tooltips, viewport zoom and pan, a driver selector,
  pause/restart controls, and rolling-window streaming from OpenF1 `/car_data`.

---

## [0.1.0] — 2026-06-30

### Added
- Project foundation: Clean Architecture, Riverpod, a Dio client with retry and
  TTL-cache interceptors that honour `Retry-After`, a sealed `Result` / `Failure`
  error model, a GoRouter adaptive shell (desktop rail / mobile bottom bar) and
  the dark design system.
- Home, Standings and Live Race screens wired to OpenF1 and Jolpica.

---

[Unreleased]: https://github.com/ArsalanKaleem/F1-Vision/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.6.0
[0.5.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.5.0
[0.4.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.4.0
[0.3.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.3.0
[0.2.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.2.0
[0.1.0]: https://github.com/ArsalanKaleem/F1-Vision/releases/tag/v0.1.0
