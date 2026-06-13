import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';

class FavoriteCategorySelectorSheet extends StatefulWidget {
  final GifInfo gif;

  const FavoriteCategorySelectorSheet({super.key, required this.gif});

  @override
  State<FavoriteCategorySelectorSheet> createState() => _FavoriteCategorySelectorSheetState();
}

class _FavoriteCategorySelectorSheetState extends State<FavoriteCategorySelectorSheet> {
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  void _showCreateCategoryDialog(BuildContext context, LibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('New Favorite Category', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: _categoryNameController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter category name...',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final name = _categoryNameController.text.trim();
                if (name.isNotEmpty) {
                  await provider.createFavoriteCategory(name);
                  _categoryNameController.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryNeon)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final categories = provider.favoriteCategories;
    final isFav = provider.isFavorited(widget.gif.id);
    final gifCategories = provider.getCategoriesForGif(widget.gif.id);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Save to Category',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryNeon),
                onPressed: () => _showCreateCategoryDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No categories created yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final catName = categories[index];
                  final belongs = gifCategories.contains(catName);

                  return ListTile(
                    leading: Icon(
                      belongs ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: belongs ? AppTheme.primaryNeon : AppTheme.textSecondary,
                    ),
                    title: Text(
                      catName,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    onTap: () async {
                      // Ensure item is favorited first
                      if (!isFav) {
                        await provider.toggleFavorite(widget.gif);
                      }
                      await provider.toggleGifInFavoriteCategory(catName, widget.gif.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(belongs 
                                ? 'Removed from category $catName' 
                                : 'Added to category $catName'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
