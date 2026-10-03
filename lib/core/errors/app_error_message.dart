import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

/// Converts technical/data-layer failures into stable localized copy.
///
/// Backend messages and exception strings deliberately stay out of the
/// presentation layer. A feature-specific [fallback] can retain useful context
/// for failures that do not belong to the shared API error hierarchy.
String appErrorMessage(
  Object error,
  AppLocalizations l10n, {
  String? fallback,
}) {
  return switch (error) {
    NetworkError() => l10n.commonErrorNetwork,
    UnauthorizedError() => l10n.commonErrorUnauthorized,
    ForbiddenError() => l10n.commonErrorForbidden,
    NotFoundError() => l10n.commonErrorNotFound,
    ConflictError() => l10n.commonErrorConflict,
    ValidationError() => l10n.commonErrorValidation,
    ServerError() => l10n.commonErrorServer,
    UnknownError() => fallback ?? l10n.commonErrorUnknown,
    _ => fallback ?? l10n.commonErrorUnknown,
  };
}
