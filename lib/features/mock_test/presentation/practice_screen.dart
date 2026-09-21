import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/app_section_card.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(l10n.navigationPractice)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppSectionCard(
            title: l10n.mockTestTitle,
            subtitle: l10n.mockTestSubtitle,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const JlptBadge(JlptLevel.n3),
                  title: Text(
                    l10n.mockTestName('N3', '04'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    l10n.mockDurationStatus(110, l10n.notAttempted),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(l10n.latestResult),
                  subtitle: Text(l10n.mockScoreReading(112, 180, 48)),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text(l10n.view),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: l10n.aiGrading,
            subtitle: l10n.writingAndKanjiPractice,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.writing),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(l10n.skillKanji),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
