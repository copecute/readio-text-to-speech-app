import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_locale.dart';

class WelcomeView extends StatefulWidget {
  final VoidCallback onFinish;

  const WelcomeView({
    super.key,
    required this.onFinish,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _hasStoragePermission = false;
  bool _hasNotificationPermission = false;

  static const _channel = MethodChannel('com.copecute.readio/storage');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) {
      setState(() {
        _hasStoragePermission = true;
        _hasNotificationPermission = true;
      });
      return;
    }

    try {
      final storage = await _channel.invokeMethod<bool>('hasStoragePermission') ?? false;
      final notif = await _channel.invokeMethod<bool>('hasNotificationPermission') ?? true;
      if (mounted) {
        setState(() {
          _hasStoragePermission = storage;
          _hasNotificationPermission = notif;
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _requestStorage() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestStoragePermission');
      await Future.delayed(const Duration(milliseconds: 600));
      await _checkPermissions();
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
    }
  }

  Future<void> _requestNotification() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestNotificationPermission');
      await Future.delayed(const Duration(milliseconds: 600));
      await _checkPermissions();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localization = AppLocalizationScope.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: context.tr('app_language_title'),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localization.language.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
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
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildIntroPage(theme, isDark),
                  _buildPermissionPage(theme, isDark),
                ],
              ),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // App Logo
          Hero(
            tag: 'app_logo',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(isDark ? 90 : 50),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/logo-readio.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'READIO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('welcome_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('welcome_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.hintColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Features List
          _buildFeatureTile(
            theme,
            icon: Icons.offline_bolt_rounded,
            color: const Color(0xFF6366F1),
            title: context.tr('welcome_feat1_title'),
            desc: context.tr('welcome_feat1_desc'),
          ),
          const SizedBox(height: 14),
          _buildFeatureTile(
            theme,
            icon: Icons.tune_rounded,
            color: const Color(0xFF06B6D4),
            title: context.tr('welcome_feat2_title'),
            desc: context.tr('welcome_feat2_desc'),
          ),
          const SizedBox(height: 14),
          _buildFeatureTile(
            theme,
            icon: Icons.audio_file_rounded,
            color: const Color(0xFF10B981),
            title: context.tr('welcome_feat3_title'),
            desc: context.tr('welcome_feat3_desc'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12.5, color: theme.hintColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPage(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_rounded,
              color: theme.colorScheme.primary,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('perm_page_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('perm_page_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: theme.hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Permission 1: Storage / File Access
          _buildPermissionCard(
            theme,
            icon: Icons.folder_special_rounded,
            color: const Color(0xFF6366F1),
            title: context.tr('perm_storage_title'),
            desc: context.tr('perm_storage_desc'),
            isGranted: _hasStoragePermission,
            onGrant: _requestStorage,
          ),
          const SizedBox(height: 16),

          // Permission 2: Notifications & Media Controls
          _buildPermissionCard(
            theme,
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFEC4899),
            title: context.tr('perm_notif_title'),
            desc: context.tr('perm_notif_desc'),
            isGranted: _hasNotificationPermission,
            onGrant: _requestNotification,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? Colors.green.withAlpha(120)
              : theme.colorScheme.outlineVariant.withAlpha(70),
          width: isGranted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              if (isGranted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Đã cấp',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(fontSize: 12.5, color: theme.hintColor, height: 1.35),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onGrant,
                icon: const Icon(Icons.lock_open_rounded, size: 16),
                label: Text(context.tr('perm_btn_grant')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Primary Navigation Button
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(context.tr('welcome_btn_back')),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeWelcome();
                    }
                  },
                  icon: Icon(
                    _currentPage == 0
                        ? Icons.arrow_forward_rounded
                        : Icons.rocket_launch_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _currentPage == 0
                        ? context.tr('welcome_btn_next')
                        : context.tr('welcome_btn_start'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
