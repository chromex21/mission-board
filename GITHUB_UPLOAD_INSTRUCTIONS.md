# GitHub Release Upload Instructions

## ✅ Status: Ready to Upload

### Files Built Successfully
- ✅ APK built: `build\app\outputs\flutter-apk\app-release.apk`
- ✅ Size: 57.9 MB (60,684,030 bytes)
- ✅ Version: 1.2.0 (Build 2)
- ✅ Git commit pushed to main
- ✅ Git tag v1.2.0 created and pushed

## 📤 Upload to GitHub Releases

### Step 1: Go to GitHub Releases Page
1. Open: https://github.com/chromex21/mission-board/releases
2. Click **"Draft a new release"** button

### Step 2: Configure Release
Fill in the following:

**Tag version**: `v1.2.0` (should already exist)

**Release title**: `Version 1.2.0 - Enhanced UI & Chat Fixes`

**Description**: Copy from `GITHUB_RELEASE_NOTES.md` or use this:

```
## 🎉 What's New

### Messaging System Fixed ✅
- Messages now persist correctly after sending
- Fixed Firestore security rules field name mismatch

### Automatic Message Cleanup 🧹
- Lobby messages clean up after 12 hours automatically

### Interactive User Profiles 👤
- Click messages to view user profiles
- Click active users to view profiles

### Universal Theme Support 🎨
- Light/Dark theme works across ALL screens
- Fixed white screen bug in achievements

### Improved Mobile UI 📱
- Active users button moved to bottom-left
- Compact pill-shaped design

### Check for Updates 🔄
- Manual update check in Settings > App Info

## 📦 Installation

Download `app-release.apk` below and install on Android device.

Web version: https://mission-board-b8dbc.web.app

## 🐛 Bug Fixes
- Messages disappearing after sending
- White screen on achievements navigation
- Theme not applying universally

Full changelog: [VERSION_1.2.0_CHANGELOG.md](https://github.com/chromex21/mission-board/blob/main/VERSION_1.2.0_CHANGELOG.md)
```

### Step 3: Upload APK
1. In the **"Attach binaries"** section
2. Click to browse or drag and drop
3. Upload: `C:\Users\chrom\Videos\mission_board\build\app\outputs\flutter-apk\app-release.apk`
4. Wait for upload to complete (57.9 MB)

### Step 4: Publish Release
1. ✅ Check **"Set as the latest release"**
2. Click **"Publish release"** button

## 🌐 Update Firebase Config (Optional)

To enable the "Check for Updates" feature to notify users:

1. Go to Firebase Console: https://console.firebase.google.com/project/mission-board-b8dbc/firestore
2. Navigate to Firestore Database
3. Collection: `app_config`
4. Document: `version`
5. Update/Create with:

```json
{
  "latestVersion": "1.2.0",
  "buildNumber": 2,
  "downloadUrl": "https://github.com/chromex21/mission-board/releases/download/v1.2.0/app-release.apk",
  "releaseNotes": "Enhanced UI with universal theme support, chat fixes, and improved mobile experience.",
  "forceUpdate": false
}
```

## ✅ Verification Checklist

After uploading:
- [ ] Release visible at https://github.com/chromex21/mission-board/releases
- [ ] APK downloadable from release page
- [ ] Release marked as "Latest"
- [ ] Tag v1.2.0 linked correctly
- [ ] Download link works: `https://github.com/chromex21/mission-board/releases/download/v1.2.0/app-release.apk`

## 📱 Testing the Release

1. Download APK from GitHub release
2. Install on Android device
3. Open app and check version in Settings > App Info
4. Should show "Version 1.2.0"
5. Test "Check for Updates" - should say "Up to Date"

## 🎯 Next Steps

After release is published:
1. Share download link with users
2. Update Firebase config for update notifications
3. Monitor for any issues
4. Prepare for next version (1.3.0)

---

**Release URL** (after publishing): https://github.com/chromex21/mission-board/releases/tag/v1.2.0
**APK Direct Link** (after publishing): https://github.com/chromex21/mission-board/releases/download/v1.2.0/app-release.apk
