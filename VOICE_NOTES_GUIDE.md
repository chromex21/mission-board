# Voice Notes Implementation Guide

## Firebase Storage Capabilities

### Free Tier (Spark Plan)
According to Firebase documentation (as of December 2025):

**Storage:**
- 5 GB total storage
- 1 GB/day download bandwidth
- 20,000 uploads/day
- 50,000 downloads/day

### Voice Note File Sizes

**Typical voice note sizes:**
- Low quality (8 kHz, mono): ~60 KB/minute
- Medium quality (16 kHz, mono): ~120 KB/minute  
- Standard quality (22 kHz, mono): ~170 KB/minute
- High quality (44 kHz, stereo): ~600 KB/minute

**Recommended for chat apps:**
- Use **16 kHz mono** format
- ~120 KB per minute
- 1 minute voice note = 120 KB
- 5 minute voice note = 600 KB

### Capacity Calculations

With 5 GB storage on free tier:
- **1-minute voice notes**: ~42,000 recordings
- **3-minute average**: ~14,000 recordings
- **5-minute voice notes**: ~8,500 recordings

With 1 GB/day download bandwidth:
- **1-minute playbacks**: ~8,500 plays/day
- **3-minute playbacks**: ~2,800 plays/day

## When You'll Need to Upgrade

### Free Tier is Fine For:
- Small teams (5-50 users)
- Moderate voice note usage
- Short messages (1-2 minutes)
- Internal team communication

### Upgrade Needed When:
- More than 100 daily active users
- Heavy voice note usage (10+ per user/day)
- Long voice notes (5+ minutes)
- High playback rates
- Storing messages indefinitely

### Blaze Plan (Pay-as-you-go)
**Costs after free tier:**
- Storage: $0.026 per GB/month
- Download: $0.12 per GB
- Upload: Free

**Example costs for 200 active users:**
- 10 voice notes/user/day × 2 min average = 240 KB/user/day
- 200 users × 240 KB = 48 MB/day = 1.4 GB/month
- Storage cost: ~$0.04/month
- Download cost (2× plays): ~$0.34/month
- **Total: ~$0.40/month**

## Implementation Recommendations

### 1. Audio Format
```dart
// Use opus codec with Flutter sound_recorder
import 'package:flutter_sound/flutter_sound.dart';

// Recommended settings:
- Codec: Codec.opusOGG
- Sample rate: 16000 Hz
- Bit rate: 16000 bps
- Mono channel
```

### 2. File Size Limits
```dart
const maxVoiceNoteDuration = Duration(minutes: 5);
const maxFileSizeBytes = 1048576; // 1 MB
```

### 3. Storage Structure
```
/voice_notes
  /{conversationId}
    /{messageId}.ogg
```

### 4. Cleanup Strategy
```dart
// Auto-delete voice notes older than 30 days
// Or implement per-conversation retention policies
Future<void> cleanupOldVoiceNotes() async {
  final cutoff = DateTime.now().subtract(Duration(days: 30));
  // Delete files older than cutoff
}
```

### 5. Compression
- Use opus codec (built-in compression)
- Quality level 5-7 (balance size/quality)
- No need for additional compression

## Security Rules

```javascript
match /voice_notes/{conversationId}/{messageId} {
  allow read: if request.auth != null &&
    (isParticipant(conversationId) || request.auth.token.admin == true);
  
  allow write: if request.auth != null &&
    isParticipant(conversationId) &&
    request.resource.size < 1048576 && // 1 MB limit
    request.resource.contentType.matches('audio/.*');
    
  allow delete: if request.auth != null &&
    (isSender(conversationId, messageId) || request.auth.token.admin == true);
}
```

## UI/UX Considerations

### 1. Recording Interface
- Hold-to-record button
- Visual waveform during recording
- Time counter
- Slide-to-cancel gesture
- Preview before sending

### 2. Playback Interface
- Play/pause button
- Playback speed control (1x, 1.5x, 2x)
- Progress bar with timestamp
- Download option (optional)
- Waveform visualization

### 3. User Feedback
- "Recording..." indicator
- "Uploading..." progress
- "Delivered" confirmation
- Error handling for:
  - No microphone permission
  - File too large
  - Network error
  - Storage full

## Packages Needed

```yaml
dependencies:
  # Audio recording
  flutter_sound: ^9.2.13
  
  # Permissions
  permission_handler: ^11.0.1
  
  # Waveform visualization
  audio_waveforms: ^1.0.5
  
  # File handling
  path_provider: ^2.1.1
```

## Cost Optimization Tips

1. **Auto-cleanup**: Delete voice notes after 30-90 days
2. **Quality settings**: Use 16 kHz instead of 44 kHz
3. **Duration limits**: Cap at 5 minutes per message
4. **Lazy loading**: Don't auto-download on slow connections
5. **Caching**: Cache recently played voice notes locally
6. **Compression**: Use opus codec (better than MP3/AAC)

## Conclusion

**Yes, voice notes ARE supported on Firebase free tier!**

The free tier is sufficient for:
- Small to medium teams
- Personal projects
- MVP/Beta testing
- Projects with < 100 daily active users

You'll only need to upgrade to Blaze (pay-as-you-go) when:
- You have 100+ daily active users
- Users send 10+ voice notes per day
- You're storing messages indefinitely

**Estimated cost for 200 active users: ~$0.40/month**

This is very affordable and you can start on the free tier then upgrade as needed!
