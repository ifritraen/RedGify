import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/niches_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';

class NichesScreen extends StatefulWidget {
  const NichesScreen({super.key});

  @override
  State<NichesScreen> createState() => _NichesScreenState();
}

class _NichesScreenState extends State<NichesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NichesProvider>(context, listen: false);
      provider.fetchNichesList().then((_) {
        if (provider.niches.isNotEmpty && provider.selectedNicheId == null) {
          provider.selectNiche(provider.niches.first.id);
        }
      });
    });

    _scrollController.addListener(() {
      final provider = Provider.of<NichesProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        provider.fetchNextNicheGifsPage();
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
    final provider = Provider.of<NichesProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Niche Horizontal Category Selector
          if (provider.isLoadingNiches && provider.niches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
            )
          else if (provider.nichesError != null && provider.niches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error fetching niches: ${provider.nichesError}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.niches.length,
                itemBuilder: (context, index) {
                  final niche = provider.niches[index];
                  final isSelected = niche.id == provider.selectedNicheId;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        niche.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryNeon,
                      backgroundColor: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryNeon : Colors.white.withAlpha(20),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          provider.selectNiche(niche.id);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Sorting Tabs selector for Niches
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSortChip(provider, 'trending', '🔥 Trending'),
                const SizedBox(width: 8),
                _buildSortChip(provider, 'new', '⚡ Newest'),
                const SizedBox(width: 8),
                _buildSortChip(provider, 'views', '👁️ Views'),
              ],
            ),
          ),

          // Selected Niche Infinite Feed Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.refreshSelectedNiche();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (provider.gifsError != null && provider.nicheGifs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Error loading niche content: ${provider.gifsError}',
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (provider.nicheGifs.isEmpty && !provider.isLoadingGifs)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No content found for this niche.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                          childAspectRatio: 0.70,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return VideoCard(
                              gif: provider.nicheGifs[index],
                              siblings: provider.nicheGifs,
                              index: index,
                            );
                          },
                          childCount: provider.nicheGifs.length,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(NichesProvider provider, String orderValue, String label) {
    final isSelected = provider.activeOrder == orderValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryNeon,
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNeon : Colors.white.withAlpha(15),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setOrder(orderValue);
        }
      },
    );
  }
}
