# Ai-D

A Flutter project by Guannan Du exploring journaling, mood tracking, AI conversations, and discovering activities.

Ai-D brings personal reflection and social activity into one app: write about your day, record how you feel, talk with an AI companion, and browse activities shared by administrators.

> **Project status:** An early personal project, preserved as part of my development history. The repository contains prototype features and some original scaffold code. A current end-to-end build and the connected services have not been verified.

## What's in the app

| Area | Implementation |
| --- | --- |
| **Your Journey** | Journal entries with a daily rating, mood, written reflection, and image support. Entries can be browsed afterward. |
| **AI companion** | A chat interface and a screen that generates short, supportive messages through an OpenAI SDK integration. |
| **Personal check-ins** | Inputs around meals, goals, and stress. |
| **Explore** | A Firestore-backed feed of administrator-created activities, with detail pages. |
| **Accounts and profiles** | Firebase authentication, profile management, and separate user/admin navigation. |
| **Admin tools** | Publish activities with a title, description, date, and uploaded image. |

## Built with

- **Flutter and Dart** for the interface.
- **Firebase Authentication** for accounts.
- **Cloud Firestore** for user roles and activity posts.
- **Firebase Realtime Database** for journal and check-in records.
- **Firebase Storage** for uploaded images.
- **chat_gpt_sdk** for the existing AI integration.
- **image_picker**, **cached_network_image**, and other Flutter packages for media and interface features.

The repository includes Android and iOS projects and a web scaffold. The presence of these folders does not mean every platform has been tested.

## Run locally

### 1. Install the development tools

Use a Flutter SDK compatible with the dependency versions in this repository. The declared Dart constraint is `>=3.0.3 <4.0.0`. Running this older project on a newer Flutter release may require dependency or platform migration.

For iOS development, use macOS with Xcode and CocoaPods. For Android, configure the Android SDK and an emulator or device.

### 2. Get the source and dependencies

```sh
git clone https://github.com/airplanethoughts/Ai-D.git
cd Ai-D
flutter pub get
```

### 3. Configure the services

Use a Firebase project you control. Configure Firebase Authentication, Firestore, Realtime Database, and Storage to match the features you want to run.

Firebase configuration lives in:

- `lib/auth/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Replace the original project configuration with your own, and review database/storage access rules. Authentication routes users according to a `role` value of `Users` or `Admins` in the Firestore user document.

The AI integration is initialized in `lib/chat_page.dart`, `lib/form_widget.dart`, and `lib/users/gpt_summary.dart`. Review its credential setup and model selection before use. For a deployed app, keep service credentials on a trusted backend rather than embedding a private API key in a client build.

### 4. Launch

```sh
flutter run
```

## Code map

```text
lib/
  main.dart                    App startup, Firebase initialization, role routing
  auth/                        Authentication and Firebase options
  form_widget.dart             Journal-entry form
  your_journals.dart           Journal history
  specific_journal.dart        Journal detail
  little_get_to_know_screen.dart  Personal check-ins
  chat_page.dart               AI conversation interface
  profile.dart                 Profile and account actions
  users/
    home_page.dart             Main user navigation
    gpt_summary.dart           AI-generated supportive messages
    activity_near_me.dart      Activity feed
    specific_activity.dart    Activity detail
  admins/
    home_page.dart             Admin navigation
    pages/activities_post.dart Activity creation and image uploads
```

The internal Dart package is still named `jack_social_app_v2`, and some app labels retain the original “Jack Social App” name.

## Development notes

- The checked-in widget test is still Flutter's counter-app example; it does not cover Ai-D's actual flows.
- Existing AI calls, Firebase configuration, account-role handling, and platform behavior need verification before treating this as a production app.
- Activity browsing currently reads administrator posts. The file name `activity_near_me.dart` should not be taken as evidence of working distance-based filtering.

