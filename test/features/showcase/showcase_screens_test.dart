import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/speech/application/speech_controller.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';
import 'package:rikipath_mobile/features/speech/presentation/speech_to_text_screen.dart';
import 'package:rikipath_mobile/features/text_scan/application/text_scan_controller.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';
import 'package:rikipath_mobile/features/text_scan/presentation/text_scan_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  test('showcase routes stay inside the Practice branch', () {
    expect(AppRoutes.speechPractice, '/practice/speech');
    expect(AppRoutes.textScan, '/practice/scan-text');
  });

  testWidgets('Speech screen renders permission denial without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = _ScreenSpeechEngine();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechPermissionGatewayProvider.overrideWithValue(
            const _ScreenSpeechPermission(false),
          ),
          speechTokenRepositoryProvider.overrideWithValue(
            const _ScreenSpeechTokenRepository(),
          ),
          speechRecognitionEngineProvider.overrideWithValue(engine),
        ],
        child: _localizedApp(const SpeechToTextScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('speech_start_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cần quyền sử dụng micro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await engine.dispose();
  });

  testWidgets('Speech screen stops recognition when it is disposed', (
    tester,
  ) async {
    final engine = _ScreenSpeechEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechPermissionGatewayProvider.overrideWithValue(
            const _ScreenSpeechPermission(true),
          ),
          speechTokenRepositoryProvider.overrideWithValue(
            const _ScreenSpeechTokenRepository(),
          ),
          speechRecognitionEngineProvider.overrideWithValue(engine),
        ],
        child: _localizedApp(const SpeechToTextScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('speech_start_button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(engine.stopCalls, greaterThanOrEqualTo(1));
    await engine.dispose();
  });

  testWidgets('Text Scan preserves layout and exposes editable OCR result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final image = TextScanImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      fileName: 'essay.png',
      contentType: 'image/png',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          textScanImagePickerProvider.overrideWithValue(
            _ScreenTextScanPicker(image),
          ),
          textScanRepositoryProvider.overrideWithValue(
            const _ScreenTextScanRepository(),
          ),
        ],
        child: _localizedApp(const TextScanScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('text_scan_choose_button')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('text_scan_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('text_scan_preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('text_scan_result_field')),
      findsOneWidget,
    );
    expect(find.text('今日は日本語を勉強します。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    home: RikiToastHost(child: home),
  );
}

class _ScreenSpeechPermission implements SpeechPermissionGateway {
  const _ScreenSpeechPermission(this.value);

  final bool value;

  @override
  Future<bool> requestMicrophonePermission() async => value;
}

class _ScreenSpeechTokenRepository implements SpeechTokenRepository {
  const _ScreenSpeechTokenRepository();

  @override
  Future<SpeechToken> issueToken() async => const SpeechToken(
    value: 'temporary-token',
    region: 'southeastasia',
    language: 'ja-JP',
    expiresInSeconds: 600,
  );
}

class _ScreenSpeechEngine implements SpeechRecognitionEngine {
  final StreamController<SpeechRecognitionUpdate> _controller =
      StreamController<SpeechRecognitionUpdate>.broadcast();
  int stopCalls = 0;

  @override
  Stream<SpeechRecognitionUpdate> get updates => _controller.stream;

  @override
  Future<void> start(SpeechToken token) async {}

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
  }
}

class _ScreenTextScanPicker implements TextScanImagePicker {
  const _ScreenTextScanPicker(this.image);

  final TextScanImage image;

  @override
  Future<TextScanImage?> pickFromGallery() async => image;
}

class _ScreenTextScanRepository implements TextScanRepository {
  const _ScreenTextScanRepository();

  @override
  Future<TextScanResult> scan(TextScanImage image) async {
    return const TextScanResult(text: '今日は日本語を勉強します。');
  }
}
