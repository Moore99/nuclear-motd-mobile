# Nuclear MOTD Mobile App

A Flutter mobile application for the Nuclear Message of the Day platform.

## Features

- 📱 Daily messages curated for the nuclear industry
- 🏷️ Subscribe to topics of interest
- 🔔 Push notifications for new messages
- 📚 Bookmark favorite messages
- 🔍 Search through message history
- 📤 Share messages with colleagues
- 🌙 Dark mode support
- 📶 Offline mode with caching
- 🎯 Onboarding for new users

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- Android Studio / Xcode
- Firebase project (for push notifications)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/nuclear-motd-mobile.git
cd nuclear-motd-mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a Firebase project
   - Add Android app with package name: `com.nuclearmotd.app`
   - Add iOS app with bundle ID: `com.nuclearmotd.app`
   - Download and place config files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. Run the app:
```bash
flutter run
```

## Building for Release

### Android

1. **Generate a keystore** (one-time):
```bash
keytool -genkey -v -keystore android/nuclear-motd-release.keystore -alias nuclear_motd -keyalg RSA -keysize 2048 -validity 10000
```

2. **Create key.properties**:
```bash
cp android/key.properties.template android/key.properties
# Edit key.properties with your keystore details
```

3. **Build APK**:
```bash
flutter build apk --release --dart-define=ENVIRONMENT=production
```

4. **Build App Bundle** (for Play Store):
```bash
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS

1. **Configure signing in Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target → Signing & Capabilities
   - Set your Team and Bundle Identifier

2. **Add Push Notifications capability**:
   - In Signing & Capabilities, add "Push Notifications"
   - Add "Background Modes" → check "Remote notifications"

3. **Build**:
```bash
flutter build ios --release --dart-define=ENVIRONMENT=production
```

4. **Archive and distribute**:
   - In Xcode: Product → Archive
   - Distribute App → App Store Connect

### Windows

```bash
flutter build windows --release --dart-define=ENVIRONMENT=production
```

## Environment Configuration

The app supports multiple environments via dart-define:

```bash
# Development (default)
flutter run

# Staging
flutter run --dart-define=ENVIRONMENT=staging --dart-define=STAGING_URL=https://staging.nuclear-motd.com/api

# Production
flutter run --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://nuclear-motd.com/api
```

## Project Structure

```
lib/
├── core/
│   ├── cache/          # Offline caching
│   ├── config/         # App configuration
│   ├── network/        # API client
│   ├── router/         # Navigation
│   ├── services/       # Push notifications, bookmarks, etc.
│   └── theme/          # App theming
├── features/
│   ├── auth/           # Login, signup, password reset
│   ├── bookmarks/      # Saved messages
│   ├── home/           # Dashboard
│   ├── messages/       # Message list and detail
│   ├── onboarding/     # First-time user experience
│   ├── profile/        # User profile and settings
│   ├── search/         # Message search
│   ├── shared/         # Shared widgets
│   ├── splash/         # Splash screen
│   └── topics/         # Topic management
└── main.dart
```

## App Icons and Splash Screen

1. Create PNG icons in `assets/icons/`:
   - `app_icon.png` (1024x1024)
   - `app_icon_foreground.png` (1024x1024, transparent)
   - `splash_icon.png` (512x512, transparent)

2. Generate icons:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## License

Copyright © 2024 Kernkraft Consulting Inc. All rights reserved.

## Support

- Website: https://nuclear-motd.com
- Email: support@nuclear-motd.com
