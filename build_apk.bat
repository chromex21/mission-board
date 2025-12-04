@echo off
cd /d c:\Users\chrom\Videos\mission_board
echo Starting APK build...
call flutter build apk --release --no-pub 2>&1
echo.
echo Build finished. Checking for APK...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo SUCCESS: APK created!
    for %%I in ("build\app\outputs\flutter-apk\app-release.apk") do echo Size: %%~zI bytes
) else (
    echo ERROR: APK not found
)
pause
