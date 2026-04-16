# /project:fix-issue — Fix an Issue

Given a bug or issue description:

1. **Reproduce**: Identify the relevant files and understand the current behavior
2. **Root cause**: Trace through the code to find the source of the problem
3. **Fix**: Implement the minimal fix that resolves the issue
4. **Verify**: Run `flutter analyze` to ensure no new errors are introduced
5. **Test**: Run related tests with `flutter test` or suggest new test cases if none exist

Keep changes minimal — fix only what's broken, don't refactor surrounding code.
