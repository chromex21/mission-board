# Mission Board v1.2.0 - Enhanced UI & Chat Fixes

## 🎉 What's New

### Messaging System Fixed ✅
- **Fixed**: Messages now persist correctly after sending
- **Fixed**: Firestore security rules field name mismatch
- Messages no longer disappear after being sent

### Automatic Message Cleanup 🧹
- Lobby messages automatically clean up after 12 hours
- Keeps chat performant and relevant
- Runs automatically when lobby opens

### Interactive User Profiles 👤
- Click on any message in lobby to view sender's profile
- Click on active users in sidebar to view their profiles
- Easily start direct conversations

### Universal Theme Support 🎨
- Light/Dark theme now works across **ALL** screens
- Fixed white screen bug when navigating back from achievements
- Consistent theme across lobby, messages, settings, and more
- All UI elements properly themed

### Improved Mobile UI 📱
- Active users button moved to bottom-left (less intrusive)
- Compact pill-shaped design with label
- Better positioned away from message input
- Smooth slide-up animation

### Check for Updates 🔄
- New "Check for Updates" in Settings > App Info
- Manually check for latest version
- Shows current version (1.2.0)
- Download prompt with release notes

## 📦 Installation

### Android
Download and install `app-release.apk`

**Note**: You may need to enable "Install from Unknown Sources" in your device settings.

### Web
Visit: https://mission-board-b8dbc.web.app

## 🐛 Bug Fixes

- ✅ Messages disappearing after sending
- ✅ White screen on achievements navigation
- ✅ Theme not applying universally
- ✅ Security rules field validation

## 🔧 Technical Details

- **Version**: 1.2.0 (Build 2)
- **Flutter**: 3.38.3
- **Dart**: 3.10.1

### Firestore Rules Update
Updated lobby message validation to check correct field name (`content` instead of `message`)

### New Features
- ThemeProvider integration across all screens
- UpdateService with manual update checks
- Auto-cleanup service for old messages
- Enhanced user interaction

## 💡 Coming Soon

Consider these features for future updates:
- Voice notes support (guide included in docs)
- Message search
- Message reactions
- Read receipts
- Typing indicators

## 📚 Documentation

- [VERSION_1.2.0_CHANGELOG.md](VERSION_1.2.0_CHANGELOG.md) - Detailed changelog
- [VERSION_1.2.0_IMPLEMENTATION.md](VERSION_1.2.0_IMPLEMENTATION.md) - Implementation details
- [VOICE_NOTES_GUIDE.md](VOICE_NOTES_GUIDE.md) - Voice notes implementation guide

## 🙏 Notes

This release focuses on:
- Fixing critical messaging bugs
- Improving user experience
- Consistent theming
- Better mobile interactions

**Full Changelog**: https://github.com/chromex21/mission-board/compare/v1.1.0...v1.2.0
