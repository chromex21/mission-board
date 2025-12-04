#!/usr/bin/env pwsh
# Build APK script for Mission Board

Write-Host "Starting APK build..."
Write-Host "Current directory: $(Get-Location)"

# Ensure we're in the right directory
Set-Location "C:\Users\chrom\Videos\mission_board"

# Run flutter build with no prompts
& flutter build apk --release --no-pub

Write-Host "Build complete!"

# Check for APK
$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host "APK created successfully at: $apkPath"
    Write-Host "File size: $(((Get-Item $apkPath).Length / 1MB).ToString('F2')) MB"
} else {
    Write-Host "APK not found. Check build output above for errors."
}
