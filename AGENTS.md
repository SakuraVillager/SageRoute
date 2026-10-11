# Repository Guidelines

## Project Structure & Module Organization

SageRoute is a Flutter application. Production Dart code lives in `lib/`, organized by responsibility: `pages/` and `views/` contain screens and flows, `components/` reusable widgets, `models/` domain and database records, `data/` repositories and mocks, `services/` integrations, `route_planning/` routing logic, `theme/` styling, and `utils/` helpers. `lib/main.dart` initializes the app. Tests mirror these concerns under `test/` (for example, `test/data/` and `test/route_planning/`). Platform runners are in `android/`, `ios/`, `web/`, and `windows/`; static assets and design notes are in `assets/` and `docs/`.

## Build, Test, and Development Commands

Run dependency setup and static checks before submitting changes:

```bash
flutter pub get
flutter analyze
flutter test
```

Run the app with local map configuration:

```bash
flutter run --dart-define-from-file=dart_define.json
```

Build an Android APK with the same defines:

```bash
flutter build apk --dart-define-from-file=dart_define.json
```

To focus on one area, pass a test file or directory, such as `flutter test test/models/`.

## Coding Style & Naming Conventions

Use Dart formatting (`dart format .`) and the rules in `analysis_options.yaml` (including single quotes, trailing commas, `const` constructors/declarations, no `print`, and widget keys). Use `lower_snake_case.dart` filenames, `UpperCamelCase` for classes/widgets, and `lowerCamelCase` for members. Keep repository/model mapping code separate from UI code; prefer existing shared components and theme tokens over one-off styling.

## Testing Guidelines

Tests use `flutter_test` and are named with the `_test.dart` suffix. Add focused unit/widget coverage beside the relevant suite when changing models, repositories, route planning, or theme behavior. Use the existing test helpers for environment loading and deterministic gateways; avoid requiring live Supabase or AMap services in unit tests. Run `flutter test` and `flutter analyze` locally, and investigate failures rather than suppressing lints.

## Commit & Pull Request Guidelines

History contains concise imperative messages, including scoped fixes such as `fix route planning bugs` and occasional conventional prefixes (`fix: ...`). Follow that style: keep the subject short, describe the user-visible change, and use `fix:`, `feat:`, or `refactor:` when appropriate. Pull requests should explain the behavior change, list validation commands, link an issue when available, and include screenshots or a short recording for UI changes. Call out platform-specific setup or migration steps.

## Security & Configuration Tips

Do not commit real credentials. Copy `dart_define.example.json` to the gitignored `dart_define.json`, and keep Supabase/AMap values in local configuration (`assets/env.env` as documented). Verify keys and platform permissions when testing map or location features.
