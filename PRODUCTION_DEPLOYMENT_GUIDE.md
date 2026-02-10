# Nuclear MOTD - Production Deployment Guide

## 📋 Pre-Deployment Checklist

### Backend
- [ ] Production environment variables configured (`.env.production`)
- [ ] Database migrations applied
- [ ] AWS SES email service configured and verified
- [ ] SSL/TLS certificates installed
- [ ] Backup strategy in place

### Mobile App
- [ ] All features tested and working
- [ ] API endpoints point to production backend
- [ ] App signing keys generated
- [ ] App icons and splash screens configured
- [ ] Privacy policy and terms of service URLs updated
- [ ] Version numbers updated

---

## 🔧 Backend Production Deployment

### 1. Prepare Production Environment

```bash
# Navigate to backend project
cd C:\Projects\nuclear-motd

# Ensure .env.production is configured
# Check these critical settings:
# - DATABASE_URL
# - SECRET_KEY (strong, unique)
# - AWS_SES credentials
# - FRONTEND_URL (your production domain)
```

### 2. Deploy to Production Server

```bash
# Option 1: Using existing deploy script
./deploy-vultr-canada.sh

# Option 2: Manual Docker deployment
docker-compose -f docker-compose.yml up -d --build

# Option 3: Direct Python deployment
python run_production.py
```

### 3. Verify Backend

```bash
# Check API health
curl https://your-domain.com/api/health

# Test authentication endpoint
curl https://your-domain.com/api/auth/login

# Verify database connection
python verify_production_pagination.py
```

---

## 📱 Android App Production

### Step 1: Generate Release Signing Key

```bash
cd C:\Projects\nuclear-motd-mobile\android\app

# Generate keystore (do this ONCE and keep it SAFE!)
keytool -genkey -v -keystore nuclear-motd-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias nuclear-motd

# You'll be asked for:
# - Keystore password (choose strong password)
# - Key password (can be same as keystore password)
# - Your name, organization, etc.
```

**⚠️ CRITICAL:** Back up `nuclear-motd-release-key.jks` securely! You cannot update your app without it.

### Step 2: Configure Signing

Create `C:\Projects\nuclear-motd-mobile\android\key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=nuclear-motd
storeFile=nuclear-motd-release-key.jks
```

**⚠️ Add to .gitignore:**
```bash
# Add these lines to .gitignore
android/key.properties
android/app/nuclear-motd-release-key.jks
```

### Step 3: Update Production API URL

Update `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Change this to your production URL
  static const String apiBaseUrl = 'https://your-production-domain.com';
  
  // ... rest of config
}
```

### Step 4: Build Release APK

```bash
cd C:\Projects\nuclear-motd-mobile

# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build App Bundle for Play Store (recommended)
flutter build appbundle --release
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Step 5: Test Release Build

```bash
# Install on physical device
flutter install --release

# Test all features:
# - Login/Registration
# - Message viewing
# - Schedule changes
# - Content submission
# - Push notifications
```

---

## 🍎 iOS App Production

### Step 1: Apple Developer Account

1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. Create App ID in Developer Console
3. Generate certificates and provisioning profiles

### Step 2: Configure Xcode

```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Runner target
# 2. Update Bundle Identifier: com.nuclearmotd.app
# 3. Update Version: 1.0.0
# 4. Update Build: 1
# 5. Set Team (your Apple Developer account)
# 6. Configure Signing & Capabilities
```

### Step 3: Configure Push Notifications

1. In Xcode: Runner → Signing & Capabilities → Add "Push Notifications"
2. In Apple Developer Console:
   - Create APNs Key
   - Download and configure in Firebase

### Step 4: Build for iOS

```bash
# Build iOS release
flutter build ios --release

# Or build for TestFlight/App Store
flutter build ipa --release
```

---

## 🚀 Google Play Store Submission

### 1. Create Google Play Console Account

- Go to [Google Play Console](https://play.google.com/console)
- Pay one-time $25 registration fee
- Complete account setup

### 2. Create App Listing

**Store Listing:**
- App name: Nuclear MOTD
- Short description: Daily nuclear industry messages
- Full description:
  ```
  Nuclear MOTD delivers daily curated messages about nuclear safety, 
  regulations, best practices, and industry updates. Stay informed 
  with personalized content tailored to your interests.
  
  Features:
  - Daily curated messages
  - Customizable schedule
  - Multiple topic categories
  - Bookmark important content
  - Submit your own insights
  ```

**Required Assets:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 (phone), 7-inch and 10-inch tablet recommended
- Privacy policy URL
- Content rating questionnaire

### 3. Upload App Bundle

```bash
# Build production app bundle
flutter build appbundle --release

