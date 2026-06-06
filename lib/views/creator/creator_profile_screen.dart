import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/creator_profile_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';

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
        provider.fetchNextCreatorGifsPage(widget.username);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreatorProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.username}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          provider.isLoadingProfile
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
              : provider.profileError != null
                  ? Center(
                      child: Padding(
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
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withAlpha(15)),
                            ),
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
                                      ? const Icon(Icons.person, size: 48, color: Colors.white)
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
                                            color: Colors.white,
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
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 12),
                                // Profile stats count
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn('Followers', '${provider.userInfo?.followers ?? 0}'),
                                    Container(width: 1, height: 24, color: Colors.white10),
                                    _buildStatColumn('Views', '${provider.userInfo?.views ?? 0}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Media uploads grid
                        if (provider.gifsError != null && provider.creatorGifs.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Error loading uploads: ${provider.gifsError}',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          )
                        else if (provider.creatorGifs.isEmpty && !provider.isLoadingGifs)
                          const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No uploads found.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 0,
                                childAspectRatio: 0.70,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return VideoCard(gif: provider.creatorGifs[index]);
                                },
                                childCount: provider.creatorGifs.length,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
