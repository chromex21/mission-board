# Quick Integration Guide - Mission Board vc central v1.5.0 Features

This guide shows how to integrate the new presence, reactions, replies, and caching features into your existing app.

---

## 1. Add New Providers to Main App

**File**: `lib/main.dart`

Add the new providers to your MultiProvider:

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => MissionProvider()),
    ChangeNotifierProvider(create: (_) => FriendsProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    
    // NEW PROVIDERS
    ChangeNotifierProvider(create: (_) => PresenceProvider()),
    ChangeNotifierProvider(create: (_) => MessageCacheProvider()),
  ],
  child: MaterialApp(...),
);
```

---

## 2. Initialize Providers on App Start

**File**: `lib/main.dart` or your root widget

```dart
@override
void initState() {
  super.initState();
  
  // Get providers
  final presenceProvider = context.read<PresenceProvider>();
  final cacheProvider = context.read<MessageCacheProvider>();
  final authProvider = context.read<AuthProvider>();
  
  // Initialize message cache
  cacheProvider.initialize();
  
  // Listen to auth state
  authProvider.addListener(() {
    final user = authProvider.user;
    if (user != null) {
      // Initialize presence when user logs in
      presenceProvider.initializePresence(user.uid);
    } else {
      // Mark offline when user logs out
      presenceProvider.markOffline(authProvider.user?.uid ?? '');
    }
  });
}
```

---

## 3. Update Message Thread Screen

**File**: `lib/views/common/message_thread_screen.dart`

### 3.1 Add Typing Indicator

```dart
class _MessageThreadScreenState extends State<MessageThreadScreen> {
  late TextEditingController _messageController;
  Timer? _typingTimer;
  MessageReply? _replyingTo; // For reply feature
  
  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    
    // Listen for typing
    _messageController.addListener(_onTypingChanged);
    
    // Load cached messages first
    _loadCachedMessages();
  }
  
  void _onTypingChanged() {
    final presenceProvider = context.read<PresenceProvider>();
    final currentUserId = context.read<AuthProvider>().user?.uid;
    
    if (currentUserId == null) return;
    
    // Cancel previous timer
    _typingTimer?.cancel();
    
    // Set typing indicator
    presenceProvider.setTyping(currentUserId, widget.conversationId, true);
    
    // Auto-remove after 3 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 3), () {
      presenceProvider.setTyping(currentUserId, widget.conversationId, false);
    });
  }
  
  void _loadCachedMessages() {
    final cacheProvider = context.read<MessageCacheProvider>();
    final cached = cacheProvider.getCachedMessages(widget.conversationId);
    
    if (cached != null && cached.isNotEmpty) {
      // Display cached messages immediately
      setState(() {
        _messages = cached;
      });
    }
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    final presenceProvider = context.read<PresenceProvider>();
    final currentUserId = context.read<AuthProvider>().user?.uid;
    if (currentUserId != null) {
      presenceProvider.setTyping(currentUserId, widget.conversationId, false);
    }
    super.dispose();
  }
}
```

### 3.2 Display Typing Indicator

```dart
// Add this widget above message list
Widget _buildTypingIndicator() {
  final presenceProvider = context.watch<PresenceProvider>();
  final typingUsers = presenceProvider.getTypingUsers(widget.conversationId);
  final currentUserId = context.read<AuthProvider>().user?.uid;
  
  // Filter out current user
  final otherUsersTyping = typingUsers.where((id) => id != currentUserId).toList();
  
  if (otherUsersTyping.isEmpty) return const SizedBox.shrink();
  
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        const SizedBox(width: 8),
        // Animated typing dots
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedOpacity(
            opacity: (index % 2 == 0) ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.grey400,
                shape: BoxShape.circle,
              ),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Text(
          '${otherUsersTyping.length} typing...',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.grey400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
```

### 3.3 Add Message Reactions

```dart
// In message bubble widget, wrap with GestureDetector
Widget _buildMessageBubble(Message message) {
  return GestureDetector(
    onLongPress: () => _showReactionPicker(message),
    child: Column(
      crossAxisAlignment: message.senderId == currentUserId
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // Message content
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.senderId == currentUserId
                ? AppTheme.primaryPurple
                : AppTheme.grey800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply reference if exists
              if (message.replyTo != null)
                ReplyReferenceWidget(
                  reply: message.replyTo!,
                  onTap: () => _scrollToMessage(message.replyTo!.messageId),
                ),
              
              // Message text
              Text(message.content),
              
              // Message status
              if (message.senderId == currentUserId)
                _buildMessageStatus(message.status),
            ],
          ),
        ),
        
        // Reactions
        if (message.reactions.isNotEmpty)
          MessageReactionWidget(
            reactions: message.reactions,
            currentUserId: currentUserId,
            onReactionTap: (emoji) => _toggleReaction(message, emoji),
            onAddReaction: () => _showReactionPicker(message),
          ),
      ],
    ),
  );
}

