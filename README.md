# RikiPath Mobile

Flutter mobile app for the RikiPath Japanese/JLPT learning platform.

## Tech Stack

- Flutter and Dart
- Riverpod (`flutter_riverpod`) for state management and dependency injection
- `go_router` for navigation
- Dio for HTTP networking
- Drift and `drift_flutter` for local persistence
- `flutter_secure_storage` for authentication-token storage
- `build_runner` and `drift_dev` for generated database code

Environment values are currently supplied with Dart compile-time definitions; the project does not use `flutter_dotenv`.

## Requirements

- Flutter 3.47.3 (stable)
- Dart 3.13.3
- Android Studio with the Android SDK
- Git

Visual Studio is not required for Android development. It is only relevant when building Flutter Windows desktop applications.

## Clone

```powershell
git clone https://github.com/minh28102004/rikipath-mobile.git
cd rikipath-mobile
```

## Environment Setup

Create a local environment file from the public template:

```powershell
Copy-Item .env.example .env
```

Fill the required public values described in `.env.example`: `APP_ENV`, `API_BASE_URL`, `SWAGGER_URL`, and `ENABLE_API_LOGGING`.

The app reads these values through Dart defines. For a local CLI run, pass the file with:

```powershell
flutter run --dart-define-from-file=.env
```

Never put secrets, JWT signing keys, database passwords, or backend private credentials in a Flutter `.env` file. Dart-defined values can be extracted from a built mobile application and are not secret storage. The local `.env` file is ignored by Git and must not be committed.

See [Environment Configuration](docs/codex/ENVIRONMENT.md) for environment-specific rules and the current development HTTP limitation.

## Install Dependencies

```powershell
flutter pub get
```

## Generate Code

The Drift database uses generated Dart code:

```powershell
dart run build_runner build
```

Rerun this command after changing Drift tables, database annotations, or other generated model definitions, and whenever generated `.g.dart` files are missing or out of date.

## Run Application

List available devices:

```powershell
flutter devices
```

Run the application:

```powershell
flutter run
```

The current configuration requires environment values at startup. Unless an IDE launch configuration already supplies them, use:

```powershell
flutter run --dart-define-from-file=.env
```

To start an Android emulator, open Android Studio, go to **Tools > Device Manager**, create a virtual device if needed, and press the play button beside the device. Wait for it to boot before running `flutter devices` or `flutter run`.

## Development Validation

Before committing, run:

```powershell
dart format .
flutter analyze
flutter test
```

Current validated baseline at the time this guide was written:

- `flutter analyze`: No issues found
- `flutter test`: 73 tests passed

This is a current baseline, not a permanent guarantee; update it when the test suite or toolchain changes.

## Project Structure

```text
lib/
  app/        -> application bootstrap, router, and theme
  core/       -> configuration, networking, database, storage, and shared widgets
  features/   -> feature modules
test/         -> automated tests
docs/codex/   -> architecture, API, and implementation documentation
```

`RikiPath.Backend/` is a local, strictly read-only backend contract reference and is not part of the mobile repository. `docs/ui_reference/` contains local Stitch design references and is ignored by Git.

## Architecture Rules

```text
UI
  -> Controller/Provider
  -> Repository
  -> API/Database
```

- Widgets must not call Dio directly.
- Do not invent backend endpoints or DTO fields; use the documented API contract and read-only backend reference.
- Reuse the centralized RikiPath design system.
- The learner mobile JLPT scope is N5, N4, and N3.
- Store authentication tokens through `flutter_secure_storage`.

## Git Workflow

Use Conventional Commits, with one logical feature per commit. Examples:

```text
feat(auth): implement authentication flow
feat(learning): implement learning roadmap
fix(core): resolve API error mapping
docs(readme): update setup guide
chore(config): update development configuration
```

- Do not commit `.env`.
- Do not commit `RikiPath.Backend/`.
- Do not commit ZIP archives, build output, or temporary files.
- Never force push to `main` unless the team explicitly agrees.

## Useful Commands

```powershell
flutter pub get
dart run build_runner build
dart format .
flutter analyze
flutter test
flutter run
```

## Troubleshooting

### `flutter` is not recognized

Add the Flutter SDK `/bin` directory to `PATH`, restart the terminal, and try again.

### Generated `.g.dart` files are missing

```powershell
dart run build_runner build
```

### Android toolchain issue

```powershell
flutter doctor
```

Resolve the Android SDK, license, or Java issues reported by the command.

### Dependencies are out of sync

```powershell
flutter pub get
```

## Documentation

- [Codex Rules](docs/codex/CODEX_RULES.md)
- [Project Audit](docs/codex/PROJECT_AUDIT.md)
- [API Contract](docs/codex/API_CONTRACT.md)
- [API Gaps](docs/codex/API_GAPS.md)
- [Environment Configuration](docs/codex/ENVIRONMENT.md)
- [Routing Architecture](docs/codex/ROUTING_ARCHITECTURE.md)
- [Flutter Design System](docs/codex/FLUTTER_DESIGN_SYSTEM.md)
