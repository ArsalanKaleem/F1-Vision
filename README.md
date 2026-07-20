<div align="center">

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

| Source | Used for | Notes |
|---|---|---|
| [OpenF1](https://openf1.org) | Sessions, live positions, weather, car telemetry | Live in-session telemetry needs a paid OpenF1 account; otherwise the latest completed session streams as a replay. |
| [Jolpica](https://github.com/jolpica/jolpica-f1) | Standings, results, qualifying, pit stops (historical) | Ergast-compatible. `limit` caps at 100, so season results paginate (handled + cached). |

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

- [ ] Drivers grid + detail pages
- [ ] Teams (constructor) pages with pit-stop analysis
- [ ] Calendar with countdowns & circuit details
- [ ] Head-to-head driver comparison
- [ ] Favourites synced per account

## 🤝 Contributing & license

PRs welcome — read [CONTRIBUTING.md](CONTRIBUTING.md) first.
Released under the [MIT License](LICENSE).
