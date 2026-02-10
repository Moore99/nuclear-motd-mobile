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

**View flutter logs:**

```bash
flutter logs
```

**Clear flutter logs:**

```bash
flutter logs --clear
```

## Testing

**Run all tests:**

```bash
flutter test
```

**Run specific test file:**

```bash
flutter test test/widget_test.dart
```

## Development Commands

**Install dependencies:**

```bash
flutter pub get
```

**Clean build artifacts:**

```bash
flutter clean
```

**Check for issues:**

```bash
flutter doctor
```

**List connected devices:**

```bash
flutter devices
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" devices
```

## Architecture Overview

### Core Application Structure

- **Flutter** with **Riverpod** state management
- **Dio** for HTTP networking with interceptors
- **Go Router** for navigation
- **Shared Preferences** for local storage
- **Google Mobile Ads** for monetization

### Key Features

- **Authentication**: JWT token-based auth with auto-refresh
- **Message List**: Paginated message browsing with read/unread status
- **Message Detail**: Full message viewing with mark-as-read functionality
- **Bookmarks**: Local bookmark storage and management
- **Share**: Native share functionality for messages
- **Push Notifications**: FCM integration with badge count management
- **Offline Support**: Message caching for offline viewing

### Backend Integration

The mobile app connects to the Nuclear MOTD backend API:

- **Base URL**: `https://nuclear-motd.com` (production) or `http://localhost:8000` (development)
- **API Endpoints**:
  - `/api/mobile/auth/login` - User authentication
  - `/api/mobile/auth/register` - User registration
  - `/api/mobile/messages` - Message list with pagination
  - `/api/mobile/messages/{id}` - Message detail
  - `/api/mobile/messages/{id}/mark-read` - Mark message as read
  - `/api/mobile/unread-count` - Get unread message count

