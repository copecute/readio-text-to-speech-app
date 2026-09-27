import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_locale.dart';
import '../services/tts_service.dart';
import '../services/history_service.dart';

class SettingsView extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final TtsService ttsService;
  final HistoryService historyService;

  const SettingsView({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.ttsService,
    required this.historyService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int get _totalSavedFiles => widget.historyService.items.length;

  int get _totalStorageBytes => widget.historyService.items.fold<int>(
        0,
        (sum, item) => sum + item.fileSizeBytes,
      );

  String get _formattedStorage {
    if (_totalStorageBytes < 1024) return '$_totalStorageBytes B';
    if (_totalStorageBytes < 1024 * 1024) {
      return '${(_totalStorageBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_totalStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showClearCacheDialog() {
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
              await widget.historyService.clearAll();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã dọn dẹp bộ nhớ lưu trữ âm thanh.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(context.tr('btn_confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizationScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // App Language Card
        _buildSectionHeader(
          context.tr('app_language_title'),
          Icons.translate_rounded,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn ngôn ngữ giao diện của ứng dụng:',
                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppLanguage.values.map((lang) {
                    final isSelected = localization.language == lang;
                    return ChoiceChip(
                      label: Text('${lang.flag}  ${lang.label}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          localization.onLanguageChanged(lang);
                        }
                      },
                      selectedColor: theme.colorScheme.primary.withAlpha(40),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Appearance / Theme Card
        _buildSectionHeader(
          context.tr('appearance_title'),
          Icons.palette_outlined,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(context.tr('theme_system')),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(context.tr('theme_light')),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(context.tr('theme_dark')),
                  ),
                ],
                selected: {widget.currentThemeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  widget.onThemeModeChanged(newSelection.first);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // TTS Engine Settings Card (Android & Cross-platform)
        _buildSectionHeader(
          context.tr('tts_settings_title'),
          Icons.settings_voice_outlined,
        ),
        Card(
          child: Column(
            children: [
              if (widget.ttsService.engines.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(context.tr('tts_engine_name')),
                  subtitle: Text(widget.ttsService.currentEngine ?? 'Default'),
                  trailing: DropdownButton<String>(
                    value: widget.ttsService.engines
                            .contains(widget.ttsService.currentEngine)
                        ? widget.ttsService.currentEngine
                        : null,
                    underline: const SizedBox(),
                    items: widget.ttsService.engines.map((eng) {
                      return DropdownMenuItem(
                        value: eng,
                        child: Text(
                          eng.split('.').last,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await widget.ttsService.setEngine(val);
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Làm mới danh sách giọng đọc'),
                subtitle: Text(
                  'Hiện có ${widget.ttsService.allVoices.length} giọng đọc được nhận diện.',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await widget.ttsService.loadVoices();
                    if (!mounted) return;
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã tải lại: ${widget.ttsService.allVoices.length} giọng đọc.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Storage Management Card
        _buildSectionHeader(
          'Quản lý dữ liệu & Bộ nhớ',
          Icons.folder_shared_outlined,
        ),
        Card(
          child: Column(
            children: [
              FutureBuilder<Directory>(
                future: TtsService.getAudioStorageDirectory(),
                builder: (context, snapshot) {
                  final path = snapshot.data?.path ?? 'copecute/readio';
                  return ListTile(
                    leading: const Icon(Icons.folder_special_outlined),
                    title: Text(context.tr('storage_location_title')),
                    subtitle: Text(path, style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.folder_open_rounded, size: 20),
                          tooltip: context.tr('btn_open_folder'),
                          onPressed: () => HistoryService.openFolder(path),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Sao chép đường dẫn',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: path));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('storage_folder_copied')),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Dung lượng tệp âm thanh'),
                subtitle: Text('$_totalSavedFiles tệp đã lưu • $_formattedStorage'),
                trailing: _totalSavedFiles > 0
                    ? TextButton(
                        onPressed: _showClearCacheDialog,
                        child: const Text(
                          'Dọn dẹp',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // How to Add More Voices Guide
        _buildSectionHeader(
          context.tr('guide_title'),
          Icons.help_outline_rounded,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.desktop_windows_outlined,
                        color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Windows (PC & Laptop)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('guide_windows'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_android_outlined,
                        color: Colors.green, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Android (Điện thoại & Máy tính bảng)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('guide_android'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // About Card
        _buildSectionHeader(
          context.tr('about_title'),
          Icons.info_outline_rounded,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.graphic_eq, color: Colors.white),
                ),
                title: const Text(
                  'Readio Text to Speech',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(context.tr('app_subtitle')),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Readio chạy hoàn toàn ngoại tuyến và trực tiếp dựa trên Engine Text-to-Speech của hệ điều hành (Windows Speech API / Android TextToSpeech). Dữ liệu văn bản và âm thanh của bạn được bảo mật tuyệt đối trên thiết bị.',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
