import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'services/tts_service.dart';
import 'services/history_service.dart';
import 'services/audio_player_service.dart';
import 'services/preset_service.dart';
import 'services/bgm_service.dart';
import 'views/home_view.dart';
import 'views/welcome_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String savedLangCode = prefs.getString('app_language_code') ?? 'vi';
  final String savedTheme = prefs.getString('app_theme_mode') ?? 'system';
  final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  final ttsService = TtsService();
  await ttsService.initialize();

  final historyService = HistoryService();
  await historyService.loadHistory();

  final audioPlayerService = AudioPlayerService();

  final presetService = PresetService();
  await presetService.init();

  // Live TTS params are restored from SharedPreferences inside TtsService.initialize().
  // Only seed from the active preset on first launch (no saved rate yet), so
  // cold-start never wipes a saved preset's tweaked values.
  final prefsForTts = await SharedPreferences.getInstance();
  final hasPersistedTts = prefsForTts.containsKey('readio_tts_speech_rate');
  final active = presetService.activePreset;
  if (!hasPersistedTts && active != null) {
    await ttsService.applyPresetValues(
      speechRate: active.speechRate,
      pitch: active.pitch,
      volume: active.volume,
      voiceKey: active.voiceKey,
      locale: active.locale,
      voiceName: active.voiceName,
    );
  }

  final bgmService = BgmService();
  await bgmService.init();

  runApp(ReadioApp(
    initialLanguage: AppLanguage.fromCode(savedLangCode),
    initialThemeMode: _parseThemeMode(savedTheme),
    initialHasCompletedOnboarding: hasCompletedOnboarding,
    ttsService: ttsService,
    historyService: historyService,
    audioPlayerService: audioPlayerService,
    presetService: presetService,
    bgmService: bgmService,
  ));
}

ThemeMode _parseThemeMode(String val) {
  switch (val) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class ReadioApp extends StatefulWidget {
  final AppLanguage initialLanguage;
  final ThemeMode initialThemeMode;
  final bool initialHasCompletedOnboarding;
  final TtsService ttsService;
  final HistoryService historyService;
  final AudioPlayerService audioPlayerService;
  final PresetService presetService;
  final BgmService bgmService;

  const ReadioApp({
    super.key,
    required this.initialLanguage,
    required this.initialThemeMode,
    required this.initialHasCompletedOnboarding,
    required this.ttsService,
    required this.historyService,
    required this.audioPlayerService,
    required this.presetService,
    required this.bgmService,
  });

  @override
  State<ReadioApp> createState() => _ReadioAppState();
}

class _ReadioAppState extends State<ReadioApp> {
  late AppLanguage _language;
  late ThemeMode _themeMode;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _themeMode = widget.initialThemeMode;
    _showOnboarding = !widget.initialHasCompletedOnboarding;
  }

  void _onLanguageChanged(AppLanguage lang) async {
    setState(() {
      _language = lang;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', lang.code);
  }

  void _onThemeModeChanged(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
  }

  @override
  void dispose() {
    widget.ttsService.dispose();
    widget.audioPlayerService.dispose();
    widget.presetService.dispose();
    widget.bgmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocalizationScope(
      language: _language,
      onLanguageChanged: _onLanguageChanged,
      child: MaterialApp(
        title: 'Readio Text to Speech',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: _showOnboarding
            ? WelcomeView(
                onFinish: () {
                  setState(() {
                    _showOnboarding = false;
                  });
                },
              )
            : HomeView(
                currentThemeMode: _themeMode,
                onThemeModeChanged: _onThemeModeChanged,
                ttsService: widget.ttsService,
                historyService: widget.historyService,
                audioPlayerService: widget.audioPlayerService,
                presetService: widget.presetService,
                bgmService: widget.bgmService,
              ),
      ),
    );
  }
}
