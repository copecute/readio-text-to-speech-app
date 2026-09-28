import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/localization/app_locale.dart';
import '../models/history_audio_item.dart';
import '../models/tts_voice_item.dart';
import '../services/history_service.dart';
import '../services/tts_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/audio_player_bar.dart';

class HistoryView extends StatefulWidget {
  final HistoryService historyService;
  final AudioPlayerService audioPlayerService;
  final ValueChanged<String> onLoadIntoEditor;

  const HistoryView({
    super.key,
    required this.historyService,
    required this.audioPlayerService,
    required this.onLoadIntoEditor,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  HistoryAudioItem? _activePlayingItem;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryAudioItem> get _filteredItems {
    final all = widget.historyService.items;
    if (_searchQuery.trim().isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.text.toLowerCase().contains(query) ||
          item.voiceName.toLowerCase().contains(query);
    }).toList();
  }

  void _showDeleteDialog(HistoryAudioItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('delete_dialog_title')),
        content: Text('${context.tr('delete_dialog_msg')}\n"${item.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('btn_cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_activePlayingItem?.id == item.id ||
                  widget.audioPlayerService.currentItem?.id == item.id) {
                await widget.audioPlayerService.stop();
                widget.audioPlayerService.clearCurrentItem();
                setState(() {
                  _activePlayingItem = null;
                });
              }
              await widget.historyService.deleteItem(item.id);
              setState(() {});
            },
            child: Text(context.tr('btn_confirm')),
          ),
        ],
      ),
    );
  }


  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('btn_clear_history')),
        content: Text(context.tr('confirm_clear_history')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('btn_cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              widget.audioPlayerService.stop();
              _activePlayingItem = null;
              await widget.historyService.clearAll();
              setState(() {});
            },
            child: Text(context.tr('btn_confirm')),
          ),
        ],
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('text_copied')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Column(
      children: [
        // Top search and actions bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: context.tr('history_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (widget.historyService.items.isNotEmpty) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: context.tr('btn_clear_history'),
                  onPressed: _showClearAllDialog,
                  icon: const Icon(Icons.delete_sweep, size: 20),
                ),
              ],
            ],
          ),
        ),

        // Storage Directory Path Indicator
        FutureBuilder<Directory>(
          future: TtsService.getAudioStorageDirectory(),
          builder: (context, snapshot) {
            final path = snapshot.data?.path ?? 'copecute/readio';
            final theme = Theme.of(context);
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_special_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path,
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => HistoryService.openFolder(path),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('btn_open_folder'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('storage_folder_copied')),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.copy_rounded, size: 16, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // List or Empty View
        Expanded(
          child: items.isEmpty
              ? _buildEmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildHistoryCard(item);
                  },
                ),
        ),

        // Bottom sticky player if an item is active
        StreamBuilder<HistoryAudioItem?>(
          stream: widget.audioPlayerService.onItemChanged,
          initialData: widget.audioPlayerService.currentItem,
          builder: (context, snapshot) {
            final active = snapshot.data ?? widget.audioPlayerService.currentItem ?? _activePlayingItem;
            if (active == null) return const SizedBox.shrink();
            return AudioPlayerBar(
              item: active,
              playerService: widget.audioPlayerService,
              onDismiss: () {
                widget.audioPlayerService.stop();
                widget.audioPlayerService.clearCurrentItem();
                setState(() {
                  _activePlayingItem = null;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.audio_file_outlined,
                size: 46,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('history_empty_title'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('history_empty_subtitle'),
              style: TextStyle(color: theme.hintColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryAudioItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isThisActive = widget.audioPlayerService.currentItem?.id == item.id ||
        widget.audioPlayerService.currentlyPlayingPath == item.filePath ||
        _activePlayingItem?.id == item.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Play button avatar
                StreamBuilder<PlayerState>(
                  stream: widget.audioPlayerService.onPlayerStateChanged,
                  initialData: widget.audioPlayerService.playerState,
                  builder: (context, snapshot) {
                    final isPlayingThis = isThisActive &&
                        widget.audioPlayerService.isPlaying &&
                        widget.audioPlayerService.currentlyPlayingPath ==
                            item.filePath;

                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPlayingThis
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlayingThis
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlayingThis
                              ? Colors.white
                              : theme.colorScheme.primary,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() {
                            _activePlayingItem = item;
                          });
                          if (isPlayingThis) {
                            widget.audioPlayerService.pause();
                          } else {
                            widget.audioPlayerService.playItem(item);
                          }
                        },
                      ),
                    );
                  },
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
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            item.formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                          Text(
                            '•  ${item.formattedFileSize}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                          if (item.voiceName.isNotEmpty)
                            Text(
                              '•  ${TtsVoiceItem(name: item.voiceName, locale: item.locale).getFriendlyName()}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    switch (val) {
                      case 'open':
                        HistoryService.openFileFolder(item.filePath);
                        break;
                      case 'share':
                        HistoryService.shareFile(item.filePath, text: item.text);
                        break;
                      case 'copy_path':
                        Clipboard.setData(ClipboardData(text: item.filePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(item.filePath),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        break;
                      case 'copy':
                        _copyText(item.text);
                        break;
                      case 'load':
                        widget.onLoadIntoEditor(item.text);
                        break;
                      case 'delete':
                        _showDeleteDialog(item);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'open',
                      child: ListTile(
                        leading: const Icon(Icons.folder_open, size: 20),
                        title: Text(context.tr('btn_open_folder')),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: const Icon(Icons.share, size: 20),
                        title: Text(context.tr('btn_share')),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy_path',
                      child: ListTile(
                        leading: Icon(Icons.link, size: 20),
                        title: Text('Sao chép đường dẫn'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        leading: const Icon(Icons.copy, size: 20),
                        title: Text(context.tr('btn_copy_text')),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'load',
                      child: ListTile(
                        leading: const Icon(Icons.edit, size: 20),
                        title: const Text('Mở trong soạn thảo'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        title: const Text(
                          'Xóa tệp',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Text snippet preview container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
