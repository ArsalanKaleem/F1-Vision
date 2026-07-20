# 🏎️ F1 Vision

**A cinematic, real-time Formula 1 companion app built with Flutter.**

F1 Vision turns live and historical Formula 1 data into a Bloomberg-terminal-style command center — animated telemetry gauges, a race-control-style live leaderboard, championship standings, and a multi-panel analytics dashboard — all wrapped in a dark-mode-first, F1-broadcast-inspired design system that adapts fluidly from desktop to mobile.

> Built as a data-visualization-heavy showcase app: strongly-typed API clients, a clean repository/provider architecture, TTL caching, graceful degradation when services are unavailable, and a UI layer designed to feel like it belongs on a race broadcast.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Screens & Navigation](#screens--navigation)
- [Architecture](#architecture)
- [Data Sources](#data-sources)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Design System](#design-system)
- [Error Handling & Resilience](#error-handling--resilience)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

F1 Vision is a cross-platform Flutter application (mobile, web, and desktop) that presents Formula 1 data — live session telemetry, race leaderboards, driver/constructor standings, and season-wide analytics — through a highly polished, animated interface. The app is designed around two complementary data sources: **OpenF1** for live and recent telemetry/timing, and **Jolpica** (an Ergast-compatible API) for historical results and standings.

The project emphasizes:

- **A flagship telemetry cockpit** with live gauges and synchronized speed/RPM/pedal traces.
- **A race-control-style live leaderboard** where position changes animate smoothly instead of jumping.
- **A "Bloomberg terminal" analytics command center** built from season-wide historical aggregates, with charts, rankings, and championship-form panels.
- **Optional Firebase authentication** (email/password + Google Sign-In) that gracefully degrades to a fully functional guest experience when Firebase isn't configured.
- **A single, disciplined design system** — one color palette, one typography scale, one set of reusable "glass card" surfaces — reused across every screen.

---

## Key Features

### 🏠 Dashboard (Home)

A landing overview of the current or most recent session: session status, live leaderboard preview, and current track weather, styled like a broadcast graphics package.

### 📡 Live Race

A race-control-style leaderboard for live or recent sessions. Rows are absolutely positioned by classification, so when the running order changes between polls, cars **slide** smoothly into their new slot rather than snapping — mirroring how professional timing screens behave.

### 📊 Telemetry

The flagship screen: animated speed/RPM/throttle/brake gauges, an engineer-style cursor read-out, and synchronized channel charts streamed from OpenF1's `car_data` endpoint. Includes a driver selector and a viewport navigator for scrubbing through a lap or stint. The two-column desktop "cockpit" layout collapses into a single scrolling column on mobile.

### 🏆 Standings

Driver and Constructor championship standings in a tabbed view, with cards that animate in on load and points that count up rather than simply appearing.

### 📈 Analytics Command Center

A multi-panel, terminal-style dashboard built entirely from Jolpica historical data for a selected season, including:

- **Overview panels** — headline season metrics with progress rings.
- **Championship panels** — points progression over the season via line charts.
- **Ranking panels** — driver/constructor rankings via donut and horizontal bar charts.
- **Distribution panels** — result distributions and correlations via donut charts and scatter plots.
- **Form panels** — recent-form sparklines and radar comparison charts.
- **Tally panels** — win/podium/pole tallies via horizontal bar charts.

The current season's data refreshes on a short cache TTL; completed seasons are cached for hours since their data is immutable.

### 🔐 Authentication (optional)

Email/password and Google Sign-In via Firebase Auth, with a **Continue as Guest** path. If no Firebase configuration is present on the target platform, the app detects this at startup and simply runs without an auth layer — no crashes, no blocking dialogs.

### 🎨 Theming

A dark-mode-first theme (the app's signature look) with a full light-mode palette behind the same API, plus a **System** option that follows the OS and updates live. Preferences persist via `shared_preferences`.

### 🚧 Coming Soon (scaffolded)

Several routes ship with a polished "Coming Soon" placeholder screen that previews the intended feature set, so the navigation and information architecture are already in place for:

- **Drivers** — driver cards with headshots, nationality, points, wins, podiums, and animated ranking changes.
- **Teams** — constructor cards with logos, points, average pit-stop time, and a season performance graph.
- **Calendar** — season schedule, live countdown to the next session, and circuit detail pages.
- **Compare Drivers** — head-to-head comparison via radar charts and sector/pace deltas.

---

## Screens & Navigation

Navigation is driven by a single source of truth (`nav_destinations.dart`) shared between a desktop side rail and a mobile bottom bar, so both stay perfectly in sync:


| Route                 | Screen                   | Status                    |
| --------------------- | ------------------------ | ------------------------- |
| `/`                   | Dashboard                | ✅ Implemented            |
| `/live`               | Live Race                | ✅ Implemented            |
| `/drivers`            | Drivers                  | 🚧 Coming Soon            |
| `/teams`              | Teams                    | 🚧 Coming Soon            |
| `/standings`          | Standings                | ✅ Implemented            |
| `/calendar`           | Calendar                 | 🚧 Coming Soon            |
| `/telemetry`          | Telemetry                | ✅ Implemented            |
| `/analytics`          | Analytics Command Center | ✅ Implemented            |
| `/compare`            | Compare Drivers          | 🚧 Coming Soon            |
| `/settings`           | Settings                 | ✅ Implemented            |
| `/login`, `/register` | Auth                     | ✅ Implemented (optional) |

Routing uses **GoRouter** with a `ShellRoute` that keeps the navigation chrome (`AppShell`) mounted while inner pages transition with a shared fade-through animation. An auth-aware `redirect` guards protected routes — but only when Firebase has actually initialized successfully; otherwise the redirect logic is a no-op and every route is open.

---

## Architecture

F1 Vision follows a **layered, repository-based architecture** built on Riverpod for dependency injection and state management:

```
UI (Screens / Widgets)
        │  watches
        ▼
Providers (Riverpod)
        │  reads
        ▼
Repositories (domain-facing, return Result<T>)
        │  calls
        ▼
Services (typed API clients: OpenF1Service, JolpicaService)
        │  uses
        ▼
DioClient (HTTP + retry + TTL cache + error translation)
        │
        ▼
   OpenF1 API / Jolpica API
```

**Key architectural decisions:**

- **One `DioClient` per upstream API** (OpenF1 and Jolpica), each with its own base URL, timeouts, retry interceptor, and shared `CacheStore`.
- **A `Result<T>` type** at the repository boundary, so the UI layer never has to catch exceptions directly — it pattern-matches on success/failure.
- **A typed `AppException` → `Failure` hierarchy** (`TimeoutException`, `NetworkException`, `RateLimitException`, `ServerException`, `ParseException`, `AuthFailure`, etc.) that maps cleanly from low-level Dio errors to UI-safe failure messages.
- **TTL-based response caching**, with short TTLs for live/current-season data and long TTLs for immutable historical data — reducing load on both public APIs.
- **Immutable, pure panel widgets** in the Analytics Command Center: the season data provider is watched exactly once at the top of the screen, and the resulting `SeasonAnalytics` object flows down to stateless panels, minimizing rebuilds.
- **Auth is fully optional at the architecture level.** `firebaseReadyProvider` is set once in `main()` based on whether `Firebase.initializeApp()` succeeds, and every downstream provider/route respects it — so the app works immediately after cloning, even without Firebase project files.

---

## Data Sources

F1 Vision integrates two complementary, free, public F1 data APIs:

### [OpenF1](https://openf1.org/) — live & recent telemetry

- Base URL: `https://api.openf1.org/v1`
- Returns bare JSON arrays; supports `session_key=latest` for the current/most recent session.
- Used for: sessions, drivers, car telemetry (`car_data`), position, intervals, stints, pit stops, weather, and race control messages.
- Unauthenticated; the app is polite with request volume via caching.

### [Jolpica](https://api.jolpi.ca/) — historical results (Ergast-compatible)

- Base URL: `https://api.jolpi.ca/ergast/f1`
- Responses are wrapped in the classic `MRData` envelope, unwrapped defensively by `JolpicaService`.
- Used for: driver/constructor standings, race schedules, race results, qualifying, and pit-stop history — including paginated season-wide result sets for the analytics dashboard.
- Unauthenticated rate limit of roughly 4 requests/second and 500/hour; the app identifies itself via a `User-Agent` header and caches historical (immutable) data for hours.

---

## Tech Stack


| Category              | Package(s)                                         |
| --------------------- | -------------------------------------------------- |
| Framework             | Flutter (Dart)                                     |
| State management / DI | `flutter_riverpod`                                 |
| Routing               | `go_router`                                        |
| Networking            | `dio`                                              |
| Authentication        | `firebase_auth`, `firebase_core`, `google_sign_in` |
| Charts                | `fl_chart`                                         |
| Animation             | `flutter_animate`                                  |
| Typography            | `google_fonts`                                     |
| Persistence           | `shared_preferences`                               |
| Utilities             | `intl`, `shimmer`                                  |

*(Dependencies inferred from the `lib/` source tree; see `pubspec.yaml` in the full project for exact version constraints.)*

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        # API endpoint & timing/cache constants
│   ├── network/           # DioClient, interceptors, TTL cache, Result<T>
│   ├── errors/             # AppException / Failure hierarchy
│   ├── theme/               # AppColors, AppTextStyles, AppTheme, TeamPalette
│   ├── utils/                # Formatters, JSON helpers, responsive breakpoints
│   └── widgets/               # Shared UI: GlassCard, LiveBadge, AnimatedCounter, ...
├── features/
│   ├── home/                    # Dashboard screen
│   ├── live_race/                 # Live leaderboard
│   ├── telemetry/                   # Gauges, channel charts, driver selector
│   │   └── widgets/
│   ├── standings/                     # Driver / Constructor standings
│   ├── analytics/                       # Analytics Command Center + chart widgets
│   │   └── widgets/
│   │       └── charts/                    # Line, donut, bar, radar, scatter, sparkline, ring
│   ├── auth/                                # Login / Register screens
│   ├── settings/                              # Theme & preferences
│   └── shell/                                   # AppShell (nav chrome), ComingSoonScreen
├── models/                 # Freezed-style/plain data models (Driver, Session, Telemetry, ...)
├── providers/               # Riverpod providers wiring repositories to the UI
├── repositories/             # Domain repositories + typed API services
│   └── services/               # OpenF1Service, JolpicaService
├── routes/                # GoRouter configuration & shared nav destinations
├── firebase_options.dart  # Generated FlutterFire platform config (optional)
└── main.dart               # App bootstrap
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Dart SDK (bundled with Flutter)
- A configured target platform (Android Studio / Xcode / Chrome / desktop toolchain, as needed)
- *(Optional)* A [Firebase](https://firebase.google.com/) project, if you want authentication enabled

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd f1_vision

# Fetch dependencies
flutter pub get

# Run on a connected device / emulator / browser
flutter run
```

The app works out of the box **without any Firebase setup** — `main.dart` attempts `Firebase.initializeApp()` at launch, and if it throws (because no platform config is present), the app simply proceeds without an authentication layer instead of crashing.

### Building for release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows / macOS / Linux
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

---

## Configuration

### Enabling authentication (optional)

To enable email/password and Google Sign-In:

1. Create a Firebase project at the [Firebase Console](https://console.firebase.google.com/).
2. Run `flutterfire configure` (from the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)) to generate `lib/firebase_options.dart` for your project.
3. Add the platform-specific config files as prompted (`google-services.json` for Android, `GoogleService-Info.plist` for iOS/macOS).
4. Enable **Email/Password** and **Google** sign-in providers in the Firebase Console under Authentication → Sign-in method.
5. Re-run `flutter run` — the app will detect a valid Firebase configuration and enable the auth-gated routes and guest-mode toggle automatically.

No API keys are required for OpenF1 or Jolpica — both are consumed unauthenticated.

### Adjusting cache & retry behavior

Timing constants live in `lib/core/constants/api_constants.dart`:

- `defaultCacheTtl` — short TTL for live/current data (default 30s)
- `historicalCacheTtl` — long TTL for immutable historical data (default 6h)
- `maxRetries` / `retryBaseDelay` — retry policy for transient network failures
- `connectTimeout` / `receiveTimeout` — per-request timeouts

---

## Design System

F1 Vision uses a single, centralized design language rather than ad-hoc styling per screen:

- **`AppColors`** — a dark-mode-first palette with a parallel light palette behind identical member names; brand colors (F1 red, tyre compounds, semantic green/amber/blue) stay constant across both modes so charts and identities remain recognizable regardless of theme.
- **`TeamPalette`** — maps Jolpica/Ergast constructor IDs to real team brand colors (Red Bull blue, Ferrari red, Mercedes teal, McLaren papaya, etc.), with a deterministic fallback hue for unrecognized/historical constructors so older seasons still render distinct, stable colors.
- **`AppTextStyles` / `AppTheme`** — a shared typography scale (via `google_fonts`) and `ThemeData` builder consumed by every screen.
- **`GlassCard`** — the app's signature translucent, blurred-surface card used across dashboards, standings, and analytics panels.
- **Responsive layout helpers** — a `context.responsive(mobile: ..., desktop: ...)` utility used throughout to adapt padding, column counts, and layout direction between mobile and desktop without duplicating widget trees.
- **Motion** — `flutter_animate` powers entrance animations (fade/slide on cards, counting animations on stat values), while position changes in the live leaderboard animate via implicit layout transitions rather than hard cuts.

---

## Error Handling & Resilience

- Every network failure is translated into a typed `AppException` (`TimeoutException`, `NetworkException`, `RateLimitException`, `ServerException`, `ParseException`) at the `DioClient` layer, then surfaced to the UI as a `Failure` with a message safe to display directly.
- Repositories return `Result<T>` (success/failure) rather than throwing, so screens can render dedicated empty/error/loading states (see `analytics_states.dart`) instead of crashing or showing a blank screen.
- A `RetryInterceptor` automatically retries transient failures with backoff before giving up.
- The app is designed to **degrade gracefully**: no Firebase config → no auth layer; no live session → falls back to the most recent completed session; upstream rate-limiting → served from cache where TTL allows.

---

## Roadmap

The following screens are scaffolded with "Coming Soon" previews and represent the next implementation targets:

- [ ]  **Drivers** — full driver directory with per-driver detail pages and animated ranking transitions.
- [ ]  **Teams** — constructor cards with pit-stop analytics and a season performance graph.
- [ ]  **Calendar** — full season schedule, live countdowns, and circuit detail pages (track map, DRS zones, lap record).
- [ ]  **Compare Drivers** — two-driver head-to-head comparison with radar charts and sector/pace deltas.

---

## Contributing

Contributions, issues, and feature requests are welcome.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please keep new code consistent with the existing architecture — typed services in `repositories/services/`, domain logic in `repositories/`, state exposed via `providers/`, and UI kept declarative and driven by Riverpod state.

---

## License

This project's license has not yet been specified. Add a `LICENSE` file to the repository root and reference it here (e.g., MIT, Apache 2.0) before public distribution.

---

## Acknowledgements

- [OpenF1](https://openf1.org/) — free, open real-time and historical F1 data API.
- [Jolpica F1](https://github.com/jolpica/jolpica-f1) — free, Ergast-compatible historical F1 data API.
- Team and driver data, colors, and terminology are used for informational and educational purposes; F1 Vision is an independent project and is not affiliated with Formula 1, the FIA, or any F1 team.

# 🏎️ F1 Vision

**A premium Formula 1 analytics dashboard built with Flutter** — live timing,
car telemetry, and a Bloomberg-terminal-style Analytics Command Center, in a
cinematic dark (or light) design.

![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-Android%20·%20iOS%20·%20Web%20·%20Desktop-555)
![License](https://img.shields.io/badge/license-MIT-green)

*Unofficial fan project — not associated with Formula 1.*

</div>

---

## ✨ Features

### Fully built & wired to live data

- **Analytics Command Center** *(flagship)* — 14 season panels rendered with 9
  reusable chart types (animated line & area with zoom/pan, horizontal bars,
  pie, donut, radar, scatter, sparklines, progress rings). Driver &
  constructor rankings, championship progress, team trends, fastest laps,
  poles, podiums, average finish, DNFs & reliability, race pace, pit stops,
  driver form and a head-to-head radar — every chart with tooltips and
  hover/touch interaction. Responsive 3 → 2 → 1-column masonry, shimmer /
  empty / error states, 90 s auto-refresh for the current season.
- **Telemetry Dashboard** — an engineer-style cockpit streaming OpenF1
  `/car_data`: animated 270° speed & RPM gauges, gear / DRS / throttle / brake
  status rail, three synchronized traces sharing one crosshair, viewport zoom
  & pan, pause / restart, driver selector.
- **Live Race / Race Result** — during a session: a race-control leaderboard
  where rows slide smoothly on position changes, with tyre pills, DRS chips
  and gaps. Outside a session it automatically becomes a clean **latest
  classification** — just the finishing order (P1, P2, …) with driver and
  team.
- **Standings** — driver & constructor championships with a season selector.
- **Home** — live-session hero, weather, and next-race overview.
- **Settings** — Dark / Light / System theme (persisted), account management,
  about.
- **Authentication (optional)** — e-mail/password registration & sign-in plus
  **Sign in with Google**, guest mode, password reset. Powered by Firebase;
  without a Firebase config the app simply runs without auth.

### Scaffolded (routed placeholders)

Drivers, Teams, Calendar and Compare render polished "Coming Soon" screens and
are already wired into navigation — drop real UI into each feature folder to
light them up (see `CONTRIBUTING.md` for the recipe).

## 📸 Screenshots

> Add screenshots or a screen recording here — `docs/screenshots/` is a good
> home. The Analytics Command Center and Telemetry Dashboard make the best
> hero shots.

## 🔌 Data sources


| Source                                           | Used for                                               | Notes                                                                                                              |
| ------------------------------------------------ | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| [OpenF1](https://openf1.org)                     | Sessions, live positions, weather, car telemetry       | Live in-session telemetry needs a paid OpenF1 account; otherwise the latest completed session streams as a replay. |
| [Jolpica](https://github.com/jolpica/jolpica-f1) | Standings, results, qualifying, pit stops (historical) | Ergast-compatible.`limit` caps at 100, so season results paginate (handled + cached).                              |

No API keys are required for the dashboards.

## 🚀 Getting started

```bash
git clone https://github.com/YOUR_USERNAME/f1-vision.git
cd f1-vision

# 1. Generate the platform folders (android/ ios/ web/ …) — first time only.
#    This repo ships the Dart source; `flutter create .` scaffolds the rest.
flutter create . --project-name f1_vision

# 2. Install dependencies
flutter pub get

# 3. Run (pick your device)
flutter run
```

**Requirements:** Flutter **3.27+** (the code uses `Color.withValues`), Dart 3.3+.

### Optional: enable sign-in

Follow **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)** to connect a
Firebase project (e-mail + Google auth). Without it the app runs in
no-auth mode automatically.

## 🗂️ Project structure

```
lib/
├── core/               # design system, networking, errors, shared widgets
│   ├── constants/      #   API endpoints & cache TTLs
│   ├── errors/         #   AppException / Failure + mapping
│   ├── network/        #   DioClient (retry + TTL cache), Result<T>
│   ├── theme/          #   AppColors (light+dark), AppTextStyles, AppTheme
│   ├── utils/          #   Json coercion, responsive helpers, formatters
│   └── widgets/        #   GlassCard, LiveBadge, skeletons, counters…
├── models/             # immutable data classes (+ fromJson)
├── repositories/       # data aggregation → Result<T>
│   └── services/       #   raw OpenF1 / Jolpica access
├── providers/          # Riverpod: DI, polling, theme, auth
├── features/           # one folder per screen (UI only)
└── routes/             # GoRouter (auth redirects) + nav destinations
```

Data flows one way: **models → services → repositories → providers → UI**.
The architecture rules and a step-by-step "add a feature" checklist live in
[CONTRIBUTING.md](CONTRIBUTING.md).

## 🎨 Theming

The entire palette lives in `lib/core/theme/app_colors.dart` behind
brightness-aware getters — surfaces and text swap between the near-black
cockpit and a warm paper-white, while brand colours (F1 red, tyre compounds,
team colours) stay constant so charts remain recognisable. The theme choice
persists across launches.

## 🧭 Roadmap

- [ ]  Drivers grid + detail pages
- [ ]  Teams (constructor) pages with pit-stop analysis
- [ ]  Calendar with countdowns & circuit details
- [ ]  Head-to-head driver comparison
- [ ]  Favourites synced per account

## 🤝 Contributing & license

PRs welcome — read [CONTRIBUTING.md](CONTRIBUTING.md) first.
Released under the [MIT License](LICENSE).
