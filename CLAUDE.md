# CLAUDE.md

This file provides guidance to Claude Code when working with the Nuclear MOTD mobile app codebase.

## Running the Application

**Primary run command:**

```bash
flutter run
```

**Build APK for Android:**

```bash
flutter build apk --release
```

**Install APK on connected device:**

```bash
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" install -r "build/app/outputs/flutter-apk/app-release.apk"
```

**Force-stop app and restart:**

```bash
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" shell am force-stop com.nuclearmotd.app
```

**iOS builds**: No Mac available — all iOS builds go through **Codemagic** (cloud CI).
Push to GitHub master, then trigger a Codemagic build manually.

**Diagnose compile errors locally (Android):**

```bash
flutter build apk --debug 2>&1 | grep "lib\|Error\|FAILED"
```

Note: Local Android builds often fail due to OneDrive file locking on the `build/` directory.
This is NOT a code error — if no Dart errors appear, the code is fine. Codemagic builds on Mac
don't have this issue.

## Testing

```bash
flutter test
flutter analyze   # Note: shows false-positive URI errors on Windows — pre-existing, non-blocking
```

## Development Commands

```bash
flutter pub get   # After modifying pubspec.yaml
flutter clean     # Often fails on OneDrive repos due to file locking — usually safe to ignore
flutter doctor
```

## Architecture Overview

### Core Application Structure

- **Flutter** with **Riverpod** state management
- **Dio** for HTTP networking with auth interceptor (JWT)
- **Go Router** for navigation
- **Shared Preferences** + **MessageCacheService** for local storage/offline
- **Google Mobile Ads** for monetization
- **Firebase Messaging** for push notifications

### Backend Integration

- **Base URL**: `https://nuclear-motd.com` (both production and development — server handles auth)
- **Dio base URL** is set in `AppConfig.apiBaseUrl`; paths in `AppConfig` are relative (e.g. `/messages`)
- **Actual server paths** (as seen in server logs — no `/api/mobile/` prefix in URLs):
  - `POST /auth/login` — authentication
  - `GET /messages` — all messages (unread-first, deduplicated by message_id)
  - `GET /messages/{id}` — message detail
  - `POST /messages/{id}/mark-read` — mark message as read
  - `GET /unread-count` — unread count
  - `GET /dashboard` — dashboard stats
  - `GET /messages?limit=10` — recent messages (home screen)

### Key Provider Architecture

```
messagesProvider (StateNotifierProvider)  ← lib/features/messages/messages_provider.dart
  └── MessagesNotifier.loadMessages()     ← fetches GET /messages, caches locally
  └── MessagesNotifier.markLocallyAsRead(id) ← instant optimistic update

unreadCountProvider (Provider<int>)       ← lib/features/shared/widgets/bell_icon.dart
  └── derives from messagesProvider       ← no API call, instant, always in sync
```

### Mark-as-Read Flow (build 27+)

1. User opens message → `_hasMarkedAsRead` flag prevents duplicate calls
2. `Future.microtask(() => _markMessageAsRead())` — runs after build completes
3. `await dio.post('.../mark-read')` — server marks DB record
4. `messagesProvider.notifier.markLocallyAsRead(id)` — **instant** UI update (no network)
5. `notificationServiceProvider.refreshBadge()` — updates app icon badge (async)
6. `messagesProvider.notifier.loadMessages()` — background server sync

**Why optimistic update?** Server logs showed `GET /messages` (loadMessages) was sometimes
falling back to stale cache without reaching the server. Optimistic local update ensures
the UI always reflects the read status immediately.

