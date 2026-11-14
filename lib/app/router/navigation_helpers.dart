import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

void popOrGo<T>(
  BuildContext context,
  String fallbackRoute, {
  T? result,
  Object? extra,
}) {
  final router = GoRouter.maybeOf(context);
  if (router != null && router.canPop()) {
    router.pop(result);
    return;
  }
  final navigator = Navigator.maybeOf(context);
  if (navigator != null && navigator.canPop()) {
    navigator.pop(result);
    return;
  }
  router?.go(fallbackRoute, extra: extra);
}

void navigateContextAware(
  BuildContext context,
  String targetLocation, {
  Object? extra,
}) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }

  if (AppRoutes.isLearnerTabRoot(targetLocation) ||
      AppRoutes.isMentorTabRoot(targetLocation)) {
    router.go(targetLocation, extra: extra);
    return;
  }

  final currentPath = router.routerDelegate.currentConfiguration.uri.path;

  if (AppRoutes.isShellBranchRoute(targetLocation) &&
      !AppRoutes.isShellBranchRoute(currentPath)) {
    router.go(targetLocation, extra: extra);
    return;
  }

  router.push(targetLocation, extra: extra);
}

Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = 'Hủy thay đổi?',
  String message =
      'Bạn có thay đổi chưa lưu. Nếu rời khỏi màn hình này, các thay đổi sẽ bị hủy.',
  String stayLabel = 'Ở lại',
  String discardLabel = 'Rời đi',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(stayLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(discardLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> handleProtectedBackNavigation({
  required BuildContext context,
  required bool hasUnsavedChanges,
  required String fallbackRoute,
  String title = 'Hủy thay đổi?',
  String message =
      'Bạn có thay đổi chưa lưu. Nếu rời khỏi màn hình này, các thay đổi sẽ bị hủy.',
  String stayLabel = 'Ở lại',
  String discardLabel = 'Rời đi',
  VoidCallback? onConfirmedDiscard,
}) async {
  if (!hasUnsavedChanges) {
    onConfirmedDiscard?.call();
    popOrGo(context, fallbackRoute);
    return;
  }
  final confirmed = await confirmDiscardChanges(
    context,
    title: title,
    message: message,
    stayLabel: stayLabel,
    discardLabel: discardLabel,
  );
  if (confirmed && context.mounted) {
    onConfirmedDiscard?.call();
    popOrGo(context, fallbackRoute);
  }
}
