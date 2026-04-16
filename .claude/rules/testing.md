# Testing Rules

## General
- All new features should have corresponding widget tests
- Tests live in `test/` mirroring `lib/` structure
- Integration tests in `test/integration/`

## Widget Tests
- Use bounded `pump(Duration(...))` instead of `pumpAndSettle` for screens with timers/animations
- Provide required BlocProviders when testing routed pages
- Use simple `ThemeData()` in tests — avoid GoogleFonts dependency
- Test viewport: ~430px width for mobile layout assertions

## Bloc/Cubit Tests
- Test state transitions for each event/method
- Use `blocTest` from `bloc_test` package when available
- Verify initial state, intermediate states, and final state

## Gotchas
- `fake_async`: create timers inside the fake zone, not before
- Pages with periodic timers must cancel them in `dispose` — otherwise pending timer assertions fail
- After renaming widget classes, update test files to match
- When `AppRouter` gains new constructor params, update integration tests immediately
