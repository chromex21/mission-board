# Firebase Setup Guide - Mission Board

## ✅ What You Already Have

Your Firebase project is already configured:
- **Project ID**: `mission-board-b8dbc`
- **Authentication**: Enabled (Email/Password)
- **Firestore Database**: Created
- **Web App**: Configured

## 🔧 What Needs to Be Done

### Step 1: Deploy Firestore Rules

The app now has rules for comments, attachments, and teams. Deploy them:

```bash
# Install Firebase CLI if you haven't
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy the new rules
firebase deploy --only firestore:rules
```

### Step 2: Deploy Firestore Indexes

Comments and attachments need composite indexes to work:

```bash
# Deploy indexes
firebase deploy --only firestore:indexes
```

**OR** manually create indexes in Firebase Console:
1. Go to https://console.firebase.google.com/project/mission-board-b8dbc/firestore/indexes
2. Click "Add Index"
3. For **comments** collection:
   - Collection ID: `comments`
   - Field 1: `missionId` (Ascending)
   - Field 2: `createdAt` (Ascending)
   - Query scope: Collection
4. For **attachments** collection:
   - Collection ID: `attachments`
   - Field 1: `missionId` (Ascending)
   - Field 2: `createdAt` (Ascending)
   - Query scope: Collection

**Index building takes 5-15 minutes**

### Step 3: Verify Everything Works

After indexes are built:
1. Open a mission detail screen
2. Click "Comments" tab - should show empty state (not error)
3. Add a comment - should work
4. Click "Files" tab - should show empty state (not error)
5. Add a file URL - should work

## 💰 Firebase Free Tier Limits (Spark Plan)

### What You Get for FREE:

**Authentication:**
- ✅ Unlimited email/password authentications
- ✅ 10,000 phone auth verifications/month (not using)

**Firestore Database:**
- ✅ 1 GB storage
- ✅ 10 GB/month bandwidth (read/write)
- ✅ 50,000 reads/day
- ✅ 20,000 writes/day
- ✅ 20,000 deletes/day

**Hosting (if you deploy web):**
- ✅ 10 GB storage
- ✅ 360 MB/day bandwidth

**Cloud Functions:**
- ❌ NOT available on free tier (but you're not using them)

**Storage (Firebase Storage for files):**
- ❌ NOT available on free tier (but you're using URL links instead)

### 📊 Estimating Your Usage

For **testing with friends** (10-20 users):

**Daily Operations (typical):**
- Login: ~20 authentications/day
- View missions: ~500 reads/day
- Accept/complete missions: ~50 writes/day
- Comments: ~100 writes/day, ~200 reads/day
- Attachments: ~20 writes/day, ~50 reads/day

**Total Daily:**
- ~750 reads (well under 50,000 limit)
- ~170 writes (well under 20,000 limit)

**You're SAFE on the free tier** for development and friend testing! 🎉

### 🚨 When You'd Need to Upgrade (Blaze/Pay-as-you-go):

- More than **200 active users daily**
- Storing large files (need Firebase Storage)
- Need Cloud Functions for automation
- Need more than 1GB database storage

### 💡 Tips to Stay Within Free Limits:

1. ✅ **Use URL links** for attachments (already doing this!)
2. ✅ **Paginate data** - Don't load all missions at once (already doing this!)
3. ✅ **Cache data locally** - Flutter caches Firestore data automatically
4. ✅ **Limit real-time listeners** - Only on active screens (already doing this!)

## 🔐 Current Features Using Firebase:

### ✅ Already Working:
- User authentication (email/password)
- User profiles (display name, country, stats)
- Missions (create, view, assign, complete)
- Teams (create, join, view)
- Leaderboard (real-time rankings)

### 🆕 Now Will Work (after index deployment):
- **Comments** - Discuss missions with team
- **Attachments** - Share file links (screenshots, docs, etc.)

## 🎯 Features NOT Using Firebase (Local Only):

None! Everything is cloud-synced.

## 📱 APK Build Considerations

When building for Android:
1. ✅ `google-services.json` is already in `android/app/`
2. ✅ Firebase is configured in `firebase.json`
3. ✅ All dependencies are in `pubspec.yaml`

Just build normally:
```bash
flutter build apk --release
```

## 🆘 Troubleshooting

### "Error loading comments/attachments"

**If you see this BEFORE deploying indexes:**
- Normal! Indexes aren't built yet
- Deploy indexes (Step 2 above)
- Wait 5-15 minutes for indexing

**If you see this AFTER deploying indexes:**
- Check Firebase Console → Firestore → Indexes
- Make sure indexes show "Enabled" (not "Building")
- Check browser console for specific error

### "Permission denied"

- Rules weren't deployed
- Run: `firebase deploy --only firestore:rules`
- Make sure you're logged in: `firebase login`

### Index link in console

If you try to add a comment/attachment before indexes are ready, Firebase will show:
- Error message with a link to create the index
- Click the link, it auto-creates the index
- Wait 5-15 minutes for it to build

## 📞 Next Steps

1. **Now**: Deploy rules and indexes (Steps 1-2)
2. **After indexing**: Test comments and attachments
3. **Then**: Build APK for friends to test
4. **Monitor**: Check Firebase Console → Usage tab

Your free tier should handle **100+ users** comfortably during testing! 🚀
