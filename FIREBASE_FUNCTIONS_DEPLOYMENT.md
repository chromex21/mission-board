# Firebase Cloud Functions - Deployment Guide

## Quick Start

### 1. Install Firebase CLI (One-time setup)
```bash
npm install -g firebase-tools
firebase login
```

### 2. Link Project to Firebase
```bash
# In mission_board root directory
firebase init

# Select:
# - Functions: Configure Cloud Functions
# - Use existing project
# - Select your Mission Board project
# - JavaScript
# - ESLint: Yes
# - Install dependencies: Yes
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

---

## Detailed Setup

### Prerequisites
- Node.js 18 or higher
- Firebase CLI installed
- Firebase project with Blaze (pay-as-you-go) plan
- Admin access to Firebase project

### Step-by-Step Deployment

#### 1. Install Dependencies
```bash
cd functions
npm install
```

#### 2. Test Locally (Optional)
```bash
# Start emulators
firebase emulators:start --only functions

# Test specific function
curl http://localhost:5001/YOUR_PROJECT_ID/us-central1/sendMessageNotification
```

#### 3. Deploy to Production
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendMessageNotification

# Deploy with debug
firebase deploy --only functions --debug
```

#### 4. Verify Deployment
```bash
# List deployed functions
firebase functions:list

# View logs
firebase functions:log

# View logs for specific function
firebase functions:log --only sendMessageNotification
```

---

## Function Descriptions

### Notification Functions (Real-time triggers)

#### `sendMessageNotification`
- **Trigger**: New message created in `conversations/{id}/messages`
- **Action**: Sends push notification to all recipients (except sender)
- **Frequency**: Every time a message is sent

#### `sendFriendRequestNotification`
- **Trigger**: New document in `friendRequests` collection
- **Action**: Sends push notification to receiver
- **Frequency**: Every time a friend request is sent

#### `sendMissionNotification`
- **Trigger**: New document in `missions` collection
- **Action**: Sends push notification to assigned user
- **Frequency**: Every time a mission is created with assignedTo

### Scheduled Functions (Cron jobs)

#### `cleanupOldNotifications`
- **Schedule**: Daily at 2:00 AM UTC (`0 2 * * *`)
- **Action**: Deletes notifications older than 30 days
- **Estimated Runtime**: 5-30 seconds (depending on data)

#### `cleanupOldMessages`
- **Schedule**: Weekly on Sunday at 3:00 AM UTC (`0 3 * * 0`)
- **Action**: Deletes messages older than 90 days
- **Estimated Runtime**: 1-5 minutes (depending on data)

#### `expireFriendRequests`
- **Schedule**: Weekly on Sunday at 4:00 AM UTC (`0 4 * * 0`)
- **Action**: Deletes pending friend requests older than 30 days
- **Estimated Runtime**: 5-10 seconds

#### `markOverdueMissions`
- **Schedule**: Every hour (`0 * * * *`)
- **Action**: Marks missions as overdue and sends notifications
- **Estimated Runtime**: 10-30 seconds

#### `sendMissionReminders`
- **Schedule**: Every 6 hours (`0 */6 * * *`)
- **Action**: Sends reminders for missions due in 24 hours
- **Estimated Runtime**: 10-30 seconds

#### `updateLeaderboard`
- **Schedule**: Daily at 3:00 AM UTC (`0 3 * * *`)
- **Action**: Recalculates user rankings and scores
- **Estimated Runtime**: 30 seconds - 2 minutes

---

## Monitoring

### Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Functions** in sidebar
4. View:
   - Function list
   - Invocation count
   - Execution time
   - Error rate
   - Logs

### Command Line
```bash
# View all logs
firebase functions:log

# View logs from last hour
firebase functions:log --since 1h

# View logs for specific function
firebase functions:log --only sendMessageNotification

# Follow logs in real-time
firebase functions:log --follow

# View only errors
firebase functions:log --min-level error
```

### Set Up Alerts (Recommended)
1. Go to Firebase Console → Functions
2. Click on a function
3. Click **Set up alert**
4. Configure:
   - Error rate threshold
   - Execution time threshold
   - Email notifications

---

## Troubleshooting

### Common Issues

#### Issue: "Functions are not deployed"
**Cause**: Not authenticated or wrong project selected  
**Solution**:
```bash
firebase login
firebase use --add  # Select correct project
firebase deploy --only functions
```

#### Issue: "Billing account not configured"
**Cause**: Project is on Spark (free) plan  
**Solution**:
1. Go to Firebase Console → Usage and Billing
2. Upgrade to Blaze (pay-as-you-go) plan
3. Note: You still get free tier limits

#### Issue: "Function times out"
**Cause**: Long-running queries or too much data  
**Solution**:
```javascript
// In index.js, increase timeout
exports.myFunction = functions
  .runWith({ timeoutSeconds: 300 })  // 5 minutes
  .pubsub.schedule('0 2 * * *')
  .onRun(async (context) => {
    // Your code
  });
```

#### Issue: "Missing permissions"
**Cause**: Functions don't have required Firestore permissions  
**Solution**:
Firebase Admin SDK has full access by default. If issues persist:
1. Check Firestore security rules
2. Verify service account has required roles

