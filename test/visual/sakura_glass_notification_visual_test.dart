import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

class _VisualNotificationRepo implements NotificationRepository {
  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const <AppNotification>[];

  @override
  Future<int> loadUnreadCount() async => 2;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

Future<void> _loadRealFontsAndIcons() async {
  Future<ByteData?> readFont(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }

  final segoeRegular = await readFont(r'C:\Windows\Fonts\segoeui.ttf');
  final segoeSemiBold = await readFont(r'C:\Windows\Fonts\seguisb.ttf');
  final segoeBold = await readFont(r'C:\Windows\Fonts\segoeuib.ttf');
  final segoeSymbol = await readFont(r'C:\Windows\Fonts\seguisym.ttf');
  final segoeEmoji = await readFont(r'C:\Windows\Fonts\seguiemj.ttf');
  final yuGothic = await readFont(r'C:\Windows\Fonts\YuGothM.ttc');

  for (final family in <String>[
    'Ahem',
    'FlutterTest',
    'Roboto',
    'Noto Sans',
    'Noto Sans JP',
    'sans-serif',
  ]) {
    final loader = FontLoader(family);
    var loadedAny = false;
    if (segoeRegular != null) {
      loader.addFont(Future<ByteData>.value(segoeRegular));
      loadedAny = true;
    }
    if (segoeSemiBold != null) {
      loader.addFont(Future<ByteData>.value(segoeSemiBold));
      loadedAny = true;
    }
    if (segoeBold != null) {
      loader.addFont(Future<ByteData>.value(segoeBold));
      loadedAny = true;
    }
    if (yuGothic != null) {
      loader.addFont(Future<ByteData>.value(yuGothic));
      loadedAny = true;
    }
    if (loadedAny) await loader.load();
  }

  if (segoeEmoji != null) {
    final emojiLoader = FontLoader('Segoe UI Emoji')
      ..addFont(Future<ByteData>.value(segoeEmoji));
    await emojiLoader.load();
  }
  if (segoeSymbol != null) {
    final symbolLoader = FontLoader('Segoe UI Symbol')
      ..addFont(Future<ByteData>.value(segoeSymbol));
    await symbolLoader.load();
  }

  final sdkRoot = Platform.environment['FLUTTER_ROOT'] ?? r'D:\flutter';
  final materialFont = await readFont(
    '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (materialFont != null) {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(materialFont));
    await iconLoader.load();
  }
}

void main() {
  final outputPath = Platform.environment['RIKIPATH_VISUAL_OUTPUT_DIR'];

  setUpAll(() async {
    if (outputPath != null && outputPath.isNotEmpty) {
      await _loadRealFontsAndIcons();
    }
  });

  for (final type in <RikiToastType>[
    RikiToastType.success,
    RikiToastType.error,
    RikiToastType.warning,
    RikiToastType.info,
    RikiToastType.loading,
    RikiToastType.confirmation,
  ]) {
    testWidgets(
      'capture ${type.name} light glass toast without a backend call',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2;
        tester.view.padding = const FakeViewPadding(
          top: 32 * 2,
          bottom: 16 * 2,
        );
        tester.view.viewPadding = const FakeViewPadding(
          top: 32 * 2,
          bottom: 16 * 2,
        );
        addTearDown(tester.view.reset);
        final boundaryKey = GlobalKey();
        final container = ProviderContainer(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _VisualNotificationRepo(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light.copyWith(
                  textTheme: AppTheme.light.textTheme.apply(
                    fontFamily: 'Roboto',
                  ),
                ),
                locale: const Locale('vi'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) =>
                    RikiToastHost(child: child ?? const SizedBox.shrink()),
                home: Scaffold(
                  backgroundColor: AppColors.backgroundPrimary,
                  appBar: SakuraAppHeader(
                    streakDays: 7,
                    unreadNotificationCount: 2,
                    onNotificationsPressed: () {},
                    onCalendarPressed: () {},
                  ),
                  body: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space4,
                      AppSpacing.space12 + AppSpacing.space8,
                      AppSpacing.space4,
                      AppSpacing.space4,
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space5),
                        decoration: BoxDecoration(
                          gradient: AppColors.sakuraHeroGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brandBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lộ trình JLPT N3',
                              style: AppTypography.sectionTitle,
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              'Hôm nay bạn đã hoàn thành 25/45 phút mục tiêu.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      RikiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buổi học tiếp theo với Cố vấn',
                              style: AppTypography.cardTitle,
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              '19:30 hôm nay · Luyện hội thoại N3 cùng Sensei Kenji',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final element = tester.element(find.byType(Scaffold));
        await tester.runAsync(() async {
          await precacheImage(const AssetImage(rikiBrandLogoAsset), element);
        });
        await tester.pumpAndSettle();

        container
            .read(rikiToastServiceProvider.notifier)
            .show(
              type: type,
              title: switch (type) {
                RikiToastType.success => 'Đăng nhập thành công',
                RikiToastType.error => 'Không thể kết nối máy chủ',
                RikiToastType.warning => 'Bạn có thay đổi chưa lưu',
                RikiToastType.info => 'Lộ trình học đã được làm mới',
                RikiToastType.loading => 'Đang đồng bộ dữ liệu',
                RikiToastType.confirmation => 'Xác nhận cập nhật lịch học',
                RikiToastType.celebration => '',
              },
              description: switch (type) {
                RikiToastType.success =>
                  'Chào mừng bạn trở lại với RikiPath.',
                RikiToastType.error =>
                  'Thanh toán chưa hoàn tất. Vui lòng kiểm tra kết nối và thử lại.',
                RikiToastType.warning =>
                  'Hãy lưu mục tiêu JLPT trước khi rời khỏi màn hình này.',
                RikiToastType.info =>
                  'Bài luyện nghe N3 mới vừa được thêm vào hôm nay.',
                RikiToastType.loading =>
                  'Hệ thống đang lưu lộ trình cá nhân của bạn...',
                RikiToastType.confirmation =>
                  'Lịch cố vấn đã sẵn sàng để áp dụng cho tuần tới.',
                RikiToastType.celebration => '',
              },
            );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 280));
        expect(tester.takeException(), isNull);

        final toastFinder = find.byKey(
          ValueKey<String>('riki_toast_${type.name}'),
        );
        expect(toastFinder, findsOneWidget);
        final headerBottom = tester
            .getBottomLeft(find.byType(SakuraAppHeader))
            .dy;
        final toastTop = tester.getTopLeft(toastFinder).dy;
        expect(toastTop, greaterThan(headerBottom));

        if (outputPath != null && outputPath.isNotEmpty) {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final output = Directory(outputPath);
            if (!output.existsSync()) output.createSync(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            final file = File(
              '${output.path}${Platform.pathSeparator}sakura_light_glass_${type.name}.png',
            );
            file.writeAsBytesSync(data!.buffer.asUint8List());
          });
        }
      },
    );
  }
}
