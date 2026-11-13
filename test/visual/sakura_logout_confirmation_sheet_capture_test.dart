import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';

void main() {
  testWidgets('Capture Sakura logout confirmation bottom sheet', (tester) async {
    final repaintKey = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: RepaintBoundary(
            key: repaintKey,
            child: Builder(
              builder: (context) => Stack(
                children: [
                  Container(
                    color: const Color(0xFFF7F6F7),
                    child: Center(
                      child: Text(
                        'Background Profile Screen',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  // Render the bottom sheet container aligned at the bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F2D282A),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space5,
                          AppSpacing.space3,
                          AppSpacing.space5,
                          AppSpacing.space6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5D5DA),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space5),
                            Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFFFF0F4), Color(0xFFFFE5EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFF8BBD0).withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1CE05A7A),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const SakuraColorfulIcon(
                                  type: SakuraColorfulIconType.logout,
                                  size: 36,
                                  useEmoji: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              'Bạn muốn đăng xuất?',
                              textAlign: TextAlign.center,
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              'Bạn sẽ cần đăng nhập lại để tiếp tục học trên thiết bị này.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space5),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button),
                                ),
                                elevation: 2,
                                shadowColor: AppColors.brandShadow,
                              ),
                              onPressed: () {},
                              child: const Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space3),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: const Color(0xFFFFF7F9),
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(
                                  color: Color(0xFFEBDDE1),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Ở lại',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull);

    await tester.runAsync(() async {
      final image = await boundary!.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      final file = File(r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce\sakura_logout_confirmation_sheet.png');
      file.writeAsBytesSync(bytes);
      expect(file.existsSync(), isTrue);
    });
  });
}
