import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  final targetDir = Directory(
    r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  final testDate = DateTime(2026, 11, 12);

  final dayEvents = <SakuraCalendarEvent>[
    SakuraCalendarEvent(
      id: 'evt-16-cancel',
      bookingId: 101,
      title: 'Tư vấn JLPT với Mentor One',
      startTime: DateTime(2026, 11, 12, 16, 0),
      endTime: DateTime(2026, 11, 12, 17, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.cancelled,
      statusLabel: 'Đã hủy',
      participantName: 'Mentor One',
    ),
    SakuraCalendarEvent(
      id: 'evt-16-confirm',
      bookingId: 102,
      title: 'Tư vấn JLPT với Mentor One',
      startTime: DateTime(2026, 11, 12, 16, 0),
      endTime: DateTime(2026, 11, 12, 17, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.accepted,
      statusLabel: 'Đã xác nhận',
      participantName: 'Mentor One',
    ),
    SakuraCalendarEvent(
      id: 'evt-21-cancel',
      bookingId: 201,
      title: 'Tư vấn JLPT với Mentor One',
      startTime: DateTime(2026, 11, 12, 21, 0),
      endTime: DateTime(2026, 11, 12, 22, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.cancelled,
      statusLabel: 'Đã hủy',
      participantName: 'Mentor One',
    ),
    SakuraCalendarEvent(
      id: 'evt-21-avail',
      availabilityId: 202,
      title: 'Còn chỗ: Mentor One',
      startTime: DateTime(2026, 11, 12, 21, 0),
      endTime: DateTime(2026, 11, 12, 22, 30),
      type: SakuraCalendarEventType.availableSlot,
      statusLabel: 'Có thể đặt',
      participantName: 'Mentor One',
    ),
  ];

  Future<void> captureScreen(
    WidgetTester tester, {
    required Widget child,
    required String fileName,
    Size size = const Size(393, 852),
  }) async {
    tester.view.physicalSize = Size(size.width * 2.5, size.height * 2.5);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            debugShowCheckedModeBanner: false,
            home: child,
          ),
        ),
      ),
    );

    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      final file = File('${targetDir.path}${Platform.pathSeparator}$fileName.png');
      file.writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Saved reference capture: ${file.path} (${bytes.length} bytes)');
    });

    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Capture Day View with enlarged card text', (tester) async {
    await captureScreen(
      tester,
      fileName: 'sakura_calendar_day_view_larger_card_text',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.day,
        initialDate: testDate,
        events: dayEvents,
        fabLabel: 'Tìm lịch tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });
}
