# Mission Board - Quick Update Setup

## ✅ What's Done

1. **Update Service** - Checks version on app launch
2. **Auto-prompt** - Shows dialog when update available  
3. **Download website** - `web/download.html` ready to deploy
4. **Firestore rules** - Deployed (app_config read access)
5. **APK rebuilt** - With update checking feature

---

## 🚀 Next Steps (Do This Now!)

### Step 1: Upload APK to Firebase Storage

```powershell
# Option A: Firebase CLI
firebase storage:upload build/app/outputs/flutter-apk/app-release.apk /downloads/mission-board-v1.0.0.apk --public

# Option B: Firebase Console (Easier)
# 1. Go to: https://console.firebase.google.com/project/mission-board-b8dbc/storage
# 2. Click "Upload file"
# 3. Select: build/app/outputs/flutter-apk/app-release.apk
# 4. Rename to: mission-board-v1.0.0.apk
# 5. Click file → "Download URL" → Copy it
```

### Step 2: Create Version Document

Go to Firestore Console:
https://console.firebase.google.com/project/mission-board-b8dbc/firestore

1. Create collection: `app_config`
2. Add document ID: `version`
3. Add these fields:

```
latestVersion: "1.0.0" (string)
buildNumber: 1 (number)
downloadUrl: "PASTE_YOUR_DOWNLOAD_URL_HERE" (string)
releaseNotes: "Initial release! Track missions, compete with teams, and level up your productivity 🚀" (string)
forceUpdate: false (boolean)
```

Click "Save"

### Step 3: Deploy Download Website

**Option A: Firebase Hosting**
```powershell
# 1. Edit web/download.html line 96
# Replace: YOUR_APK_DOWNLOAD_URL_HERE
# With: Your Firebase Storage URL

# 2. Deploy
firebase deploy --only hosting

# Your site will be at:
# https://mission-board-b8dbc.web.app/download.html
```

**Option B: GitHub Pages (Free)**
```powershell
# 1. Create new repo: mission-board-download
# 2. Upload web/download.html
# 3. Settings → Pages → Enable
# 4. Share: https://YOURUSERNAME.github.io/mission-board-download/download.html
```

**Option C: Quick Test (Netlify Drop)**
1. Go to: https://app.netlify.com/drop
2. Drag `web/download.html` 
3. Get instant URL
4. Update download URL in file if needed

---

## 🧪 Test Your Setup

### Test Update Flow:

1. **Install current version** (build 1) on Android device
2. **In Firestore**, change `buildNumber` to `2`
3. **Open app** → Should show update dialog! ✨
4. **Click "Update Now"** → Opens download URL
5. **Install new APK** → Done!

### Quick Test Without Device:

```dart
// In lib/services/update_service.dart, temporarily add:
static Future<UpdateInfo?> checkForUpdate() async {
  // Force show update dialog for testing
  return UpdateInfo(
    currentVersion: '1.0.0',
    latestVersion: '1.0.1',
    downloadUrl: 'https://your-url.com/app.apk',
    releaseNotes: 'Test update!',
    forceUpdate: false,
  );
}
```

Run on Chrome: `flutter run -d chrome`

---

## 📦 Future Updates (Easy!)

When you fix bugs or add features:

```powershell
# 1. Update version
# Edit pubspec.yaml line 19:
version: 1.0.1+2  # Changed from 1.0.0+1

# 2. Build new APK
flutter build apk --release

# 3. Upload to Firebase Storage
# Name: mission-board-v1.0.1.apk

# 4. Update Firestore app_config/version:
latestVersion: "1.0.1"
buildNumber: 2  # ← IMPORTANT: Must be higher than before!
downloadUrl: "NEW_URL"
releaseNotes: "Fixed bugs, added new features!"
```

**That's it!** All users automatically get update prompt.

---

## 💰 Cost Breakdown (100% Free!)

- **Firebase Storage**: 5GB free (your APK is 58MB = 86 versions free)
- **Firebase Hosting**: 10GB free bandwidth  
- **Firestore**: 50k reads/day free (plenty for version checks)
- **GitHub Pages**: Unlimited & free
- **Netlify**: 100GB/month free

**Estimated cost for 1000 users/month: $0**

---

## 🎯 Share Your App

Send users to your download website:
- `mission-board-b8dbc.web.app/download.html` (Firebase)
- Or your GitHub Pages URL
- Or custom domain (optional, ~$12/year)

They get:
- ✅ Automatic updates
- ✅ No Play Store needed
- ✅ Direct APK download
- ✅ Installation instructions

---

## ⚡ Pro Tips

**GitHub Releases (Recommended):**
```powershell
git tag v1.0.0
git push origin v1.0.0
# Then: GitHub → Releases → Create Release → Upload APK
# Benefit: Unlimited storage, version history, download stats
```

**Custom Domain:**
```
www.missionboard.app/download
↓
Points to Firebase Hosting or GitHub Pages
$12/year from Namecheap
```

**QR Code for Easy Download:**
```
Use qr-code-generator.com
Input: Your download.html URL
Print QR → Users scan → Instant download!
```

---

Ready to deploy? Run Step 1-3 above and you're live! 🚀

Need help with any step? Let me know!
