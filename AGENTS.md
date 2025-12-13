# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` hosts the current app entry and primary widgets; expand with feature-specific subdirectories (`lib/features/`, `lib/widgets/`) as the app grows.
- `test/widget_test.dart` contains sample widget tests; mirror `lib/` structure in `test/` and name files `<feature>_test.dart`.
- Platform shells live under `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`; keep platform-specific tweaks isolated there.
- `pubspec.yaml` defines SDK (Dart 3.10.x), dependencies, and assets; update `pubspec.lock` via `flutter pub get`. Lints live in `analysis_options.yaml`.

## Build, Test, and Development Commands
- `flutter pub get` — install/refresh dependencies after changing `pubspec.yaml`.
- `flutter analyze` — static analysis using `flutter_lints`; run before every commit.
- `dart format .` — format all Dart code (2-space indent); keep diffs clean.
- `flutter test` — run unit/widget tests.
- `flutter run -d <device_id>` — launch the app locally; use `flutter devices` to list targets.
- `flutter build apk` / `flutter build ios` / `flutter build web` — produce release artifacts per platform.

## Coding Style & Naming Conventions
- Follow `flutter_lints`: prefer `const` widgets where possible, avoid `print`, handle null-safety explicitly.
- Files and directories: lower_snake_case; classes/types: PascalCase; methods/variables: lowerCamelCase; constants: ALL_CAPS.
- Keep widgets small and composable; extract shared UI into `lib/widgets/`. Co-locate models/services by feature.
- Document non-obvious logic with brief comments; avoid broad doc blocks for self-evident code.

## Testing Guidelines
- Use `flutter_test` with WidgetTester for UI interactions; organize tests under `test/` mirroring `lib/`.
- Name tests descriptively (`'increments counter on tap'`), and prefer given-when-then structure in assertions.
- Aim for meaningful coverage on new features; add regression tests for bugs. Run `flutter test` before PRs.

## Commit & Pull Request Guidelines
- Commit messages: short, imperative (“Add chart filter”), ideally following Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
- One logical change per commit; include dependency updates separately.
- Pull requests should describe the change, link related issues, list tests run, and attach screenshots/GIFs for UI updates.
- Keep diffs small; prefer early reviews over large drops. Update docs (README/AGENTS.md) when workflows change.
