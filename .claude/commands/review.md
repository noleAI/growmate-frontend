# /project:review — Code Review

Review the current changes for:

1. **Dart analysis**: Run `flutter analyze` and report any issues
2. **Code style**: Check adherence to flutter_lints rules and project conventions
3. **Architecture**: Verify feature modules follow the hybrid Clean Architecture pattern
4. **State management**: Ensure Bloc/Cubit usage is correct (events, states, providers)
5. **i18n**: Check that user-facing strings use `context.t` and preserve Vietnamese diacritics
6. **UI consistency**: Verify Zen UI kit usage, 8pt spacing grid, theme text styles
7. **Testing**: Confirm new features have corresponding tests

Report findings organized by severity (error → warning → suggestion).
