import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Rgify',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            _SidebarTile(
              icon: Icons.trending_up,
              title: 'Trending',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarTile(
              icon: Icons.explore,
              title: 'Curated Niches',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarTile(
              icon: Icons.bookmark,
              title: 'Bookmarks',
              onTap: () => Navigator.pop(context),
            ),
            _SidebarTile(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'v1.0.6 (Premium Build)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withAlpha(128),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      hoverColor: AppTheme.cardBg,
      horizontalTitleGap: 8,
    );
  }
}
