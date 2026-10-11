import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

void main() {
  testWidgets('profile detail header keeps a white surface while scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          appBar: ProfileDetailHeader(title: 'Chỉnh sửa hồ sơ'),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.backgroundColor, AppColors.surface);
    expect(appBar.surfaceTintColor, Colors.transparent);
    expect(appBar.scrolledUnderElevation, 0);
    expect(find.byType(BackButton), findsOneWidget);
  });

  test('default app bars use the same white, non-tinting surface', () {
    final appBarTheme = AppTheme.light.appBarTheme;

    expect(appBarTheme.backgroundColor, AppColors.surface);
    expect(appBarTheme.surfaceTintColor, Colors.transparent);
    expect(appBarTheme.scrolledUnderElevation, 0);
  });
}
