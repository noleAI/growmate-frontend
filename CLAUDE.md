# GrowMate Frontend — Team Instructions

## Project Overview

GrowMate is a Flutter mobile learning app for Vietnamese high-school students preparing for the national exam (THPT).
It features AI-powered adaptive learning, quizzes with LaTeX math rendering, diagnosis/intervention flows, smart scheduling, and wellness features.

- **Framework**: Flutter (Dart ^3.11.4)
- **Backend**: Supabase (primary), optional FastAPI agentic backend
- **State management**: flutter_bloc (Bloc + Cubit)
- **Routing**: go_router with auth/consent guards
- **Platforms**: Android, Web, Windows

## Architecture

Hybrid Clean Architecture + Feature-First:

```
lib/
├── main.dart              # Entry point, DI via MultiBlocProvider
├── app/                   # Router, Theme, i18n
├── core/                  # Shared: constants, network, services, models, storage
├── data/                  # Shared data layer (repositories, models)
├── features/              # 22 feature modules (auth, quiz, diagnosis, etc.)
├── presentation/          # Shared screens (profile)
└── shared/                # Zen UI kit, AI widgets, nav bars
```

Feature modules live in `lib/features/<feature>/` and may contain:
- `data/` — repositories, datasources, models
- `domain/` — entities, usecases (full Clean Arch features only)
- `presentation/` — pages, cubits/blocs, widgets

## Build & Run Commands

```bash
# Get dependencies
flutter pub get

# Code generation (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Run on Chrome
flutter run -d chrome

# Analyze
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/path/to/test.dart
```

## Code Style & Conventions

### Dart/Flutter
- Follow `package:flutter_lints/flutter.yaml` lint rules
- Use `freezed` + `json_serializable` for immutable models (generate with build_runner)
- State classes: Bloc for complex event-driven flows, Cubit for simpler state
- Always provide global blocs/cubits in `main.dart` MultiBlocProvider
- Feature-local cubits are created in route builders or feature pages

### Naming
- Feature folders: `snake_case` (e.g., `agentic_session`, `ai_companion`)
- Classes: `PascalCase`
- Files: `snake_case.dart`
- Routes: defined in `lib/app/router/app_routes.dart`

### UI System
- Design tokens: 8pt spacing grid via `GrowMateLayout` (8/12/16/24/32)
- Typography: centralized in `AppTheme` textTheme — prefer theme styles over ad-hoc sizes
- Color palette: `GrowMateColors` with desaturated blue accent
- Zen UI kit: `ZenButton`, `ZenCard`, `ZenPageContainer`, `ZenTextField`, etc. in `lib/shared/widgets/`
- Soft cards: minimal borders, subtle shadows
- Vietnamese UI copy must preserve diacritics (e.g., "Trang chủ" not "Trang chu")

### i18n
- Bilingual: Vietnamese (vi) + English (en)
- Use `context.t` extension from `lib/app/i18n/`
- Never use identical vi/en placeholders — audit translations after changes
- User-facing literals in cubit/repository payloads bypass `context.t` — avoid hardcoded Vietnamese in state classes

### Math / Quiz
- LaTeX rendering via `flutter_math_fork` + custom `QuizMathText`
- Inline math: `$...$` in content/options
- Block formulas: `metadata.formula` with `renderAsLatex: true`
- Content sanitizer: don't trim at parenthesized labels like `(C)`, only strip duplicated ordered marker sequences

## API & Backend

- Abstract `ApiService` interface with implementations:
  - `MockApiService` — local mock data (currently active: `useMockApi = true`)
  - `RealApiService` — FastAPI backend
  - `SupabaseHybridApiService` — Supabase RPC data plane
- Feature flags in `main.dart`: `useMockApi`, `useSupabaseRpcDataPlane`, `useAgenticBackend`
- Environment config via `.env` file (loaded by `flutter_dotenv`)
- Token management: `GlobalTokenStorage` + `flutter_secure_storage`

## Testing Guidelines

- Widget tests: avoid `pumpAndSettle` on screens with repeating timers/animations — use bounded `pump(Duration(...))`
- Wrap `MaterialApp.router` with required BlocProviders in tests
- GoogleFonts can fail in test VM — use simple `ThemeData` in tests
- After large UI rewrites, run `flutter analyze` immediately
- Integration tests live in `test/integration/`

## Important Gotchas

- GoRouter is `late final` — route table changes require **hot restart**, not hot reload
- `ZenCard` has no `height` param — wrap with `SizedBox(height:)` for fixed height
- Renaming fields in const state classes may be rejected by hot reload — do full restart
- When `AppRouter` constructor adds new dependencies, update integration tests immediately
- Snackbar theme must be theme-aware: use `colorScheme.onSurface` + `surfaceContainerHigh`
