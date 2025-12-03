import 'package:mission_board/models/user_model.dart';

/// Role-based permission system
class Permissions {
  /// Check if user can create missions
  static bool canCreateMissions(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can edit missions
  static bool canEditMissions(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can delete missions
  static bool canDeleteMissions(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can create teams
  static bool canCreateTeams(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can manage teams
  static bool canManageTeams(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can access admin panel
  static bool canAccessAdminPanel(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can accept missions
  static bool canAcceptMissions(AppUser? user) {
    return user?.role == UserRole.worker;
  }

  /// Check if user can complete missions
  static bool canCompleteMissions(AppUser? user) {
    return user?.role == UserRole.worker;
  }

  /// Check if user can approve missions
  static bool canApproveMissions(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user can reject missions
  static bool canRejectMissions(AppUser? user) {
    return user?.role == UserRole.admin;
  }

  /// Get role display name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.worker:
        return 'Agent';
    }
  }

  /// Get role badge color
  static String getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '#8B5CF6'; // Purple
      case UserRole.worker:
        return '#10B981'; // Green
    }
  }

  /// Get role description
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Create and manage missions, teams, and system settings';
      case UserRole.worker:
        return 'Accept and complete missions, collaborate with teams';
    }
  }
}
