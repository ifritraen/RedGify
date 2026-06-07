import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/isar_service.dart';
import '../../providers/explore_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/theme_provider.dart';
import '../creator/creator_profile_screen.dart';
import '../player/tag_results_screen.dart';
import '../widgets/glassy_container.dart';
import '../widgets/playback_settings_sheet.dart';
import '../../providers/library_provider.dart';

class MeProfileScreen extends StatefulWidget {
  const MeProfileScreen({super.key});

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  final IsarService _isarService = IsarService();

  Future<Map<String, List<MapEntry<String, int>>>> _calculateStats() async {
    final exploreProvider = Provider.of<ExploreProvider>(context, listen: false);
    final historyItems = await _isarService.getRawHistory();
    
    if (exploreProvider.niches.isEmpty) {
      await exploreProvider.fetchNichesList();
    }
    final nichesList = exploreProvider.niches;

    final Map<String, int> nicheCounts = {};
    final Map<String, int> tagCounts = {};
    final Map<String, int> creatorCounts = {};

    for (var item in historyItems) {
      final gif = item.gifInfo.value;
      if (gif == null) continue;
      final count = item.watchCount > 0 ? item.watchCount : 1;

      // Creator
      final creator = gif.userName;
      if (creator.isNotEmpty) {
        creatorCounts[creator] = (creatorCounts[creator] ?? 0) + count;
      }

      // Tags
      for (var tag in gif.tags) {
        final lowerTag = tag.trim().toLowerCase();
        if (lowerTag.isNotEmpty) {
          tagCounts[lowerTag] = (tagCounts[lowerTag] ?? 0) + count;
        }
      }

      // Niches
      for (var niche in nichesList) {
        final nicheNameLower = niche.name.trim().toLowerCase();
        final nicheIdLower = niche.id.trim().toLowerCase();
        final matches = gif.tags.any((tag) {
          final t = tag.trim().toLowerCase();
          return t == nicheNameLower || t == nicheIdLower;
        });
        if (matches) {
          nicheCounts[niche.name] = (nicheCounts[niche.name] ?? 0) + count;
        }
      }
    }

    final sortedNiches = nicheCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedCreators = creatorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'niches': sortedNiches,
      'tags': sortedTags,
      'creators': sortedCreators,
    };
  }

  void _showAllStatsDialog(String title, List<MapEntry<String, int>> items, Function(String) onTapItem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(235);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white.withAlpha(100) : AppTheme.textSecondary;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);
    final cardBgColor = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(color: subtitleColor),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final entry = items[index];
                              final rank = index + 1;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: rank == 1
                                          ? AppTheme.primaryNeon.withAlpha(50)
                                          : rank == 2
                                              ? AppTheme.secondaryNeon.withAlpha(50)
                                              : rank == 3
                                                  ? AppTheme.accentNeon.withAlpha(50)
                                                  : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        color: rank <= 3 ? Colors.white : AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry.key,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                  ),
                                  trailing: Text(
                                    '${entry.value} views',
                                    style: const TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onTapItem(entry.key);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, List<MapEntry<String, int>> allItems, Function(String) onTapItem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (allItems.length > 5)
            TextButton(
              onPressed: () => _showAllStatsDialog(title, allItems, onTapItem),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 13)),
                  Icon(Icons.chevron_right, color: AppTheme.primaryNeon, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsList(List<MapEntry<String, int>> items, Function(String) onTapItem, {required String prefix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final borderBgColor = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10);
    final nonPodiumBg = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10);

    if (items.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderBgColor),
        ),
        child: Text(
          'No views recorded yet',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    final displayItems = items.take(5).toList();

    return Column(
      children: displayItems.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        final rank = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 1
                  ? AppTheme.primaryNeon.withAlpha(40)
                  : borderBgColor,
              width: 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1
                    ? AppTheme.primaryNeon.withAlpha(55)
                    : rank == 2
                        ? AppTheme.secondaryNeon.withAlpha(55)
                        : rank == 3
                            ? AppTheme.accentNeon.withAlpha(55)
                            : nonPodiumBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              prefix + entry.key,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '${entry.value} times',
              style: const TextStyle(
                color: AppTheme.accentNeon,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onTap: () => onTapItem(entry.key),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   'ME PROFILE',
        //   style: GoogleFonts.outfit(
        //     color: Colors.white,
        //     fontWeight: FontWeight.bold,
        //     letterSpacing: 1.5,
        //   ),
        // ),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
        // centerTitle: true,
        title: Text(
          'ME PROFILE',
          style: GoogleFonts.outfit(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PlaybackSettingsSheet(),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: themeProvider.isDarkMode ? Colors.white : AppTheme.textPrimaryLight,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<MapEntry<String, int>>>>(
        future: _calculateStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final stats = snapshot.data!;
          final niches = stats['niches']!;
          final tags = stats['tags']!;
          final creators = stats['creators']!;

          final totalWatches = niches.fold<int>(0, (sum, element) => sum + element.value);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
              children: [
                // Top user card
                GlassyContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  color: AppTheme.cardBg,
                  borderColor: AppTheme.border,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(isDark ? 0.15 : 0.08),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ],
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNeon.withAlpha(100),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anonymous Viewer',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total watched sessions: $totalWatches',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Niches Stats
                _buildSectionHeader('Top Niches', niches, (nicheName) {
                  // Navigate to Explore Screen and pre-select niche
                  final explore = Provider.of<ExploreProvider>(context, listen: false);
                  final matchingNiche = explore.niches.firstWhere(
                    (n) => n.name.toLowerCase() == nicheName.toLowerCase(),
                    orElse: () => explore.niches.first,
                  );
                  explore.selectNiche(matchingNiche.id);
                  // We can't directly trigger bottom nav switch from here unless we pass a handler,
                  // but we can notify the user or try to find a home state index switcher.
                  // Actually, let's show a snackbar and let the user know, or switch tabs if possible.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Niche "$nicheName" selected in Explore tab.'),
                      backgroundColor: AppTheme.primaryNeon,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }),
                _buildStatsList(niches, (nicheName) {
                  final explore = Provider.of<ExploreProvider>(context, listen: false);
                  final matchingNiche = explore.niches.firstWhere(
                    (n) => n.name.toLowerCase() == nicheName.toLowerCase(),
                    orElse: () => explore.niches.first,
                  );
                  explore.selectNiche(matchingNiche.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Niche "$nicheName" selected in Explore tab.'),
                      backgroundColor: AppTheme.primaryNeon,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }, prefix: '📁 '),

                // Tags Stats
                _buildSectionHeader('Top Tags', tags, (tagName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => SearchProvider()..performSearch(tagName),
                        child: TagResultsScreen(tag: tagName),
                      ),
                    ),
                  );
                }),
                _buildStatsList(tags, (tagName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => SearchProvider()..performSearch(tagName),
                        child: TagResultsScreen(tag: tagName),
                      ),
                    ),
                  );
                }, prefix: '#'),

                // Creators Stats
                _buildSectionHeader('Top Creators', creators, (creatorName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatorProfileScreen(username: creatorName),
                    ),
                  );
                }),
                _buildStatsList(creators, (creatorName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatorProfileScreen(username: creatorName),
                    ),
                  );
                }, prefix: '👤 '),

                // Subscribed Creators Section
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Subscribed Creators',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<LibraryProvider>(
                  builder: (context, libraryProvider, child) {
                    final subscribed = libraryProvider.subscribedCreators;
                    if (subscribed.isEmpty) {
                      return Container(
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10)),
                        ),
                        child: Text(
                          'No subscribed creators yet',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: subscribed.length,
                      itemBuilder: (context, index) {
                        final creatorName = subscribed[index];
                        return GlassyContainer(
                          color: AppTheme.cardBg,
                          borderColor: AppTheme.border,
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => CreatorProfileScreen(username: creatorName),
                                 ),
                               );
                             },
                             child: Stack(
                               children: [
                                 Center(
                                   child: Column(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       CircleAvatar(
                                         radius: 24,
                                         backgroundColor: AppTheme.primaryNeon.withAlpha(50),
                                         child: const Icon(Icons.person, size: 24, color: AppTheme.primaryNeon),
                                       ),
                                       const SizedBox(height: 8),
                                       Text(
                                         '@$creatorName',
                                         style: GoogleFonts.outfit(
                                           color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                                           fontSize: 13,
                                           fontWeight: FontWeight.bold,
                                         ),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                         textAlign: TextAlign.center,
                                       ),
                                     ],
                                   ),
                                 ),
                                 Positioned(
                                   top: 0,
                                   right: 0,
                                   child: IconButton(
                                     icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                     onPressed: () {
                                       libraryProvider.unsubscribeCreator(creatorName);
                                     },
                                     constraints: const BoxConstraints(),
                                     padding: EdgeInsets.zero,
                                    ),
                                  ),
                               ],
                             ),
                           ),
                         );
                       },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
