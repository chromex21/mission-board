# 🔥 CRITICAL TESTING CHECKLIST - DO BEFORE DECLARING COMPLETE

## ⚠️ YOU MUST TEST THESE 5 THINGS IN THE ACTUAL RUNNING APP

### 1. Fresh User Flow ✅

**Install & Auth:**
- [ ] Run `flutter run` successfully
- [ ] Sign up with new email/password works
- [ ] Log in with same credentials works
- [ ] **CRITICAL**: Close app, reopen → user stays logged in (no login screen)
- [ ] Log out button works and returns to login screen

**How to test:**
```bash
# Clear app data first
flutter clean
flutter run

# In app:
1. Sign up: test@example.com / password123
2. Log out
3. Log in again
4. Close app completely
5. Reopen app - should go straight to Mission Board (NOT login screen)
```

---

### 2. Worker Flow ✅

**Viewing Missions:**
- [ ] Worker sees all OPEN missions on board
- [ ] Worker sees missions ASSIGNED TO THEM (not other people's)
- [ ] Mission cards show status badge (OPEN = green, ASSIGNED = orange)
- [ ] Tapping a mission opens detail screen

**Accepting Mission:**
- [ ] Tap OPEN mission → "Accept Mission" button visible
- [ ] Click "Accept Mission"
- [ ] Mission disappears from other users' boards INSTANTLY
- [ ] Status changes to ASSIGNED
- [ ] Mission stays in YOUR board with ASSIGNED badge
- [ ] Other users CANNOT accept it anymore (locked to you)

**Completing Mission:**
- [ ] Tap YOUR assigned mission → "Mark as Complete" button visible
- [ ] Click "Mark as Complete"
- [ ] Mission disappears from board INSTANTLY
- [ ] Success message shows
- [ ] Mission gone forever (completed)

**Test with 2 devices/browsers:**
```bash
# Device 1 (Worker A):
flutter run

# Device 2 (Worker B):
flutter run -d chrome

# Test race condition:
1. Admin creates mission
2. Both workers see it instantly
3. Worker A accepts it
4. Worker B should see it disappear IMMEDIATELY
5. Worker B tries to tap it → should be gone or show error
```

---

### 3. Admin Flow ✅

**Admin UI:**
- [ ] Admin sees "+" button in app bar
- [ ] Regular worker does NOT see "+" button
- [ ] Tapping "+" opens Create Mission screen

**Creating Mission:**
- [ ] Fill form: title, description, reward (number), difficulty (1-5)
- [ ] Click "Create Mission"
- [ ] Returns to board
- [ ] New mission appears INSTANTLY on admin's board
- [ ] New mission appears INSTANTLY on all workers' boards (open another device to test)

**Test instant visibility:**
```bash
# Admin device:
flutter run

# Worker device:
flutter run -d chrome

# Admin creates mission "Test Mission"
# Worker should see "Test Mission" appear WITHOUT refreshing
```

---

### 4. Firestore Role Check ✅

**Manual Admin Setup:**
- [ ] Create account through app
- [ ] Go to Firebase Console → Firestore
- [ ] Find `users` collection
- [ ] Find your user document (by uid)
- [ ] Change `role` field from `"worker"` to `"admin"`
- [ ] **CRITICAL**: WITHOUT restarting app, "+" button appears within 2-3 seconds
- [ ] Create a mission to verify admin powers work

**Firebase Console URL:**
```
https://console.firebase.google.com/
→ Your Project
→ Firestore Database
→ users collection
→ Find your user
→ Edit role field: "worker" → "admin"
```

---

### 5. Mission Ownership & Security ✅

**assignedTo Locking:**
- [ ] Worker A accepts mission
- [ ] Firestore document updates with `assignedTo: "workerA_uid"`
- [ ] Worker B cannot see the mission anymore
- [ ] Worker B cannot accept it (even if they have the ID)
- [ ] Only Worker A can complete it

**Test in Firestore Console:**
```
1. Worker accepts mission "Mission 1"
2. Open Firebase Console → Firestore → missions
3. Find "Mission 1" document
4. Verify:
   - status: "assigned"
   - assignedTo: "actual-user-uid-here"
5. Try to manually change assignedTo to another uid
6. Original worker should not be able to complete it anymore
```

---

## 🚨 IF ANY OF THESE FAIL:

### Problem: User doesn't stay logged in
**Fix**: Check Firebase Auth persistence settings

### Problem: Missions don't appear instantly
**Fix**: Check that Firestore real-time listener is working (check `MissionProvider._listenToMissions()`)

### Problem: Worker can steal assigned missions
**Fix**: Add Firestore security rules:
```javascript
match /missions/{missionId} {
  allow update: if request.auth != null && (
    // Allow admin to do anything
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
    // Allow accepting open missions
    (resource.data.status == 'open' && request.resource.data.status == 'assigned') ||
    // Allow completing own missions
    (resource.data.assignedTo == request.auth.uid && 
     resource.data.status == 'assigned' && 
     request.resource.data.status == 'completed')
  );
}
```

### Problem: "+" button doesn't appear after changing role
**Fix**: Check `AuthProvider` is listening to user document changes (not just auth state)

### Problem: Other workers see assigned missions
**Fix**: Check filter in `mission_board_screen.dart` line 41-44

---

## ✅ SUCCESS CRITERIA

All checkboxes above must be checked MANUALLY IN THE RUNNING APP.

**Do NOT check a box unless you:**
1. Actually tested it in the running app
2. Saw it work with your own eyes
3. Tested the FAILURE case too (e.g., worker B can't steal mission)

---

## 🎯 ACTUAL TEST PLAN

### Test Session 1: Single User (15 minutes)
```bash
flutter run
```
1. Sign up → log in → log out → log in
2. Close app → reopen (stays logged in?)
3. View missions (empty is OK)

### Test Session 2: Admin (10 minutes)
1. Go to Firestore → change your user to admin
2. Wait 5 seconds → "+" appears?
3. Create mission with form
4. Mission appears instantly?

### Test Session 3: Two Workers (15 minutes)
```bash
# Terminal 1
flutter run

# Terminal 2
flutter run -d chrome
```
1. Worker A accepts mission
2. Worker B sees it disappear IMMEDIATELY
3. Worker A completes mission
4. Mission gone from both boards

### Test Session 4: Race Condition (10 minutes)
1. Admin creates mission
2. Both workers tap Accept simultaneously
3. Only ONE should succeed
4. Other should see error or "already taken"

---

## 📊 Real-Time Update Test

**Expected behavior:**
- Admin creates mission → Workers see it in <2 seconds (NO REFRESH BUTTON)
- Worker accepts mission → Other workers see it disappear in <2 seconds
- Worker completes mission → Everyone sees it disappear in <2 seconds

**How to verify:**
Open 3 browser windows side by side. All changes should propagate INSTANTLY.

---

## ⏰ TIME ESTIMATE

- Setting up Firebase: 10 min
- Test Session 1: 15 min
- Test Session 2: 10 min
- Test Session 3: 15 min
- Test Session 4: 10 min

**Total: 60 minutes of ACTUAL testing**

If you haven't done this, **THE APP IS NOT FINISHED.**

---

## 🔍 What I Fixed Just Now

✅ Real-time listener for missions (no more manual refresh)  
✅ Show OPEN + MY ASSIGNED missions (not other people's)  
✅ Prevent mission stealing (check if already assigned)  
✅ Verify ownership before completing  
✅ Visual status badges (green=OPEN, orange=ASSIGNED)  
✅ Error messages for race conditions  
✅ Success notifications  

**Now you need to TEST these changes in the actual running app!**
