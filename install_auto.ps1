# Find ADB and install APK
$APK_PATH = "C:\Projects\nuclear-motd-mobile\build\app\outputs\flutter-apk\app-release.apk"

Write-Host "=== Finding ADB ===" -ForegroundColor Cyan

# Common ADB locations
$adbPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
    "C:\Android\Sdk\platform-tools\adb.exe",
    "C:\Program Files\Android\Android Studio\platform-tools\adb.exe",
    "C:\flutter\bin\cache\artifacts\engine\android-arm-release\adb.exe"
)

$adb = $null
foreach ($path in $adbPaths) {
    if (Test-Path $path) {
        $adb = $path
        Write-Host "Found ADB at: $adb" -ForegroundColor Green
        break
    }
}

if (-not $adb) {
    Write-Host "Could not find ADB automatically." -ForegroundColor Red
    Write-Host ""
    Write-Host "Searching in common locations..." -ForegroundColor Yellow
    
    # Search for adb.exe
    $found = Get-ChildItem -Path "$env:LOCALAPPDATA" -Filter "adb.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $adb = $found.FullName
        Write-Host "Found ADB at: $adb" -ForegroundColor Green
    } else {
        Write-Host "ADB not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please use Flutter's install command instead:" -ForegroundColor Yellow
        Write-Host "  flutter install" -ForegroundColor Cyan
        exit
    }
}

Write-Host ""
Write-Host "=== Checking for connected devices ===" -ForegroundColor Cyan
$devicesOutput = & $adb devices
Write-Host $devicesOutput

if ($devicesOutput -match "device$") {
    Write-Host ""
    Write-Host "Phone detected!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Installing APK..." -ForegroundColor Yellow
    & $adb install -r $APK_PATH
    
    Write-Host ""
    Write-Host "=== SUCCESS! ===" -ForegroundColor Green
    Write-Host "App installed on your phone!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "No phone connected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Connect phone via USB"
    Write-Host "  2. Enable USB debugging"
    Write-Host "  3. Run this script again"
    Write-Host ""
    Write-Host "OR use Flutter command:" -ForegroundColor Yellow
    Write-Host "  flutter install" -ForegroundColor Cyan
}
