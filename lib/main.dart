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
import 'config/theme.dart';
import 'views/home/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => NichesProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        // ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => CreatorProfileProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
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
    );
  }
}
