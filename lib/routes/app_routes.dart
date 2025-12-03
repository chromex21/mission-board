import 'package:flutter/material.dart';

import '../views/worker/mission_board_screen.dart';
import '../views/worker/history_screen.dart';
import '../views/worker/create_personal_mission_screen.dart';
import '../views/worker/mission_feed_view.dart';
import '../views/worker/mission_marketplace_view.dart';
import '../views/worker/create_mission_view.dart';
import '../views/admin/create_mission_screen.dart';
import '../views/admin/create_team_mission_screen.dart';
import '../views/admin/admin_panel_screen.dart';
import '../views/common/login_screen.dart';
import '../views/common/profile_screen.dart';
import '../views/common/settings_screen.dart';
import '../views/common/notifications_screen.dart';
import '../views/team/teams_screen.dart';
import '../views/team/team_detail_screen.dart';
import '../views/worker/leaderboard_screen.dart';
import '../views/worker/mission_detail_screen.dart';
import '../views/worker/achievements_screen.dart';
import '../models/mission_model.dart';

class AppRoutes {
  static const String login = '/login';
  static const String missionBoard = '/missions';
  static const String missionHistory = '/missions/history';
  static const String missionFeed = '/mission-feed';
  static const String missionMarketplace = '/mission-marketplace';
  static const String createMission = '/create-mission';
  static const String createTeamMission = '/create-team-mission';
  static const String createPersonalMission = '/create-personal-mission';
  static const String missionDetail = '/mission-detail';
  static const String adminPanel = '/admin';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String teams = '/teams';
  static const String teamDetail = '/team';
  static const String leaderboard = '/leaderboard';
  static const String notifications = '/notifications';
  static const String achievements = '/achievements';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Handle dynamic routes first
    if (routeSettings.name?.startsWith('/team/') ?? false) {
      final teamId = routeSettings.name!.substring(6);
      return MaterialPageRoute(
        builder: (_) => TeamDetailScreen(teamId: teamId),
      );
    }

    switch (routeSettings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.missionBoard:
        return MaterialPageRoute(builder: (_) => const MissionBoardScreen());
      case AppRoutes.missionHistory:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case AppRoutes.missionFeed:
        return MaterialPageRoute(builder: (_) => const MissionFeedView());
      case AppRoutes.missionMarketplace:
        return MaterialPageRoute(builder: (_) => const MissionMarketplaceView());
      case AppRoutes.createMission:
        return MaterialPageRoute(builder: (_) => const CreateMissionView());
      case AppRoutes.createTeamMission:
        return MaterialPageRoute(
          builder: (_) => const CreateTeamMissionScreen(),
        );
      case AppRoutes.createPersonalMission:
        return MaterialPageRoute(
          builder: (_) => const CreatePersonalMissionScreen(),
        );
      case AppRoutes.adminPanel:
        return MaterialPageRoute(builder: (_) => const AdminPanelScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.teams:
        return MaterialPageRoute(builder: (_) => const TeamsScreen());
      case AppRoutes.leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.achievements:
        return MaterialPageRoute(builder: (_) => const AchievementsScreen());
      case AppRoutes.missionDetail:
        final mission = routeSettings.arguments as Mission;
        return MaterialPageRoute(
          builder: (_) => MissionDetailScreen(mission: mission),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
