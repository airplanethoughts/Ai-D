# Working on Ai-D

Use Flutter 3.47.9 (Dart 3.13.7), Node 22 and Java 21. Flutter web is the verified target. Keep dependency lockfiles committed.

## Start locally

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
```

The default is a local demo. It does not access Firebase or call an AI provider. Use fictional journal entries for screenshots and tests. Do not commit local configuration, credentials, journal exports or account data.

## Check a change

```sh
flutter analyze
flutter test
flutter test test/free_deployment_test.dart --dart-define=ENABLE_AI=false --dart-define=ENABLE_UPLOADS=false
flutter build web --no-wasm-dry-run
npm ci
npm ci --prefix functions
npm run test:deploy
npm test --prefix functions
npm run test:rules
```

The rule tests use the `demo-ai-d` emulator project, never production. GitHub Actions also builds the emulator-configured client. For UI changes, check a narrow mobile viewport and a desktop viewport, including empty, loading, error and saved states.

## Review expectations

Describe the user-visible change and verification in your pull request. Preserve journal data on failure, provide actionable errors, and keep demo, free-plan and optional paid features clearly distinguished. AI keys belong only in the server secret manager. Any backend authorization change needs emulator coverage.

See the [README](README.md) for connected-mode setup and deployment. Committing code does not deploy the live app or change its database rules.
