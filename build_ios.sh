#!/bin/bash
# Build script for Nuclear MOTD iOS release
# Usage: ./build_ios.sh

echo "========================================"
echo "Building Nuclear MOTD for iOS"
echo "========================================"

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

# Build iOS
echo "Building iOS archive..."
flutter build ios --release --dart-define=ENVIRONMENT=production

echo ""
echo "========================================"
echo "iOS build complete!"
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device' as build target"
echo "3. Product -> Archive"
echo "4. Distribute to App Store Connect"
echo "========================================"
