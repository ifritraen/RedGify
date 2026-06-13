import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/playback_settings_provider.dart';

class PlaybackSettingsSheet extends StatelessWidget {
  const PlaybackSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<PlaybackSettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(235);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white.withAlpha(140) : AppTheme.textSecondary;
    final borderColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.tune_outlined, color: AppTheme.primaryNeon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'PLAYBACK SETTINGS',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customize loop counts, autoplay sequences, and battery-saving sleepers.',
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              // Autoplay Next Switch
              _buildSettingRow(
                title: 'Autoplay Next Video',
                subtitle: 'Automatically advance to the next video when finished.',
                child: Switch.adaptive(
                  value: settingsProvider.autoplayNext,
                  activeTrackColor: AppTheme.primaryNeon,
                  onChanged: (value) => settingsProvider.setAutoplayNext(value),
                ),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

              const SizedBox(height: 20),

              // Playback mode selection
              Text(
                'Video Playback Loop Mode',
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPlaybackActionOptions(settingsProvider, isDark, textColor, subtitleColor, borderColor),

              const SizedBox(height: 24),

              // Loop slider (N times)
              if (settingsProvider.playbackAction != PlaybackAction.playOnceAndNext) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repeat Times (Limit)',
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${settingsProvider.repeatLimit} loops',
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Number of times a video repeats before transitioning or pausing.',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryNeon,
                    inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                    thumbColor: AppTheme.primaryNeon,
                    overlayColor: AppTheme.primaryNeon.withAlpha(40),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: settingsProvider.repeatLimit.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      settingsProvider.setRepeatLimit(value.round());
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'RedGify v1.0.7',
                  style: TextStyle(
                    color: subtitleColor.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    required Widget child,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        child,
      ],
    );
  }

  Widget _buildPlaybackActionOptions(
    PlaybackSettingsProvider provider,
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        _buildActionOption(
          provider: provider,
          action: PlaybackAction.playOnceAndNext,
          title: 'Play Once & Next',
          subtitle: 'Runs exactly once, then transitions to the next item.',
          isDark: isDark,
          textColor: textColor,
          subtitleColor: subtitleColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 8),
        _buildActionOption(
          provider: provider,
          action: PlaybackAction.repeatXAndNext,
          title: 'Repeat X Times & Next',
          subtitle: 'Loops video up to limit, then moves to next.',
          isDark: isDark,
          textColor: textColor,
          subtitleColor: subtitleColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 8),
        _buildActionOption(
          provider: provider,
          action: PlaybackAction.repeatXAndPause,
          title: 'Repeat X Times & Pause (Sleep Mode)',
          subtitle: 'Loops up to limit, then pauses. Best for bedtime.',
          isDark: isDark,
          textColor: textColor,
          subtitleColor: subtitleColor,
          borderColor: borderColor,
        ),
      ],
    );
  }

  Widget _buildActionOption({
    required PlaybackSettingsProvider provider,
    required PlaybackAction action,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final isSelected = provider.playbackAction == action;
    final itemBg = isSelected
        ? AppTheme.primaryNeon.withAlpha(25)
        : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10));
    final activeBorderColor = isSelected ? AppTheme.primaryNeon : borderColor;

    return GestureDetector(
      onTap: () => provider.setPlaybackAction(action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeBorderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryNeon : subtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
