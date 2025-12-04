# Services Architecture - Mission Board

**Date**: December 4, 2025  
**Current Version**: 1.3.1

## 🤔 What Are "Services"?

**Services** are background processes that run independently of the UI, continuously monitoring, processing, and responding to events. They keep your app "alive" and reactive even when users aren't actively using it.

Think of services as **invisible workers** that:
- Watch for changes in data
- Send notifications when events happen
- Process data in the background
- Keep everything synchronized
- Automate repetitive tasks

---

## 🔥 Firebase Services (Currently Available)

### ✅ 1. **Firebase Cloud Firestore Listeners** (ACTIVE)
**What It Does**:
- Real-time database that pushes updates instantly
- Streams changes to your app without polling

**Where You're Using It**:
- **Message notifications**: New messages trigger UI updates
- **Friend requests**: Real-time friend request notifications
- **Mission updates**: Mission feed updates automatically
- **Online status**: User presence indicators
- **Lobby chat**: Messages appear instantly for all users

**Example in Your Code**:
```dart
// In messaging_provider.dart
Stream<List<Message>> getMessagesStream(String conversationId) {
  return _firestore
    .collection('conversations')
    .doc(conversationId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .snapshots()  // 👈 This is a real-time listener service
    .map((snapshot) => /* convert to messages */);
}
```

**Benefit**: 
- Zero latency - users see changes instantly
- No need to refresh manually
- Saves battery (no constant polling)

---

### ✅ 2. **Firebase Authentication State Listener** (ACTIVE)
**What It Does**:
- Monitors user login state
- Handles token refresh automatically
- Detects when users sign out

**Where You're Using It**:
```dart
// In auth_provider.dart
_firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
  // Updates user data in real-time
});
```

**Benefit**:
- Users stay logged in seamlessly
- Security tokens refresh automatically
- Instant logout if account deleted

---

### ✅ 3. **Stream Subscriptions** (ACTIVE)
**What It Does**:
- Continuous data streams from Firestore
- Automatic UI updates when data changes

**Where You're Using It**:
- Notifications stream
- Friends list stream
- Missions feed stream
- Messages stream
- Teams stream

**Example**:
```dart
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('notifications')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots(),  // 👈 Real-time service
  builder: (context, snapshot) {
    // UI updates automatically
  },
);
```

**Benefit**:
- App always shows fresh data
- No manual refresh needed
- Multi-user collaboration works smoothly

---

## 🚀 Firebase Services (NOT Yet Implemented)

### ❌ 4. **Firebase Cloud Functions** (NOT ACTIVE)
**What It Does**:
- Server-side code that runs in response to events
- Processes data in the cloud, not on user's device
- Runs even when no users are online

**What You COULD Do With It**:

#### A. **Scheduled Cleanup Jobs**
```javascript
// Cloud Function that runs daily at 2 AM
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 2 * * *')
  .onRun(async (context) => {
    // Delete notifications older than 30 days
    const cutoff = Date.now() - (30 * 24 * 60 * 60 * 1000);
    const old = await db.collection('notifications')
      .where('createdAt', '<', cutoff)
      .get();
    
    const batch = db.batch();
    old.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

**Benefits**:
- Keep database clean automatically
- Delete old messages/notifications
- Archive completed missions
- Generate weekly statistics

---

#### B. **Mission Auto-Complete**
```javascript
// Runs every hour to check mission deadlines
exports.autoCompleteMissions = functions.pubsub
  .schedule('0 * * * *')  // Every hour
  .onRun(async (context) => {
    const now = Date.now();
    
    // Find missions past deadline that are still "in-progress"
    const overdue = await db.collection('missions')
      .where('status', '==', 'in-progress')
      .where('deadline', '<', now)
      .get();
    
    // Auto-mark as failed or send reminders
    for (const doc of overdue.docs) {
      await doc.ref.update({ status: 'overdue' });
      
      // Send notification to assigned user
      await db.collection('notifications').add({
        userId: doc.data().assignedTo,
        type: 'missionOverdue',
        title: 'Mission Overdue!',
        message: `Mission "${doc.data().title}" is past deadline`,
        createdAt: now,
      });
    }
  });
