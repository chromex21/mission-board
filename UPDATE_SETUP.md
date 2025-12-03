# Mission Board - Self-Updating Setup Guide

## 🚀 Quick Setup

### 1. Upload APK to Firebase Storage

```bash
# Using Firebase CLI
firebase storage:upload build/app/outputs/flutter-apk/app-release.apk /downloads/mission-board-v1.0.0.apk

# Or manually via Firebase Console:
# 1. Go to Firebase Console > Storage
# 2. Create folder: downloads
# 3. Upload: app-release.apk
# 4. Make it public (or use signed URLs)
# 5. Copy download URL
```

### 2. Create Version Document in Firestore

In Firebase Console > Firestore:

```
Collection: app_config
Document: version

Fields:
{
  "latestVersion": "1.0.0",
  "buildNumber": 1,
  "downloadUrl": "YOUR_FIREBASE_STORAGE_URL_HERE",
  "releaseNotes": "Initial release with missions, teams, and chat!",
  "forceUpdate": false
}
```

### 3. Update Firestore Security Rules

Add to `firestore.rules`:

```
match /app_config/{document} {
  allow read: if true;  // Anyone can check version
  allow write: if request.auth != null && 
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

### 4. Host Download Website

**Option A: Firebase Hosting (Free)**
```bash
# Update web/download.html with your APK URL
firebase deploy --only hosting
# Your site: https://mission-board-b8dbc.web.app/download.html
```

**Option B: GitHub Pages (Free)**
1. Create GitHub repo
2. Upload `web/download.html`
3. Enable GitHub Pages in Settings
4. Share: `https://yourusername.github.io/mission-board/download.html`

**Option C: Netlify Drop (Free)**
1. Go to https://app.netlify.com/drop
2. Drag `web/download.html`
3. Get instant URL

### 5. Update Your APK (Future Releases)

When releasing v1.0.1:

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2  # version+buildNumber

# 2. Build new APK
flutter build apk --release

# 3. Upload to Firebase Storage
# Name it: mission-board-v1.0.1.apk

# 4. Update Firestore app_config/version:
{
  "latestVersion": "1.0.1",
  "buildNumber": 2,  # ← Must increment!
  "downloadUrl": "NEW_URL",
  "releaseNotes": "Bug fixes and new features!",
  "forceUpdate": false  # true = users MUST update
}
```

**That's it!** All users will see update prompt on next app launch.

---

## 🎯 How It Works

1. **User opens app** → `UpdateService.checkForUpdate()` runs
2. **Compares** local buildNumber (1) vs Firestore buildNumber (2)
3. **If newer exists** → Shows dialog with release notes
4. **User clicks "Update"** → Opens download URL in browser
5. **User installs** → Done! (Android allows direct APK install)

---

## 📱 Android Installation Guide (For Users)

**First Time:**
1. Download APK from your website
2. Android shows "Blocked by Play Protect"
3. Click "Install anyway" or "More details" → "Install anyway"
4. Go to Settings → Enable "Install from Unknown Sources" for your browser
5. Install the app

**Updates:**
- App shows update dialog automatically
- Click "Update Now"
- Downloads new APK
- Install (no need to enable Unknown Sources again)
- Done!

---

## 💡 Pro Tips

**Free APK Hosting Options:**
- Firebase Storage: 5GB free
- GitHub Releases: Unlimited (use releases page)
- Google Drive: Share link (set to "Anyone with link")
- Dropbox: Public folder link
- Your own server/VPS

**GitHub Releases Method (Recommended):**
```bash
# 1. Tag release
git tag v1.0.0
git push origin v1.0.0

# 2. Go to GitHub → Releases → Create Release
# 3. Upload app-release.apk
# 4. Copy download URL to Firestore
```

**Force Update Example:**
```json
{
  "forceUpdate": true,
  "releaseNotes": "Critical security update - please update immediately"
}
```
→ Users cannot dismiss dialog, must update

---

## 🔒 Security Notes

- APK is signed with your keystore (already done)
- Users see "Developer: Unknown" (normal for non-Play Store)
- Consider code signing certificate ($99/year) for "Verified Developer"
- Firebase rules prevent unauthorized version changes (admin only)

---

## 📊 Optional: Add Analytics

Track downloads and update rates:

```dart
// In update_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

static Future<void> _downloadAndInstall(String url) async {
  // Log update event
  FirebaseAnalytics.instance.logEvent(
    name: 'app_update_initiated',
    parameters: {'version': updateInfo.latestVersion},
  );
  
  // ...existing code...
}
```

---

## ❓ FAQ

**Q: Can I use this for iOS?**
A: iOS doesn't allow APK installation. You'd need TestFlight (free) or Enterprise Certificate ($299/year).

**Q: Will this work on web?**
A: Web auto-updates when you redeploy. No manual process needed.

**Q: How do I test updates?**
A: Change buildNumber in Firestore to 999. Your app will show update prompt.

**Q: What if Firebase Storage is full?**
A: Use GitHub Releases (unlimited) or delete old APK versions.

**Q: Can users install without "Unknown Sources"?**
A: No, it's required for non-Play Store apps. But only needed once.

---

Ready to deploy? Let me know if you need help with any step!
