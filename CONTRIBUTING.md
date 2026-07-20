# Contributing to F1 Vision

Thanks for helping build F1 Vision! This guide explains how the codebase is organised, how to add a new feature without breaking the architecture, and the git workflow the project follows.

For a full feature overview, screenshots, and setup instructions, see the [README](https://claude.ai/chat/README.md) first — this document assumes you already have the app running locally.

## Project architecture

Data flows in one direction, through four layers:

```
models  →  services  →  repositories  →  providers  →  features (UI)
```


| Layer        | Folder                       | Responsibility                                      |
| ------------ | ---------------------------- | --------------------------------------------------- |
| Models       | `lib/models/`                | Immutable data classes +`fromJson`parsing           |
| Services     | `lib/repositories/services/` | Raw API access (OpenF1, Jolpica, Firebase)          |
| Repositories | `lib/repositories/`          | Compose services, aggregate data, return`Result<T>` |
| Providers    | `lib/providers/`             | Riverpod state, polling, caching decisions          |
| Features     | `lib/features/<name>/`       | Screens + feature-local widgets only                |

Shared building blocks live in `lib/core/` (theme, networking, errors, reusable widgets, responsive helpers) and routing in `lib/routes/`.

**Golden rules**

1. UI never calls Dio or parses JSON — it only watches providers.
2. Repositories never throw across the boundary — they return `Result<T>` (`Success` / `Err<Failure>`) via a `_guard` helper.
3. Colours and text styles come from `AppColors` / `AppTextStyles` only — never hard-code a `Color(0xFF…)` in a feature (this is what makes light/dark mode work).
4. New screens must handle **loading, empty, and error** states.
5. Don't refactor completed features while adding a new one.

## Adding a new feature (checklist)

Say you're building the **Drivers** page:

1. **Model** — add `lib/models/driver_profile.dart` with `fromJson` using the `Json.*` helpers (they coerce the loose typing of the APIs).
2. **Service method** — add the endpoint path to `lib/core/constants/api_constants.dart`, then a typed fetch method to the right service (`jolpica_service.dart` or `openf1_service.dart`), choosing a cache TTL (`defaultCacheTtl` for live data, `historicalCacheTtl` for immutable seasons).
3. **Repository** — expose it through an existing repository or a new one, wrapped in `_guard`.
4. **Provider** — a `FutureProvider` (add `_poll(ref, interval)` only if the data genuinely changes while on screen). Register any new repository in `lib/providers/core_providers.dart`.
5. **Screen** — `lib/features/drivers/drivers_screen.dart` + `lib/features/drivers/widgets/…`. Reuse `GlassCard`, `SectionHeader`, `SkeletonBox`, the analytics chart widgets, etc.
6. **Route** — in `lib/routes/app_router.dart`, replace the feature's `ComingSoonScreen` block with `_fade(s, const DriversScreen())` and delete nothing else. The nav entry already exists in `nav_destinations.dart`.
7. **Docs** — move the feature from "Scaffolded" to "Fully built" in `README.md` and add a line to `CHANGELOG.md`.

## Git workflow

* `main` is always releasable. Work on branches: `feature/<name>`, `fix/<name>`, or `docs/<name>`.
* Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/): `feat: add drivers grid`, `fix: bottom nav labels on tap`, `docs: firebase setup guide`, `chore: bump fl_chart`.
* Open a Pull Request into `main`; keep PRs focused on one feature/fix.

**PR checklist**

* [ ]  `flutter analyze` passes with no new warnings
* [ ]  `flutter run` verified on at least one platform (note which)
* [ ]  Loading / empty / error states handled for any new data
* [ ]  No hard-coded colours; both light and dark mode checked
* [ ]  README / CHANGELOG updated if user-facing

## Releasing

1. Bump `version:` in `pubspec.yaml` (semver: minor for features, patch for fixes).
2. Update the version string in `lib/features/settings/settings_screen.dart`.
3. Add a `CHANGELOG.md` entry.
4. Tag: `git tag v0.5.0 && git push --tags`.

## Code of Conduct

Be respectful and constructive in issues, PRs, and reviews. Assume good intent, critique code rather than people, and keep discussion focused on what's best for the project.

## License

F1 Vision is licensed under the [MIT License](https://claude.ai/chat/LICENSE). By contributing, you agree that your contributions will be licensed under the same terms.
