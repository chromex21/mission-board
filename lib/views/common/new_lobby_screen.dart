import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lobby_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/lobby_model.dart';
import '../../models/lobby_message_model.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/lobby/lobby_header.dart';
import '../../widgets/lobby/lobby_card.dart';
import '../../widgets/lobby/enhanced_message_display.dart';
import '../../widgets/lobby/lobby_message_input.dart';
import '../../widgets/layout/app_layout.dart';

class NewLobbyScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const NewLobbyScreen({super.key, this.onNavigate});

  @override
  State<NewLobbyScreen> createState() => _NewLobbyScreenState();
}

class _NewLobbyScreenState extends State<NewLobbyScreen> {
  AuthProvider? _authProvider;
  LobbyProvider? _lobbyProvider;
  String? _currentLobbyId;
  bool _showDiscovery = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return AppLayout(
      currentRoute: '/lobby',
      title: _showDiscovery ? 'Lobby Discovery' : 'Lobby',
      onNavigate: widget.onNavigate ?? (route) {},
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      child: _showDiscovery ? _buildDiscoveryView() : _buildLobbyView(isMobile),
    );
  }

  Widget _buildDiscoveryView() {
    final lobbyProvider = Provider.of<LobbyProvider>(context);

    return Column(
      children: [
        // Header with back button if in a lobby
        if (_currentLobbyId != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey900,
              border: Border(bottom: BorderSide(color: AppTheme.grey800)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showDiscovery = true;
                      _currentLobbyId = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Browse Lobbies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // Lobby grid
        Expanded(
          child: StreamBuilder<List<Lobby>>(
            stream: lobbyProvider.streamLobbies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading lobbies: ${snapshot.error}',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                );
              }

              final lobbies = snapshot.data ?? [];

              if (lobbies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: AppTheme.grey600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No lobbies available yet',
                        style: TextStyle(fontSize: 16, color: AppTheme.grey400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back soon!',
                        style: TextStyle(fontSize: 14, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                );
              }

              return LobbyGrid(
                lobbies: lobbies,
                onJoinLobby: (lobby) => _joinLobby(lobby),
                joinedLobbyIds: _currentLobbyId != null
                    ? {_currentLobbyId!}
                    : {},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyView(bool isMobile) {
    if (_currentLobbyId == null) {
      return _buildDiscoveryView();
    }

    final lobbyProvider = Provider.of<LobbyProvider>(context);

    return FutureBuilder<Lobby?>(
      future: lobbyProvider.getLobby(_currentLobbyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lobby = snapshot.data;
        if (lobby == null) {
          return Center(
            child: Text(
              'Lobby not found',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          );
        }

        return isMobile ? _buildMobileLobby(lobby) : _buildDesktopLobby(lobby);
      },
    );
  }

  Widget _buildDesktopLobby(Lobby lobby) {
    return Row(
      children: [
        // Messages area (70%)
        Expanded(flex: 7, child: _buildMessagesArea(lobby)),

        // Users sidebar (30%)
        Expanded(flex: 3, child: _buildUsersSidebar(lobby)),
      ],
    );
  }

  Widget _buildMobileLobby(Lobby lobby) {
    return _buildMessagesArea(lobby);
  }

  Widget _buildMessagesArea(Lobby lobby) {
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey800),
      ),
      child: Column(
        children: [
          // Lobby header with online count
          StreamBuilder<List<LobbyUser>>(
            stream: lobbyProvider.streamLobbyUsers(_currentLobbyId!),
            builder: (context, snapshot) {
              final onlineCount = snapshot.data?.length ?? 0;
              return LobbyHeader(
                lobby: lobby,
                onlineCount: onlineCount,
                onInfoTap: () => _showLobbyInfo(lobby),
                onUserListTap: () => _showUserList(),
              );
            },
          ),

          // Messages feed
          Expanded(
            child: StreamBuilder<List<LobbyMessage>>(
              stream: lobbyProvider.streamLobbyMessagesForLobby(
                _currentLobbyId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppTheme.grey600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(
                            color: AppTheme.grey400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage =
                        message.userId == authProvider.appUser?.uid;

                    return EnhancedMessageDisplay(
                      message: message,
                      isOwnMessage: isOwnMessage,
                      onTap: () {
                        // Could show message details or user profile
                      },
                      onLongPress: () {
                        // Could show message actions
                        _showMessageActions(message, isOwnMessage);
                      },
                      onReaction: (emoji) {
                        lobbyProvider.toggleReaction(
                          message.id,
                          authProvider.appUser!.uid,
                          emoji,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildUsersSidebar(Lobby lobby) {
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey900 : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.grey700 : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, size: 20, color: AppTheme.successGreen),
              const SizedBox(width: 8),
              const Text(
                'Online Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<LobbyUser>>(
              stream: lobbyProvider.streamLobbyUsers(_currentLobbyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No users online',
                      style: TextStyle(color: AppTheme.grey400, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryPurple.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          user.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.rank.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        user.rank.displayName,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final authProvider = Provider.of<AuthProvider>(context);
    final lobbyProvider = Provider.of<LobbyProvider>(context);

    return LobbyMessageInput(
      onSendMessage: (content, messageType) {
        _sendMessage(
          content,
          messageType,
          null, // No file path for lobby messages
          authProvider,
          lobbyProvider,
        );
      },
      canSendMessage: lobbyProvider.canSendMessage,
      cooldownRemaining: lobbyProvider.timeUntilNextMessage,
    );
  }

  Future<void> _joinLobby(Lobby lobby) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);

    if (authProvider.appUser == null) return;

    // Determine rank (simple logic, can be enhanced)
    LobbyRank rank = LobbyRank.member;
    if (authProvider.appUser!.role == 'admin') {
      rank = LobbyRank.admin;
    } else if (authProvider.appUser!.role == 'mod') {
      rank = LobbyRank.mod;
    }

    await lobbyProvider.joinLobby(
      lobbyId: lobby.id,
      userId: authProvider.appUser!.uid,
      displayName:
          authProvider.appUser!.displayName ?? authProvider.appUser!.email,
      photoURL: authProvider.appUser!.photoURL,
      rank: rank,
    );

    setState(() {
      _currentLobbyId = lobby.id;
      _showDiscovery = false;
    });
  }

  void _sendMessage(
    String content,
    String messageType,
    String? filePath,
    AuthProvider authProvider,
    LobbyProvider lobbyProvider,
  ) {
    if (content.trim().isEmpty) return;
    if (authProvider.appUser == null) return;
    if (_currentLobbyId == null) return;

    // Determine rank
    LobbyRank rank = LobbyRank.member;
    if (authProvider.appUser!.role == 'admin') {
      rank = LobbyRank.admin;
    } else if (authProvider.appUser!.role == 'mod') {
      rank = LobbyRank.mod;
    }

    // For now, use content as the media URL if provided
    // TODO: Implement proper file upload to Firebase Storage
    final mediaUrl = filePath;

    lobbyProvider.sendMessageToLobby(
      lobbyId: _currentLobbyId!,
      userId: authProvider.appUser!.uid,
      userName:
          authProvider.appUser!.displayName ?? authProvider.appUser!.email,
      userPhotoUrl: authProvider.appUser!.photoURL,
      content: content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      userRank: rank.name,
    );
  }

  void _showLobbyInfo(Lobby lobby) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey900,
        title: Row(
          children: [
            if (lobby.iconEmoji != null)
              Text(lobby.iconEmoji!, style: const TextStyle(fontSize: 32)),
            if (lobby.iconEmoji != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                lobby.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic: ${lobby.topic}',
              style: TextStyle(color: AppTheme.grey200),
            ),
            const SizedBox(height: 8),
            Text(lobby.description, style: TextStyle(color: AppTheme.grey400)),
            const SizedBox(height: 16),
            Text(
              '${lobby.onlineCount} online • ${lobby.totalMembers} members',
              style: TextStyle(color: AppTheme.successGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserList() {
    // Mobile: Show user list in bottom sheet
    // Already shown in sidebar on desktop
  }

  void _showMessageActions(LobbyMessage message, bool isOwnMessage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnMessage)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorRed),
                title: const Text('Delete Message'),
                onTap: () {
                  // Delete message
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.emoji_emotions,
                color: AppTheme.primaryPurple,
              ),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                // Show emoji picker
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider ??= Provider.of<AuthProvider>(context, listen: false);
    _lobbyProvider ??= Provider.of<LobbyProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Leave lobby when screen is disposed
    if (_currentLobbyId != null && _authProvider?.appUser != null) {
      _lobbyProvider?.leaveLobby(
        lobbyId: _currentLobbyId!,
        userId: _authProvider!.appUser!.uid,
        displayName:
            _authProvider!.appUser!.displayName ??
            _authProvider!.appUser!.email,
      );
    }
    super.dispose();
  }
}
