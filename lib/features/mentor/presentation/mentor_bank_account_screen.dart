import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_compensation_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_compensation_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình quản lý tài khoản ngân hàng nhận thù lao của Cố vấn.
/// Số tài khoản đầy đủ chỉ được gửi lên Backend, giao diện chỉ hiển thị dạng che số.
class MentorBankAccountScreen extends ConsumerStatefulWidget {
  const MentorBankAccountScreen({super.key});

  @override
  ConsumerState<MentorBankAccountScreen> createState() =>
      _MentorBankAccountScreenState();
}

const List<({String bin, String shortName})> _vnBankPresets = [
  (bin: '970436', shortName: 'Vietcombank'),
  (bin: '970407', shortName: 'Techcombank'),
  (bin: '970422', shortName: 'MBBank'),
  (bin: '970416', shortName: 'ACB'),
  (bin: '970418', shortName: 'BIDV'),
  (bin: '970415', shortName: 'VietinBank'),
  (bin: '970423', shortName: 'TPBank'),
  (bin: '970432', shortName: 'VPBank'),
  (bin: '970403', shortName: 'Sacombank'),
  (bin: '970405', shortName: 'Agribank'),
];

class _MentorBankAccountScreenState
    extends ConsumerState<MentorBankAccountScreen> {
  final _binController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _holderController = TextEditingController();
  bool _submitting = false;
  bool _hasDirtyChanges = false;
  bool _ignoreFieldNotifications = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _binController.addListener(_onFieldChanged);
    _bankNameController.addListener(_onFieldChanged);
    _accountController.addListener(_onFieldChanged);
    _holderController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_ignoreFieldNotifications) return;
    final dirty =
        _binController.text.trim().isNotEmpty ||
        _bankNameController.text.trim().isNotEmpty ||
        _accountController.text.trim().isNotEmpty ||
        _holderController.text.trim().isNotEmpty;
    if (dirty != _hasDirtyChanges || mounted) {
      if (mounted) {
        setState(() => _hasDirtyChanges = dirty);
      }
    }
  }

  @override
  void dispose() {
    _binController.removeListener(_onFieldChanged);
    _bankNameController.removeListener(_onFieldChanged);
    _accountController.removeListener(_onFieldChanged);
    _holderController.removeListener(_onFieldChanged);
    _binController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateMentorBankAccountInput(
      bankBin: _binController.text,
      bankShortName: _bankNameController.text,
      accountNumber: _accountController.text,
      accountHolderName: _holderController.text,
    );
    if (error != null) {
      setState(() {
        _error = error;
        _success = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(mentorCompensationRepositoryProvider)
          .upsertBankAccount(
            bankBin: _binController.text,
            bankShortName: _bankNameController.text,
            accountNumber: _accountController.text,
            accountHolderName: _holderController.text,
          );
      if (!mounted) return;
      _ignoreFieldNotifications = true;
      _accountController.clear();
      _ignoreFieldNotifications = false;
      setState(() {
        _submitting = false;
        _hasDirtyChanges = false;
        _success =
            'Đã gửi tài khoản. Quản trị viên sẽ xác minh trước khi chi trả.';
      });
      ref.invalidate(mentorBankAccountsProvider);
      ref.invalidate(mentorCompensationOverviewProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Chưa thể lưu tài khoản ngân hàng. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(mentorBankAccountsProvider);
    final hasUnsavedChanges = _hasDirtyChanges && !_submitting;
    final hasGoRouter = GoRouter.maybeOf(context) != null;
    final canPopRoute =
        !hasUnsavedChanges &&
        (GoRouter.maybeOf(context)?.canPop() ??
            (ModalRoute.of(context)?.canPop ?? true));
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: AppRoutes.mentorCompensation,
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            key: const Key('mentor_bank_account_screen'),
            backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          leading: (hasGoRouter || hasUnsavedChanges)
              ? BackButton(
                  onPressed: () => handleProtectedBackNavigation(
                    context: context,
                    hasUnsavedChanges: hasUnsavedChanges,
                    fallbackRoute: AppRoutes.mentorCompensation,
                  ),
                )
              : null,
          title: const Text('Tài khoản nhận thù lao'),
        ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            switch (accounts) {
              AsyncData(:final value) => _AccountList(accounts: value),
              AsyncError() => MentorErrorState(
                message: 'Chưa thể tải tài khoản ngân hàng.',
                onRetry: () => ref.invalidate(mentorBankAccountsProvider),
              ),
              _ => const Center(child: SakuraLoadingIndicator()),
            },
            const SizedBox(height: AppSpacing.space4),
            RikiCard(
              borderColor: AppColors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Thêm hoặc cập nhật tài khoản',
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    'Tài khoản mới sẽ thay thế tài khoản hiện tại và cần được xác minh lại.',
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    context.l10n.mentorBankPopularPresetsTitle,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children: _vnBankPresets.map((preset) {
                      final selected =
                          _binController.text.trim() == preset.bin;
                      return ChoiceChip(
                        key: Key('mentor_bank_preset_${preset.bin}'),
                        label: Text(preset.shortName),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _binController.text = preset.bin;
                            _bankNameController.text = preset.shortName;
                            _error = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  TextField(
                    key: const Key('mentor_bank_bin_field'),
                    controller: _binController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mã BIN ngân hàng (6 số)',
                      helperText: context.l10n.mentorBankCustomCodeHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('mentor_bank_name_field'),
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên ngân hàng',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('mentor_bank_account_field'),
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const Key('mentor_bank_holder_field'),
                    controller: _holderController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      _error!,
                      key: const Key('mentor_bank_error'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      _success!,
                      key: const Key('mentor_bank_success'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space3),
                  RikiPrimaryButton(
                    key: const Key('mentor_bank_submit_button'),
                    label: _submitting ? 'Đang lưu…' : 'Lưu tài khoản',
                    leadingIcon: Icons.save_outlined,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
        AppLoadingOverlay(
          visible: _submitting,
          title: context.l10n.loadingOverlaySavingTitle,
          subtitle: context.l10n.loadingOverlayUpdatingSubtitle,
        ),
      ],
      ),
    );
  }
}

class _AccountList extends StatelessWidget {
  const _AccountList({required this.accounts});

  final List<MentorBankAccountItem> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const MentorEmptyState(
        icon: Icons.account_balance_outlined,
        title: 'Chưa có tài khoản nhận thù lao',
        description:
            'Thêm tài khoản để nhận thù lao sau khi kỳ lương được duyệt.',
      );
    }
    return Column(
      children: [
        for (final a in accounts) ...[
          RikiCard(
            key: ValueKey('mentor_bank_account_${a.id}'),
            backgroundColor: AppColors.cardWarmWhite,
            borderColor: a.isCurrent
                ? AppColors.brandPrimary
                : AppColors.cardBorderMuted,
            boxShadow: AppShadows.sakuraSubtle,
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.bankShortName} · ${a.maskedAccountNumber}',
                        style: AppTypography.cardTitle,
                      ),
                      Text(
                        '${a.accountHolderName} · Phiên bản ${a.accountVersion}'
                        '${a.isCurrent ? ' (hiện tại)' : ''}',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        bankVerificationLabel(a.verificationStatus),
                        style: AppTypography.metadata.copyWith(
                          color: a.isVerified
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      ],
    );
  }
}
