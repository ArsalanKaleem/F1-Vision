# Changelog

All notable changes to F1 Vision are documented here. Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased](https://github.com/%3Cowner%3E/f1-vision/compare/v0.4.0...HEAD)

### Planned

* Drivers grid + per-driver detail pages
* Teams / constructor cards with pit-stop analytics
* Calendar with live countdown and circuit detail pages
* Head-to-head driver comparison (radar + sector/pace deltas)

## [0.4.0](https://github.com/%3Cowner%3E/f1-vision/compare/v0.3.0...v0.4.0) — 2026-07-04

### Added

* **Authentication** — e-mail/password sign-in & registration plus **Sign in with Google** (Firebase Auth). Includes a "Continue as guest" path, password reset, friendly error messages, and router redirects. Auth is *optional*: without a Firebase config the app runs exactly as before.
* **Light mode** — full light palette behind the same design system, with a Dark / Light / System selector. System follows the OS live; the choice is persisted with `shared_preferences`.
* **Settings screen** — appearance selector, account card (profile + sign out), and about section. Replaces the Coming-Soon placeholder.
* GitHub project files: `LICENSE` (MIT), `CONTRIBUTING.md`, `CHANGELOG.md`, full Flutter `.gitignore`, `docs/FIREBASE_SETUP.md`.

### Changed

* **Live Race** now detects whether a session is actually running. Outside a live session it presents "Race Result — latest classification": a clean ordered list of finishing positions (P1, P2, …) without the pulsing LIVE badge, gaps, DRS or tyre decorations, and it polls far less often.
* Router is now a Riverpod provider with auth-aware redirects.

### Fixed

* Bottom navigation labels disappearing when a tab was tapped — the theme now defines explicit selected/unselected label and icon styles for `NavigationBar` instead of relying on Material 3 defaults.

## [0.3.0](https://github.com/%3Cowner%3E/f1-vision/compare/v0.2.0...v0.3.0) — 2026-07-03

### Added

* **Analytics Command Center** (flagship): 14 season panels (driver & constructor rankings, championship progress, team trends, fastest laps, poles, podiums, average finish, DNFs & reliability, race pace, pit stops, driver form, season stats, head-to-head radar) built from 9 reusable chart widgets (line/area with zoom & pan, horizontal bars, pie, donut, radar, scatter, sparklines, progress rings). Responsive 3→2→1-column masonry, shimmer/empty/error states, 90 s auto-refresh for the current season.
* Season-wide Jolpica feeds (paginated results, poles, status, pit stops) and an `AnalyticsRepository` aggregating them into one immutable payload.

## [0.2.0](https://github.com/%3Cowner%3E/f1-vision/compare/v0.1.0...v0.2.0) — 2026-06-30

### Added

* **Telemetry Dashboard**: animated speed & RPM gauges, gear/DRS/throttle/ brake status rail, three synchronized traces with crosshair + tooltips, viewport zoom/pan, driver selector, pause/restart, rolling-window streaming from OpenF1 `/car_data`.

## [0.1.0](https://github.com/%3Cowner%3E/f1-vision/releases/tag/v0.1.0) — 2026-06-30

### Added

* Foundation: Clean Architecture, Riverpod, Dio client with retry/cache interceptors, `Result`/`Failure` error model, GoRouter adaptive shell (desktop rail / mobile bottom bar), dark design system.
* Home, Standings, and Live Race screens wired to OpenF1 + Jolpica.
