import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../core/localization/app_locale.dart';
import '../models/tts_voice_item.dart';
import '../models/history_audio_item.dart';
import '../models/tts_preset.dart';
import '../models/bgm_track.dart';
import '../services/tts_service.dart';
import '../services/history_service.dart';
import '../services/audio_player_service.dart';
import '../services/preset_service.dart';
import '../services/bgm_service.dart';
import '../widgets/bgm_manager_sheet.dart';

class CreateView extends StatefulWidget {
  final TtsService ttsService;
  final HistoryService historyService;
  final AudioPlayerService audioPlayerService;
  final PresetService presetService;
  final BgmService bgmService;
  final VoidCallback onGoToHistory;

  const CreateView({
    super.key,
    required this.ttsService,
    required this.historyService,
    required this.audioPlayerService,
    required this.presetService,
    required this.bgmService,
    required this.onGoToHistory,
  });

  @override
  State<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<CreateView> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isGenerating = false;
  bool _isPreviewingInputText = false;
  bool _isCustomFileName = false;
  String _exportFormat = 'wav';
  String? _selectedCountryLocale;
  String? _lastGeneratedPath;
  String? _lastGeneratedTitle;
  HistoryAudioItem? _lastGeneratedItem;
  StreamSubscription<TtsPlaybackState>? _ttsStateSub;

