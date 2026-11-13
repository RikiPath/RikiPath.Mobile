import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_drawer.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  final targetDir = Directory(
    r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  final baseDate = DateTime(2026, 11, 10);

  final confirmedEvent = SakuraCalendarEvent(
    id: 'evt-conf-1',
    bookingId: 101,
    title: 'Tư vấn 1-1 với Sensei Tanaka',
    startTime: DateTime(2026, 11, 10, 9, 0),
    endTime: DateTime(2026, 11, 10, 10, 30),
    type: SakuraCalendarEventType.consultation,
    status: MentorMeetingStatus.accepted,
    statusLabel: 'Đã xác nhận',
    participantName: 'Sensei Tanaka',
    participantRole: 'Chuyên gia JLPT N2, Kaiwa nâng cao',
    jlptLevel: 'N2',
    meetingLink: 'https://meet.google.com/rikipath-tanaka-n2',
    notes: 'Phân tích điểm yếu Dokkai đề thi tháng 7 và chiến lược làm bài đọc dài.',
  );

  final availableSlotEvent = SakuraCalendarEvent(
    id: 'evt-slot-1',
    availabilityId: 202,
    title: 'Khung giờ tư vấn mở',
    startTime: DateTime(2026, 11, 10, 14, 0),
    endTime: DateTime(2026, 11, 10, 15, 30),
    type: SakuraCalendarEventType.availableSlot,
    statusLabel: 'Chưa đặt',
    participantName: 'Sensei Yamada',
    jlptLevel: 'N2',
  );

  final cancelledEvent = SakuraCalendarEvent(
    id: 'evt-canc-1',
    bookingId: 303,
    title: 'Tư vấn 1-1 với Sensei Tanaka',
    startTime: DateTime(2026, 11, 10, 16, 0),
    endTime: DateTime(2026, 11, 10, 17, 30),
    type: SakuraCalendarEventType.consultation,
    status: MentorMeetingStatus.cancelled,
    statusLabel: 'Đã hủy',
    participantName: 'Sensei Tanaka',
    participantRole: 'Chuyên gia JLPT N2, Kaiwa nâng cao',
    jlptLevel: 'N2',
    notes: 'Học viên xin hủy do bận lịch công tác đột xuất.',
  );

  final srsEvent = SakuraCalendarEvent(
    id: 'evt-srs-1',
    title: 'Ôn tập từ vựng SRS',
    startTime: DateTime(2026, 11, 10, 8, 0),
    endTime: DateTime(2026, 11, 10, 8, 30),
    type: SakuraCalendarEventType.srsReview,
    statusLabel: 'SRS đến hạn',
    notes: '45 từ vựng N2 cần củng cố trước 23:59 hôm nay.',
  );

  final learningEvent = SakuraCalendarEvent(
    id: 'evt-learn-1',
    title: 'Hoàn thành Bài 12: Ngữ pháp Soumatome',
    startTime: DateTime(2026, 11, 10, 11, 0),
    endTime: DateTime(2026, 11, 10, 12, 0),
    type: SakuraCalendarEventType.learningPlan,
    statusLabel: 'Hoàn thành',
  );

  final weekEvents = <SakuraCalendarEvent>[
    confirmedEvent,
    availableSlotEvent,
    cancelledEvent,
    srsEvent,
    learningEvent,
    SakuraCalendarEvent(
      id: 'evt-wed-1',
      bookingId: 404,
      title: 'Tư vấn Kaiwa N3 Sensei Kenji',
      startTime: DateTime(2026, 11, 11, 10, 0),
      endTime: DateTime(2026, 11, 11, 11, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.accepted,
      statusLabel: 'Đã xác nhận',
      participantName: 'Sensei Kenji',
    ),
    SakuraCalendarEvent(
      id: 'evt-fri-1',
      title: 'Luyện đề Bunpou tổng hợp',
      startTime: DateTime(2026, 11, 13, 19, 0),
      endTime: DateTime(2026, 11, 13, 20, 30),
      type: SakuraCalendarEventType.studySession,
      statusLabel: 'Cá nhân',
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

  testWidgets('Screen 01: Month View (01_Lich_Thang)', (tester) async {
    await captureScreen(
      tester,
      fileName: 'refactor_01_Lich_Thang',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.month,
        initialDate: baseDate,
        events: weekEvents,
        fabLabel: 'Tìm slot tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Screen 02: Day View (02_Lich_Ngay)', (tester) async {
    await captureScreen(
      tester,
      fileName: 'refactor_02_Lich_Ngay',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.day,
        initialDate: baseDate,
        events: weekEvents,
        fabLabel: 'Tìm slot tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Screen 03: Right Drawer (03_Panel_Mo_Ben_Phai)', (tester) async {
    await captureScreen(
      tester,
      fileName: 'refactor_03_Panel_Mo_Ben_Phai',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 320,
            child: SakuraCalendarDrawer(
              currentMode: SakuraCalendarViewMode.month,
              visibleEventTypes: {
                SakuraCalendarEventType.consultation,
                SakuraCalendarEventType.availableSlot,
                SakuraCalendarEventType.srsReview,
                SakuraCalendarEventType.learningPlan,
              },
              roleName: 'Học viên RikiPath',
              onSelectMode: (_) {},
              onToggleEventType: (_) {},
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('Screen 04: Week View (04_Lich_Tuan)', (tester) async {
    await captureScreen(
      tester,
      fileName: 'refactor_04_Lich_Tuan',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.week,
        initialDate: baseDate,
        events: weekEvents,
        fabLabel: 'Tìm slot tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Screen 05: Year View (05_Lich_Nam)', (tester) async {
    await captureScreen(
      tester,
      fileName: 'refactor_05_Lich_Nam',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.year,
        initialDate: baseDate,
        events: weekEvents,
        fabLabel: 'Tìm slot tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Screen 06: Confirmed Detail Sheet (06_Chi_Tiet_Da_Xac_Nhan)', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'refactor_06_Chi_Tiet_Da_Xac_Nhan',
      child: Scaffold(
        backgroundColor: const Color(0x66000000),
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SakuraEventDetailSheet(event: confirmedEvent),
        ),
      ),
    );
  });

  testWidgets('Screen 07: Selected Day Event List (07_Danh_Sach_Su_Kien_10_11)', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'refactor_07_Danh_Sach_Su_Kien_10_11',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.month,
        initialDate: baseDate,
        events: weekEvents,
        fabLabel: 'Tìm slot tư vấn',
        fabIcon: Icons.calendar_month_outlined,
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Screen 08: Cancelled Detail Sheet (08_Chi_Tiet_Da_Huy)', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'refactor_08_Chi_Tiet_Da_Huy',
      child: Scaffold(
        backgroundColor: const Color(0x66000000),
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SakuraEventDetailSheet(event: cancelledEvent),
        ),
      ),
    );
  });
}
