import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class SharedBankScreen extends StatelessWidget {
  const SharedBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.library,
        subtitle: 'SharedBank',
        onBack: context.pop,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey<String>('shared_bank_landing'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_vocabulary'),
              icon: Icons.translate,
              color: AppColors.brandPrimary,
              label: context.l10n.vocabulary,
              onTap: () => context.push(AppRoutes.vocabulary),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_kanji'),
              icon: Icons.brush_outlined,
              color: AppColors.info,
              label: context.l10n.skillKanji,
              onTap: () => context.push(AppRoutes.kanji),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_grammar'),
              icon: Icons.account_tree_outlined,
              color: AppColors.skillGrammar,
              label: context.l10n.grammar,
              onTap: () => context.push(AppRoutes.grammar),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEntry extends StatelessWidget {
  const _LibraryEntry({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: RikiCard(
          borderColor: AppColors.learnerOutline,
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(label, style: AppTypography.cardTitle)),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
