import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../worker/mission_board_screen.dart';
import '../worker/history_screen.dart';
import '../worker/leaderboard_screen.dart';
import '../team/teams_screen.dart';
import '../admin/admin_panel_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'lobby_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentRoute = '/missions';

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _getCurrentScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (_currentRoute) {
      case '/missions':
        return MissionBoardScreen(onNavigate: _handleNavigation);
      case '/missions/history':
        return HistoryScreen(onNavigate: _handleNavigation);
      case '/teams':
        return TeamsScreen(onNavigate: _handleNavigation);
      case '/leaderboard':
        return LeaderboardScreen(onNavigate: _handleNavigation);
      case '/lobby':
        return LobbyScreen(onNavigate: _handleNavigation);
      case '/messages':
        return MessagesScreen(onNavigate: _handleNavigation);
      case '/admin':
        return authProvider.isAdmin
            ? AdminPanelScreen(onNavigate: _handleNavigation)
            : MissionBoardScreen(onNavigate: _handleNavigation);
      case '/profile':
        return ProfileScreen(onNavigate: _handleNavigation);
      case '/settings':
        return SettingsScreen(onNavigate: _handleNavigation);
      default:
        return MissionBoardScreen(onNavigate: _handleNavigation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getCurrentScreen();
  }
}