  String _generateDefaultFileName() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      final now = DateTime.now();
      return 'Audio_${now.minute}${now.second}';
    }
    // First line
    String line = text.split(RegExp(r'[\r\n]+')).first.trim();
    if (line.length > 30) {
      line = line.substring(0, 30).trim();
    }
    // Remove invalid filename characters
    final sanitized = line.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    if (sanitized.isEmpty) {
      final now = DateTime.now();
      return 'Audio_${now.minute}${now.second}';
    }
    return sanitized;
  }

  void _onTextChanged() {
    if (!_isCustomFileName) {
      final autoName = _generateDefaultFileName();
      if (_fileNameController.text != autoName) {
        _fileNameController.text = autoName;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initVoiceSelection();
    _fileNameController.text = _generateDefaultFileName();
    _textController.addListener(_onTextChanged);
    widget.presetService.addListener(_onPresetChanged);
    _ttsStateSub = widget.ttsService.stateStream.listen((state) {
      if (state == TtsPlaybackState.stopped) {
        if (_isPreviewingInputText && mounted) {
          setState(() {
            _isPreviewingInputText = false;
          });
        }
        if (widget.bgmService.isPlaying) {
          widget.bgmService.stopBgm();
        }
      } else if (state == TtsPlaybackState.paused) {
        if (widget.bgmService.isPlaying) {
          widget.bgmService.pauseBgm();
        }
      }
    });
  }

  void _onPresetChanged() {
    if (mounted) setState(() {});
  }

  void _initVoiceSelection() {
    final currentVoice = widget.ttsService.currentVoice;
    if (currentVoice != null) {
      _selectedCountryLocale = currentVoice.locale;
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    widget.presetService.removeListener(_onPresetChanged);
    _ttsStateSub?.cancel();
    _textController.dispose();
    _fileNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Text statistics
  int get _charCount => _textController.text.length;
  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  String get _estimatedReadTime {
    final words = _wordCount;
    if (words == 0) return '0s';
    final rate = widget.ttsService.speechRate > 0
        ? (widget.ttsService.speechRate / 0.5)
        : 1.0;
    // Average speech is ~140 words per minute at 1.0x
    final seconds = (words / (140 * rate / 60)).round();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes}m ${remainingSecs}s';
  }

  Future<void> _pasteFromClipboard() async {
    final msg = context.tr('btn_paste');
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
      });
      _showMessage(msg);
    }
  }

  Future<void> _loadTxtFile() async {
    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (result.isEmpty) return;
      final bytes = await result.first.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      setState(() {
        _textController.text = content;
      });
      _showMessage('${context.tr('btn_load_txt')}: ${result.first.name}');
    } catch (e) {
      if (mounted) {
        _showMessage('Error loading file: $e');
      }
    }
  }

  void _showSampleDialog() {
    final samples = [
      {
        'title': 'Tiếng Việt - Đoạn văn bản mẫu',
        'text':
            'Chào mừng bạn đến với Readio! Ứng dụng chuyển đổi văn bản thành giọng nói chất lượng cao trên thiết bị của bạn. Bạn có thể tự do điều chỉnh tốc độ, cao độ và lưu lại các tệp âm thanh WAV yêu thích.',
      },
      {
        'title': 'English - Technology & Innovation',
        'text':
            'Welcome to Readio Text to Speech Studio. Enjoy natural voice synthesis running completely on your device. Customize speech rate, pitch, and export crystal-clear audio files anytime.',
      },
      {
        'title': 'Lời chào đa ngôn ngữ (Multilingual greeting)',
        'text':
            'Xin chào! Hello! Bonjour! Hola! こんにちは! 안녕하세요! Guten Tag! Cảm ơn bạn đã lựa chọn trải nghiệm Readio.',
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('btn_samples'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 14),
              ...samples.map((s) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        s['title']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        s['text']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        setState(() {
                          _textController.text = s['text']!;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  String _getPreviewText(String text, {int maxChars = 220}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChars) return trimmed;
    final sub = trimmed.substring(0, maxChars);
    final lastPunct = sub.lastIndexOf(RegExp(r'[.!?\n]'));
    if (lastPunct > 40) {
      return sub.substring(0, lastPunct + 1);
    }
    final lastSpace = sub.lastIndexOf(' ');
    if (lastSpace > 40) {
      return '${sub.substring(0, lastSpace)}...';
    }
    return '$sub...';
  }

  void _togglePlayPreview() async {
    if (_isPreviewingInputText && widget.ttsService.isSpeaking) {
      await widget.ttsService.stop();
      if (widget.bgmService.isPlaying) {
        await widget.bgmService.stopBgm();
      }
      if (mounted) {
        setState(() {
          _isPreviewingInputText = false;
        });
      }
      return;
    }

    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      _showMessage(context.tr('input_hint'));
      return;
    }

    final previewText = _getPreviewText(rawText);
    setState(() {
      _isPreviewingInputText = true;
    });
    if (widget.bgmService.isEnabled) {
      widget.bgmService.startBgm();
    }
    await widget.ttsService.applySettings();
    await widget.ttsService.speak(previewText);
  }

  Future<void> _generateAndSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    // Stop ongoing preview playback & BGM immediately to focus on generation
    if (widget.ttsService.isSpeaking) {
      await widget.ttsService.stop();
    }
    if (widget.bgmService.isPlaying) {
      await widget.bgmService.stopBgm();
    }
    if (_isPreviewingInputText) {
      setState(() {
        _isPreviewingInputText = false;
      });
    }

    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.copecute.readio/storage');
        final bool hasPermission =
            await channel.invokeMethod<bool>('hasStoragePermission') ?? false;
        if (!hasPermission) {
          if (!mounted) return;
          final bool? shouldRequest = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Icon(Icons.folder_special_rounded, color: Color(0xFF6C5CE7), size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('storage_permission_title'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                context.tr('storage_permission_desc'),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.tr('storage_permission_cancel')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(context.tr('storage_permission_grant')),
                ),
              ],
            ),
          );
          if (shouldRequest == true) {
            await channel.invokeMethod('requestStoragePermission');
          }
          return;
        }
      } catch (e) {
        debugPrint('Error checking storage permission: $e');
      }
    }

    setState(() {
      _isGenerating = true;
    });

    double currentProgress = 10;
    void Function(void Function())? overlaySetState;
    final cancelToken = CancelToken();
    bool cancelled = false;
    OverlayEntry? overlayEntry;

    Future<void> doCancel() async {
      if (cancelled) return;
      cancelled = true;
      cancelToken.cancel();
      await widget.ttsService.stop();
      overlayEntry?.remove();
      overlayEntry = null;
      if (mounted) {
        setState(() { _isGenerating = false; });
        _showMessage(context.tr('generate_cancelled'));
      }
    }

    void Function()? dismissOverlay;

    if (!mounted) return;

    // Compute file name early for display
    final rawNamePreview = _fileNameController.text.trim().isNotEmpty
        ? _fileNameController.text.trim()
        : _generateDefaultFileName();
    final String displayFileName = rawNamePreview.isNotEmpty
        ? (rawNamePreview.toLowerCase().endsWith('.$_exportFormat')
            ? rawNamePreview
            : '$rawNamePreview.$_exportFormat')
        : 'audio.$_exportFormat';

    overlayEntry = OverlayEntry(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            overlaySetState = setSt;
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            return PopScope(
              canPop: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withAlpha(200),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated progress ring
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: currentProgress / 100.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              builder: (_, value, child) {
                                final pct = (value * 100).round();
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 96,
                                      height: 96,
                                      child: CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 7,
                                        color: colorScheme.primary,
                                        backgroundColor: colorScheme.primary.withAlpha(40),
                                      ),
                                    ),
                                    Text(
                                      '$pct%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            // File name
                            Text(
                              displayFileName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Subtitle
                            Text(
                              context.tr('generating_please_wait'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(170),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Cancel button
                            OutlinedButton.icon(
                              onPressed: doCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.stop_circle_outlined, size: 20),
                              label: Text(
                                context.tr('generate_cancelled_btn'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry!);

    dismissOverlay = () {
      overlayEntry?.remove();
      overlayEntry = null;
    };

    void updateProgress(int percent, String stage) {
      if (cancelled) return;
      currentProgress = percent.toDouble();
      overlaySetState?.call(() {});
      widget.ttsService.updateProgressNotification(
        title: displayFileName,
        progress: percent,
        isFinished: percent >= 100,
      );
    }

    try {
      updateProgress(25, '');
      await Future.delayed(const Duration(milliseconds: 200));

      final rawName = _fileNameController.text.trim().isNotEmpty
          ? _fileNameController.text.trim()
          : _generateDefaultFileName();
      String customName = rawName.replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_').trim();
      
      final ext = '.$_exportFormat';
      if (!customName.toLowerCase().endsWith(ext)) {
        customName = customName.replaceAll(RegExp(r'\.(wav|mp3|m4a|aac)$', caseSensitive: false), '');
        customName = '$customName$ext';
      }

      final String fullPath = await widget.ttsService.synthesizeToFile(
        text,
        customFileName: customName.isNotEmpty ? customName : null,
        targetTitle: customName.isNotEmpty ? customName : null,
        bgmTrack: widget.bgmService.isEnabled ? widget.bgmService.currentTrack : null,
        bgmVolume: widget.bgmService.volume,
        bgmPlayMode: widget.bgmService.playMode,
        cancelToken: cancelToken,
        onProgress: (ratio, status) {
          updateProgress((ratio * 100).toInt().clamp(10, 98), status);
        },
      );

      if (cancelled) return;

      final File savedFile = File(fullPath);
      final int size = savedFile.existsSync() ? savedFile.lengthSync() : 0;
      final String fileName = savedFile.uri.pathSegments.last;

      final currentVoice = widget.ttsService.currentVoice;
      String voiceDisplayName = currentVoice?.name ?? 'System Voice';
      if (currentVoice != null) {
        final filtered = widget.ttsService.allVoices
            .where((v) => v.locale == currentVoice.locale)
            .toList();
        final map = TtsService.getVoiceDisplayNames(filtered);
        voiceDisplayName = map[currentVoice.uniqueKey] ?? currentVoice.getFriendlyName();
      }

      final historyItem = HistoryAudioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        text: text,
        filePath: fullPath,
        createdAt: DateTime.now(),
        fileSizeBytes: size,
        voiceName: voiceDisplayName,
        locale: currentVoice?.locale ?? 'Unknown',
        pitch: widget.ttsService.pitch,
        rate: widget.ttsService.speechRate,
      );

      await widget.historyService.addItem(historyItem);
      updateProgress(100, 'Tạo tệp thành công: $fileName');

      if (mounted) {
        dismissOverlay?.call();
        setState(() {
          _lastGeneratedPath = fullPath;
          _lastGeneratedTitle = fileName;
          _lastGeneratedItem = historyItem;
        });
        _showSuccessSnackBar(historyItem);
      }
    } on GenerationCancelledException {
      // User cancelled — already handled in doCancel(), nothing to do here
    } catch (e) {
      if (mounted && !cancelled) {
        dismissOverlay?.call();
        _showMessage('${context.tr('generate_error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(HistoryAudioItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('generate_success'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item.filePath,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.tr('btn_preview'),
          onPressed: () {
            widget.audioPlayerService.playItem(item);
            widget.onGoToHistory();
          },
        ),
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFixedBottomActionBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 25),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Preview Button (Nghe thử 10-30s)
            Expanded(
              flex: 4,
              child: StreamBuilder<TtsPlaybackState>(
                stream: widget.ttsService.stateStream,
                initialData: widget.ttsService.playbackState,
                builder: (context, snapshot) {
                  final isPreviewingText = _isPreviewingInputText &&
                      widget.ttsService.isSpeaking &&
                      widget.ttsService.previewingVoiceKey == null &&
                      !_isGenerating;

                  return OutlinedButton.icon(
                    onPressed: (!hasText || _isGenerating) ? null : _togglePlayPreview,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isPreviewingText
                            ? Colors.redAccent
                            : theme.colorScheme.primary.withAlpha(180),
                        width: 1.5,
                      ),
                      foregroundColor: isPreviewingText ? Colors.redAccent : theme.colorScheme.primary,
                    ),
                    icon: Icon(
                      isPreviewingText ? Icons.stop_circle_rounded : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isPreviewingText ? context.tr('stop_preview') : '${context.tr('btn_preview')} (10-30s)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Create Audio Button (Tạo âm thanh)
            Expanded(
              flex: 5,
              child: FilledButton.icon(
                onPressed: (!hasText || _isGenerating) ? null : _generateAndSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  elevation: 3,
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isGenerating ? 'Đang tạo...' : context.tr('btn_create'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 16,
                  vertical: 14,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 960 : 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Textarea with Quick Actions Toolbar
                        _buildEditorCard(),
                        const SizedBox(height: 14),

                        // 2. Reading Configuration / Preset Tile
                        _buildReadingConfigCard(),
                        const SizedBox(height: 14),

                        // 3. Background Music Tile
                        _buildBgmCard(),

                        // 4. Recently Generated Audio Card (if available)
                        if (_lastGeneratedPath != null) ...[
                          const SizedBox(height: 14),
                          _buildRecentGeneratedCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 4. Fixed Bottom Action Bar
        _buildFixedBottomActionBar(),
      ],
    );
  }

  Widget _buildEditorCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _textController.text.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(isDark ? 60 : 90),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Quick Action Buttons & Stats
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Quick Action Pill: Paste
                    _buildToolbarPill(
                      icon: Icons.content_paste_rounded,
                      label: context.tr('btn_paste'),
                      onTap: _pasteFromClipboard,
                      theme: theme,
                    ),

                    // Quick Action Pill: Load TXT
                    _buildToolbarPill(
                      icon: Icons.file_open_rounded,
                      label: context.tr('btn_load_txt'),
                      onTap: _loadTxtFile,
                      theme: theme,
                    ),

                    // Quick Action Pill: Sample
                    _buildToolbarPill(
                      icon: Icons.auto_stories_rounded,
                      label: context.tr('btn_samples'),
                      onTap: _showSampleDialog,
                      theme: theme,
                    ),

                    if (hasText)
                      IconButton(
                        tooltip: context.tr('clear_text'),
                        icon: const Icon(Icons.backspace_outlined, size: 18),
                        color: Colors.redAccent.withAlpha(200),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _textController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
                // Stats Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_charCount kt • ~$_estimatedReadTime',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Textarea container
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _textController,
                scrollController: _scrollController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('input_hint'),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.hintColor.withAlpha(140),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Export Filename Preview & Edit Bar (not focused by default)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.audio_file_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${context.tr('export_filename')}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fileNameController,
                      autofocus: false,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        _isCustomFileName = val.trim().isNotEmpty;
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.tr('filename_hint'),
                        hintStyle: TextStyle(fontSize: 12, color: theme.hintColor.withAlpha(120)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (_isCustomFileName) ...[
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Tự động theo văn bản',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _isCustomFileName = false;
                          _fileNameController.text = _generateDefaultFileName();
                        });
                      },
                    ),
                  ],
                  PopupMenuButton<String>(
                    initialValue: _exportFormat,
                    onSelected: (val) {
                      setState(() {
                        _exportFormat = val;
                      });
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'wav',
                        child: Row(
                          children: [
                            Icon(Icons.audiotrack_rounded, size: 18, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('.WAV (Chất lượng gốc)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'mp3',
                        child: Row(
                          children: [
                            Icon(Icons.music_note_rounded, size: 18, color: Colors.purpleAccent),
                            SizedBox(width: 8),
                            Text('.MP3 (Nén gọn nhẹ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(70)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '.${_exportFormat.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPreset(TtsPreset preset, [StateSetter? modalSetState]) async {
    await widget.presetService.setActivePreset(preset);
    await widget.ttsService.setSpeechRate(preset.speechRate);
    await widget.ttsService.setPitch(preset.pitch);
    await widget.ttsService.setVolume(preset.volume);
    if (preset.voiceKey != null) {
      final found = widget.ttsService.allVoices.cast<TtsVoiceItem?>().firstWhere(
            (v) => v?.uniqueKey == preset.voiceKey,
            orElse: () => null,
          );
      if (found != null) {
        await widget.ttsService.setVoice(found);
      }
    }
    modalSetState?.call(() {});
    if (mounted) setState(() {});
  }

  Future<void> _showSavePresetDialog([StateSetter? modalSetState]) async {
    final textCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('preset_save_new')),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr('preset_name_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('btn_cancel')),
          ),
          FilledButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            child: Text(context.tr('btn_save')),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newPreset = TtsPreset(
        id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
        name: result,
        voiceKey: widget.ttsService.currentVoice?.uniqueKey,
        voiceName: widget.ttsService.currentVoice?.getFriendlyName(),
        locale: widget.ttsService.currentVoice?.locale,
        speechRate: widget.ttsService.speechRate,
        pitch: widget.ttsService.pitch,
        volume: widget.ttsService.volume,
        isBuiltIn: false,
      );
      await widget.presetService.savePreset(newPreset);
      modalSetState?.call(() {});
      if (mounted) {
        setState(() {});
        _showMessage(context.tr('preset_saved_success'));
      }
    }
  }

  Widget _buildReadingConfigCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentVoice = widget.ttsService.currentVoice;
    final activePreset = widget.presetService.activePreset;
    final presetName = activePreset?.name ?? 'Tùy chỉnh';
    final friendlyVoiceName = currentVoice?.getFriendlyName() ?? 'Giọng đọc mặc định';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(isDark ? 60 : 90),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openConfigurationModal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr('reading_config_title'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            presetName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      friendlyVoiceName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '⚡ Tốc độ: ${(widget.ttsService.speechRate / 0.5).toStringAsFixed(1)}x  •  🎚️ Cao độ: ${widget.ttsService.pitch.toStringAsFixed(1)}x',
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cấu hình',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgmCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.bgmService,
      builder: (context, _) {
        final isEnabled = widget.bgmService.isEnabled;
        final currentTrack = widget.bgmService.currentTrack;
        final volPercent = (widget.bgmService.volume * 100).round();

        String modeLabel;
        switch (widget.bgmService.playMode) {
          case BgmPlayMode.repeatOne:
            modeLabel = context.tr('bgm_mode_repeat_one');
            break;
          case BgmPlayMode.repeatAll:
            modeLabel = context.tr('bgm_mode_repeat_all');
            break;
          case BgmPlayMode.playOneOnce:
            modeLabel = context.tr('bgm_mode_play_one_once');
            break;
          case BgmPlayMode.playAllOnce:
            modeLabel = context.tr('bgm_mode_play_all_once');
            break;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(isDark ? 60 : 90),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              BgmManagerSheet.show(context, widget.bgmService);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isEnabled
                            ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                            : [Colors.grey.shade600, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.tr('bgm_title'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? Colors.purple.withAlpha(25)
                                    : theme.hintColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isEnabled ? context.tr('bgm_enabled') : context.tr('bgm_disabled'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isEnabled ? Colors.purple : theme.hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isEnabled
                              ? (currentTrack?.name ?? context.tr('bgm_choose_track'))
                              : context.tr('bgm_off_description'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isEnabled ? null : theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isEnabled) ...[
                          const SizedBox(height: 3),
                          Text(
                            '🔊 ${context.tr('bgm_volume')}: $volPercent%  •  🔂 $modeLabel',
                            style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isEnabled,
                    onChanged: (val) {
                      widget.bgmService.setEnabled(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openConfigurationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return AnimatedBuilder(
              animation: Listenable.merge([widget.ttsService, widget.presetService]),
              builder: (animCtx, _) {
                final currentVoice = widget.ttsService.currentVoice;
                final allVoices = widget.ttsService.allVoices;
                final locales = allVoices.map((v) => v.locale).toSet().toList()..sort();
                if (_selectedCountryLocale == null && locales.isNotEmpty) {
                  _selectedCountryLocale = locales.first;
                }
                final filteredVoices = allVoices
                    .where((v) => v.locale == _selectedCountryLocale)
                    .toList();
                final displayNames = TtsService.getVoiceDisplayNames(filteredVoices);

                final rate = widget.ttsService.speechRate;
                final pitch = widget.ttsService.pitch;
                final volume = widget.ttsService.volume;
                final isPreviewing = widget.ttsService.isPreviewing;

                return Container(
                  height: MediaQuery.of(ctx).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar & Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                        child: Column(
                          children: [
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ctx.tr('reading_config_title'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(modalCtx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Scrollable Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            // --- PRESET SECTION ---
                            Row(
                              children: [
                                Text(
                                  ctx.tr('preset_label'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () {
                                    _showSavePresetDialog(setModalState);
                                  },
                                  icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                                  label: Text(
                                    ctx.tr('save_preset'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Preset Pills
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.presetService.presets.map((preset) {
                                final isSelected = widget.presetService.activePresetId == preset.id;
                                return InputChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.label_outline_rounded,
                                        size: 14,
                                        color: isSelected ? Colors.white : theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                  onSelected: (_) {
                                    _applyPreset(preset, setModalState);
                                  },
                                  onDeleted: preset.isBuiltIn
                                      ? null
                                      : () async {
                                          await widget.presetService.deletePreset(preset.id);
                                          setModalState(() {});
                                          if (mounted) setState(() {});
                                        },
                                  deleteIconColor: isSelected ? Colors.white70 : theme.hintColor,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 20),

                            // --- VOICE SECTION ---
                            Row(
                              children: [
                                Text(
                                  ctx.tr('choose_voice'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const Spacer(),
                                // Country locale dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: theme.dividerColor.withAlpha(40)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCountryLocale,
                                      isDense: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      items: locales.map((loc) {
                                        final flag = TtsService.countryFlagFromLocale(loc);
                                        final name = TtsService.countryNameFromLocale(loc);
                                        return DropdownMenuItem<String>(
                                          value: loc,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(flag, style: const TextStyle(fontSize: 15)),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$name ($loc)',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newVal) {
                                        if (newVal != null) {
                                          setState(() {
                                            _selectedCountryLocale = newVal;
                                          });
                                          setModalState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Voice preview card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: theme.dividerColor.withAlpha(50)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.amber.withAlpha(35),
                                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.amber, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentVoice != null
                                              ? (displayNames[currentVoice.uniqueKey] ?? currentVoice.getFriendlyName())
                                              : ctx.tr('default_voice'),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (currentVoice?.genderLabel != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: (currentVoice!.genderLabel == 'Nữ' ? Colors.pinkAccent : Colors.blueAccent).withAlpha(25),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  currentVoice.genderLabel!,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: currentVoice.genderLabel == 'Nữ' ? Colors.pinkAccent : Colors.blueAccent,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                            ],
                                            Text(
                                              currentVoice?.locale ?? 'vi-VN',
                                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Audition voice button
                                  IconButton.filledTonal(
                                    icon: Icon(
                                      isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                      size: 20,
                                      color: isPreviewing ? Colors.redAccent : null,
                                    ),
                                    onPressed: () {
                                      if (isPreviewing) {
                                        widget.ttsService.stopPreview();
                                      } else if (currentVoice != null) {
                                        widget.ttsService.previewVoice(currentVoice);
                                      }
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  // Open full list button
                                  OutlinedButton(
                                    onPressed: () {
                                      _openVoiceAuditionSheet(filteredVoices, displayNames);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      ctx.tr('choose_voice_sheet_title'),
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),


                            const SizedBox(height: 20),

                            // --- BGM SECTION (NHẠC NỀN) ---
                            Row(
                              children: [
                                const Icon(Icons.music_note_rounded, color: Colors.purpleAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  ctx.tr('bgm_section_title'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const Spacer(),
                                Switch.adaptive(
                                  value: widget.bgmService.isEnabled,
                                  onChanged: (val) {
                                    widget.bgmService.setEnabled(val);
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (widget.bgmService.isEnabled) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: theme.dividerColor.withAlpha(50)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.purple.withAlpha(30),
                                          child: const Icon(Icons.audiotrack_rounded, color: Colors.purpleAccent, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.bgmService.currentTrack?.name ?? 'Chưa chọn nhạc',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Âm lượng: ${(widget.bgmService.volume * 100).toInt()}%',
                                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            BgmManagerSheet.show(context, widget.bgmService);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            ctx.tr('bgm_manager_title'),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // --- AUDIO PARAMS ---
                            Text(
                              ctx.tr('audio_params_title'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 12),

                            // Speech rate
                            Row(
                              children: [
                                const Icon(Icons.speed_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  ctx.tr('speech_rate'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(rate / 0.5).toStringAsFixed(1)}x',
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
                              value: rate.clamp(0.25, 0.75),
                              min: 0.25,
                              max: 0.75,
                              onChanged: (val) {
                                widget.ttsService.setSpeechRate(val);
                              },
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                _buildModalQuickChip(ctx.tr('preset_slow'), 0.42, rate, (v) {
                                  widget.ttsService.setSpeechRate(v);
                                }),
                                _buildModalQuickChip(ctx.tr('preset_normal'), 0.50, rate, (v) {
                                  widget.ttsService.setSpeechRate(v);
                                }),
                                _buildModalQuickChip(ctx.tr('preset_fast'), 0.58, rate, (v) {
                                  widget.ttsService.setSpeechRate(v);
                                }),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Pitch
                            Row(
                              children: [
                                const Icon(Icons.graphic_eq_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  ctx.tr('pitch'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${pitch.toStringAsFixed(1)}x',
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
                              value: pitch,
                              min: 0.5,
                              max: 2.0,
                              onChanged: (val) {
                                widget.ttsService.setPitch(val);
                              },
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                _buildModalQuickChip(ctx.tr('preset_deep'), 0.8, pitch, (v) {
                                  widget.ttsService.setPitch(v);
                                }),
                                _buildModalQuickChip(ctx.tr('preset_normal'), 1.0, pitch, (v) {
                                  widget.ttsService.setPitch(v);
                                }),
                                _buildModalQuickChip(ctx.tr('preset_high'), 1.3, pitch, (v) {
                                  widget.ttsService.setPitch(v);
                                }),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Volume
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  ctx.tr('volume'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  '${(volume * 100).toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                widget.ttsService.setVolume(val);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Apply / Done Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              ctx.tr('apply_config'),
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
          },
        );
      },
    );
  }

  void _openVoiceAuditionSheet(
    List<TtsVoiceItem> voices,
    Map<String, String> displayNames,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filterQuery = '';
        bool onlyFavorites = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final currentVoice = widget.ttsService.currentVoice;

            final displayedList = voices.where((v) {
              final name = displayNames[v.uniqueKey] ?? v.getFriendlyName();
              final matchesQuery = filterQuery.isEmpty ||
                  name.toLowerCase().contains(filterQuery.toLowerCase()) ||
                  v.name.toLowerCase().contains(filterQuery.toLowerCase());
              final matchesFav = !onlyFavorites || widget.ttsService.isFavorite(v);
              return matchesQuery && matchesFav;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.hintColor.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('choose_voice_sheet_title'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Search field
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        filterQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm giọng đọc...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('${context.tr('filter_all_voices')} (${voices.length})'),
                        selected: !onlyFavorites,
                        onSelected: (_) {
                          setModalState(() {
                            onlyFavorites = false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          '${context.tr('filter_favorite_voices')} (${voices.where((v) => widget.ttsService.isFavorite(v)).length})',
                        ),
                        selected: onlyFavorites,
                        onSelected: (_) {
                          setModalState(() {
                            onlyFavorites = true;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Voices List
                  Expanded(
                    child: displayedList.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy giọng đọc phù hợp',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          )
                        : ListView.separated(
                            itemCount: displayedList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final v = displayedList[i];
                              final isSelected = currentVoice?.name == v.name;
                              final isFav = widget.ttsService.isFavorite(v);
                              final friendlyName = displayNames[v.uniqueKey] ?? v.getFriendlyName();

                              return StreamBuilder<TtsPlaybackState>(
                                stream: widget.ttsService.stateStream,
                                builder: (context, _) {
                                  final isPreviewing =
                                      widget.ttsService.previewingVoiceKey == v.uniqueKey &&
                                          widget.ttsService.isSpeaking;

                                  return Card(
                                    elevation: isSelected ? 2 : 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    color: isSelected
                                        ? theme.colorScheme.primary.withAlpha(20)
                                        : null,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: IconButton(
                                        icon: Icon(
                                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: isFav ? Colors.amber : theme.hintColor,
                                        ),
                                        onPressed: () async {
                                          await widget.ttsService.toggleFavorite(v);
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              friendlyName,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (v.genderLabel != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (v.genderLabel == 'Nữ' ? Colors.pinkAccent : Colors.blueAccent).withAlpha(30),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                v.genderLabel!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: v.genderLabel == 'Nữ' ? Colors.pinkAccent : Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${v.name} • ${v.isNetwork ? 'Online' : 'Offline'}',
                                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Preview button on each voice
                                          IconButton.filledTonal(
                                            icon: Icon(
                                              isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                              size: 20,
                                              color: isPreviewing ? Colors.redAccent : null,
                                            ),
                                            onPressed: () {
                                              if (isPreviewing) {
                                                widget.ttsService.stopPreview();
                                              } else {
                                                widget.ttsService.previewVoice(v);
                                              }
                                              setModalState(() {});
                                              setState(() {});
                                            },
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                      onTap: () {
                                        widget.ttsService.setVoice(v);
                                        setState(() {});
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalQuickChip(
    String label,
    double value,
    double currentValue,
    ValueChanged<double> onSelect,
  ) {
    final isSelected = (currentValue - value).abs() < 0.05;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: theme.colorScheme.primary.withAlpha(35),
      visualDensity: VisualDensity.compact,
    );
  }

  void _playGeneratedAndOpenHistory() {
    if (_lastGeneratedItem != null) {
      widget.audioPlayerService.playItem(_lastGeneratedItem!);
    } else if (_lastGeneratedPath != null) {
      final found = widget.historyService.items.cast<HistoryAudioItem?>().firstWhere(
            (item) => item?.filePath == _lastGeneratedPath,
            orElse: () => null,
          );
      if (found != null) {
        widget.audioPlayerService.playItem(found);
      } else {
        final fallbackItem = HistoryAudioItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _lastGeneratedTitle ?? 'Audio.wav',
          text: _textController.text.trim(),
          filePath: _lastGeneratedPath!,
          createdAt: DateTime.now(),
          fileSizeBytes: File(_lastGeneratedPath!).existsSync()
              ? File(_lastGeneratedPath!).lengthSync()
              : 0,
          voiceName: widget.ttsService.currentVoice?.getFriendlyName() ?? 'System Voice',
          locale: widget.ttsService.currentVoice?.locale ?? 'vi-VN',
          pitch: widget.ttsService.pitch,
          rate: widget.ttsService.speechRate,
        );
        widget.audioPlayerService.playItem(fallbackItem);
      }
    }
    widget.onGoToHistory();
  }

  Widget _buildRecentGeneratedCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withAlpha(20),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.check, color: Colors.white),
        ),
        title: Text(
          _lastGeneratedTitle ?? 'Audio.wav',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          context.tr('generate_success'),
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        onTap: _playGeneratedAndOpenHistory,
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: _playGeneratedAndOpenHistory,
        ),
      ),
    );
  }
}
