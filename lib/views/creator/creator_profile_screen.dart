import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/creator_profile_provider.dart';
import '../../providers/library_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
import '../../providers/playback_settings_provider.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String username;

  const CreatorProfileScreen({super.key, required this.username});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreatorProfileProvider>(context, listen: false)
          .loadCreatorProfile(widget.username);
    });

    _scrollController.addListener(() {
      final provider = Provider.of<CreatorProfileProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        provider.fetchNextPage(widget.username);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTabSelector(CreatorProfileProvider provider) {
    final isGifs = provider.activeTab == 'g';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildTabChip(
              label: 'GIFs',
              isActive: isGifs,
              onTap: () => provider.selectTab('g', widget.username),
            ),
            const SizedBox(width: 12),
            _buildTabChip(
              label: 'Images',
              isActive: !isGifs,
              onTap: () => provider.selectTab('i', widget.username),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip({required String label, required bool isActive, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBg = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.primaryNeon.withAlpha(45) 
                : fallbackBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.primaryNeon : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primaryNeon : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreatorProfileProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeMedia = provider.activeMedia;

    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.username}', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<PlaybackSettingsProvider>(context).gridColumns == 1 ? Icons.grid_view : Icons.view_stream,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              Provider.of<PlaybackSettingsProvider>(context, listen: false).toggleGridColumns();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await provider.loadCreatorProfile(widget.username, bypassCache: true);
            },
            child: provider.isLoadingProfile
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
                : provider.profileError != null
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height - 100,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading profile: ${provider.profileError}',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Glassmorphic User Profile Header Card
                          SliverToBoxAdapter(
                            child: GlassyContainer(
                              borderRadius: 24,
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(20),
                              color: AppTheme.cardBg,
                              borderColor: AppTheme.border,
                              child: Column(
                                children: [
                                  // Avatar Row
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppTheme.primaryNeon,
                                    backgroundImage: provider.userInfo?.profileImageUrl != null
                                        ? NetworkImage(provider.userInfo!.profileImageUrl!)
                                        : null,
                                    child: provider.userInfo?.profileImageUrl == null
                                        ? Icon(Icons.person, size: 48, color: isDark ? Colors.white : AppTheme.textPrimaryLight)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  // User details
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        provider.userInfo?.name ?? widget.username,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (provider.userInfo?.verified ?? false) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, size: 18, color: AppTheme.accentNeon),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${widget.username}',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                   const SizedBox(height: 16),
                                   Divider(color: AppTheme.border),
                                   const SizedBox(height: 12),
                                   // Profile stats count
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                     children: [
                                       _buildStatColumn('Followers', '${provider.userInfo?.followers ?? 0}'),
                                       Container(width: 1, height: 24, color: AppTheme.border),
                                       _buildStatColumn('Views', '${provider.userInfo?.views ?? 0}'),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   Consumer<LibraryProvider>(
                                     builder: (context, libProvider, child) {
                                       final isSubscribed = libProvider.isSubscribed(widget.username);
                                       return SizedBox(
                                         width: double.infinity,
                                         child: ElevatedButton.icon(
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: isSubscribed 
                                                 ? Colors.white.withAlpha(20)
                                                 : AppTheme.primaryNeon,
                                             foregroundColor: Colors.white,
                                             side: BorderSide(
                                               color: isSubscribed 
                                                   ? AppTheme.primaryNeon.withAlpha(100) 
                                                   : Colors.transparent
                                             ),
                                             shape: RoundedRectangleBorder(
                                               borderRadius: BorderRadius.circular(16),
                                             ),
                                             padding: const EdgeInsets.symmetric(vertical: 12),
                                           ),
                                           icon: Icon(
                                             isSubscribed ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
                                             size: 18,
                                             color: isSubscribed ? AppTheme.primaryNeon : Colors.white,
                                           ),
                                           label: Text(
                                             isSubscribed ? 'SUBSCRIBED' : 'SUBSCRIBE',
                                             style: GoogleFonts.outfit(
                                               fontWeight: FontWeight.bold,
                                               letterSpacing: 1.0,
                                               color: Colors.white,
                                             ),
                                           ),
                                           onPressed: () {
                                             if (isSubscribed) {
                                               libProvider.unsubscribeCreator(widget.username);
                                             } else {
                                               libProvider.subscribeCreator(widget.username);
                                             }
                                           },
                                         ),
                                       );
                                     },
                                   ),
                                ],
                              ),
                            ),
                          ),

                          // Tab selector for GIFs / Images
                          _buildTabSelector(provider),

                          // Media uploads grid
                          if (provider.gifsError != null && activeMedia.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Error loading uploads: ${provider.gifsError}',
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            )
                          else if (activeMedia.isEmpty && !provider.isLoadingGifs)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No uploads found.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          else ...[
                            SliverPadding(
                              // padding: const EdgeInsets.only(left: 16, right: 16, bottom: 84),
                              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 84),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  // crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                                  // crossAxisSpacing: 16,
                                  // mainAxisSpacing: 0,
                                  // childAspectRatio: 0.70,
                                  crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                  childAspectRatio: 0.70,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return VideoCard(
                                      gif: activeMedia[index],
                                      siblings: activeMedia,
                                      index: index,
                                    );
                                  },
                                  childCount: activeMedia.length,
                                ),
                              ),
                            ),
                            if (provider.isLoadingGifs)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppTheme.primaryNeon),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
          ),
          const BulkActionBar(),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
