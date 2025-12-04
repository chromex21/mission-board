# Testing Guide - Friend Requests & Messaging Fix v1.5.1

## 🧪 Test Scenarios

### Prerequisites
- Two test accounts logged in on different devices or browsers
- Accounts: **Account A** and **Account B**
- Both accounts have FCM tokens (notifications enabled)

---

## Test 1: Basic Friend Request Flow ✅

### Steps:
1. **Account A**: Navigate to Account B's profile
2. **Account A**: Click "Send Friend Request"
3. **Expected**: Success message appears
4. **Account B**: Should receive push notification (if app in background)
5. **Account B**: Open notifications screen
6. **Expected**: See "Friend Request from Account A"
7. **Account B**: Click notification
8. **Expected**: Navigate to Account A's profile
9. **Expected**: See "Accept Friend Request" button
10. **Account B**: Click "Accept Request"
11. **Expected**: Success message "You and [Account A] are now friends"
12. **Expected**: Button changes to "Friends" with green checkmark
13. **Account A**: Should receive notification "Friend Request Accepted"
14. **Account A**: Navigate to Account B's profile
15. **Expected**: See "Friends" button (not "Send Friend Request")

### What to Verify:
- ✅ No permission errors
- ✅ Both users added to each other's friends list
- ✅ Notifications delivered and displayed
- ✅ UI updates immediately after acceptance
- ✅ No "refresh app" message

### Previous Bug:
- ❌ Step 10 showed "Permission error - try refreshing the app"
- ❌ Users weren't added as friends
- ❌ Had to restart app to see changes

---

## Test 2: Messaging Between Friends ✅

### Steps:
1. **Account A**: Navigate to Account B's profile (now friends)
2. **Account A**: Click "Message" button
3. **Expected**: Navigate to conversation screen
4. **Account A**: Type message "Hello from Account A"
5. **Account A**: Click send
6. **Expected**: Message appears in conversation
7. **Account B**: Should receive push notification
8. **Account B**: Open conversations list
9. **Expected**: See conversation with Account A
10. **Expected**: Unread badge shows "1"
11. **Account B**: Open conversation
12. **Expected**: See message from Account A
13. **Account B**: Reply "Hello from Account B"
14. **Account A**: Should receive notification
15. **Account A**: Open conversation
16. **Expected**: See reply from Account B

### What to Verify:
- ✅ No "Failed to send message" errors
- ✅ Messages delivered instantly
- ✅ Push notifications work
- ✅ Unread counts update correctly
- ✅ Conversation list updates

### Previous Bug:
- ❌ "Failed to send message exception"
- ❌ Messages failed to create conversation
- ❌ Old "Ocleum Flutter" system notifications

---

## Test 3: Mutual Friend Request (Auto-Accept) ✅

### Steps:
1. **Account A**: Send friend request to Account C
2. **Account C**: **WITHOUT accepting**, send friend request to Account A
3. **Expected**: Account C's request auto-accepts Account A's pending request
4. **Expected**: Both users become friends immediately
5. **Expected**: Both receive "Friend Request Accepted" notification
6. **Expected**: No duplicate friend requests exist

### What to Verify:
- ✅ Auto-accept logic works
- ✅ No duplicate requests created
- ✅ Both users immediately friends
- ✅ Both receive notifications

---

## Test 4: Rejecting Friend Request ✅

### Steps:
1. **Account A**: Send friend request to Account D
2. **Account D**: Navigate to Account A's profile
3. **Account D**: Click "Reject" (or "X" button)
4. **Expected**: Request status changes to "rejected"
5. **Expected**: "Accept" button disappears
6. **Account A**: Check sent requests
7. **Expected**: See request marked as rejected
8. **Account A**: Can send new request later

### What to Verify:
- ✅ Rejection updates status correctly
- ✅ No permission errors
- ✅ Users not added as friends
- ✅ Request can be deleted/resent

---

## Test 5: Canceling Friend Request ✅

### Steps:
1. **Account A**: Send friend request to Account E
2. **Account A**: Navigate to "Sent Requests"
3. **Account A**: Click "Cancel" on pending request
4. **Expected**: Request removed from list
5. **Account E**: Navigate to notifications
6. **Expected**: No friend request notification from Account A
7. **Account A**: Navigate to Account E's profile
8. **Expected**: See "Send Friend Request" button again

### What to Verify:
- ✅ Cancellation removes request
- ✅ Recipient doesn't see canceled request
- ✅ Can send new request after canceling

---

## Test 6: Unfriending ✅

### Steps:
1. **Account A & B**: Already friends (from Test 1)
2. **Account A**: Navigate to Account B's profile
3. **Account A**: Click "Friends" button
4. **Expected**: Show options menu
5. **Account A**: Click "Unfriend"
6. **Expected**: Confirmation dialog appears
7. **Account A**: Confirm unfriend
8. **Expected**: Success message "No longer friends with Account B"
9. **Account A**: Button changes to "Send Friend Request"
10. **Account B**: Navigate to Account A's profile
11. **Expected**: See "Send Friend Request" (not "Friends")

### What to Verify:
- ✅ Both users removed from each other's friends list
- ✅ No permission errors
- ✅ Can send new friend request after unfriending
- ✅ Previous conversations still exist (not deleted)

---