void _showReactionPicker(Message message) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ReactionPicker(
      onReactionSelected: (emoji) => _addReaction(message, emoji),
    ),
  );
}

Future<void> _addReaction(Message message, String emoji) async {
  final currentUserId = context.read<AuthProvider>().user?.uid;
  if (currentUserId == null) return;
  
  // Add reaction to Firestore
  await FirebaseFirestore.instance
      .collection('conversations')
      .doc(message.conversationId)
      .collection('messages')
      .doc(message.id)
      .update({
    'reactions': FieldValue.arrayUnion([
      {
        'emoji': emoji,
        'userId': currentUserId,
        'timestamp': Timestamp.now(),
      }
    ]),
  });
}

void _toggleReaction(Message message, String emoji) {
  final currentUserId = context.read<AuthProvider>().user?.uid;
  if (currentUserId == null) return;
  
  // Check if user already reacted with this emoji
  final hasReacted = message.reactions.any(
    (r) => r.emoji == emoji && r.userId == currentUserId,
  );
  
  if (hasReacted) {
    _removeReaction(message, emoji);
  } else {
    _addReaction(message, emoji);
  }
}
```

### 3.4 Add Reply Functionality

```dart
// Add state variable
MessageReply? _replyingTo;

// Add reply button to message options
void _replyToMessage(Message message) {
  setState(() {
    _replyingTo = MessageReply(
      messageId: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      content: message.content,
      type: message.type,
    );
  });
  _focusNode.requestFocus();
}

// Update send message function
Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;
  
  final content = _messageController.text.trim();
  final currentUser = context.read<AuthProvider>().user;
  final cacheProvider = context.read<MessageCacheProvider>();
  
  if (currentUser == null) return;
  
  // Create message with reply if exists
  final message = Message(
    id: '', // Will be set by Firestore
    conversationId: widget.conversationId,
    senderId: currentUser.uid,
    senderName: currentUser.displayName ?? currentUser.email,
    content: content,
    type: MessageType.text,
    timestamp: DateTime.now(),
    status: MessageStatus.sending,
    replyTo: _replyingTo, // Include reply reference
  );
  
  // Add to cache immediately (optimistic update)
  await cacheProvider.addMessageToCache(widget.conversationId, message);
  
  // Clear input and reply
  _messageController.clear();
  setState(() {
    _replyingTo = null;
  });
  
  try {
    // Send to Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add(message.toMap());
    
    // Update status to sent
    await cacheProvider.updateMessageStatus(
      widget.conversationId,
      docRef.id,
      MessageStatus.sent,
    );
  } catch (e) {
    // Update status to failed
    await cacheProvider.updateMessageStatus(
      widget.conversationId,
      message.id,
      MessageStatus.failed,
    );
  }
}

// Add reply preview above text field
Widget _buildInputArea() {
  return Column(
    children: [
      // Reply preview
      if (_replyingTo != null)
        ReplyPreviewWidget(
          reply: _replyingTo!,
          onCancelReply: () => setState(() => _replyingTo = null),
        ),
      
      // Text field
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _replyingTo != null 
                    ? 'Reply to ${_replyingTo!.senderName}...'
                    : 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    ],
  );
}
```

### 3.5 Add Message Status Icons

```dart
Widget _buildMessageStatus(MessageStatus status) {
  IconData icon;
  Color color;
  
  switch (status) {
    case MessageStatus.sending:
      icon = Icons.access_time;
      color = AppTheme.grey400;
      break;
    case MessageStatus.sent:
      icon = Icons.check;
      color = AppTheme.grey400;
      break;
    case MessageStatus.delivered:
      icon = Icons.done_all;
      color = AppTheme.grey400;
      break;
    case MessageStatus.read:
      icon = Icons.done_all;
      color = AppTheme.primaryPurple;
      break;
    case MessageStatus.failed:
      icon = Icons.error_outline;
      color = AppTheme.errorRed;
      break;
  }
  
  return Icon(icon, size: 14, color: color);
}
```

---

## 4. Update Profile/User List to Show Presence

**File**: `lib/views/common/full_profile_screen.dart`

```dart
@override
void initState() {
  super.initState();
  
  // Listen to this user's presence
  final presenceProvider = context.read<PresenceProvider>();
  presenceProvider.listenToPresence(widget.user.uid);
}

@override
void dispose() {
  // Stop listening
  final presenceProvider = context.read<PresenceProvider>();
  presenceProvider.stopListeningToPresence(widget.user.uid);
  super.dispose();
}

