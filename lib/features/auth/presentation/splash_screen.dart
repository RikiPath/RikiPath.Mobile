import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RikiFullScreenLoader(
        key: const ValueKey<String>('splash_loading_view'),
        title: context.l10n.preparingLearningContent,
        subtitle: context.l10n.preparingLearningSubtext,
        semanticsLabel: context.l10n.loading,
        header: const RikiBrandLockup(),
      ),
    );
  }
}
