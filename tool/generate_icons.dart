// Run this script to generate app icons
// Usage: dart run tool/generate_icons.dart

void main() {
  print('''
========================================
App Icon Generation
========================================

Since Dart doesn't have built-in image generation without Flutter,
please create the following icons manually:

1. assets/icons/app_icon.png (1024x1024)
   - Blue background (#1565C0)
   - White atom symbol

2. assets/icons/app_icon_foreground.png (1024x1024)
   - Transparent background
   - White atom symbol (centered with padding)

3. assets/icons/splash_icon.png (512x512)
   - Transparent background
   - White atom symbol

Use the SVG file at assets/icons/app_icon.svg as reference.

Quick option: Use https://cloudconvert.com/svg-to-png to convert the SVG.

After creating the icons, run:
  flutter pub run flutter_launcher_icons
  flutter pub run flutter_native_splash:create
========================================
''');
}
