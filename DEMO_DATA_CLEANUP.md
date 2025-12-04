# Demo Data Cleanup Instructions

## Overview
The Mission Feed currently displays demo data that was created for testing purposes. This data exists in your Firestore database and needs to be removed before production deployment.

## What Demo Data Exists

The following demo activities were created in the `mission_activities` collection:

- **10 fake users**: Sarah Chen, Marcus Johnson, Elena Rodriguez, David Kim, Amara Williams, Alex Turner, Priya Patel, James Brown, Lily Zhang, Omar Hassan
- **~50 activities**: Mission completions, level ups, achievements, and milestones
- All activities have timestamps from the past 7 days

## How to Clean Up

### Option 1: Firebase Console (Manual - Recommended for Small Datasets)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mission-board-b8dbc`
3. Navigate to **Firestore Database**
4. Find the `mission_activities` collection
5. Delete all documents that contain demo user names (Sarah Chen, Marcus Johnson, etc.)

### Option 2: Firestore Rules + Script (Automated)

Run this script in your Firebase project to delete all demo data:

```javascript
// Run in Firebase Console > Firestore > Query
const db = admin.firestore();
const batch = db.batch();

const demoUserIds = ['user1', 'user2', 'user3', 'user4', 'user5', 
                     'user6', 'user7', 'user8', 'user9', 'user10'];

const snapshot = await db.collection('mission_activities')
  .where('userId', 'in', demoUserIds)
  .get();

snapshot.docs.forEach(doc => {
  batch.delete(doc.ref);
});

await batch.commit();
console.log(`Deleted ${snapshot.size} demo activities`);
```

### Option 3: Clear All Activities (Nuclear Option)

If you want to start completely fresh:

```javascript
const snapshot = await db.collection('mission_activities').get();
const batch = db.batch();

snapshot.docs.forEach(doc => {
  batch.delete(doc.ref);
});

await batch.commit();
console.log('All activities deleted');
```

## Verification

After cleanup, the Mission Feed should show:
- "No activities yet" message
- "Complete missions to see activity here" subtitle

## Future Prevention

The demo data generation code has been commented out in:
- `lib/providers/mission_feed_provider.dart` (lines 99-202)

This code will NOT generate new demo data. It's safe to leave commented for reference.

## When to Clean

✅ **Clean before**:
- Publishing to production
- Sharing with real users
- Creating promotional screenshots/videos

❌ **Keep for now if**:
- Still testing features
- Need visual examples for development
- Showing the app to stakeholders (but note it's demo data)

---

**Status**: Demo data generation is disabled. Database cleanup pending before production release.
