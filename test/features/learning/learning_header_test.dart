import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

void main() {
  testWidgets('learning headers keep the shared 64 pixel geometry', (
    tester,
  ) async {
    const rootHeader = LearningHeader.root(
      level: JlptLevel.n4,
      streakDays: 7,
      hasUnreadNotifications: true,
      initials: 'RP',
      onProfilePressed: _noop,
    );

    await tester.pumpWidget(_host(rootHeader));

    expect(rootHeader.preferredSize.height, 64);
    expect(tester.getSize(find.byType(AppBar)).height, 64);
    expect(find.text('RikiPath'), findsOneWidget);

    const detailHeader = LearningHeader.detail(
      title: 'Chi tiết ngữ pháp với tiêu đề rất dài',
      subtitle: 'NGỮ PHÁP',
      level: JlptLevel.n4,
      initials: 'RP',
      onBack: _noop,
      onProfilePressed: _noop,
    );

    await tester.pumpWidget(_host(detailHeader));
    await tester.pump();

    expect(detailHeader.preferredSize.height, 64);
    expect(tester.getSize(find.byType(AppBar)).height, 64);
    expect(find.text('NGỮ PHÁP'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
  });
}

Widget _host(PreferredSizeWidget header) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(appBar: header, body: const SizedBox.expand()),
  );
}

void _noop() {}
