# Code Style Rules

## Dart Conventions
- Follow `package:flutter_lints/flutter.yaml` — do not disable rules without justification
- Use `const` constructors wherever possible
- Prefer `final` for local variables that don't change
- Use trailing commas for better formatting
- Max line length: follow dartfmt defaults (80 chars soft, formatter decides)

## File Organization
- One public class per file (private helpers are fine in same file)
- Import order: dart → flutter → packages → project relative
- Use relative imports within the same feature module, package imports across features

## Naming
- Files: `snake_case.dart`
- Classes/enums: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (Dart convention, not SCREAMING_CASE)
- Private members: prefix with `_`

## State Management
- Bloc for complex event-driven flows with multiple event types
- Cubit for simpler state transitions
- Always emit new state objects (never mutate existing state)
- Use `freezed` for state/event classes when beneficial

## Widget Structure
- Extract widgets into separate files when they exceed ~100 lines
- Use the Zen UI kit primitives (`ZenCard`, `ZenButton`, etc.) — don't reinvent
- Follow 8pt spacing grid (`GrowMateLayout` constants)
- Prefer theme text styles via `Theme.of(context).textTheme` over inline `TextStyle`
