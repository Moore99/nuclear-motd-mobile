# Check if phone is connected and install APK directly
$APK_PATH = "C:\Projects\nuclear-motd-mobile\build\app\outputs\flutter-apk\app-release.apk"

Write-Host "=== Nuclear MOTD Direct Install ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Checking if phone is connected..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

if ($devices -match "device$") {
    Write-Host "Phone detected!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Step 2: Installing APK..." -ForegroundColor Yellow
    Write-Host "Installing: $APK_PATH" -ForegroundColor Gray
    adb install -r $APK_PATH
    
    Write-Host ""
    Write-Host "Step 3: Launching app..." -ForegroundColor Yellow
    adb shell am start -n com.nuclearmotd.mobile/com.nuclearmotd.mobile.MainActivity
    
    Write-Host ""
    Write-Host "=== DONE! ===" -ForegroundColor Green
    Write-Host "The app should now be running on your phone!" -ForegroundColor Green
} else {
    Write-Host "No phone detected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. Phone is connected via USB"
    Write-Host "  2. USB debugging is enabled"
    Write-Host "  3. You've authorized this computer on your phone"
    Write-Host ""
    Write-Host "To enable USB debugging:" -ForegroundColor Cyan
    Write-Host "  Settings -> About Phone -> Tap 'Build Number' 7 times"
    Write-Host "  Settings -> Developer Options -> Enable 'USB Debugging'"
}
