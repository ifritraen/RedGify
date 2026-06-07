import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';
import '../../providers/playback_settings_provider.dart';

class TagResultsScreen extends StatefulWidget {
  final String tag;
  const TagResultsScreen({super.key, required this.tag});

  @override
  State<TagResultsScreen> createState() => _TagResultsScreenState();
}

class _TagResultsScreenState extends State<TagResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final search = Provider.of<SearchProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        search.fetchNextSearchResults();
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
    final search = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '#${widget.tag}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
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
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await search.performSearch(widget.tag, bypassCache: true);
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (search.errorMessage != null)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Error loading results: ${search.errorMessage}',
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else if (search.searchResults.isEmpty && !search.isLoading)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No content found for this tag.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          // padding: const EdgeInsets.all(16),
                          padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
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
                                  gif: search.searchResults[index],
                                  siblings: search.searchResults,
                                  index: index,
                                );
                              },
                              childCount: search.searchResults.length,
                            ),
                          ),
                        ),
                        if (search.isLoading)
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
              ),
            ],
          ),
          const BulkActionBar(),
        ],
      ),
    );
  }
}
