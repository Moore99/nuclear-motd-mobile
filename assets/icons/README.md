# App Icon Generation Instructions

## Required Icon Files

You need to create the following PNG files in the `assets/icons/` folder:

### 1. app_icon.png (1024x1024)
- Main app icon
- Square image with your atom logo
- Used for iOS and as fallback for Android

### 2. app_icon_foreground.png (1024x1024)
- Android adaptive icon foreground
- Should have transparent background
- The icon should be centered with padding (about 66% of the image)
- Android will apply the background color (#1565C0) automatically

### 3. splash_icon.png (512x512 or 1024x1024)
- Splash screen center icon
- White icon on transparent background works best
- Will be displayed on the blue (#1565C0) splash background

## Design Specifications

Based on the SVG in this folder, the icon should be:
- Blue background: #1565C0
- White atom symbol with:
  - 3 elliptical orbits (one horizontal, two at 60° angles)
  - Central nucleus circle
  - 3 electron dots on the orbits

## Quick Option: Use Online Tool

1. Open the `app_icon.svg` file in a browser
2. Take a screenshot or use an SVG to PNG converter
3. Resize to required dimensions
4. Save as PNG files

## Recommended Tools
- Figma (free)
- Canva (free)
- Adobe Illustrator
- GIMP (free)
- Online: https://cloudconvert.com/svg-to-png

## After Creating Icons

Run these commands:

```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create
```
