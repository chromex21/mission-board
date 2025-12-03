# Mission Board (v1)

A Flutter task/mission assignment system with Firebase backend.

## Features

- **Authentication**: Email/password login with Firebase Auth
- **User Roles**: Admin (create/manage missions) and Worker (view/accept/complete missions)
- **Mission Board**: View all open missions as cards
- **Mission Detail**: Accept and complete missions
- **Admin Panel**: Create new missions with title, description, reward, and difficulty

## Project Structure

```
lib/
├── core/           # Core app configuration
├── models/         # Data models (Mission, AppUser)
├── providers/      # State management (AuthProvider, MissionProvider)
├── routes/         # App routing
├── services/       # Firebase services
├── utils/          # Helper functions and validators
├── views/          # UI screens
│   ├── admin/      # Admin-only screens
│   ├── auth/       # Authentication screens
│   ├── worker/     # Worker screens
│   └── common/     # Shared screens
└── widgets/        # Reusable widgets
```

## Firebase Setup

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable **Authentication** (Email/Password)
4. Enable **Cloud Firestore**
5. Enable **Storage**

### 2. Configure Flutter App

**Option A: Using FlutterFire CLI (Recommended)**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

**Option B: Manual Setup**
1. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
2. Place them in the appropriate platform folders
3. Update `main.dart` to use manual initialization

### 3. Firestore Security Rules

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
      allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 4. Create Admin User

Since the first user needs to be an admin, you'll need to manually create one:

1. Sign up a user through the app
2. Go to Firestore in Firebase Console
3. Find the user document in the `users` collection
4. Change the `role` field from `worker` to `admin`

Or use this Firestore rule temporarily to allow the first admin creation.

## Running the App

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## User Flow

### Worker
1. Login/Sign up
2. View mission board (all open missions)
3. Tap a mission to see details
4. Accept a mission (status: open → assigned)
5. Complete the mission (status: assigned → completed)

### Admin
1. Login with admin account
2. View mission board
3. Tap "+" to create new mission
4. Fill in mission details and submit
5. View all missions and their statuses

## Tech Stack

- **Flutter** (SDK ^3.10.1)
- **Firebase Core** (v4.2.1)
- **Firebase Auth** (v6.1.2)
- **Cloud Firestore** (v6.1.0)
- **Firebase Storage** (v13.0.4)
- **Provider** (v6.1.5) - State management

## Next Steps (Post-v1)

- Mission filters (status, difficulty)
- User profiles
- Mission history
- Push notifications
- Image upload for proof-of-completion
- Mission comments/chat