## File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart              # API endpoints, ad unit IDs
│   ├── network/
│   │   └── dio_client.dart              # Dio client, AuthInterceptor, friendlyMessage extension
│   ├── router/
│   │   └── app_router.dart              # Go Router navigation config
│   ├── services/
│   │   ├── bookmarks_service.dart       # Local bookmark storage
│   │   ├── notification_service.dart    # FCM, app icon badge (AppBadgePlus)
│   │   └── share_service.dart           # Native share sheet
│   ├── cache/
│   │   └── message_cache_service.dart   # Offline message caching (SharedPreferences)
│   └── theme/
│       ├── app_theme.dart               # Colors, theme
│       └── atom_logo.dart               # Custom atom logo widget
├── features/
│   ├── auth/
│   │   └── presentation/screens/
│   │       ├── login_screen.dart
│   │       ├── signup_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       └── reset_password_screen.dart
│   ├── home/
│   │   └── presentation/screens/
│   │       └── home_screen.dart         # Dashboard + recent messages + BellIcon in AppBar
│   ├── messages/
│   │   ├── messages_provider.dart       # MessagesNotifier, messagesProvider (shared source)
│   │   └── presentation/screens/
│   │       ├── messages_screen.dart     # Full message list, unread filter, pull-to-refresh
│   │       └── message_detail_screen.dart # Detail view, mark-as-read, bookmark, share
│   ├── search/
│   │   └── presentation/screens/
│   │       └── search_screen.dart
│   ├── topics/
│   │   └── presentation/screens/
│   │       └── topics_screen.dart
│   ├── profile/
│   │   └── presentation/screens/
│   │       ├── profile_screen.dart
│   │       ├── schedule_screen.dart
│   │       ├── help_screen.dart
│   │       ├── about_screen.dart
│   │       ├── submit_content_screen.dart
│   │       ├── privacy_policy_screen.dart
│   │       └── terms_of_service_screen.dart
│   └── shared/
│       └── widgets/
│           ├── bell_icon.dart           # Bell icon + unreadCountProvider
│           ├── sponsor_banner.dart      # AdMob banner ads
│           ├── overflow_menu.dart       # App menu with logout
│           └── offline_banner.dart      # Network status indicator
└── main.dart                            # App entry point, Firebase init
```

## Current Features

### Messages

- All messages loaded at once (no pagination) — server returns unread-first, then by date
- Client-side unread filter toggle in messages list AppBar
- Pull-to-refresh
- Bell icon in home screen AppBar shows live unread count (derives from `messagesProvider`)
- Reading a message instantly updates its read status in the list and bell count
- Native ad insertion every 5 messages

### Mark-as-Read

- Fires automatically when message detail loads (once per screen instance)
- Optimistic local update for instant UI feedback
- Server confirmation via `POST /messages/{id}/mark-read`

### Notifications & Badge

- FCM push notifications (Firebase Messaging)
- App icon badge via `AppBadgePlus` (iOS) and silent local notification (Android/Samsung)
- Badge syncs every 5 minutes via periodic timer
- Refreshes after marking a message as read

### Other

- Bookmarks: local storage, toggle from detail screen
- Share: native share sheet from list and detail
- Offline: cached messages shown when network unavailable
- Search: full-text search via server

## Common Mistakes Claude Makes

### Import Management

- **`friendlyMessage` extension** is defined in `dio_client.dart`. Any file using
  `error.friendlyMessage` on a `DioException` MUST import `dio_client.dart`.
  Forgetting this is a compile error.
- When refactoring provider locations, check ALL files that import the old location.
- `messages_provider.dart` is the shared source — import from there, not from `messages_screen.dart`.

### State Management (Riverpod)

- Use `ref.read(provider.notifier).methodName()` to call methods on `StateNotifier` —
  do NOT use `ref.invalidate(provider)` for `StateNotifierProvider` as it disposes the
  notifier and has timing/reliability issues.
- `unreadCountProvider` is a synchronous `Provider<int>` that derives from `messagesProvider` —
  it updates automatically whenever `messagesProvider` state changes.
- Use `ref.read()` for one-time actions, `ref.watch()` for reactive rebuilds.
- `Future.microtask()` for side effects triggered in `build()` method.

### iOS-Specific

- Do NOT add `FirebaseApp.configure()` to `AppDelegate.swift` — FlutterFire handles
  initialization via Dart's `Firebase.initializeApp()` in `main.dart`. Adding it causes
  SIGABRT crash on iOS startup.
- `flutter_local_notifications` conflicts with Firebase Messaging's `UNUserNotificationCenter`
  delegate on iOS. Local notifications are Android-only; iOS badge uses `AppBadgePlus` only.
- iOS builds only via Codemagic — no local Mac build available.

### Build Debugging

- `flutter analyze` on Windows shows false-positive `uri_does_not_exist` errors for
  `dio_client.dart` imports — these are pre-existing and don't block Codemagic builds.
- Local `flutter build apk` often fails with OneDrive file-locking errors — not a code issue.
- "kernel_snapshot_program failed: Exception" = Dart compile error. Run
  `flutter build apk --debug 2>&1 | grep "lib\|Error"` to see the actual error line.

### Android-Specific

- Always force-stop after installing new APK: `adb shell am force-stop com.nuclearmotd.app`
- AdMob native ads require factory registration in native Android code (`MainActivity.kt`)

## Debugging Common Issues

### Messages List Not Updating After Reading

**Symptom**: Message still shows "unread" after returning to list

**Current solution**: `markLocallyAsRead(id)` in `MessagesNotifier` updates local state
instantly. If this isn't working, check that `message_detail_screen.dart` is calling
`ref.read(messagesProvider.notifier).markLocallyAsRead(widget.messageId)` after
the mark-read API call.

**Do NOT use**: `ref.invalidate(messagesProvider)` — this disposes the notifier and
has timing/reliability issues causing silent fallback to stale cache.

### Bell Count Not Updating

**How it works**: `unreadCountProvider` is a `Provider<int>` that watches `messagesProvider`.
It updates automatically — no API call needed. If it's wrong, `messagesProvider` has stale data.

### App Icon Badge Not Showing (iOS)

`AppBadgePlus.updateBadge(count)` is called after mark-read. Badge requires notification
permission. On iOS 16+, `UNUserNotificationCenter.setBadgeCount()` is used internally.
Still under investigation if number appears on home screen icon.

### API Calls Failing (401)

Silent re-login is implemented in `AuthInterceptor` — it reads saved credentials from
`FlutterSecureStorage` and retries. If re-login fails, token is cleared and router
redirects to login screen.

## Development Workflow

### iOS Release (Codemagic)

1. Make changes, test locally if possible
2. Bump `version` in `pubspec.yaml` (e.g. `0.9.6+27` → `0.9.6+28`)
3. `git add`, `git commit`, `git push origin master`
4. Trigger Codemagic build manually
5. Codemagic distributes to TestFlight automatically on success

### Android Testing

1. `flutter build apk --release` (may fail due to OneDrive — retry or use Codemagic)
2. `adb install -r build/app/outputs/flutter-apk/app-release.apk`
3. `adb shell am force-stop com.nuclearmotd.app`
4. Launch manually on device
5. `flutter logs` to monitor

## Current Build Status (2026-02-21)

**Build 0.9.6+27** — confirmed working on iOS via Codemagic/TestFlight

- iOS boots, authenticates, loads all messages
- Mark-as-read works: instant visual feedback via optimistic local update
- Bell count updates instantly when messages are read
- Unread filter works in messages list
- App icon badge (iOS home screen number): **under investigation**
- Backend `/messages` endpoint changes (all messages, unread-first):
  **needs server deploy** — user must SSH in and run
  `sudo bash /home/nuclear-motd/restart_server.sh`
