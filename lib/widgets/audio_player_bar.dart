import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/history_audio_item.dart';
import '../services/audio_player_service.dart';
import '../core/localization/app_locale.dart';
import 'waveform_animation.dart';

class AudioPlayerBar extends StatelessWidget {
  final HistoryAudioItem item;
  final AudioPlayerService playerService;
  final VoidCallback onDismiss;

  const AudioPlayerBar({
    super.key,
    required this.item,
    required this.playerService,
    required this.onDismiss,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<PlayerState>(
      stream: playerService.onPlayerStateChanged,
      initialData: playerService.playerState,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data ?? playerService.playerState;
        final isPlaying = state == PlayerState.playing;

        return StreamBuilder<Duration>(
          stream: playerService.onPositionChanged,
          initialData: playerService.position,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: playerService.onDurationChanged,
              initialData: playerService.duration,
              builder: (context, durSnapshot) {
                final duration = durSnapshot.data ?? Duration.zero;
                final maxSec = duration.inMilliseconds > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0;
                final curSec = position.inMilliseconds
                    .toDouble()
                    .clamp(0.0, maxSec);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 50 : 20),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: theme.colorScheme.primary,
                                size: 26,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  playerService.pause();
                                } else {
                                  playerService.playFile(item.filePath);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.voiceName.isNotEmpty
                                      ? '${item.voiceName} • ${item.formattedFileSize}'
                                      : item.formattedFileSize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          WaveformAnimation(
                            isPlaying: isPlaying,
                            height: 22,
                            barCount: 10,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            tooltip: context.tr('btn_cancel'),
                            onPressed: () {
                              playerService.stop();
                              onDismiss();
                            },
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: theme.sliderTheme.copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: curSec,
                          max: maxSec,
                          onChanged: (val) {
                            playerService.seek(
                              Duration(milliseconds: val.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
