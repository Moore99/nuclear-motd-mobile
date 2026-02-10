# Google Play Store Deployment Preparation
# Builds AAB (Android App Bundle) for Play Store upload

Write-Host "=== Google Play Store Deployment Preparation ===" -ForegroundColor Cyan
Write-Host ""

cd C:\Projects\nuclear-motd-mobile

Write-Host "Step 1: Check current version..." -ForegroundColor Yellow
$pubspec = Get-Content pubspec.yaml -Raw
if ($pubspec -match 'version:\s*(\S+)') {
    $currentVersion = $matches[1]
    Write-Host "  Current version: $currentVersion" -ForegroundColor Gray
} else {
    Write-Host "  Could not detect version" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 2: Clean previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "  Cleaned" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Get dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "  Dependencies updated" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Build Android App Bundle (AAB)..." -ForegroundColor Yellow
Write-Host "  This will take a few minutes..." -ForegroundColor Gray
flutter build appbundle --release
Write-Host ""

if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
    $aabFile = Get-Item "build\app\outputs\bundle\release\app-release.aab"
    Write-Host "  SUCCESS: AAB built!" -ForegroundColor Green
    Write-Host "  Location: $($aabFile.FullName)" -ForegroundColor Cyan
    Write-Host "  Size: $([math]::Round($aabFile.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Step 5: Copy AAB to desktop for easy access..." -ForegroundColor Yellow
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $destFile = "$desktopPath\nuclear-motd-release.aab"
    Copy-Item $aabFile.FullName $destFile -Force
    Write-Host "  Copied to: $destFile" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "  ERROR: AAB file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps for Google Play Console:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. GO TO: https://play.google.com/console" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. CREATE APP (if not already created):" -ForegroundColor Yellow
Write-Host "   - App name: Nuclear MOTD" -ForegroundColor Gray
Write-Host "   - Default language: English (Canada)" -ForegroundColor Gray
Write-Host "   - App or game: App" -ForegroundColor Gray
Write-Host "   - Free or paid: Free" -ForegroundColor Gray
Write-Host ""
Write-Host "3. COMPLETE APP CONTENT:" -ForegroundColor Yellow
Write-Host "   - Privacy Policy URL: https://nuclear-motd.com/privacy" -ForegroundColor Gray
Write-Host "   - App category: Business or Productivity" -ForegroundColor Gray
Write-Host "   - Content rating: Complete questionnaire" -ForegroundColor Gray
Write-Host "   - Target audience: Professionals (18+)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. SET UP INTERNAL TESTING:" -ForegroundColor Yellow
Write-Host "   - Testing > Internal testing > Create new release" -ForegroundColor Gray
Write-Host "   - Upload the AAB file from your desktop:" -ForegroundColor Gray
Write-Host "     $destFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. ADD INTERNAL TESTERS:" -ForegroundColor Yellow
Write-Host "   - Create an email list (e.g., 'Nuclear MOTD Team')" -ForegroundColor Gray
Write-Host "   - Add tester emails:" -ForegroundColor Gray
Write-Host "     * Your email" -ForegroundColor Gray
Write-Host "     * Team members" -ForegroundColor Gray
Write-Host ""
Write-Host "6. TESTERS WILL RECEIVE:" -ForegroundColor Yellow
Write-Host "   - Invitation link via email" -ForegroundColor Gray
Write-Host "   - Can install via Google Play Store" -ForegroundColor Gray
Write-Host "   - Updates automatically from Play Store" -ForegroundColor Gray
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "  - AAB file is required (not APK)" -ForegroundColor Yellow
Write-Host "  - Version code must increment for each upload" -ForegroundColor Yellow
Write-Host "  - All app content sections must be complete before production" -ForegroundColor Yellow
Write-Host ""
