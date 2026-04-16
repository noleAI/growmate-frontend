# Deploy Skill

## Trigger
Auto-invoked on `/project:deploy` command or when preparing a release build.

## Steps

1. **Pre-flight checks**:
   - Run `flutter analyze` — abort if errors found
   - Run `flutter test` — abort if failures
   - Verify `.env` has required keys (SUPABASE_URL, SUPABASE_ANON_KEY)

2. **Clean build**:
   - `flutter clean`
   - `flutter pub get`
   - `dart run build_runner build --delete-conflicting-outputs`

3. **Build target** (ask user which platform):
   - **Android APK**: `flutter build apk --release`
   - **Android Bundle**: `flutter build appbundle --release`
   - **Web**: `flutter build web --release`
   - **Windows**: `flutter build windows --release`

4. **Post-build**:
   - Report build output path and file size
   - Check for obfuscation artifacts if Android release

## Output
Summary of build status, output location, and any warnings encountered.