```

**Benefits**:
- Automatic deadline enforcement
- No manual checking needed
- Users get reminded automatically

---

#### C. **Friend Request Expiration**
```javascript
// Delete friend requests older than 30 days
exports.expireFriendRequests = functions.pubsub
  .schedule('0 0 * * 0')  // Weekly on Sunday
  .onRun(async (context) => {
    const cutoff = Date.now() - (30 * 24 * 60 * 60 * 1000);
    
    const old = await db.collection('friendRequests')
      .where('createdAt', '<', cutoff)
      .where('status', '==', 'pending')
      .get();
    
    const batch = db.batch();
    old.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

**Benefits**:
- Prevent stale friend requests
- Keep UI clean
- Automatic housekeeping

---

#### D. **Leaderboard Calculation**
```javascript
// Recalculate leaderboard rankings daily
exports.updateLeaderboard = functions.pubsub
  .schedule('0 3 * * *')  // 3 AM daily
  .onRun(async (context) => {
    const users = await db.collection('users').get();
    
    // Calculate scores
    const rankings = [];
    for (const user of users.docs) {
      const missions = await db.collection('missions')
        .where('assignedTo', '==', user.id)
        .where('status', '==', 'completed')
        .get();
      
      rankings.push({
        userId: user.id,
        score: missions.size * 100,
        completedMissions: missions.size,
      });
    }
    
    // Sort and update ranks
    rankings.sort((a, b) => b.score - a.score);
    const batch = db.batch();
    rankings.forEach((r, index) => {
      batch.update(db.collection('users').doc(r.userId), {
        rank: index + 1,
        score: r.score,
      });
    });
    await batch.commit();
  });
```

**Benefits**:
- Accurate rankings without manual updates
- Runs during off-peak hours
- Reduces real-time load

---

#### E. **Notification Triggers** (Database Triggers)
```javascript
// Automatically create notification when mission assigned
exports.onMissionCreated = functions.firestore
  .document('missions/{missionId}')
  .onCreate(async (snap, context) => {
    const mission = snap.data();
    
    if (mission.assignedTo) {
      // Create notification for assigned user
      await db.collection('notifications').add({
        userId: mission.assignedTo,
        type: 'missionAssigned',
        title: 'New Mission Assigned!',
        message: `You have been assigned: ${mission.title}`,
        actorId: mission.createdBy,
        actionId: snap.id,
        isRead: false,
        createdAt: Date.now(),
      });
      
      // Send push notification (if FCM enabled)
      const userDoc = await db.collection('users').doc(mission.assignedTo).get();
      if (userDoc.data().fcmToken) {
        await admin.messaging().send({
          token: userDoc.data().fcmToken,
          notification: {
            title: 'New Mission!',
            body: mission.title,
          },
        });
      }
    }
  });
```

**Benefits**:
- Automatic notifications (you're doing this manually now)
- Centralized notification logic
- Works even if app is closed (with FCM)

---

### ❌ 5. **Firebase Cloud Messaging (FCM)** (NOT ACTIVE)
**What It Does**:
- Sends push notifications to user's device
- Works when app is closed or in background
- Delivers alerts instantly

**Current Situation**:
- ✅ You create notifications in Firestore
- ❌ Users only see them when app is open
- ❌ No alerts when app is closed

**What It Could Do**:
```dart
// In Flutter app
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get device token
    String? token = await _fcm.getToken();
    
    // Save to Firestore
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'fcmToken': token});
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // Show local notification
      showNotification(message);
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
}
```

**Cloud Function Integration**:
```javascript
// Send push when message received
exports.sendMessageNotification = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const recipientId = /* get recipient */;
    
    const userDoc = await db.collection('users').doc(recipientId).get();
    const fcmToken = userDoc.data().fcmToken;
    
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'New Message',
          body: `${message.senderName}: ${message.content}`,
        },
        data: {
          type: 'message',
          conversationId: context.params.convId,
        },
      });
    }
  });
```

**Benefits**:
- Users get alerted immediately
- Works when app is closed
- Increases user engagement dramatically
- Critical for messaging apps

---

### ❌ 6. **Firebase Performance Monitoring** (NOT ACTIVE)
**What It Does**:
- Tracks app performance automatically
- Measures screen load times
- Monitors network requests
- Detects slow operations

**Setup**:
```dart
// Just add the package and Firebase handles it
// No code needed - automatic monitoring
```

**Benefits**:
- Find slow screens
- Optimize database queries
- Improve user experience
- Data-driven improvements

---

### ❌ 7. **Firebase Crashlytics** (NOT ACTIVE)
**What It Does**:
- Automatically reports crashes
- Captures stack traces
- Shows which users affected
- Groups similar crashes

**Setup**:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  // Catch Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

**Benefits**:
- Know about crashes before users report them
- Fix critical bugs quickly
- Prioritize bug fixes by impact
- Professional error tracking

---

### ❌ 8. **Firebase Analytics** (NOT ACTIVE)
**What It Does**:
- Tracks user behavior automatically
- Shows which features are used most
- Measures user retention
- Conversion tracking

**Example**:
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'mission_completed',
  parameters: {
    'mission_type': 'team',
    'completion_time': duration.inSeconds,
  },
);
```

**Benefits**:
- Understand how users use your app
- Find unused features
- Improve based on data
- Measure growth

---

## 🎯 What Services Would Benefit You RIGHT NOW?

### Priority 1: **Firebase Cloud Functions** (HIGH IMPACT)
**Why You Need It**:
- Automatic cleanup of old data
- Mission deadline enforcement
- Centralized notification logic
- Background processing

**Immediate Use Cases**:
1. **Delete old notifications** (>30 days)
2. **Auto-complete overdue missions**
3. **Send mission reminders** (24h before deadline)
4. **Calculate daily leaderboard**
5. **Expire old friend requests**

**Implementation Effort**: MEDIUM  
**Impact**: HIGH  
**Cost**: $0 (Free tier covers most use cases)

---

### Priority 2: **Firebase Cloud Messaging (FCM)** (CRITICAL)
**Why You Need It**:
- Your app is a messaging app
- Users need alerts when app is closed
- Currently, notifications only work when app is open

**Immediate Use Cases**:
1. Message notifications (most important!)
2. Friend request alerts
3. Mission assignment notifications
4. Level up celebrations
5. Team updates

**Implementation Effort**: MEDIUM  
**Impact**: VERY HIGH  
**Cost**: $0 (Free for unlimited messages)

**ROI**: This single feature could **double user engagement**

---

### Priority 3: **Firebase Analytics** (STRATEGIC)
**Why You Need It**:
- Know which features users love
- Find bugs through behavior patterns
- Measure growth and retention
- Data-driven decisions

**Implementation Effort**: LOW (mostly automatic)  
**Impact**: MEDIUM (long-term strategic value)  
**Cost**: $0 (Free)

---

## 📊 Service Comparison

| Service | Active? | Effort | Impact | Cost | Priority |
|---------|---------|--------|--------|------|----------|
| Firestore Listeners | ✅ Yes | - | Very High | $0 | ✅ Done |
| Auth State Listener | ✅ Yes | - | High | $0 | ✅ Done |
| Stream Subscriptions | ✅ Yes | - | High | $0 | ✅ Done |
| **Cloud Functions** | ❌ No | Medium | **Very High** | $0 | 🔥 #1 |
| **Cloud Messaging (FCM)** | ❌ No | Medium | **Critical** | $0 | 🔥 #2 |
| Performance Monitor | ❌ No | Low | Medium | $0 | #4 |
| Crashlytics | ❌ No | Low | Medium | $0 | #5 |
| Analytics | ❌ No | Low | Medium | $0 | #3 |

---

## 💡 Real-World Example: How Services Keep Apps Alive

### Example 1: WhatsApp
**Services Running**:
- ✅ Push notifications (FCM) - instant message alerts
- ✅ Background sync - downloads messages when app closed
- ✅ Status updates - shows online/offline in real-time
- ✅ Media compression - processes images server-side
- ✅ Delivery receipts - tracks message delivery automatically

**Result**: App feels "alive" even when you're not using it

---

### Example 2: Instagram
**Services Running**:
- ✅ Feed generation - algorithmically sorts posts
- ✅ Notification system - likes, comments, follows
- ✅ Analytics - tracks engagement automatically
- ✅ Content moderation - AI scans uploads
- ✅ Scheduled posts - Cloud Functions post at scheduled time

**Result**: Content appears fresh, users stay engaged

---

### Example 3: Your Mission Board (Current vs. Potential)

**Currently Active** ✅:
- Real-time message updates (when app open)
- Real-time notifications (when app open)
- Friend request alerts (when app open)
- Mission updates (when app open)

**With Cloud Functions** 🚀:
- ✅ Auto-complete overdue missions
- ✅ Delete old data automatically
- ✅ Calculate leaderboard daily
- ✅ Send mission reminders
- ✅ Expire old friend requests

**With FCM** 🚀:
- ✅ Message alerts **when app closed** (HUGE!)
- ✅ Friend request alerts on lock screen
- ✅ Mission notifications even when offline
- ✅ Level up celebrations instantly

---

## 🚀 Recommended Next Steps

### Step 1: Enable Firebase Cloud Messaging (FCM)
**Time**: 2-3 hours  
**Impact**: Massive - transforms user experience  
**What You Get**:
- Push notifications when app closed
- 10x better engagement
- Professional messaging experience

### Step 2: Create Essential Cloud Functions
**Time**: 4-6 hours  
**Impact**: High - app becomes self-maintaining  
**Functions to Create**:
1. Auto-delete old notifications (30+ days)
2. Mark overdue missions
3. Send mission deadline reminders
4. Calculate daily leaderboard
5. Expire old friend requests (30+ days)

### Step 3: Add Analytics
**Time**: 30 minutes  
**Impact**: Strategic insights  
**What You Get**:
- User behavior data
- Feature usage statistics
- Retention metrics
- Growth tracking

---

## 💰 Cost Analysis

### Current Firebase Usage (Free Tier):
- ✅ Firestore: Likely within free tier (50K reads/day)
- ✅ Authentication: Free for unlimited users
- ✅ Storage: Free up to 5GB

### With New Services:
- ✅ **Cloud Functions**: FREE (125K invocations/month free)
- ✅ **FCM**: FREE (unlimited messages)
- ✅ **Analytics**: FREE (unlimited events)
- ✅ **Crashlytics**: FREE (unlimited reports)
- ✅ **Performance**: FREE (unlimited sessions)

**Total Additional Cost**: **$0/month** (for moderate traffic)

---

## 🎯 The Bottom Line

**Services are what make apps feel "alive"**. They:
- Work 24/7 in the background
- Keep data fresh and relevant
- Alert users at the right time
- Automate repetitive tasks
- Scale without manual intervention

**Your App Currently**: 
- Works great when users are active
- Real-time updates within the app
- But silent when app is closed

**Your App With Services**:
- Alerts users even when app closed
- Self-maintaining (auto-cleanup)
- Proactive (deadline reminders)
- Always up-to-date (background sync)
- Professional-grade experience

**The secret to keeping apps alive**: Services that run independently, monitor everything, and act automatically. That's what separates hobby projects from professional apps.

Want me to implement FCM and Cloud Functions? I can have push notifications working in ~2 hours.
