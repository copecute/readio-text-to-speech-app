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
  bool _configDirty = false;
  String _exportFormat = 'mp3';
  String? _selectedCountryLocale;
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
    _loadExportFormat();
    _fileNameController.text = _generateDefaultFileName();
    _textController.addListener(_onTextChanged);
    widget.presetService.addListener(_onPresetChanged);
    widget.ttsService.addListener(_onTtsChanged);
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

  Future<void> _loadExportFormat() async {
    final format = await TtsService.loadExportFormat();
    if (!mounted) return;
    setState(() {
      _exportFormat = format;
    });
  }

  Future<void> _setExportFormat(String format) async {
    final normalized = format == 'wav' ? 'wav' : 'mp3';
    setState(() {
      _exportFormat = normalized;
    });
    await TtsService.saveExportFormat(normalized);
  }

  void _onPresetChanged() {
    if (mounted) setState(() {});
  }

  void _onTtsChanged() {
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
    widget.ttsService.removeListener(_onTtsChanged);
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
                        _buildEditorCard(),
                        const SizedBox(height: 14),
                        _buildReadingConfigCard(),
                        const SizedBox(height: 14),
                        _buildBgmCard(),
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
                      _setExportFormat(val);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'mp3',
                        child: Row(
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              size: 18,
                              color: _exportFormat == 'mp3'
                                  ? theme.colorScheme.primary
                                  : Colors.deepOrangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '.MP3 (Nén gọn nhẹ)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _exportFormat == 'mp3'
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            if (_exportFormat == 'mp3') ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.primary),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'wav',
                        child: Row(
                          children: [
                            Icon(
                              Icons.audiotrack_rounded,
                              size: 18,
                              color: _exportFormat == 'wav'
                                  ? theme.colorScheme.primary
                                  : Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '.WAV (Chất lượng gốc)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _exportFormat == 'wav'
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            if (_exportFormat == 'wav') ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.primary),
                            ],
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
    await widget.ttsService.applyPresetValues(
      speechRate: preset.speechRate,
      pitch: preset.pitch,
      volume: preset.volume,
      voiceKey: preset.voiceKey,
      locale: preset.locale,
      voiceName: preset.voiceName,
    );
    final appliedVoice = widget.ttsService.currentVoice;
    if (appliedVoice != null) {
      _selectedCountryLocale = appliedVoice.locale;
    } else if (preset.locale != null && preset.locale!.isNotEmpty) {
      _selectedCountryLocale = preset.locale;
    }
    _configDirty = false;
    modalSetState?.call(() {});
    if (mounted) setState(() {});
  }

  void _markConfigDirty([StateSetter? modalSetState]) {
    final active = widget.presetService.activePreset;
    final dirty = active == null ||
        !active.matchesSettings(
          speechRate: widget.ttsService.speechRate,
          pitch: widget.ttsService.pitch,
          volume: widget.ttsService.volume,
          voiceKey: widget.ttsService.currentVoice?.uniqueKey,
        );
    if (_configDirty != dirty) {
      _configDirty = dirty;
      modalSetState?.call(() {});
      if (mounted) setState(() {});
    } else {
      modalSetState?.call(() {});
    }
  }

  /// Persist current live TTS settings into the active preset (or prompt for a new one).
  Future<bool> _saveCurrentConfigAsPreset([StateSetter? modalSetState]) async {
    final voice = widget.ttsService.currentVoice;
    final active = widget.presetService.activePreset;

    if (active != null) {
      await widget.presetService.updatePresetSettings(
        id: active.id,
        voiceKey: voice?.uniqueKey,
        voiceName: voice?.name,
        locale: voice?.locale,
        speechRate: widget.ttsService.speechRate,
        pitch: widget.ttsService.pitch,
        volume: widget.ttsService.volume,
      );
      _configDirty = false;
      modalSetState?.call(() {});
      if (mounted) {
        setState(() {});
        _showMessage(context.tr('preset_updated_success'));
      }
      return true;
    }

    await _showSavePresetDialog(modalSetState);
    if (widget.presetService.activePreset != null) {
      _configDirty = false;
      return true;
    }
    return false;
  }

  Future<void> _showSavePresetDialog([StateSetter? modalSetState]) async {
    final active = widget.presetService.activePreset;
    final canUpdate = active != null;
    final textCtrl = TextEditingController(text: canUpdate ? active.name : '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(ctx.tr(canUpdate ? 'preset_save_or_update' : 'preset_save_new')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ctx.tr('preset_save_hint'),
              style: TextStyle(fontSize: 13, color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: ctx.tr('preset_name_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('btn_cancel')),
          ),
          if (canUpdate)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, {'action': 'update'});
              },
              child: Text(ctx.tr('preset_update_current')),
            ),
          FilledButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, {'action': 'new', 'name': name});
              }
            },
            child: Text(ctx.tr(canUpdate ? 'preset_save_as_new' : 'btn_save')),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result['action'] == 'update' && canUpdate) {
      final voice = widget.ttsService.currentVoice;
      await widget.presetService.updatePresetSettings(
        id: active.id,
        voiceKey: voice?.uniqueKey,
        voiceName: voice?.name,
        locale: voice?.locale,
        speechRate: widget.ttsService.speechRate,
        pitch: widget.ttsService.pitch,
        volume: widget.ttsService.volume,
      );
      final newName = textCtrl.text.trim();
      if (newName.isNotEmpty && newName != active.name) {
        await widget.presetService.savePreset(
          active.copyWith(
            name: newName,
            voiceKey: voice?.uniqueKey,
            voiceName: voice?.name,
            locale: voice?.locale,
            speechRate: widget.ttsService.speechRate,
            pitch: widget.ttsService.pitch,
            volume: widget.ttsService.volume,
          ),
        );
      }
      modalSetState?.call(() {});
      if (mounted) {
        setState(() {
          _configDirty = false;
        });
        _showMessage(context.tr('preset_updated_success'));
      }
      return;
    }

    final name = (result['name'] as String?)?.trim() ?? '';
    if (name.isNotEmpty) {
      final voice = widget.ttsService.currentVoice;
      final newPreset = TtsPreset(
        id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        voiceKey: voice?.uniqueKey,
        voiceName: voice?.name,
        locale: voice?.locale,
        speechRate: widget.ttsService.speechRate,
        pitch: widget.ttsService.pitch,
        volume: widget.ttsService.volume,
      );
      await widget.presetService.savePreset(newPreset);
      await widget.ttsService.applyPresetValues(
        speechRate: newPreset.speechRate,
        pitch: newPreset.pitch,
        volume: newPreset.volume,
        voiceKey: newPreset.voiceKey,
        locale: newPreset.locale,
        voiceName: newPreset.voiceName,
      );
      modalSetState?.call(() {});
      if (mounted) {
        setState(() {
          _configDirty = false;
        });
        _showMessage(context.tr('preset_saved_success'));
      }
    }
  }

  Widget _buildReadingConfigCard() {
    final theme = Theme.of(context);
    final currentVoice = widget.ttsService.currentVoice;
    final activePreset = widget.presetService.activePreset;
    final unsaved = _configDirty || activePreset == null;
    final presetName = unsaved
        ? context.tr('preset_custom')
        : (activePreset.name);
    final friendlyVoiceName =
        currentVoice?.getFriendlyName() ?? context.tr('default_voice');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openConfigurationModal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                        if (unsaved) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('preset_unsaved'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friendlyVoiceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$presetName  ·  ${(widget.ttsService.speechRate / 0.5).toStringAsFixed(1)}x  ·  ${widget.ttsService.pitch.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgmCard() {
    final theme = Theme.of(context);

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
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              BgmManagerSheet.show(context, widget.bgmService);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isEnabled ? Colors.purple : theme.hintColor)
                          .withAlpha(28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: isEnabled ? Colors.purple : theme.hintColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('bgm_title'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? (currentTrack?.name ??
                                  context.tr('bgm_choose_track'))
                              : context.tr('bgm_off_description'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isEnabled ? null : theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isEnabled) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${context.tr('bgm_volume')}: $volPercent%  ·  $modeLabel',
                            style: TextStyle(
                                fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                      ],
                    ),
                  ),
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

  Widget _configSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
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
              animation: Listenable.merge(
                  [widget.ttsService, widget.presetService]),
              builder: (animCtx, _) {
                final currentVoice = widget.ttsService.currentVoice;
                final allVoices = widget.ttsService.allVoices;
                final locales =
                    allVoices.map((v) => v.locale).toSet().toList()..sort();
                if (_selectedCountryLocale == null && locales.isNotEmpty) {
                  _selectedCountryLocale =
                      currentVoice?.locale ?? locales.first;
                }
                if (currentVoice != null &&
                    locales.contains(currentVoice.locale) &&
                    _selectedCountryLocale != currentVoice.locale) {
                  _selectedCountryLocale = currentVoice.locale;
                }
                final filteredVoices = allVoices
                    .where((v) => v.locale == _selectedCountryLocale)
                    .toList();
                final displayNames =
                    TtsService.getVoiceDisplayNames(filteredVoices);

                final rate = widget.ttsService.speechRate;
                final pitch = widget.ttsService.pitch;
                final volume = widget.ttsService.volume;
                final isPreviewing = widget.ttsService.isPreviewing;
                final bottomPad = MediaQuery.of(ctx).padding.bottom;
                final unsaved = _configDirty ||
                    widget.presetService.activePreset == null;

                return Container(
                  height: MediaQuery.of(ctx).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.hintColor.withAlpha(55),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          ctx.tr('reading_config_title'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      if (unsaved) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.circle,
                                            size: 8,
                                            color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          ctx.tr('preset_unsaved'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(modalCtx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: [
                            // ---- PRESETS ----
                            _configSectionHeader(
                              ctx.tr('preset_label'),
                              Icons.bookmark_rounded,
                              trailing: TextButton.icon(
                                onPressed: () =>
                                    _showSavePresetDialog(setModalState),
                                icon: const Icon(Icons.bookmark_add_outlined,
                                    size: 16),
                                label: Text(
                                  ctx.tr('save_preset'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                              ),
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: widget.presetService.presets.isEmpty
                                    ? Text(
                                        ctx.tr('preset_empty_hint'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.hintColor,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: widget.presetService.presets
                                            .map((preset) {
                                          final selected = widget.presetService
                                                      .activePresetId ==
                                                  preset.id &&
                                              !_configDirty;
                                          return InputChip(
                                            selected: selected,
                                            avatar: Icon(
                                              selected
                                                  ? Icons.check_circle_rounded
                                                  : Icons.tune_rounded,
                                              size: 16,
                                              color: selected
                                                  ? Colors.white
                                                  : theme.colorScheme.primary,
                                            ),
                                            label: Text(preset.name),
                                            labelStyle: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                              color: selected
                                                  ? Colors.white
                                                  : null,
                                            ),
                                            selectedColor:
                                                theme.colorScheme.primary,
                                            backgroundColor: theme.colorScheme
                                                .surfaceContainerHighest
                                                .withAlpha(90),
                                            side: BorderSide.none,
                                            onSelected: (_) => _applyPreset(
                                                preset, setModalState),
                                            onDeleted: () async {
                                              final ok =
                                                  await showDialog<bool>(
                                                context: ctx,
                                                builder: (dCtx) => AlertDialog(
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: Text(dCtx.tr(
                                                      'preset_delete_title')),
                                                  content: Text(dCtx
                                                      .tr(
                                                          'preset_delete_confirm')
                                                      .replaceAll('{name}',
                                                          preset.name)),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dCtx, false),
                                                      child: Text(dCtx
                                                          .tr('btn_cancel')),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dCtx, true),
                                                      child: Text(dCtx
                                                          .tr('btn_delete')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                await widget.presetService
                                                    .deletePreset(preset.id);
                                                final next = widget
                                                    .presetService.activePreset;
                                                if (next != null) {
                                                  await _applyPreset(
                                                      next, setModalState);
                                                } else {
                                                  _configDirty = true;
                                                  setModalState(() {});
                                                  if (mounted) setState(() {});
                                                }
                                              }
                                            },
                                            deleteIconColor: selected
                                                ? Colors.white70
                                                : theme.hintColor,
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ---- VOICE ----
                            _configSectionHeader(
                              ctx.tr('choose_voice'),
                              Icons.record_voice_over_rounded,
                              trailing: locales.isEmpty
                                  ? null
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: locales.contains(
                                                _selectedCountryLocale)
                                            ? _selectedCountryLocale
                                            : locales.first,
                                        isDense: true,
                                        borderRadius: BorderRadius.circular(12),
                                        items: locales.map((loc) {
                                          return DropdownMenuItem(
                                            value: loc,
                                            child: Text(
                                              '${TtsService.countryFlagFromLocale(loc)} ${TtsService.countryNameFromLocale(loc)}',
                                              style: const TextStyle(
                                                  fontSize: 12.5),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val == null) return;
                                          setState(() {
                                            _selectedCountryLocale = val;
                                          });
                                          setModalState(() {});
                                        },
                                      ),
                                    ),
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: theme
                                          .colorScheme.primary
                                          .withAlpha(28),
                                      child: Icon(
                                        Icons.record_voice_over_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentVoice != null
                                                ? (displayNames[currentVoice
                                                        .uniqueKey] ??
                                                    currentVoice
                                                        .getFriendlyName())
                                                : ctx.tr('default_voice'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            currentVoice?.locale ?? '—',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () {
                                        if (isPreviewing) {
                                          widget.ttsService.stopPreview();
                                        } else if (currentVoice != null) {
                                          widget.ttsService
                                              .previewVoice(currentVoice);
                                        }
                                        setModalState(() {});
                                      },
                                      icon: Icon(
                                        isPreviewing
                                            ? Icons.stop_rounded
                                            : Icons.play_arrow_rounded,
                                        color: isPreviewing
                                            ? Colors.redAccent
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    FilledButton.tonal(
                                      onPressed: () {
                                        _openVoiceAuditionSheet(
                                            filteredVoices, displayNames);
                                      },
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      child: Text(
                                        ctx.tr('change_voice'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ---- AUDIO PARAMS ----
                            _configSectionHeader(
                              ctx.tr('audio_params_title'),
                              Icons.tune_rounded,
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 14, 14, 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _paramHeader(
                                      theme,
                                      Icons.speed_rounded,
                                      ctx.tr('speech_rate'),
                                      '${(rate / 0.5).toStringAsFixed(1)}x',
                                    ),
                                    Slider(
                                      value: rate.clamp(0.25, 0.75),
                                      min: 0.25,
                                      max: 0.75,
                                      divisions: 20,
                                      label:
                                          '${(rate / 0.5).toStringAsFixed(1)}x',
                                      onChanged: (val) {
                                        widget.ttsService.setSpeechRate(val,
                                            persist: false);
                                      },
                                      onChangeEnd: (val) async {
                                        await widget.ttsService
                                            .setSpeechRate(val);
                                        _markConfigDirty(setModalState);
                                      },
                                    ),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        _buildModalQuickChip(
                                            ctx.tr('preset_slow'), 0.42, rate,
                                            (v) async {
                                          await widget.ttsService
                                              .setSpeechRate(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                        _buildModalQuickChip(
                                            ctx.tr('preset_normal'),
                                            0.50,
                                            rate, (v) async {
                                          await widget.ttsService
                                              .setSpeechRate(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                        _buildModalQuickChip(
                                            ctx.tr('preset_fast'), 0.58, rate,
                                            (v) async {
                                          await widget.ttsService
                                              .setSpeechRate(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _paramHeader(
                                      theme,
                                      Icons.graphic_eq_rounded,
                                      ctx.tr('pitch'),
                                      '${pitch.toStringAsFixed(1)}x',
                                    ),
                                    Slider(
                                      value: pitch,
                                      min: 0.5,
                                      max: 2.0,
                                      divisions: 30,
                                      label: '${pitch.toStringAsFixed(1)}x',
                                      onChanged: (val) {
                                        widget.ttsService
                                            .setPitch(val, persist: false);
                                      },
                                      onChangeEnd: (val) async {
                                        await widget.ttsService.setPitch(val);
                                        _markConfigDirty(setModalState);
                                      },
                                    ),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        _buildModalQuickChip(
                                            ctx.tr('preset_deep'), 0.8, pitch,
                                            (v) async {
                                          await widget.ttsService.setPitch(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                        _buildModalQuickChip(
                                            ctx.tr('preset_normal'),
                                            1.0,
                                            pitch, (v) async {
                                          await widget.ttsService.setPitch(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                        _buildModalQuickChip(
                                            ctx.tr('preset_high'), 1.3, pitch,
                                            (v) async {
                                          await widget.ttsService.setPitch(v);
                                          _markConfigDirty(setModalState);
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _paramHeader(
                                      theme,
                                      Icons.volume_up_rounded,
                                      ctx.tr('volume'),
                                      '${(volume * 100).toInt()}%',
                                    ),
                                    Slider(
                                      value: volume,
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 20,
                                      label: '${(volume * 100).toInt()}%',
                                      onChanged: (val) {
                                        widget.ttsService
                                            .setVolume(val, persist: false);
                                      },
                                      onChangeEnd: (val) async {
                                        await widget.ttsService.setVolume(val);
                                        _markConfigDirty(setModalState);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomPad),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(modalCtx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  unsaved
                                      ? ctx.tr('config_continue_custom')
                                      : ctx.tr('config_done'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final saved = await _saveCurrentConfigAsPreset(
                                      setModalState);
                                  if (saved && modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                  }
                                },
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: Text(
                                  ctx.tr('config_save'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
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

  Widget _paramHeader(
      ThemeData theme, IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
                                      onTap: () async {
                                        await widget.ttsService.setVoice(v);
                                        _selectedCountryLocale = v.locale;
                                        _markConfigDirty();
                                        if (!context.mounted) return;
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
    Future<void> Function(double) onSelect,
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

}
