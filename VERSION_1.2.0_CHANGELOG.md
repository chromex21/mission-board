# Version 1.2.0 Release Notes

**Release Date**: December 3, 2025

## 🎉 What's New

### Messaging Improvements

#### ✅ Chat Functionality Fixed
- **Fixed**: Messages now persist correctly after sending
- **Root Cause**: Firestore security rules were validating wrong field name
- **Solution**: Updated rules to validate `content` field instead of `message`

#### 🧹 Automatic Message Cleanup
- Lobby messages automatically clean up after 12 hours
- Prevents excessive message accumulation
- Runs automatically when lobby is opened
- Keeps chat performant and relevant

#### 👤 Interactive User Profiles
- **Click on messages** in lobby chat to view sender's profile
- **Click on active users** in sidebar to view their profile
- Easily start direct conversations with other users
- Enhanced social interaction

### UI/UX Enhancements

#### 🎨 Universal Theme Support
- Light/Dark theme now applied consistently across **ALL** screens
- Fixed white screen bug when navigating back from achievements
- Achievements screen fully supports both themes
- Message threads support theme switching
- Login screen adapts to selected theme
- Active users panel supports theme
- Lobby sidebar adapts to light/dark theme
- Modal bottom sheets use appropriate theme colors

#### 📱 Improved Active Users Button (Mobile)
- Moved to bottom-left corner (less intrusive)
- Compact pill-shaped design with "Active" label
- Better positioned away from message input
- Smooth slide-up animation maintained
- Themed to match selected appearance

#### 🔄 Check for Updates
- New "Check for Updates" button in Settings > App Info
- Shows current version (1.2.0)
- Manually check for latest version
- Download prompt with release notes
- "Up to Date" confirmation when current

#### 🖼️ Rich Media Support (Previously Added)
- GIF support via Tenor API
- Image sharing in lobby chat
- Sticker/emoji support
- Media picker with intuitive interface

#### 📱 Mobile Optimizations (Previously Added)
- Floating action button for active users on mobile
- Responsive design improvements
- Better touch targets for mobile users

## 🔧 Technical Details

### Firestore Security Rules Update
```javascript
// Updated validation from:
isValidString(request.resource.data.message, 1, 1000)

// To:
isValidString(request.resource.data.content, 1, 1000)
```

### Automatic Cleanup Implementation
- Runs on lobby widget initialization
- Deletes messages older than 12 hours
- Uses batch operations for efficiency
- Non-blocking operation

### Theme Provider Integration
- ThemeProvider now integrated in:
  - Achievements screen
  - Message thread screen
  - Login screen
  - All UI components adapt dynamically

## 📦 App Details

- **Version**: 1.2.0
- **Build**: 2
- **Flutter**: 3.38.3
- **Dart**: 3.10.1

## 🚀 How to Build

### Web Deployment
```bash
flutter build web --release
firebase deploy --only hosting
```

### Android APK
```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Windows
```bash
flutter build windows --release
```

## ❓ FAQ

### Q: Do GIFs cost money to use?
**A**: No, the app uses Tenor API (owned by Google), which is free for basic usage. Same service used by WhatsApp.

### Q: Can I add voice notes?
**A**: Yes! Firebase Storage free tier supports audio files. The free tier includes:
- 5GB storage
- 1GB/day download bandwidth
- Voice notes are typically 120 KB per minute (16 kHz mono)
- Free tier supports ~42,000 one-minute recordings
- Upgrade only needed for 100+ daily active users with heavy usage
- Estimated cost for 200 users: ~$0.40/month

**See [VOICE_NOTES_GUIDE.md](VOICE_NOTES_GUIDE.md) for complete implementation details.**

### Q: How do I update the app?
**A**: See [UPDATE_SETUP.md](UPDATE_SETUP.md) for detailed instructions on:
- Installing Firebase CLI
- Building and deploying web version
- Creating Android APK releases
- Publishing to GitHub releases

## 🐛 Bug Fixes

- ✅ Fixed: Messages disappearing after sending
- ✅ Fixed: White screen when navigating back from achievements
- ✅ Fixed: Theme not applying universally
- ✅ Fixed: Timestamp handling in lobby messages
- ✅ Fixed: Security rules field name mismatch

## 🎯 Future Improvements

Consider adding:
- Voice notes functionality
- Message search
- Message reactions
- Read receipts
- Typing indicators
- User blocking
- Message editing
- Message pinning

## 📝 Notes for Deployment

1. **Deploy Firestore Rules First**:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Test messaging functionality** before full deployment

3. **Update GitHub Release** with new APK:
   - Tag: v1.2.0
   - Title: "Version 1.2.0 - Chat Fixes & Enhancements"
   - Include this changelog in release notes

4. **Verify theme switching** works across all screens

## 🙏 Acknowledgments

This release focuses on stability, user experience, and fixing the critical messaging bug that was preventing proper chat functionality.
