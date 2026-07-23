# Changelog

All notable changes to F1 Vision are documented here.
Format: [Keep a Changelog](https://keepachangelog.com) · Versioning: [SemVer](https://semver.org).

## [0.6.0] — 2026-07-23

### Added
- **Driver Comparison Studio** — head-to-head analysis of any two drivers:
  profile overview, season head-to-head bars, performance radar, championship
  progress, and (when a race is selected) lap-time, position, sector, speed,
  tyre-strategy, pit-stop and pace-vs-tyre-age panels. Composes the cached
  Analytics and Replay payloads, so switching drivers triggers no network I/O.
- **Offline caching with Isar** — a two-tier cache (memory → Isar) behind the
  existing `CacheStore` seam, so previously-viewed screens work with no
  connection. Requires a one-time `build_runner` step (see
  `docs/OFFLINE_CACHE.md`); falls back to in-memory automatically if it can't
  open.
- **Keyboard shortcuts** in the Replay Studio — space play/pause, ←/→ lap step,
  R restart, Home/End jump, 1–4 replay speed — with an on-screen legend.
- **App icon and splash screen** assets plus `flutter_launcher_icons` and
  `flutter_native_splash` configuration.
- Design tokens (`AppSpacing`, `AppDurations`) for consistent spacing, radii
  and motion.

### Changed
- `AnalyticsPanel` and `StudioPanel` now delegate to a single shared
  `DataPanel` in `core/widgets`, removing three near-identical implementations
  and guaranteeing identical spacing and typography everywhere.
- Settings gained an **Offline data** card showing cached-response count with a
  manual purge.

### Fixed
- Accessibility: panels and comparison rows expose semantic labels for screen
  readers.

## [0.5.0] — 2026-07-23

### Added
- **Race Replay & Strategy Simulator** *(signature feature)* — replay any
  completed Grand Prix (or Sprint) lap by lap, back to 1996. Includes:
  - Race selection by season / Grand Prix / session, with circuit, date,
    winner, pole and fastest-lap headers.
  - Transport controls: play, pause, restart, previous/next lap, 0.5×–5×
    speed and a jump-to-lap scrubber.
  - A horizontal **race timeline** of safety cars, VSC, flags, weather changes,
    fastest laps and retirements — tap any marker to jump.
  - An **animated leaderboard** where rows slide between positions (no list
    rebuilds), with live gaps, tyre compounds, pit and grid-delta indicators.
  - A **tyre-strategy timeline** of every driver's stints with per-stint
    duration and pit position deltas.
  - Interactive **position-history**, **lap-time / sector / delta** and
    **speed** analysis charts, plus a synchronized auto-scrolling **race feed**
    and a live **statistics** panel.
  - Three-column desktop layout, two-column tablet, and an adaptive mobile
    stack that preserves every capability.
- **Pluggable telemetry providers** — a `ReplayEnrichmentSource` seam (OpenF1
  implementation included) lets new data providers add tyre/sector/speed/event
  detail without any UI or model changes.

## [0.4.0] — 2026-07-04

### Added
- **Authentication** — e-mail/password sign-in & registration plus
  **Sign in with Google** (Firebase Auth). Includes a "Continue as guest"
  path, password reset, friendly error messages, and router redirects.
  Auth is *optional*: without a Firebase config the app runs exactly as before.
- **Light mode** — full light palette behind the same design system, with a
  Dark / Light / System selector. System follows the OS live; the choice is
  persisted with `shared_preferences`.
- **Settings screen** — appearance selector, account card (profile + sign
  out), and about section. Replaces the Coming-Soon placeholder.
- GitHub project files: `LICENSE` (MIT), `CONTRIBUTING.md`, `CHANGELOG.md`,
  full Flutter `.gitignore`, `docs/FIREBASE_SETUP.md`.

### Changed
- **Live Race** now detects whether a session is actually running. Outside a
  live session it presents "Race Result — latest classification": a clean
  ordered list of finishing positions (P1, P2, …) without the pulsing LIVE
  badge, gaps, DRS or tyre decorations, and it polls far less often.
- Router is now a Riverpod provider with auth-aware redirects.

### Fixed
- Bottom navigation labels disappearing when a tab was tapped — the theme now
  defines explicit selected/unselected label and icon styles for
  `NavigationBar` instead of relying on Material 3 defaults.

## [0.3.0] — 2026-07-03

### Added
- **Analytics Command Center** (flagship): 14 season panels (driver &
  constructor rankings, championship progress, team trends, fastest laps,
  poles, podiums, average finish, DNFs & reliability, race pace, pit stops,
  driver form, season stats, head-to-head radar) built from 9 reusable chart
  widgets (line/area with zoom & pan, horizontal bars, pie, donut, radar,
  scatter, sparklines, progress rings). Responsive 3→2→1-column masonry,
  shimmer/empty/error states, 90 s auto-refresh for the current season.
- Season-wide Jolpica feeds (paginated results, poles, status, pit stops) and
  an `AnalyticsRepository` aggregating them into one immutable payload.

## [0.2.0] — 2026-06-30

### Added
- **Telemetry Dashboard**: animated speed & RPM gauges, gear/DRS/throttle/
  brake status rail, three synchronized traces with crosshair + tooltips,
  viewport zoom/pan, driver selector, pause/restart, rolling-window streaming
  from OpenF1 `/car_data`.

## [0.1.0] — 2026-06-30

### Added
- Foundation: Clean Architecture, Riverpod, Dio client with retry/cache
  interceptors, `Result`/`Failure` error model, GoRouter adaptive shell
  (desktop rail / mobile bottom bar), dark design system.
- Home, Standings, and Live Race screens wired to OpenF1 + Jolpica.