Widget _buildPresenceIndicator() {
  final presenceProvider = context.watch<PresenceProvider>();
  final presence = presenceProvider.getPresence(widget.user.uid);
  
  if (presence == null) return const SizedBox.shrink();
  
  return Row(
    children: [
      // Status dot
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: presence.status == PresenceStatus.online
              ? AppTheme.successGreen
              : AppTheme.grey500,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      
      // Status text
      Text(
        presence.getStatusText(),
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.grey400,
        ),
      ),
    ],
  );
}
```

---

## 5. Handle Notification Deep Links

**File**: `lib/main.dart` or a notification handler

```dart
void _handleNotificationTap(AppNotification notification) {
  final route = notification.getDefaultRoute();
  
  // Navigate using your router
  Navigator.of(context).pushNamed(route);
  
  // Mark notification as read
  context.read<NotificationProvider>().markAsRead(notification.id);
}
```

---

## 6. Update Message Stream to Cache Messages

**File**: Wherever you listen to messages

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Show cached messages while loading
      final cacheProvider = context.read<MessageCacheProvider>();
      final cached = cacheProvider.getCachedMessages(conversationId);
      
      if (cached != null && cached.isNotEmpty) {
        return _buildMessageList(cached);
      }
      
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasData) {
      final messages = snapshot.data!.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Cache messages
      final cacheProvider = context.read<MessageCacheProvider>();
      cacheProvider.cacheMessages(conversationId, messages);
      
      return _buildMessageList(messages);
    }
    
    return const Text('No messages');
  },
)
```

---

## 7. Add Presence to Mission Activity

**File**: `lib/views/worker/mission_detail_screen.dart`

When accepting or completing a mission, update presence:

```dart
Future<void> _acceptMission() async {
  // Update presence with current activity
  final presenceProvider = context.read<PresenceProvider>();
  final currentUserId = context.read<AuthProvider>().user?.uid;
  
  if (currentUserId != null) {
    await presenceProvider.updatePresence(
      currentUserId,
      PresenceStatus.online,
      currentActivity: 'Working on: ${widget.mission.title}',
    );
  }
  
  // Accept mission
  await missionProvider.acceptMission(widget.mission.id, currentUserId);
}

Future<void> _completeMission() async {
  // Complete mission
  await missionProvider.completeMission(widget.mission.id);
  
  // Update presence
  final presenceProvider = context.read<PresenceProvider>();
  final currentUserId = context.read<AuthProvider>().user?.uid;
  
  if (currentUserId != null) {
    await presenceProvider.updatePresence(
      currentUserId,
      PresenceStatus.online,
      currentActivity: 'Completed: ${widget.mission.title} ✅',
    );
    
    // Clear activity after 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      presenceProvider.updatePresence(
        currentUserId,
        PresenceStatus.online,
        currentActivity: null,
      );
    });
  }
}
```

---

## 8. Testing Checklist

After integration, test:

- [ ] Login → presence shows online
- [ ] Type in message → typing indicator appears for other user
- [ ] Stop typing → indicator disappears after 3-5 seconds
- [ ] Send message → shows single tick (sent)
- [ ] Other user receives → shows double tick (delivered)
- [ ] Other user reads → shows blue double tick (read)
- [ ] Long press message → reaction picker appears
- [ ] Add reaction → appears below message
- [ ] Multiple reactions → grouped with counts
- [ ] Swipe/tap reply → reply preview appears
- [ ] Send reply → original message shown in bubble
- [ ] Tap reply reference → scrolls to original message
- [ ] Go offline → messages still load from cache
- [ ] Send offline → queues until back online
- [ ] Tap notification → navigates to correct screen
- [ ] Accept mission → presence shows "Working on: Mission X"
- [ ] Complete mission → presence shows "Completed: Mission X ✅"

---

## 9. Troubleshooting

### Issue: Typing indicator not appearing
**Solution**: Check that both users are in the same conversation and Firestore rules allow typing subcollection access.

### Issue: Reactions not saving
**Solution**: Verify Firestore rules allow message updates by conversation participants.

### Issue: Cache not loading
**Solution**: Check that `MessageCacheProvider.initialize()` is called on app start.

### Issue: Presence stuck on online
**Solution**: Ensure `markOffline()` is called on logout and app exit.

### Issue: Deep links not working
**Solution**: Verify routes exist in `app_routes.dart` and match the pattern in `getDefaultRoute()`.

---

## 10. Performance Tips

1. **Limit Presence Listeners**: Only listen to presence for visible users (friends, conversation participants)
2. **Cache Pagination**: Load only last 100 messages, implement load-more for older messages
3. **Batch Updates**: Use Firestore batch writes for multiple operations
4. **Debounce Typing**: Use timer to avoid excessive typing indicator updates
5. **Optimize Reactions**: Consider limiting reactions per user per message

---

## Quick Command Reference

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# Run app
flutter run

# Build release
flutter build apk --release

# Clear cache (if needed)
flutter clean
flutter pub get
```

---

**Next Steps**: Implement Phase 2 (Media & Rich Content) from `IMPROVEMENTS_v1.5.0.md`

