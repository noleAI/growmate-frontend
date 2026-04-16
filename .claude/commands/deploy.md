# /project:deploy — Build & Deploy

Build the app for deployment:

1. **Pre-check**: Run `flutter analyze` and `flutter test` — abort if failures
2. **Clean**: Run `flutter clean` then `flutter pub get`
3. **Code gen**: Run `dart run build_runner build --delete-conflicting-outputs`
4. **Build**:
   - Android: `flutter build apk --release` or `flutter build appbundle --release`
   - Web: `flutter build web --release`
   - Windows: `flutter build windows --release`
5. **Verify**: Check build output exists and report file sizes

Ask which platform to build for before proceeding.
