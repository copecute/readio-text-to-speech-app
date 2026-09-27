import 'package:flutter/material.dart';
import '../core/localization/app_locale.dart';
import '../models/bgm_track.dart';
import '../services/bgm_service.dart';

class BgmManagerSheet extends StatefulWidget {
  final BgmService bgmService;

  const BgmManagerSheet({
    super.key,
    required this.bgmService,
  });

  static Future<void> show(BuildContext context, BgmService bgmService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BgmManagerSheet(bgmService: bgmService),
    );
  }

  @override
  State<BgmManagerSheet> createState() => _BgmManagerSheetState();
}

class _BgmManagerSheetState extends State<BgmManagerSheet> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _showAddFromUrlDialog() async {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.cloud_download_rounded, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                context.tr('bgm_add_url_title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('bgm_add_url_desc'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: context.tr('bgm_title_label'),
                  hintText: 'Nhạc nền nhẹ nhàng...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: 'URL tệp âm thanh (.mp3, .wav)',
                  hintText: 'https://example.com/audio.mp3',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(context.tr('btn_cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (urlCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(dialogCtx, true);
                }
              },
              child: Text(context.tr('btn_download')),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && urlCtrl.text.trim().isNotEmpty) {
      final url = urlCtrl.text.trim();
      final title = titleCtrl.text.trim();
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      try {
        await widget.bgmService.downloadTrackFromUrl(
          url: url,
          title: title,
          onProgress: (p) {
            setState(() {
              _downloadProgress = p;
            });
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(context.tr('bgm_download_success')),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('${context.tr('bgm_download_error')}: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgm = widget.bgmService;

    return AnimatedBuilder(
      animation: bgm,
      builder: (context, _) {
        final volume = bgm.volume;
        final isEnabled = bgm.isEnabled;
        final tracks = bgm.tracks;

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.purpleAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('bgm_manager_title'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            context.tr('bgm_manager_desc'),
                            style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isEnabled,
                      onChanged: (val) => bgm.setEnabled(val),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),

              // Scrollable Settings & Track list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    // Volume Control Card (Default 30%, Max 80%)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('bgm_volume_title'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(volume * 100).toInt()}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: volume,
                              min: 0.05,
                              max: 0.80, // User requested: Max 80%
                              divisions: 15,
                              onChanged: isEnabled ? (val) => bgm.setVolume(val) : null,
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildQuickVolumeChip('20%', 0.20, volume, isEnabled),
                                _buildQuickVolumeChip('30% (Chuẩn)', 0.30, volume, isEnabled),
                                _buildQuickVolumeChip('50%', 0.50, volume, isEnabled),
                                _buildQuickVolumeChip('80% (Tối đa)', 0.80, volume, isEnabled),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Playback Mode Card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('bgm_mode_title'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildModeChip(
                                  label: '🔂 ${context.tr('bgm_mode_repeat_one')}',
                                  mode: BgmPlayMode.repeatOne,
                                  current: bgm.playMode,
                                  onSelect: () => bgm.setPlayMode(BgmPlayMode.repeatOne),
                                ),
                                _buildModeChip(
                                  label: '🔁 ${context.tr('bgm_mode_repeat_all')}',
                                  mode: BgmPlayMode.repeatAll,
                                  current: bgm.playMode,
                                  onSelect: () => bgm.setPlayMode(BgmPlayMode.repeatAll),
                                ),
                                _buildModeChip(
                                  label: '⏹️ ${context.tr('bgm_mode_play_one_once')}',
                                  mode: BgmPlayMode.playOneOnce,
                                  current: bgm.playMode,
                                  onSelect: () => bgm.setPlayMode(BgmPlayMode.playOneOnce),
                                ),
                                _buildModeChip(
                                  label: '⏭️ ${context.tr('bgm_mode_play_all_once')}',
                                  mode: BgmPlayMode.playAllOnce,
                                  current: bgm.playMode,
                                  onSelect: () => bgm.setPlayMode(BgmPlayMode.playAllOnce),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Add Tracks Toolbar
                    Row(
                      children: [
                        Text(
                          '${context.tr('bgm_playlist')} (${tracks.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const Spacer(),
                        // Add from file button
                        OutlinedButton.icon(
                          onPressed: () => bgm.addTrackFromFile(),
                          icon: const Icon(Icons.file_upload_outlined, size: 16),
                          label: Text(
                            context.tr('bgm_add_file'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add from URL button
                        OutlinedButton.icon(
                          onPressed: _isDownloading ? null : _showAddFromUrlDialog,
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: Text(
                            context.tr('bgm_add_url'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ),

                    if (_isDownloading) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
                      const SizedBox(height: 4),
                      Text(
                        'Đang tải nhạc nền về máy... ${(_downloadProgress * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Track List
                    ...tracks.map((track) {
                      final isSelected = bgm.currentTrackId == track.id;
                      final isAuditioning = bgm.isPlaying && bgm.auditioningTrackId == track.id;
                      final isSkipped = track.isSkipped;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          // Grayed out if skipped
                          color: isSkipped
                              ? (theme.brightness == Brightness.dark
                                  ? Colors.grey.withAlpha(20)
                                  : Colors.grey.withAlpha(35))
                              : (isSelected
                                  ? theme.colorScheme.primary.withAlpha(20)
                                  : theme.colorScheme.surfaceContainerHighest.withAlpha(60)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSkipped
                                ? Colors.grey.withAlpha(40)
                                : (isSelected
                                    ? theme.colorScheme.primary.withAlpha(120)
                                    : theme.dividerColor.withAlpha(40)),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: IconButton.filledTonal(
                            icon: Icon(
                              isAuditioning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: isAuditioning ? Colors.redAccent : (isSkipped ? Colors.grey : null),
                              size: 20,
                            ),
                            tooltip: isAuditioning ? 'Dừng thử' : 'Nghe thử',
                            onPressed: () => bgm.toggleAudition(track),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  track.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13.5,
                                    color: isSkipped ? Colors.grey : null,
                                    decoration: isSkipped ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (track.isBuiltIn) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Mặc định',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  ),
                                ),
                              ],
                              if (isSkipped) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Bỏ qua',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            track.sourceType == BgmSourceType.asset ? 'Tích hợp sẵn' : 'Tệp riêng trong máy',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSkipped ? Colors.grey : theme.hintColor,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Skip Toggle Button (Bỏ qua bài)
                              IconButton(
                                icon: Icon(
                                  isSkipped ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 19,
                                  color: isSkipped ? Colors.grey : theme.hintColor,
                                ),
                                tooltip: isSkipped ? 'Bỏ trạng thái bỏ qua' : 'Bỏ qua bài này',
                                onPressed: () => bgm.toggleSkipTrack(track.id),
                              ),

                              // Delete Button (only for custom user tracks)
                              if (!track.isBuiltIn)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.redAccent),
                                  tooltip: 'Xóa bài này',
                                  onPressed: () => bgm.deleteTrack(track.id),
                                ),

                              // Select indicator
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? theme.colorScheme.primary : theme.hintColor.withAlpha(100),
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () => bgm.selectTrack(track.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Bottom Apply Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      context.tr('apply_config'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickVolumeChip(String label, double val, double currentVal, bool enabled) {
    final isSelected = (currentVal - val).abs() < 0.03;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: enabled ? (_) => widget.bgmService.setVolume(val) : null,
      selectedColor: theme.colorScheme.primary.withAlpha(35),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildModeChip({
    required String label,
    required BgmPlayMode mode,
    required BgmPlayMode current,
    required VoidCallback onSelect,
  }) {
    final isSelected = mode == current;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: isSelected,
      onSelected: (_) => onSelect(),
      selectedColor: theme.colorScheme.primary.withAlpha(35),
      visualDensity: VisualDensity.compact,
    );
  }
}
