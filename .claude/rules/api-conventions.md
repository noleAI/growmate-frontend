# API Conventions

## Architecture
- All API calls go through the abstract `ApiService` interface (`lib/core/network/`)
- Three implementations: `MockApiService`, `RealApiService`, `SupabaseHybridApiService`
- Feature flag selection in `main.dart` — never hardcode a specific implementation in features

## Error Handling
- Use `ApiErrorHandlerMixin` for consistent error handling in repositories
- Surface errors via Bloc/Cubit states (error states), not raw exceptions in UI
- App-level exceptions defined in `lib/core/error/app_exceptions.dart`

## Supabase
- RPC calls preferred over direct table queries
- Migration schemas documented in `supabase_*.sql` at project root
- Auth tokens managed by `GlobalTokenStorage` + `flutter_secure_storage`

## Environment
- All secrets and URLs in `.env` file (loaded via `flutter_dotenv`)
- Never hardcode API URLs, keys, or secrets in source code
- Fallback to `--dart-define` for CI/CD builds

## Data Models
- Use `freezed` + `json_serializable` for API response models
- Generate with: `dart run build_runner build --delete-conflicting-outputs`
- Generated files: `.freezed.dart`, `.g.dart` — committed to repo
