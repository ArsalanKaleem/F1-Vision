<div align="center">

<img src="assets/branding/app_icon.png" width="110" alt="F1 Vision logo" />

# F1 Vision

### Formula 1 telemetry, analytics and race strategy — in your pocket.

A production-grade Flutter application that turns public Formula 1 data into the
kind of dense, real-time dashboards normally locked inside a race engineer's
garage. Live timing, car telemetry, a Bloomberg-terminal-style analytics board,
a full lap-by-lap race replay engine, and head-to-head driver comparison.

[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20·%20iOS%20·%20Web%20·%20Windows%20·%20macOS%20·%20Linux-4A4A4A?style=flat-square)](#-platform-support)
[![Architecture](https://img.shields.io/badge/architecture-Clean%20%2B%20Riverpod-2ECC71?style=flat-square)](#-architecture)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

[**Features**](#-features) ·
[**Screens**](#-screens) ·
[**Architecture**](#-architecture) ·
[**Getting started**](#-getting-started) ·
[**Roadmap**](#-roadmap) ·
[**Contributing**](CONTRIBUTING.md)

<sub>An independent fan project. Not associated with, endorsed by, or affiliated with Formula 1, the FIA, or any team.</sub>

</div>

---

<div align="center">

<!-- ▸ Replace with a 10–20s screen recording of the Analytics Command Center. -->

<img src="docs/media/hero.gif" width="860" alt="F1 Vision — Analytics Command Center" />

<sub><i>Analytics Command Center — fourteen live panels, nine chart types, one screen.</i></sub>

</div>

---

## Table of contents

- [Why this exists](#-why-this-exists)
- [Features](#-features)
- [Screens](#-screens)
- [Architecture](#-architecture)
- [Tech stack](#-tech-stack)
- [Data sources](#-data-sources)
- [Getting started](#-getting-started)
- [Configuration](#-configuration)
- [Platform support](#-platform-support)
- [Keyboard shortcuts](#-keyboard-shortcuts)
- [Performance & offline](#-performance--offline)
- [Project structure](#-project-structure)
- [Roadmap](#-roadmap)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## 🎯 Why this exists

Most Formula 1 apps show you a leaderboard and a countdown. The interesting
questions live one layer deeper:

> *Did that undercut actually work, or did he lose the place in the pit lane?*
> *How much was the tyre falling away before the stop?*
> *Was the gap real pace, or traffic?*

F1 Vision was built to answer those questions. It reconstructs a full race lap
by lap, overlays tyre strategy against position changes, and lets you put two
drivers side by side across a season or a single stint — the analysis a strategy
engineer does on the pit wall, rebuilt as a consumer-grade interface.

It is also, deliberately, a **reference-quality Flutter codebase**: strict Clean
Architecture, a single-source design system, offline-first caching, and a
responsive layout that reflows from a three-column desktop board to a phone
without losing information density.

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

---

## 📱 Screens

<div align="center">


|                        Analytics Command Center                        |  |
| :--------------------------------------------------------------------: | :-: |
| <img src="docs/media/demo-analytics.gif" width="400" alt="Analytics" / |  |
|           Fourteen panels, nine chart types, season selector           |  |


|                           Telemetry Dashboard                           |                             Comparison Studio                             |
| :---------------------------------------------------------------------: | :-----------------------------------------------------------------------: |
| <img src="docs/media/demo-telemetry.gif" width="400" alt="Telemetry" /> | <img src="docs/media/demo-comparison.gif" width="400" alt="Comparison" /> |
|                   Live gauges and synchronised traces                   |               Head-to-head across a season or a single race               |


|                     Mobile — adaptive layout                     |                              Light mode                              |
| :---------------------------------------------------------------: | :------------------------------------------------------------------: |
| <img src="docs/media/demo-mobile.gif" width="260" alt="Mobile" /> | <img src="docs/media/demo-light.gif" width="260" alt="Light mode" /> |
|             Drawer navigation, full density preserved             |                      Every screen, both themes                      |

</div>

---

## 🏗 Architecture

F1 Vision follows **Clean Architecture** with a strictly one-directional data
flow. No widget ever touches Dio or parses JSON; no repository ever throws
across its boundary.

```
┌─────────────┐   ┌──────────────┐   ┌────────────────┐   ┌───────────┐   ┌──────────┐
│   models    │──▶│   services   │──▶│  repositories  │──▶│ providers │──▶│ features │
│  immutable  │   │  raw HTTP    │   │  aggregation   │   │  Riverpod │   │    UI    │
│ + fromJson  │   │ OpenF1 /     │   │ → Result<T>    │   │  polling  │   │ widgets  │
│             │   │ Jolpica      │   │                │   │  caching  │   │  only    │
└─────────────┘   └──────────────┘   └────────────────┘   └───────────┘   └──────────┘
                          │                                      │
                          ▼                                      ▼
                  ┌───────────────┐                     ┌─────────────────┐
                  │  DioClient    │                     │  CacheStore     │
                  │ retry, logging│◀────────────────────│  memory  → Isar │
                  │ Retry-After   │                     │  (offline L2)   │
                  └───────────────┘                     └─────────────────┘
```

### Principles


| Rule                                                    | Why                                                         |
| ------------------------------------------------------- | ----------------------------------------------------------- |
| UI only watches providers                               | Screens stay testable and free of I/O                       |
| Repositories return`Result<T>`, never throw             | Errors become data; every screen renders a real error state |
| Colours and type come from`AppColors` / `AppTextStyles` | This is what makes light mode a one-line switch             |
| Every screen handles loading / empty / error            | No blank frames, ever                                       |
| Heavy aggregation happens once, in the repository       | Immutable payloads flow down; playback never refetches      |

### Notable design decisions

**Immutable payloads, minimal rebuilds.** The Analytics board and Replay Studio
each watch their provider exactly *once*. The resulting immutable object flows
down to pure widgets, and playback advances a single lap counter that panels
read via `.select()` — so a lap tick never rebuilds the screen.

**Pluggable telemetry providers.** `ReplayEnrichmentSource` is an interface the
replay repository queries in order. OpenF1 implements it today; adding another
provider means writing one class and registering it — **no model, repository or
UI changes**.

**Composition over refetching.** The Comparison Studio performs no I/O of its
own. It composes the already-cached Analytics aggregate with the already-cached
Replay payload, so switching drivers is instant.

**Graceful degradation everywhere.** Firebase missing? The app runs without
auth. Isar can't open? In-memory cache. No telemetry provider for a 2005 race?
The replay still works from timing data and the UI says why.

---

## 🛠 Tech stack


| Layer      | Choice                                | Notes                                                       |
| ---------- | ------------------------------------- | ----------------------------------------------------------- |
| Framework  | **Flutter 3.27+**                     | Uses`Color.withValues`                                      |
| State      | **Riverpod 2**                        | Providers, families,`select`, `autoDispose`                 |
| Routing    | **GoRouter**                          | Shell route + auth redirects, deep-linkable                 |
| Networking | **Dio**                               | Custom retry + TTL cache interceptors, honours`Retry-After` |
| Charts     | **fl_chart 0.69**                     | Line, bar, pie, radar, scatter (+ custom painters)          |
| Offline    | **Isar**                              | Persistent L2 response cache                                |
| Auth       | **Firebase Auth**                     | Email/password + Google — entirely optional                |
| Motion     | **flutter_animate**, **shimmer**      | Entrances, micro-interactions, skeletons                    |
| Type       | **Sora** + **Inter** via google_fonts | Display and UI faces                                        |

---

## 🔌 Data sources


| Source                                               | Provides                                                               | Notes                                                                                                                              |
| ---------------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [**OpenF1**](https://openf1.org)                     | Sessions, live positions, car telemetry, weather, race control, stints | Covers 2023 onward. Live in-session telemetry requires a paid account; otherwise the latest completed session streams as a replay. |
| [**Jolpica**](https://github.com/jolpica/jolpica-f1) | Standings, results, qualifying, lap timings, pit stops                 | Ergast-compatible. Lap-by-lap timing back to 1996.`limit` caps at 100, so season and lap feeds paginate (handled and cached).      |

No API keys are required for any of the data features.

---

## 🚀 Getting started

### Prerequisites

- **Flutter 3.27+** and Dart 3.3+ (`flutter doctor` should be clean)
- A platform toolchain: Android Studio, Xcode, or Visual Studio 2022 (Windows)

### Install

```bash
git clone https://github.com/ArsalanKaleem/F1-Vision.git
cd F1-Vision

# This repo ships Dart source only — generate the platform folders once.
flutter create . --project-name f1_vision \
  --platforms=android,ios,web,windows,macos,linux

flutter pub get
```

### Generate the offline-cache schema — required

Isar uses code generation. **The project will not compile until you run this:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run                 # attached device
flutter run -d chrome       # web
flutter run -d windows      # desktop
```

### Optional: icons and splash

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## ⚙️ Configuration

### Make it yours

All About-screen content — name, bio, social links, store URLs, legal text —
lives in a single file:

```
lib/core/constants/app_info.dart
```

Blank entries are hidden automatically, so deleting a social link simply removes
its button.

### Authentication (optional)

The app runs perfectly without Firebase — you just see "Sign-in is not
configured" under Settings. To enable email and Google sign-in, follow
**[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)**:

1. Create a Firebase project, enable **Email/Password** and **Google**
2. `dart pub global activate flutterfire_cli && flutterfire configure`
3. Add your Android **SHA-1** (`cd android && ./gradlew signingReport`) —
   without it, Google Sign-In fails with `ApiException: 10`

`google-services.json`, `GoogleService-Info.plist` and `firebase_options.dart`
are git-ignored on purpose: each contributor generates their own.

---

## 💻 Platform support


|                        | Android | iOS |        Web        |   Windows   | macOS |    Linux    |
| ---------------------- | :-----: | :-: | :---------------: | :----------: | :---: | :----------: |
| UI, charts, routing    |   ✅   | ✅ |        ✅        |      ✅      |  ✅  |      ✅      |
| Live & historical data |   ✅   | ✅ |     ⚠️ CORS     |      ✅      |  ✅  |      ✅      |
| Offline cache (Isar)   |   ✅   | ✅ | ⚠️ session only |      ✅      |  ✅  |      ✅      |
| Email/password auth    |   ✅   | ✅ |        ✅        | ⚠️ partial |  ✅  | ⚠️ partial |
| Google sign-in         |   ✅   | ✅ |        ✅        |      ❌      |  ✅  |      ❌      |
| App icon               |   ✅   | ✅ |        ✅        |      ✅      |  ✅  |      —      |
| Native splash          |   ✅   | ✅ |        ✅        |      ❌      |  ❌  |      ❌      |

**Web notes.** `path_provider` has no web implementation, so the Isar cache
falls back to in-memory (session-only). Build with the CanvasKit renderer — the
glassmorphic panels use `BackdropFilter`, which is slow under the HTML renderer:

```bash
flutter build web --web-renderer canvaskit
```

**Windows notes.** Windows is the only platform that compiles the Firebase C++
SDK from source, which makes it the only one that can hit CMake issues.

---

## ⌨️ Keyboard shortcuts

Available in the **Replay Studio** on desktop and web:


| Key                              | Action                               |
| -------------------------------- | ------------------------------------ |
| <kbd>Space</kbd> / <kbd>K</kbd>  | Play / pause                         |
| <kbd>←</kbd> <kbd>→</kbd>      | Previous / next lap                  |
| <kbd>R</kbd>                     | Restart                              |
| <kbd>Home</kbd> / <kbd>End</kbd> | Jump to start / chequered flag       |
| <kbd>1</kbd>–<kbd>4</kbd>       | Replay speed 0.5× / 1× / 2× / 5× |

---

## ⚡ Performance & offline

- **Two-tier cache.** Memory L1 over an Isar L2 that survives restarts.
  Responses are keyed by full request URL and stored as raw JSON, so new
  endpoints cache automatically without schema changes.
- **TTL by volatility.** Live session data 30s; completed seasons and races 6h,
  since they never change.
- **Bounded rebuilds.** `select()` on playback state, `RepaintBoundary` around
  charts, single-watch screens with immutable payloads passed down.
- **Rolling-window streaming.** Telemetry fetches only each new time-slice and
  appends to a capped buffer rather than refetching the session.
- **Pruning.** Cached rows older than seven days are dropped at startup;
  Settings shows the entry count with a manual purge.

---

## 📁 Project structure

```
lib/
├── core/                    # cross-cutting foundations
│   ├── constants/           #   API endpoints, TTLs, app/developer info
│   ├── data/                #   Isar collections + offline cache store
│   ├── errors/              #   AppException → Failure mapping
│   ├── network/             #   DioClient (retry + cache), Result<T>
│   ├── theme/               #   AppColors (light+dark), type, spacing tokens
│   ├── utils/               #   JSON coercion, responsive helpers, formatters
│   └── widgets/             #   GlassCard, DataPanel, skeletons, counters
├── models/                  # immutable data classes (+ fromJson)
├── repositories/            # aggregation → Result<T>
│   ├── replay/              #   pluggable telemetry-enrichment sources
│   └── services/            #   raw OpenF1 / Jolpica access
├── providers/               # Riverpod: DI, polling, theme, auth, playback
├── features/                # one folder per screen — UI only
│   ├── about/  analytics/  auth/     compare/   home/
│   ├── live_race/  replay/  settings/  shell/  standings/  telemetry/
└── routes/                  # GoRouter + navigation destinations
```

---

## 🗺 Roadmap

- [X]  Live timing, standings, telemetry
- [X]  Analytics Command Center
- [X]  Race Replay & Strategy Simulator
- [X]  Driver Comparison Studio
- [X]  Offline caching, light mode, authentication
- [ ]  **Circuit Explorer** — interactive track maps, DRS zones, elevation, speed traps
- [ ]  Drivers & Teams detail pages
- [ ]  Calendar with countdowns and circuit profiles
- [ ]  Favourites synced per account
- [ ]  Predictive strategy simulator ("what if he'd pitted on lap 22?")

---

## 🧯 Troubleshooting


| Symptom                                                       | Fix                                                           |
| ------------------------------------------------------------- | ------------------------------------------------------------- |
| `Target of URI hasn't been generated: cached_response.g.dart` | Run`dart run build_runner build --delete-conflicting-outputs` |
| Windows:`Compatibility with CMake < 3.5 has been removed`     | See[docs/WINDOWS_BUILD.md](docs/WINDOWS_BUILD.md)             |
| Google Sign-In:`ApiException: 10`                             | Missing SHA-1 fingerprint in Firebase                         |
| App skips the login screen entirely                           | Firebase didn't initialise — check the debug console         |
| Charts blurry / slow on web                                   | Build with`--web-renderer canvaskit`                          |
| Replay says "no lap-by-lap timing"                            | Jolpica timing starts in 1996 — pick a later race            |

---

## 🤝 Contributing

Contributions are genuinely welcome — the roadmap above is a good place to
start. Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** first: it documents
the architecture rules, a step-by-step recipe for adding a feature without
breaking them, the commit convention and the PR checklist.

---

## 📄 License

Released under the [MIT License](LICENSE).

F1 Vision is an unofficial fan project. "F1", "Formula 1", "FIA" and related
marks belong to their respective owners. Data is provided by OpenF1 and Jolpica
under their own terms.

---

## 👤 Author

<div align="center">

**Arsalan Kaleem**
*Flutter Engineer · Motorsport Nerd · Karachi, Pakistan*

[![GitHub](https://img.shields.io/badge/GitHub-ArsalanKaleem-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ArsalanKaleem)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-arsalankaleem-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/arsalankaleem)
[![Portfolio](https://img.shields.io/badge/Portfolio-Visit-2ECC71?style=for-the-badge&logo=google-chrome&logoColor=white)](https://arsalankaleem.github.io/portfolio/)
[![Email](https://img.shields.io/badge/Email-Say%20hello-E1A100?style=for-the-badge&logo=gmail&logoColor=white)](mailto:arsalanabbasi.here@gmail.com)

</div>

---

## 🙏 Acknowledgements

- [**OpenF1**](https://openf1.org) — an outstanding free real-time F1 API
- [**Jolpica**](https://github.com/jolpica/jolpica-f1) — carrying the Ergast
  torch for historical data
- [**fl_chart**](https://github.com/imaNNeo/fl_chart) — the charting library
  doing the heavy lifting
- The Flutter and Riverpod teams

<div align="center">
<br>
<sub>If this project helped or inspired you, a ⭐ on the repository is always appreciated.</sub>
<br><br>
<sub>Made with ❤️ by <a href="https://github.com/ArsalanKaleem">Arsalan Kaleem</a> · © 2026</sub>
</div>
