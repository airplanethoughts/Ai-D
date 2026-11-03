# Ai-D

A Flutter app for journaling, personal reflection, and discovering community activities. Built by Guannan Du.

**Start with the local demo:** it needs no account, Firebase project, API key, or paid service. Journals are saved on the current browser/device. The connected mode adds Firebase accounts, private cloud journals, administrator-published activities, and optional AI reflection through an authenticated backend.

## Quick start — runnable demo

Tested with **Flutter 3.47.9 / Dart 3.13.7**. Use that Flutter release for reproducible results; dependency versions are committed in `pubspec.lock`.

```sh
git clone https://github.com/airplanethoughts/Ai-D.git
cd Ai-D
flutter pub get --enforce-lockfile
flutter run -d chrome
```

Alternatively, build static web files:

```sh
flutter build web --no-wasm-dry-run
python3 -m http.server 8080 --directory build/web
```

Open http://localhost:8080. The demo supports creating, editing, deleting and reloading journals, mood ratings, written reflection prompts and clearly labeled sample activity ideas. It does not pretend to generate AI responses or show live events. Browser storage is not encrypted cloud backup; clearing it removes your demo data. Avoid sensitive entries on shared devices.

## Connected mode — your own Firebase project

The demo and connected modes are deliberately separate. Never use someone else's Firebase project or embed an OpenAI key in Flutter.

1. Create a Firebase project you control. Register a **web app**, enable **Email/Password** in Authentication, and create Firestore, Realtime Database and Storage. Add `localhost` and your deployment domain to Authentication's authorized domains. Some Firebase services and function deployment require billing; review that in your own account.
2. Copy `config/firebase.example.json` to `config/firebase.local.json`. Replace every placeholder with the web app's public Firebase configuration. Use the exact database URL and storage bucket from your console. This local file is ignored by Git. `FUNCTIONS_REGION` defaults to `us-central1`.
3. Install Node **22**, Java **21**, and the project tooling. Deploy only to your own explicitly selected project:

```sh
npm ci
npm ci --prefix functions
npx firebase login
npx firebase deploy --project YOUR_PROJECT_ID --only firestore:rules,database,storage
```

4. Launch the connected client:

```sh
flutter run -d chrome --dart-define-from-file=config/firebase.local.json
```

`USE_FIREBASE` must be `true` in that file. Missing Firebase configuration shows a setup error with a local-demo fallback, rather than a blank app. The checked-in original mobile Firebase registration files are historical; they are not used to initialize the web app. Configure your own mobile registration with FlutterFire before any native deployment.

### Optional AI backend

The Flutter client calls the authenticated Firebase callable function `aiReply`; it never contains an OpenAI API key. Journals save before AI is attempted. If the backend is absent or unavailable, your journal remains saved. Chat keeps failed messages available to retry/edit, retains ten prior conversation turns, and never duplicates a failed turn on retry. Opening the chat does not trigger a paid request. Encouragement requests run once per screen mount or explicit refresh.

```sh
npx firebase functions:secrets:set OPENAI_API_KEY --project YOUR_PROJECT_ID
npx firebase deploy --project YOUR_PROJECT_ID --only functions
```

Set `OPENAI_MODEL` when the deployment tool prompts for the parameter: choose a Responses API model available in your own OpenAI project. Do not put an API key in the model field or client configuration. Review provider pricing before enabling it. See [the official Responses API documentation](https://developers.openai.com/api/docs/guides/migrate-to-responses).

The server validates roles, message lengths, turn order and authentication, supplies its own instructions, sets `store: false`, reserves a quota slot transactionally before calling the provider, and limits each authenticated UID to **20 requests per UTC day**. Failed provider attempts count toward this quota. Requests time out and provider errors are sanitized. Quotas contain UID and counts, not message content. Enable a Firestore TTL policy for `_aiUsage.expiresAt` to automatically clean old counters. Provider retention policies still apply; `store: false` is not a blanket promise of zero retention. Configure App Check and abuse/billing monitoring before operating a broadly accessible paid service; per-account quotas alone do not prevent account-farming abuse.

AI responses are reflection aids, not therapy, diagnosis or professional advice. Nothing in the client or tests requires a real provider key. A live paid response has not been tested as part of this change.

### Administrator access

Public registration always creates an ordinary user. There is no client-side "become admin" option. The `admin: true` Firebase Authentication custom claim must be granted from a trusted Admin SDK environment by the project owner. Sign out and back in afterward so the claim refreshes. Merely changing a Firestore `role` field does not grant access. The UI and rules use the claim; rules are the actual authorization boundary.

- Firestore: users can create/read their own ordinary profile; only admin claims can publish activities.
- Realtime Database: journals/check-ins are readable and writable only by their owner; date and mood values are validated.
- Storage: private journal image paths and shared activity image paths have separate rules; images must be under 5 MB.
- Everything else, including server quota counters, is denied to clients by default.

Firebase download URLs contain bearer tokens: anyone given such a URL may access that object. Do not share private journal image URLs. Deploying these rule files is a separate, explicit step; committing them does not change the old hosted Firebase project's rules.

## Run the connected data flow locally with emulators

No production Firebase project or AI key is required to exercise accounts and journals locally:

```sh
npm ci
npx firebase emulators:start --project demo-ai-d --only auth,firestore,database,storage
```

In another terminal:

```sh
flutter run -d chrome --dart-define-from-file=config/firebase.emulator.json
```

Create an ordinary account in the app. The emulator UI is at http://127.0.0.1:4000. Data is temporary unless you explicitly export/import emulator data. AI is unavailable in this configuration; journals still save. On an Android emulator, use `--dart-define=EMULATOR_HOST=10.0.2.2` as well. No rules or backend are deployed to a real project by these commands.

## Verification

```sh
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
flutter build web --no-wasm-dry-run --dart-define-from-file=config/firebase.emulator.json
npm ci
npm ci --prefix functions
npm test --prefix functions
npm run test:rules
```

The tests cover local journal persistence/edit/delete, chat failure/retry/history, encouragement request lifecycle, AI input validation, quota failure behavior, sanitized provider errors, owner-only journal access, profile privilege escalation, administrator activity writes, and image access rules. GitHub Actions runs these checks with Node 22, Java 21 and the pinned Flutter release.

**Verified target:** Flutter web. Android/iOS scaffolds are retained from the original project, and still require native toolchain/Firebase registration and platform migration checks. Native builds and a real cloud deployment are not claimed as tested.

## Source map

- `lib/demo/`: local-only runnable demo and persisted journal editor.
- `lib/main.dart`, `lib/auth/`: explicit startup modes and account/session routing.
- `lib/services/ai_service.dart`, `lib/chat_page.dart`: callable client and conversation UI.
- `lib/form_widget.dart`, `lib/your_journals.dart`: connected journal creation/history.
- `lib/users/`, `lib/admins/`: activities, encouragement and admin publishing.
- `functions/`: authenticated, quota-limited server-side AI integration.
- `*.rules`, `database.rules.json`, `rules-test/`: backend authorization and emulator tests.

The internal Dart package remains `jack_social_app_v2` to preserve import compatibility. Some unused historical examples remain in the repository; they do not implement nearby-event filtering.
