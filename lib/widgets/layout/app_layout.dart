import 'package:flutter/material.dart';
import '../navigation/app_sidebar.dart';
import '../navigation/app_top_bar.dart';
import '../../utils/responsive_helper.dart';

class AppLayout extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget child;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? onCreateMission;
  final Function(String) onNavigate;
  final VoidCallback? onProfileTap;

  const AppLayout({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
    required this.onNavigate,
    this.searchController,
    this.onSearchChanged,
    this.onCreateMission,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final showSidebar = AppBreakpoints.shouldShowSidebar(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: !showSidebar
          ? Drawer(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: AppSidebar(
                currentRoute: currentRoute,
                onNavigate: (route) {
                  Navigator.of(context).pop(); // Close drawer
                  onNavigate(route);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar (only on tablet/desktop)
          if (showSidebar)
            AppSidebar(currentRoute: currentRoute, onNavigate: onNavigate),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top bar
                AppTopBar(
                  title: title,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  onCreateMission: onCreateMission,
                  onProfileTap: onProfileTap,
                  showMenuButton: !showSidebar,
                ),

                // Content
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
