import 'package:flutter/material.dart';
import '../core/localization/app_locale.dart';
import '../services/tts_service.dart';
import '../services/history_service.dart';
import '../services/audio_player_service.dart';
import '../services/preset_service.dart';
import '../services/bgm_service.dart';
import 'create_view.dart';
import 'history_view.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final TtsService ttsService;
  final HistoryService historyService;
  final AudioPlayerService audioPlayerService;
  final PresetService presetService;
  final BgmService bgmService;

  const HomeView({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.ttsService,
    required this.historyService,
    required this.audioPlayerService,
    required this.presetService,
    required this.bgmService,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentTabIndex = 0;
  final GlobalKey<State> _createKey = GlobalKey<State>();

  void _onLoadIntoEditor(String text) {
    setState(() {
      _currentTabIndex = 0;
    });
    // Find text controller in create view or pass via state
    // CreateView state handles its text
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localization = AppLocalizationScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 800;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _buildNavigationRail(constraints.maxWidth > 1100),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(isDark, localization),
                      const Divider(height: 1),
                      Expanded(
                        child: IndexedStack(
                          index: _currentTabIndex,
                          children: [
                            CreateView(
                              key: _createKey,
                              ttsService: widget.ttsService,
                              historyService: widget.historyService,
                              audioPlayerService: widget.audioPlayerService,
                              presetService: widget.presetService,
                              bgmService: widget.bgmService,
                              onGoToHistory: () {
                                setState(() => _currentTabIndex = 1);
                              },
                            ),
                            HistoryView(
                              historyService: widget.historyService,
                              audioPlayerService: widget.audioPlayerService,
                              onLoadIntoEditor: (text) {
                                _onLoadIntoEditor(text);
                              },
                            ),
                            SettingsView(
                              currentThemeMode: widget.currentThemeMode,
                              onThemeModeChanged: widget.onThemeModeChanged,
                              ttsService: widget.ttsService,
                              historyService: widget.historyService,
                            ),
                          ],
                        ),
                      ),
                      if (!isWide) _buildBottomNavigationBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(bool isDark, AppLocalizationScope localization) {
    final theme = Theme.of(context);
    final titles = [
      context.tr('tab_create'),
      context.tr('tab_history'),
      context.tr('tab_settings'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/logo-readio.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READIO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                titles[_currentTabIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Quick Language switcher popup
          PopupMenuButton<AppLanguage>(
            tooltip: context.tr('app_language_title'),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localization.language.flag,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    localization.language.code.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (lang) => localization.onLanguageChanged(lang),
            itemBuilder: (ctx) => AppLanguage.values.map((lang) {
              return PopupMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(lang.label),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          // Dark/Light mode toggle button
          IconButton(
            tooltip: context.tr('theme_mode'),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              widget.onThemeModeChanged(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(bool isExtended) {
    return NavigationRail(
      extended: isExtended,
      selectedIndex: _currentTabIndex,
      onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo-readio.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
            if (isExtended) ...[
              const SizedBox(height: 8),
              const Text(
                'READIO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.mic_none_outlined),
          selectedIcon: const Icon(Icons.mic),
          label: Text(context.tr('tab_create')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: Text(context.tr('tab_history')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(context.tr('tab_settings')),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentTabIndex,
      onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.mic_none_outlined),
          selectedIcon: const Icon(Icons.mic),
          label: context.tr('tab_create'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: context.tr('tab_history'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: context.tr('tab_settings'),
        ),
      ],
    );
  }
}
