import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/mission_feed_provider.dart';
import 'providers/team_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/attachment_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/lobby_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'services/sound_service.dart';
import 'services/update_service.dart';
import 'routes/app_routes.dart';
import 'views/auth/login_screen.dart';
import 'views/common/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProxyProvider<ActivityProvider, MissionProvider>(
          create: (context) => MissionProvider(
            activityProvider: Provider.of<ActivityProvider>(
              context,
              listen: false,
            ),
          ),
          update: (context, activityProvider, previous) =>
              previous ?? MissionProvider(activityProvider: activityProvider),
        ),
        ChangeNotifierProvider(create: (_) => MissionFeedProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => AttachmentProvider()),
        ChangeNotifierProvider(create: (_) => LobbyProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SoundService()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          final themeData = () {
            switch (themeProvider.currentTheme) {
              case AppThemeMode.blue:
                return AppTheme.blueTheme;
              case AppThemeMode.dark:
                return AppTheme.darkTheme;
            }
          }();

          final themeMode = ThemeMode.dark; // Both themes use dark mode

          return MaterialApp(
            title: 'Mission Board',
            theme: themeData,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            // Use a reactive home instead of initialRoute so it updates on auth changes
            home: auth.user == null
                ? const LoginScreen()
                : const HomeScreenWithUpdateCheck(),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

class HomeScreenWithUpdateCheck extends StatefulWidget {
  const HomeScreenWithUpdateCheck({super.key});

  @override
  State<HomeScreenWithUpdateCheck> createState() =>
      _HomeScreenWithUpdateCheckState();
}

class _HomeScreenWithUpdateCheckState extends State<HomeScreenWithUpdateCheck> {
  @override
  void initState() {
    super.initState();
    // Check for updates after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      UpdateService.checkAndPromptUpdate(context, userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
