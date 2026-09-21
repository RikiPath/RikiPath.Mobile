import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

String userProfileErrorMessage(Object error, AppLocalizations l10n) {
  return switch (error) {
    UnauthorizedError() => l10n.profileErrorUnauthorized,
    ForbiddenError() => l10n.profileErrorForbidden,
    NetworkError() => l10n.profileErrorNetwork,
    ValidationError() => l10n.profileErrorValidation,
    ServerError() => l10n.profileErrorServer,
    _ => l10n.profileErrorUnknown,
  };
}
