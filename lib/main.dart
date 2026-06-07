import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/feed_provider.dart';
import 'providers/search_provider.dart';
import 'providers/niches_provider.dart';
import 'providers/library_provider.dart';
// import 'providers/ai_provider.dart';
import 'providers/creator_profile_provider.dart';
import 'providers/selection_provider.dart';
import 'providers/explore_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/download_provider.dart';
import 'providers/playback_settings_provider.dart';
import 'providers/playback_queue_provider.dart';
import 'services/video_cache_manager.dart';
import 'config/theme.dart';
import 'views/home/home_screen.dart';
import 'views/widgets/inactivity_monitor.dart';

import 'providers/local_player_provider.dart';
import 'providers/personalized_feed_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VideoCacheManager.clearCacheOnStartup();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => NichesProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackSettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackQueueProvider()),
        // ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => CreatorProfileProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
        ChangeNotifierProvider(create: (_) => LocalPlayerProvider()),
        ChangeNotifierProvider(create: (_) => PersonalizedFeedProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Sync the global isDark state so AppTheme static getters return the correct themed colors
    AppTheme.isDark = themeProvider.isDarkMode;

    return MaterialApp(
      title: 'RedGify',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      builder: (context, child) {
        return InactivityMonitor(child: child!);
      },
    );
  }
}
