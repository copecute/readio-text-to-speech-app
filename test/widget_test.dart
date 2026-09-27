import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readio/main.dart';
import 'package:readio/core/localization/app_locale.dart';
import 'package:readio/services/tts_service.dart';
import 'package:readio/services/history_service.dart';
import 'package:readio/services/audio_player_service.dart';
import 'package:readio/services/preset_service.dart';
import 'package:readio/services/bgm_service.dart';

void main() {
  testWidgets('Readio app renders successfully with navigation and branding',
      (tester) async {
    final ttsService = TtsService();
    final historyService = HistoryService();
    final audioPlayerService = AudioPlayerService();
    final presetService = PresetService();
    final bgmService = BgmService();

    await tester.pumpWidget(ReadioApp(
      initialLanguage: AppLanguage.vi,
      initialThemeMode: ThemeMode.light,
      ttsService: ttsService,
      historyService: historyService,
      audioPlayerService: audioPlayerService,
      presetService: presetService,
      bgmService: bgmService,
      initialHasCompletedOnboarding: true,
    ));
    await tester.pump();

    expect(find.text('READIO'), findsWidgets);
    expect(find.text('Tạo giọng nói'), findsWidgets);
    expect(find.text('Lịch sử lưu'), findsWidgets);
    expect(find.text('Cài đặt'), findsWidgets);
  });
}
