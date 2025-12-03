# Release Notes & Notifications System

## 📝 How It Works

When you release a new version:
1. **Update app_config/version** in Firestore
2. **Create release_notes document** with detailed changes
3. **System automatically notifies all users** in-app
4. Users see update prompt with release notes

---

## 🚀 Release Process (Step by Step)

### 1. Update Version in Code

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # version+buildNumber
```

### 2. Build New APK

```powershell
flutter build apk --release
```

### 3. Create GitHub Release

```powershell
git add .
git commit -m "v1.0.1 - Added new features"
git tag v1.0.1
git push origin main
git push origin v1.0.1
```

Upload APK to: https://github.com/chromex21/mission-board/releases/new?tag=v1.0.1

Get download URL:
```
https://github.com/chromex21/mission-board/releases/download/v1.0.1/mission-board-v1.0.1.apk
```

### 4. Update Firestore Documents

#### A. Update Version Document

Firestore → `app_config` → `version`:
```json
{
  "latestVersion": "1.0.1",
  "buildNumber": 2,
  "downloadUrl": "https://github.com/chromex21/mission-board/releases/download/v1.0.1/mission-board-v1.0.1.apk",
  "releaseNotes": "Bug fixes and performance improvements",
  "forceUpdate": false
}
```

#### B. Create Release Notes Document

Firestore → `release_notes` → Document ID: `2` (same as buildNumber):
```json
{
  "version": "1.0.1",
  "buildNumber": 2,
  "releaseDate": "December 3, 2025",
  "features": [
    "Added dark mode theme",
    "New achievement system",
    "Team chat improvements"
  ],
  "improvements": [
    "Faster mission loading",
    "Better notification handling",
    "Improved UI responsiveness"
  ],
  "bugFixes": [
    "Fixed crash on mission completion",
    "Fixed team invite notifications",
    "Fixed profile image upload"
  ],
  "critical": false
}
```

### 5. Notify All Users (Optional - Manual)

Run this in Firebase Console Functions or manually:

```javascript
// Cloud Function to notify all users
const admin = require('firebase-admin');

async function notifyAllUsers() {
  const usersSnapshot = await admin.firestore().collection('users').get();
  const batch = admin.firestore().batch();
  
  usersSnapshot.forEach((userDoc) => {
    const notificationRef = admin.firestore().collection('notifications').doc();
    batch.set(notificationRef, {
      userId: userDoc.id,
      type: 'release',
      title: '🎉 New Version Available!',
      body: 'Version 1.0.1 is now available with new features!',
      data: {
        version: '1.0.1',
        buildNumber: 2
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
}
```

---

## 🔔 What Users See

### On App Launch:
1. **Update Dialog** appears automatically
2. Shows version number and summary
3. Button to view full release notes
4. "Update Now" button downloads APK

### In Notifications Tab:
- Red badge appears on notifications icon
- "🎉 New Version Available!" notification
- Click opens update dialog

---

## 📋 Release Notes Template

Copy this for each release:

### Firestore `release_notes/{buildNumber}`:

```json
{
  "version": "1.0.X",
  "buildNumber": X,
  "releaseDate": "Month Day, Year",
  "features": [
    "New feature 1",
    "New feature 2"
  ],
  "improvements": [
    "Improvement 1",
    "Improvement 2"
  ],
  "bugFixes": [
    "Fixed bug 1",
    "Fixed bug 2"
  ],
  "critical": false
}
```

**Fields:**
- `features`: ✨ New functionality added
- `improvements`: 🔧 Existing features made better
- `bugFixes`: 🐛 Problems that were solved
- `critical`: Set to `true` for security updates (forces update)

---

## 🎯 Quick Release Checklist

- [ ] Update `pubspec.yaml` version
- [ ] Build APK: `flutter build apk --release`
- [ ] Create GitHub release + upload APK
- [ ] Update Firestore `app_config/version`
- [ ] Create Firestore `release_notes/{buildNumber}`
- [ ] Test on device
- [ ] Share update on social media

---

## 💡 Pro Tips

**Semantic Versioning:**
- `1.0.0` → `1.0.1` = Bug fixes (patch)
- `1.0.0` → `1.1.0` = New features (minor)
- `1.0.0` → `2.0.0` = Breaking changes (major)

**Build Number:**
- Always increment by 1
- Never skip numbers
- Used for version comparison (not visible to users)

**Force Update:**
- Set `forceUpdate: true` for critical security fixes
- Users cannot dismiss the dialog
- Use sparingly

**Release Frequency:**
- Bug fixes: As needed (within days)
- New features: Every 2-4 weeks
- Major updates: Every 2-3 months

---

## 📊 Track Adoption

Check how many users updated:

```dart
// In admin panel, query users by app version
FirebaseFirestore.instance
  .collection('users')
  .where('appVersion', isLessThan: '1.0.1')
  .get();
```

Save user's app version on login:
```dart
final packageInfo = await PackageInfo.fromPlatform();
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'appVersion': packageInfo.version});
```

---

## 🚨 Emergency Hotfix

For critical bugs:

1. Increment patch version: `1.0.1` → `1.0.2`
2. Set `forceUpdate: true` in Firestore
3. Set `critical: true` in release notes
4. Users MUST update before continuing

---

## Example: Full Release v1.0.1

**app_config/version:**
```json
{
  "latestVersion": "1.0.1",
  "buildNumber": 2,
  "downloadUrl": "https://github.com/chromex21/mission-board/releases/download/v1.0.1/mission-board-v1.0.1.apk",
  "releaseNotes": "Performance improvements and bug fixes",
  "forceUpdate": false
}
```

**release_notes/2:**
```json
{
  "version": "1.0.1",
  "buildNumber": 2,
  "releaseDate": "December 3, 2025",
  "features": [
    "Added swipe gestures for mission cards",
    "New profile customization options",
    "Export mission history to CSV"
  ],
  "improvements": [
    "50% faster mission loading",
    "Smoother animations",
    "Reduced app size by 10MB"
  ],
  "bugFixes": [
    "Fixed crash when uploading large images",
    "Fixed notification sound not playing",
    "Fixed team chat scroll issue"
  ],
  "critical": false
}
```

---

Your release system is ready! 🎉
