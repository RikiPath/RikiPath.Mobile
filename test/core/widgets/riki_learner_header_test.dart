import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';

void main() {
  testWidgets('learner header keeps the shared shell dimensions and surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          appBar: RikiLearnerHeader(title: Text('Luyện tập')),
        ),
      ),
    );

    final header = tester.widget<RikiLearnerHeader>(
      find.byType(RikiLearnerHeader),
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(header.preferredSize.height, RikiLearnerHeader.height);
    expect(tester.getSize(find.byType(AppBar)).height, 64);
    expect(appBar.toolbarHeight, RikiLearnerHeader.height);
    expect(appBar.titleSpacing, AppSpacing.space4);
    expect(appBar.backgroundColor, AppColors.surface);
    expect(appBar.scrolledUnderElevation, 0);
  });

  testWidgets('learner header preserves custom title and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          appBar: RikiLearnerHeader(
            title: Text('Sổ từ'),
            actions: <Widget>[Icon(Icons.account_circle_outlined)],
          ),
        ),
      ),
    );

    expect(find.text('Sổ từ'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });
}
