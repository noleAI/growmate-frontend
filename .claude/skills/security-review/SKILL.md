# Security Review Skill

## Trigger
Auto-invoked when changes touch: `lib/core/network/`, `lib/core/storage/`, `.env`, `lib/core/services/*api*`

## Steps

1. **Secrets scan**: Verify no API keys, tokens, or passwords are hardcoded in source files
2. **Environment check**: Confirm secrets are loaded via `flutter_dotenv` or `--dart-define`, never inline
3. **Auth flow**: Check `GlobalTokenStorage` usage — tokens must go through `flutter_secure_storage`, not `SharedPreferences`
4. **API surface**: Verify `ApiService` implementations don't expose raw error details to UI (use `ApiErrorHandlerMixin`)
5. **Input validation**: Check that user inputs (quiz answers, form fields) are sanitized before sending to backend
6. **Supabase RPC**: Ensure RPC calls use parameterized queries, not string interpolation
7. **HTTPS**: Verify all API URLs use HTTPS (no HTTP except localhost debug)

## Output
Report any findings as: `[CRITICAL]`, `[WARNING]`, or `[INFO]` with file path and line reference.