## Test 7: Blocked User Cannot Send Request ✅

### Steps:
1. **Account A**: Block Account F
2. **Account F**: Navigate to Account A's profile
3. **Account F**: Try to send friend request
4. **Expected**: Error message "Cannot send request - user unavailable"
5. **Account A**: Try to send request to Account F
6. **Expected**: Error message "Cannot send request"

### What to Verify:
- ✅ Blocked users cannot send requests
- ✅ Blocker cannot send requests to blocked user
- ✅ Clear error messages shown
- ✅ No permission errors

---

## Test 8: Notification Navigation ✅

### Steps:
1. **Account A**: Send friend request to Account B
2. **Account B**: Receive push notification
3. **Account B**: Tap notification (app in background)
4. **Expected**: App opens to Account A's profile
5. **Account B**: Accept request
6. **Account A**: Receive "Request Accepted" notification
7. **Account A**: Tap notification
8. **Expected**: Navigate to Account B's profile
9. **Account B**: Send message to Account A
10. **Account A**: Receive message notification
11. **Account A**: Tap notification
12. **Expected**: Open conversation with Account B

### What to Verify:
- ✅ Deep links work correctly
- ✅ Notifications navigate to correct screens
- ✅ Notification data contains actionId
- ✅ App doesn't crash on notification tap

---

## Test 9: Multiple Friend Requests ✅

### Steps:
1. **Account A**: Send friend requests to 5 different users
2. **All 5 users**: Receive notifications
3. **User 1**: Accept request
4. **User 2**: Reject request
5. **User 3**: Ignore request
6. **Account A**: Cancel request to User 4
7. **User 5**: Accept request
8. **Account A**: Check friends list
9. **Expected**: See User 1 and User 5 as friends

### What to Verify:
- ✅ Multiple concurrent requests work
- ✅ No race conditions
- ✅ Each request independent
- ✅ Correct final state for each

---

## Test 10: Offline to Online Sync ✅

### Steps:
1. **Account A**: Turn off internet
2. **Account B**: Send friend request to Account A
3. **Account A**: Turn on internet
4. **Expected**: Notification appears within 5 seconds
5. **Account A**: Accept request (while online)
6. **Account A**: Turn off internet
7. **Account A**: Try to send message to Account B
8. **Expected**: Error message "No internet connection"
9. **Account A**: Turn on internet
10. **Expected**: Previous messages sync correctly

### What to Verify:
- ✅ Notifications sync when coming online
- ✅ Friend requests persist offline
- ✅ Clear error messages for offline actions
- ✅ No permission errors after reconnection

---

## 🐛 Known Issues (Should Not Occur)

### ❌ These Should NOT Happen:
1. **"Permission error - try refreshing the app"**
   - If this appears: FIRESTORE RULES NOT DEPLOYED
   - Redeploy: `firebase deploy --only firestore:rules`

2. **"Failed to send message exception"**
   - If this appears: Check conversation creation
   - Verify users are in participants array

3. **"Request no longer exists"**
   - If this appears: Check request document exists
   - Verify request status is "pending"

4. **No push notifications**
   - Check FCM token saved in user document
   - Verify Cloud Functions deployed
   - Check device notification permissions

5. **"Old Ocleum Flutter system notification"**
   - Should be replaced with CustomNotificationBanner
   - If showing: Check notification service initialization

---

## 📊 Success Criteria

### All Tests Must:
- ✅ Complete without errors
- ✅ Show user-friendly messages
- ✅ Update UI immediately
- ✅ Sync across devices
- ✅ Deliver notifications
- ✅ Maintain security (no unauthorized updates)

### Metrics to Monitor:
- Friend request acceptance rate > 80%
- Message delivery success rate > 99%
- Notification delivery < 3 seconds
- Zero permission errors
- Zero app crashes

---

## 🔧 Debugging Tips

### If Permission Error Appears:
```bash
# 1. Check Firestore rules deployed
firebase deploy --only firestore:rules

# 2. Verify rules in Firebase Console
# Navigate to: Firestore Database > Rules
# Check users collection has friend list update logic

# 3. Test rule in Rules Playground
# Simulate: User B updating User A's friends array
```

### If Messaging Fails:
```bash
# 1. Check conversation exists
# Navigate to: Firestore > conversations collection
# Verify participants array contains both users

# 2. Check message subcollection
# Navigate to: conversations/{id}/messages
# Verify messages exist with correct senderId

# 3. Check Cloud Functions logs
firebase functions:log --only sendMessageNotification
```

### If Notifications Not Received:
```bash
# 1. Check FCM token saved
# Navigate to: Firestore > users/{userId}
# Verify fcmToken field exists

# 2. Check Cloud Functions deployed
firebase deploy --only functions

# 3. Check device permissions
# Settings > Apps > Mission Board > Notifications > Enabled
```

---

## ✅ Expected Results Summary

After fix deployment:
- ✅ Friend requests: 100% success rate
- ✅ Message sending: 100% success rate
- ✅ Notifications: Delivered within 3 seconds
- ✅ Permission errors: 0
- ✅ App crashes: 0
- ✅ User satisfaction: High

---

**Last Updated**: December 4, 2025  
**Fix Version**: v1.5.1  
**Status**: ✅ DEPLOYED TO PRODUCTION