## File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # API endpoints, ad unit IDs
│   ├── network/
│   │   └── dio_client.dart          # HTTP client with auth interceptor
│   ├── router/
│   │   └── app_router.dart          # Go Router navigation config
│   ├── services/
│   │   ├── bookmarks_service.dart   # Bookmark management
│   │   ├── notification_service.dart # FCM and badge management
│   │   └── share_service.dart       # Native share functionality
│   ├── cache/
│   │   └── message_cache_service.dart # Offline message caching
│   └── theme/
│       ├── app_theme.dart           # Theme and colors
│       └── atom_logo.dart           # Custom logo widget
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           └── register_screen.dart
│   ├── messages/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── messages_screen.dart       # Message list with pagination
│   │           └── message_detail_screen.dart # Message detail with mark-as-read
│   └── shared/
│       └── widgets/
│           ├── sponsor_banner.dart   # AdMob banner ads
│           ├── overflow_menu.dart    # App menu with logout
│           └── offline_banner.dart   # Network status indicator
└── main.dart                         # App entry point
```

## Common Mistakes Claude Makes

### Flutter Development

- Don't forget to run `flutter pub get` after modifying `pubspec.yaml`
- Always use `const` constructors where possible for performance
- Remember to dispose controllers and listeners in `dispose()` method
- Use `ref.read()` for one-time reads, `ref.watch()` for reactive updates
- Don't call `setState()` or `ref.read()` during build method - use `Future.microtask()` for side effects

### State Management (Riverpod)

- Use `StateNotifier` for complex state, `StateProvider` for simple values
- Use `FutureProvider` for async data fetching
- Use `autoDispose` modifier to prevent memory leaks
- `ref.invalidate()` to force provider refresh
- Don't forget to consume `ConsumerWidget` or `ConsumerStatefulWidget` to access `ref`

### Android-Specific Issues

- Always force-stop the app after installing new APK: `adb shell am force-stop com.nuclearmotd.app`
- Old app versions can persist despite reinstall - check process ID in logs
- Use `flutter clean` before building if you encounter snapshot errors
- AdMob ads require factory registration in native Android code

### API Integration

- Always handle `DioException` errors and extract `friendlyMessage` extension
- Use `ref.read(dioProvider)` to get HTTP client with auth interceptor
- Mark-as-read should trigger badge refresh: `ref.read(notificationServiceProvider).refreshBadge()`
- After marking as read, invalidate messages list: `ref.invalidate(messagesProvider)`

### Windows Development Path Issues

- Use forward slashes in paths passed to adb: `"C:/projects/nuclear-motd-mobile/build/..."`
- Quote paths with spaces when using PowerShell: `"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"`

## Current Features

### Authentication System

- JWT token-based authentication
- Automatic token refresh on 401 responses
- Secure token storage in shared preferences
- Login/Register screens with form validation

### Message Management

- **Messages List Screen**:
  - Paginated loading (20 messages at a time)
  - "Load More" button for additional messages
  - Read/unread status badges
  - Topic tags with color-coded badges
  - Pull-to-refresh functionality
  - Native ad insertion (every 5 messages)
  - Offline caching with fallback

- **Message Detail Screen**:
  - Full message content with HTML rendering
  - Topic badges at top
  - Message type badge
  - Created date and status
  - Bookmark functionality
  - Share functionality
  - Citation links (opens in external browser)
  - **Mark as read**: Automatically marks message as read when viewed
    - Triggers badge count update
    - Updates messages list to show "read" status
    - Only executes once per message view

### Offline Support

- Messages cached locally using shared preferences
- Offline banner shows when network unavailable
- Cached messages displayed when API fails
- Automatic sync when network restored

### Push Notifications

- FCM integration for push notifications
- Badge count management (iOS and Android)
- Automatic badge refresh after marking messages as read
- Background notification handling

### Bookmarks

- Local bookmark storage
- Toggle bookmark from message detail screen
- Snackbar confirmation on bookmark add/remove

### Share Functionality

- Native share sheet integration
- Share message title and content
- Platform-specific positioning (iPad support)

## Recent Changes (2026-01-30)

### Mark-as-Read Implementation

**Backend Changes** (`C:/projects/nuclear-motd/app/api/mobile_api.py`):

- Added `POST /api/mobile/messages/{message_id}/mark-read` endpoint
- Updates `UserMessageHistory.read_in_app = True` and sets `read_at` timestamp
- Modified `/api/mobile/messages` to include `read_in_app` field in response

**Mobile App Changes**:

- Converted `MessageDetailScreen` from `ConsumerWidget` to `ConsumerStatefulWidget`
- Added `_hasMarkedAsRead` flag to prevent duplicate mark-as-read calls
- Mark-as-read triggers when message data loads: `if (!_hasMarkedAsRead && messageAsync.hasValue)`
- After marking read:
  - Refreshes badge count: `ref.read(notificationServiceProvider).refreshBadge()`
  - Invalidates messages list: `ref.invalidate(messagesProvider)`
- Messages list now shows "read/unread" status instead of "active/inactive"

**Files Modified**:

- `C:/projects/nuclear-motd/app/api/mobile_api.py` - Backend API
- `C:/projects/nuclear-motd-mobile/lib/features/messages/presentation/screens/message_detail_screen.dart`
- `C:/projects/nuclear-motd-mobile/lib/features/messages/presentation/screens/messages_screen.dart`

## Read / Badge Sync Fix (2026-02-04)

### Problem
Mobile badge count and message list were inconsistent with web:
- Same message delivered on multiple dates created duplicate history records
- Badge counted raw records; web bell counted distinct message_ids
- Mobile messages list showed duplicates; reading one didn't clear all copies
- Search endpoint had a `NameError` crash (`read_in_app` undefined)

### Root Cause
Backend `/unread-count` (both web and mobile) counted raw `UserMessageHistory` rows
where `read_in_app = false`. The web bell dropdown deduplicated by `message_id` and
showed a different number. Mobile messages list showed every history record as a
separate card.

### Solution (3 layers)

**Backend (`mobile_api.py`, `user_dashboard_modern.py`)**:
- Both `/unread-count` endpoints now count `DISTINCT message_id` where `read_in_app = false`
- This matches the web bell-dropdown logic exactly
- Fixed search endpoint: pre-fetches read status per message_id from history

**Mobile messages list (`messages_screen.dart`)**:
- `MessagesNotifier.loadMessages()` deduplicates the API response by `message_id`
- Keeps the entry with the most recent `sent_at`
- If ANY copy of a message is unread, the deduplicated entry shows as unread
- Badge count (distinct unread messages) now matches list item count

**Mobile home screen (`home_screen.dart`)**:
- `recentMessagesProvider` fetches `limit=10` and deduplicates to top 3 distinct
- Each recent message card now shows a read/unread badge (matches messages list)

### How It Works End-to-End
1. User opens a message in mobile app → `mark-read` marks ALL history records for that `message_id`
2. Badge refreshes via `/unread-count` → returns count of distinct `message_id`s still unread
3. Messages list refreshes → deduplicates, flips the single entry to "read"
4. Web bell dropdown → same deduplicated count from `/notification-list`
5. Result: badge and list are consistent across mobile and web

### Additional Fix (2026-02-04 session 2)
- `/messages` endpoint in `mobile_api.py` now also deduplicates server-side
  (over-fetches 3x raw records, collapses by message_id, keeps most-recent sent_at)
- Client-side dedup in `messages_screen.dart` remains as belt-and-suspenders
- Cleaned up 7 partially-read messages on production (msg_ids 96,131,236,240,253,267,271)
  that were left over from before the "mark ALL records" fix was deployed
- Production restart via `sudo systemctl restart nuclear-motd.service`
  (note: `pkill` fails as nuclear-motd user — always use systemctl)
- Verified: web and mobile `/unread-count` return identical counts; `/messages` has zero duplicates

### Files Modified
- `C:/projects/nuclear-motd/app/api/mobile_api.py` — unread-count dedup + search fix + /messages dedup
- `C:/projects/nuclear-motd/app/api/user_dashboard_modern.py` — web unread-count dedup
- `lib/features/messages/presentation/screens/messages_screen.dart` — list dedup
- `lib/features/home/presentation/screens/home_screen.dart` — home dedup + read badge

## Debugging Common Issues

### App Not Updating After Rebuild

**Symptom**: Changes don't appear, debug logs don't show up, old code still running

**Root Cause**: Old app process persists despite installing new APK

**Solution**:

1. Force-stop the app: `"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" shell am force-stop com.nuclearmotd.app`
2. Manually launch app on device
3. Check flutter logs for new debug messages

### Badge Count Not Updating

**Symptom**: Badge shows incorrect count after reading messages

**Root Cause**: Badge service not refreshed after mark-as-read

**Solution**: Ensure `ref.read(notificationServiceProvider).refreshBadge()` is called after marking message as read

### Messages List Not Refreshing

**Symptom**: Messages still show "unread" after viewing

**Root Cause**: Provider state not invalidated

**Solution**: Call `ref.invalidate(messagesProvider)` after marking message as read

### API Calls Failing

**Symptom**: 401 unauthorized errors

**Root Cause**: JWT token expired or missing

**Solution**: Check token storage and refresh logic in `dio_client.dart`

## Development Workflow

### Before Starting Any Task

1. Pull latest: `git pull origin master`
2. Check Flutter version: `flutter doctor`
3. Verify device connected: `flutter devices`
4. Review related code sections in this file

### Standard Task Flow

1. **Research Phase**: Understand requirements, review existing code
2. **Plan Phase**: Outline approach before coding
3. **Implement Phase**: Make changes with auto-accept edits
4. **Test Phase**: Build and install APK, test on device
5. **Verify Phase**: Check flutter logs for expected behavior
6. **Commit Phase**: Use descriptive commit messages

### Testing Checklist

- [ ] Build succeeds: `flutter build apk --release`
- [ ] App force-stopped: `adb shell am force-stop com.nuclearmotd.app`
- [ ] APK installed: `adb install -r build/app/outputs/flutter-apk/app-release.apk`
- [ ] Flutter logs running: `flutter logs`
- [ ] App launched manually on device
- [ ] Expected debug messages appear in logs
- [ ] UI changes visible and working
- [ ] No errors in flutter logs

## Production Configuration

**Environment Variables** (configured in backend):

- `BASE_URL` - API base URL (https://nuclear-motd.com)
- `ENV` - Environment mode (production)

**App Configuration** (`lib/core/config/app_config.dart`):

- API endpoints
- AdMob unit IDs (Android and iOS)
- App version and build number

## Notes for Claude Code Sessions

**This file is checked into git and shared across the team. Update it whenever:**

- Claude makes a mistake (add to "Common Mistakes" section)
- You establish a new coding pattern or standard
- You discover a helpful debugging technique
- You add new features or modify existing ones

**Remember:**

- Always force-stop app after installing new APK
- Check flutter logs to verify new code is running
- Use `Future.microtask()` for side effects in build method
- Dispose resources in `dispose()` method
- Use `const` constructors for performance
- Handle `DioException` errors properly
