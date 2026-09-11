import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

void main() {
  test('theme exposes the canonical brand and focused input tokens', () {
    final theme = AppTheme.light;
    final focusedBorder = theme.inputDecorationTheme.focusedBorder;

    expect(theme.colorScheme.primary, AppColors.brandPrimary);
    expect(focusedBorder, isA<OutlineInputBorder>());
    expect(
      (focusedBorder! as OutlineInputBorder).borderSide,
      AppBorders.focused,
    );
  });

  testWidgets('primary button renders its label and invokes its action', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      _testHost(
        RikiPrimaryButton(
          label: 'Đăng nhập',
          onPressed: () => presses += 1,
        ),
      ),
    );

    expect(find.text('Đăng nhập'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(presses, 1);
  });

  testWidgets('primary button loading state blocks repeated action', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      _testHost(
        RikiPrimaryButton(
          label: 'Đăng nhập',
          loadingLabel: 'Đang đăng nhập...',
          isLoading: true,
          onPressed: () => presses += 1,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đang đăng nhập...'), findsOneWidget);
    expect(presses, 0);
  });

  testWidgets('text field displays validation treatment and message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const RikiTextField(
          label: 'Email học viên',
          hintText: 'nhap.email@example.com',
          errorText: 'Email không hợp lệ. Vui lòng kiểm tra lại định dạng.',
          prefixIcon: Icons.mail_outline,
        ),
      ),
    );

    expect(find.text('Email học viên'), findsOneWidget);
    expect(
      find.text('Email không hợp lệ. Vui lòng kiểm tra lại định dạng.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('password visibility toggle updates obscure state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(const RikiPasswordField(label: 'Mật khẩu')),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('JLPT badge supports only N5, N4, and N3 typed values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const Wrap(
          spacing: AppSpacing.space2,
          children: [
            JlptBadge(JlptLevel.n5),
            JlptBadge(JlptLevel.n4),
            JlptBadge(JlptLevel.n3),
          ],
        ),
      ),
    );

    expect(find.text('N5'), findsOneWidget);
    expect(find.text('N4'), findsOneWidget);
    expect(find.text('N3'), findsOneWidget);
  });

  testWidgets('semantic banners render their expected content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RikiInfoBanner(message: 'Thông tin lộ trình'),
            SizedBox(height: AppSpacing.space3),
            RikiWarningBanner(message: 'Kiểm tra hộp thư rác'),
            SizedBox(height: AppSpacing.space3),
            RikiSuccessBanner(message: 'Tài khoản đã sẵn sàng'),
          ],
        ),
      ),
    );

    expect(find.text('Thông tin lộ trình'), findsOneWidget);
    expect(find.text('Kiểm tra hộp thư rác'), findsOneWidget);
    expect(find.text('Tài khoản đã sẵn sàng'), findsOneWidget);
  });

  testWidgets('system typography preserves mixed Japanese and Vietnamese text', (
    tester,
  ) async {
    const sample = '日本語・漢字・ひらがな・カタカナ — Tiếng Việt';

    await tester.pumpWidget(
      _testHost(
        const RikiCard(child: Text(sample, style: AppTypography.body)),
      ),
    );

    expect(find.text(sample), findsOneWidget);
  });

  testWidgets('language badge exposes the approved compact VI state', (
    tester,
  ) async {
    await tester.pumpWidget(_testHost(const LanguageBadge()));

    expect(find.text('VI'), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

  testWidgets('selection card exposes selected state and handles action', (
    tester,
  ) async {
    var selections = 0;

    await tester.pumpWidget(
      _testHost(
        RikiSelectionCard(
          title: 'N3 - Trung cấp',
          description: 'Hướng tới trình độ trung cấp',
          badge: 'Phổ biến',
          selected: true,
          onPressed: () => selections += 1,
          leading: const SizedBox.square(
            dimension: 44,
            child: Center(child: Text('N3')),
          ),
        ),
      ),
    );

    expect(find.text('N3 - Trung cấp'), findsOneWidget);
    expect(find.text('Phổ biến'), findsOneWidget);
    await tester.tap(find.text('N3 - Trung cấp'));
    await tester.pump();
    expect(selections, 1);
  });
}

Widget _testHost(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: child,
      ),
    ),
  );
}
