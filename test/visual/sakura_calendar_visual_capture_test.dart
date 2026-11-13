import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/calendar/domain/sakura_calendar_models.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_event_detail_sheet.dart';
import 'package:rikipath_mobile/features/calendar/presentation/widgets/sakura_calendar_shell.dart';
import 'package:rikipath_mobile/features/calendar/presentation/learner_calendar_screen.dart';
import 'package:rikipath_mobile/features/calendar/presentation/mentor_calendar_screen.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

void main() {
  final targetDirs = [
    Directory(r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce'),
    Directory(r'D:\FPT University\SEP491-new\rikipath\.orchestrator\reports\full_ui_ux_audit_20261105\SCREENSHOT_EVIDENCE'),
  ];

  for (final dir in targetDirs) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  final sampleEvents = <SakuraCalendarEvent>[
    SakuraCalendarEvent(
      id: 'evt-1',
      title: 'Tư vấn Lộ trình JLPT N2 (90 phút)',
      startTime: DateTime(2026, 11, 5, 9, 0),
      endTime: DateTime(2026, 11, 5, 10, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.accepted,
      statusLabel: 'Đã xác nhận',
      participantName: 'Thầy Kenji Sato',
      participantRole: 'Cố vấn chuyên môn N2',
      jlptLevel: 'N2',
      meetingLink: 'https://meet.google.com/rikipath-jlpt-n2',
      notes: 'Trọng tâm ôn luyện Dokkai bài đọc dài & ngữ pháp Soumatome',
    ),
    SakuraCalendarEvent(
      id: 'evt-2',
      title: 'Khung giờ rảnh: Luyện hội thoại Kaiwa',
      startTime: DateTime(2026, 11, 5, 14, 0),
      endTime: DateTime(2026, 11, 5, 15, 30),
      type: SakuraCalendarEventType.availableSlot,
      statusLabel: 'Còn trống',
      participantName: 'Cô Nguyễn Mai Anh',
      participantRole: 'Giảng viên Bản ngữ',
      jlptLevel: 'N3',
    ),
    SakuraCalendarEvent(
      id: 'evt-3',
      title: 'Ôn tập Kanji Kanji Master Bài 1-5',
      startTime: DateTime(2026, 11, 6, 19, 0),
      endTime: DateTime(2026, 11, 6, 20, 30),
      type: SakuraCalendarEventType.studySession,
      statusLabel: 'Cá nhân',
      jlptLevel: 'N2',
      notes: 'Hoàn thành 50 hán tự khó và bài tập trong Notebook',
    ),
    SakuraCalendarEvent(
      id: 'evt-4',
      title: 'Thi thử JLPT N2 Mock Exam Online',
      startTime: DateTime(2026, 11, 7, 8, 30),
      endTime: DateTime(2026, 11, 7, 11, 30),
      type: SakuraCalendarEventType.studySession,
      statusLabel: 'Thi thử',
      jlptLevel: 'N2',
    ),
  ];

  final overlappingEvents = <SakuraCalendarEvent>[
    SakuraCalendarEvent(
      id: 'ov-1',
      title: 'Cố vấn 1-1 Dokkai N2',
      startTime: DateTime(2026, 11, 5, 9, 0),
      endTime: DateTime(2026, 11, 5, 10, 30),
      type: SakuraCalendarEventType.consultation,
      status: MentorMeetingStatus.accepted,
      statusLabel: 'Đã xác nhận',
      participantName: 'Thầy Kenji Sato',
      jlptLevel: 'N2',
    ),
    SakuraCalendarEvent(
      id: 'ov-2',
      title: 'Luyện đề Bunpou nhóm 4 bạn',
      startTime: DateTime(2026, 11, 5, 9, 30),
      endTime: DateTime(2026, 11, 5, 11, 0),
      type: SakuraCalendarEventType.studySession,
      statusLabel: 'Học nhóm',
      participantName: 'Nhóm Sakura N2',
      jlptLevel: 'N2',
    ),
    SakuraCalendarEvent(
      id: 'ov-3',
      title: 'Khung giờ rảnh Sensei Tanaka',
      startTime: DateTime(2026, 11, 5, 10, 0),
      endTime: DateTime(2026, 11, 5, 11, 30),
      type: SakuraCalendarEventType.availableSlot,
      statusLabel: 'Còn trống',
      participantName: 'Sensei Tanaka',
      jlptLevel: 'N1',
    ),
  ];

  Future<void> captureWidget(
    WidgetTester tester, {
    required Widget child,
    required String fileName,
    Size size = const Size(412, 915),
  }) async {
    tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
    tester.view.devicePixelRatio = 2.0;
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
            home: Scaffold(body: child),
          ),
        ),
      ),
    );

    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      for (final dir in targetDirs) {
        final file = File('${dir.path}${Platform.pathSeparator}$fileName.png');
        file.writeAsBytesSync(bytes);
        // ignore: avoid_print
        print('Captured: ${file.path} (${bytes.length} bytes)');
      }
    });

    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Capture 1: Month View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_month_view',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.month,
        events: sampleEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 2: Week View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_week_view',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.week,
        events: sampleEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 3: 3-Day View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_three_day_view',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.day,
        events: sampleEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 4: Day View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_day_view',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.day,
        events: sampleEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 5: Agenda View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_agenda_view',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.agenda,
        events: sampleEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 6: Event Detail Sheet', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_event_detail_sheet',
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.bottomCenter,
        child: SakuraEventDetailSheet(event: sampleEvents.first),
      ),
    );
  });

  testWidgets('Capture 7: Learner Calendar Screen', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_learner_calendar',
      child: const LearnerCalendarScreen(),
    );
  });

  testWidgets('Capture 8: Mentor Calendar Screen', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_mentor_calendar',
      child: const MentorCalendarScreen(),
    );
  });

  testWidgets('Capture 9: Empty Calendar View', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_empty_calendar',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.agenda,
        events: const [],
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });

  testWidgets('Capture 10: Dense Overlapping Events', (tester) async {
    await captureWidget(
      tester,
      fileName: 'mobile_phase1_6_dense_overlapping_calendar',
      child: SakuraCalendarShell(
        roleName: 'Học viên RikiPath',
        initialMode: SakuraCalendarViewMode.day,
        events: overlappingEvents,
        fabLabel: '+ Đặt lịch cố vấn',
        onFabPressed: () {},
      ),
    );
  });
}
