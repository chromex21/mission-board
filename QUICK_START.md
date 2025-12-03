# Quick Start Guide - Mission Board

## 🚀 Get Started in 5 Minutes

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Set Up Firebase

**Easy Way (Recommended):**
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will:
- Create a Firebase project (or use existing)
- Generate `firebase_options.dart` automatically
- Configure iOS and Android apps

**Then update `main.dart` line 13:**
```dart
// Uncomment and use:
import 'firebase_options.dart';
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Step 3: Enable Firebase Services

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Enable **Authentication** → Sign-in method → Email/Password
4. Enable **Firestore Database** → Create database in test mode
5. Enable **Storage** → Get started

### Step 4: Add Firestore Security Rules

In Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /missions/{missionId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Step 5: Run the App
```bash
flutter run
```

### Step 6: Create Admin User

1. **Sign up** a new account in the app
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document
4. Change `role` field from `"worker"` to `"admin"`
5. Restart the app and log in again

## ✨ You're Done!

### As Admin:
- Click **+** button to create missions
- View all missions
- See mission details

### As Worker:
- View all open missions
- Tap a mission to see details
- Click "Accept Mission" to assign to yourself
- Click "Mark as Complete" when done

## 🐛 Troubleshooting

**"Firebase not initialized"**
- Make sure you ran `flutterfire configure`
- Check that `Firebase.initializeApp()` is called in `main.dart`

**"Permission denied"**
- Update Firestore security rules (see Step 4)
- Make sure you're logged in

**"Can't create missions"**
- Make sure your user has `role: "admin"` in Firestore
- Check Firestore security rules

## 📱 Test Accounts

Create 2 accounts to test:
1. **Admin** (change role to "admin" in Firestore)
2. **Worker** (keep default "worker" role)

## 🎯 What Works Out of the Box

✅ User authentication (email/password)  
✅ Role-based access (admin/worker)  
✅ Create missions (admin only)  
✅ View mission board  
✅ Accept missions  
✅ Complete missions  
✅ Auto-refresh UI with Provider  
✅ Clean, modular architecture  

## 📚 Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Firebase init, Provider setup |
| `lib/models/mission_model.dart` | Mission data structure |
| `lib/models/user_model.dart` | User data structure with roles |
| `lib/providers/auth_provider.dart` | Authentication state management |
| `lib/providers/mission_provider.dart` | Mission CRUD operations |
| `lib/views/worker/mission_board_screen.dart` | Main mission list view |
| `lib/views/admin/create_mission_screen.dart` | Admin mission creation |
| `lib/routes/app_routes.dart` | App navigation |

Enjoy building your Mission Board app! 🎉
