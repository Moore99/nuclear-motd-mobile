@echo off
REM Build script for Nuclear MOTD Android release
REM Usage: build_android.bat [apk|appbundle]

setlocal

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=appbundle

echo ========================================
echo Building Nuclear MOTD for Android
echo Build type: %BUILD_TYPE%
echo ========================================

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean

REM Get dependencies
echo Getting dependencies...
call flutter pub get

REM Build based on type
if "%BUILD_TYPE%"=="apk" (
    echo Building APK...
    call flutter build apk --release --dart-define=ENVIRONMENT=production
    echo.
    echo APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo Building App Bundle...
    call flutter build appbundle --release --dart-define=ENVIRONMENT=production
    echo.
    echo App Bundle built successfully!
    echo Location: build\app\outputs\bundle\release\app-release.aab
)

echo.
echo ========================================
echo Build complete!
echo ========================================

endlocal