# Upload build/app/outputs/bundle/release/app-release.aab
# to Google Play Console → Production → Create new release
```

### 4. Complete Release

- Fill in release notes
- Set countries/regions
- Set pricing (free)
- Submit for review (typically takes 1-3 days)

---

## 🍎 Apple App Store Submission

### 1. Create App Store Connect Account

- Use your Apple Developer account
- Go to [App Store Connect](https://appstoreconnect.apple.com)

### 2. Create App Record

- Click "+" to add new app
- Bundle ID: com.nuclearmotd.app
- Name: Nuclear MOTD
- Primary Language: English
- SKU: nuclearmotd001

### 3. Prepare App Information

**Required:**
- App description
- Keywords
- Support URL
- Privacy Policy URL
- App Category: Productivity or News
- Content Rights
- Age Rating

**Screenshots Required:**
- iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796
- iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688
- iPad Pro 12.9": 2048 x 2732

### 4. Upload Build via Xcode

```bash
# Archive the app
# In Xcode: Product → Archive
# When archive completes: Window → Organizer
# Select archive → Distribute App → App Store Connect
# Upload
```

### 5. Submit for Review

- Select build in App Store Connect
- Fill in "What's New" text
- Submit for review (typically 24-48 hours)

---

## 🔔 Push Notifications Setup

### Android (FCM)

Already configured! Just verify:
- `google-services.json` in `android/app/`
- Firebase project created
- Cloud Messaging enabled

### iOS (APNs)

1. **Create APNs Key:**
   - Apple Developer → Certificates, IDs & Profiles
   - Keys → Create new key
   - Enable Apple Push Notifications service
   - Download and note Key ID

2. **Upload to Firebase:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Upload APNs Auth Key
   - Enter Key ID and Team ID

3. **Add Capability in Xcode:**
   - Runner → Signing & Capabilities
   - Click "+ Capability"
   - Add "Push Notifications"

---

## 📊 Analytics & Monitoring

### Recommended Services

1. **Google Analytics for Firebase**
   - Already integrated via `firebase_core`
   - Track user engagement, retention

2. **Crashlytics**
   - Add `firebase_crashlytics` package
   - Monitor app crashes in production

3. **Sentry** (Alternative)
   - Add `sentry_flutter` package
   - Real-time error tracking

---

## 🔒 Security Checklist

- [ ] API keys not hardcoded (use environment variables)
- [ ] SSL/TLS enabled on backend
- [ ] Input validation on all forms
- [ ] Rate limiting on API endpoints
- [ ] Secure storage for auth tokens
- [ ] ProGuard enabled for Android release
- [ ] Code obfuscation enabled
- [ ] Debug logging disabled in production

---

## 📝 Post-Launch Checklist

### Day 1
- [ ] Monitor crash reports
- [ ] Check server logs for errors
- [ ] Verify push notifications working
- [ ] Test user registration flow
- [ ] Monitor API response times

### Week 1
- [ ] Review user feedback
- [ ] Check analytics data
- [ ] Monitor server load
- [ ] Review database performance
- [ ] Check email delivery rates

### Month 1
- [ ] Analyze user retention
- [ ] Review feature usage
- [ ] Plan updates based on feedback
- [ ] Optimize performance bottlenecks

---

## 🔄 Update Process

### For Updates/Bug Fixes

1. **Update Version:**
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2  # Increment build number (+2)
   ```

2. **Build New Release:**
   ```bash
   flutter build appbundle --release  # Android
   flutter build ipa --release         # iOS
   ```

3. **Upload to Stores:**
   - Google Play: Upload new AAB
   - App Store: Archive and upload via Xcode

4. **Write Release Notes:**
   - Be specific about fixes/features
   - Keep it user-friendly

---

## 🆘 Troubleshooting

### Common Issues

**Build fails:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Signing issues (Android):**
- Verify key.properties path is correct
- Check keystore passwords
- Ensure keystore file exists

**iOS code signing:**
- Check Team is selected in Xcode
- Verify Bundle ID matches App ID
- Regenerate provisioning profiles if needed

**APNs not working:**
- Verify Push Notifications capability added
- Check APNs key uploaded to Firebase
- Test with physical device (push doesn't work on simulator)

---

## 📞 Support Resources

- Flutter Docs: https://docs.flutter.dev
- Play Console Help: https://support.google.com/googleplay/android-developer
- App Store Connect Help: https://developer.apple.com/support/app-store-connect/
- Firebase Docs: https://firebase.google.com/docs

---

## ✅ Final Pre-Launch Verification

```bash
# Run this command to check everything
flutter doctor -v

# Should show:
# ✓ Flutter (Channel stable)
# ✓ Android toolchain
# ✓ Xcode (for iOS)
# ✓ Android Studio / VS Code
# ✓ Connected device
```

**Ready to launch!** 🚀