#### Issue: "Cold start is slow"
**Cause**: Functions are inactive and need to cold start  
**Solution**:
- Expected behavior for infrequent functions
- Can upgrade to higher tier for warm instances (costs more)
- Optimize code to reduce initialization time

---

## Cost Management

### Free Tier (Included with Blaze Plan)
- **Invocations**: 2M/month
- **Compute Time**: 400K GB-seconds/month
- **Outbound Network**: 5GB/month

### Typical Monthly Usage (100 active users)
- **Message Notifications**: ~30K invocations
- **Scheduled Tasks**: ~1K invocations
- **Total**: ~31K invocations/month

**Expected Cost**: $0/month (well within free tier)

### Monitor Costs
```bash
# View usage in Firebase Console
# Go to: Usage and billing → Details

# Set up budget alerts
# Go to: Usage and billing → Budget & alerts
# Set alert at $5, $10, etc.
```

---

## Updating Functions

### Deploy Updated Code
```bash
# Edit functions/index.js
# Then deploy
firebase deploy --only functions
```

### Deploy Specific Function
```bash
firebase deploy --only functions:sendMessageNotification
```

### Delete a Function
```bash
firebase functions:delete functionName
```

---

## Testing Functions

### Test Scheduled Functions Manually
```bash
# Install Firebase Functions Test SDK
npm install --save-dev firebase-functions-test

# Create test file: functions/test.js
const test = require('firebase-functions-test')();
const myFunctions = require('./index');

// Test a scheduled function
test.wrap(myFunctions.cleanupOldNotifications)({});
```

### Test with Firebase Emulators
```bash
# Start emulators
firebase emulators:start

# Access Firestore Emulator UI
# Open: http://localhost:4000

# Trigger functions by:
# - Adding documents to Firestore
# - Using Functions Emulator UI
```

---

## Security Best Practices

### 1. Validate Input
```javascript
if (!message.senderId || !message.content) {
  console.error('Invalid message data');
  return null;
}
```

### 2. Handle Errors Gracefully
```javascript
try {
  await sendNotification();
} catch (error) {
  console.error('Error sending notification:', error);
  // Don't throw - let function complete
  return null;
}
```

### 3. Use Firestore Security Rules
```javascript
// Even though Functions have admin access, 
// still implement security rules for client access
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
    request.auth.uid == resource.data.userId;
}
```

### 4. Rate Limiting
```javascript
// For user-triggered functions, implement rate limiting
const rateLimitKey = `rateLimit_${userId}`;
const lastCall = await admin.database().ref(rateLimitKey).once('value');

if (lastCall.val() && Date.now() - lastCall.val() < 1000) {
  // Too many requests
  return null;
}
```

---

## Maintenance

### Weekly Tasks
- [ ] Check function logs for errors
- [ ] Verify scheduled functions ran successfully
- [ ] Monitor execution times

### Monthly Tasks
- [ ] Review function usage and costs
- [ ] Update dependencies if needed
- [ ] Review and optimize slow functions

### Updating Dependencies
```bash
cd functions
npm update
npm audit fix
firebase deploy --only functions
```

---

## Advanced Configuration

### Environment Variables
```bash
# Set config
firebase functions:config:set someservice.key="THE API KEY"

# Get config
firebase functions:config:get

# Use in code
const config = functions.config();
const apiKey = config.someservice.key;
```

### Multiple Regions
```javascript
// Deploy to multiple regions for better latency
exports.sendMessageNotification = functions
  .region('us-central1', 'europe-west1')
  .firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    // Your code
  });
```

### Concurrency Limits
```javascript
// Limit concurrent executions (prevents overload)
exports.sendBulkNotifications = functions
  .runWith({ 
    maxInstances: 10,
    timeoutSeconds: 540,
  })
  .pubsub
  .schedule('0 2 * * *')
  .onRun(async (context) => {
    // Your code
  });
```

---

## Rollback

### If Something Goes Wrong
```bash
# List previous deployments
firebase functions:log

# Note: Firebase doesn't have built-in rollback
# You'll need to:
# 1. Revert code changes in Git
# 2. Redeploy functions

git revert HEAD
firebase deploy --only functions
```

---

## Support

### Get Help
- **Firebase Support**: [Firebase Support](https://firebase.google.com/support)
- **Stack Overflow**: Tag `firebase-cloud-functions`
- **Firebase Community**: [Firebase Slack](https://firebase.community/)

### Useful Commands
```bash
# Help for any command
firebase help functions
firebase help deploy

# Check CLI version
firebase --version

# Update CLI
npm update -g firebase-tools
```

---

## Checklist for First Deployment

- [ ] Node.js 18 installed
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Logged in (`firebase login`)
- [ ] Project linked (`firebase use --add`)
- [ ] Blaze plan enabled
- [ ] Dependencies installed (`cd functions && npm install`)
- [ ] Functions deployed (`firebase deploy --only functions`)
- [ ] Logs checked (`firebase functions:log`)
- [ ] Test notification sent successfully
- [ ] Scheduled functions will run at next scheduled time

---

**Deployment Complete! Your Firebase Cloud Functions are now live and working 24/7.** 🎉
