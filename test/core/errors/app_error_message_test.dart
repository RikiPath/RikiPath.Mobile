import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

void main() {
  final l10n = AppLocalizationsVi();

  test('network error uses localized copy instead of transport text', () {
    final message = appErrorMessage(
      const NetworkError(message: 'SocketException: host lookup failed'),
      l10n,
    );

    expect(message, l10n.commonErrorNetwork);
    expect(message, isNot(contains('SocketException')));
  });

  test('authorization statuses keep distinct user-facing messages', () {
    expect(
      appErrorMessage(const UnauthorizedError(), l10n),
      l10n.commonErrorUnauthorized,
    );
    expect(
      appErrorMessage(const ForbiddenError(), l10n),
      l10n.commonErrorForbidden,
    );
  });

  test('resource and conflict errors remain distinct', () {
    expect(
      appErrorMessage(const NotFoundError(), l10n),
      l10n.commonErrorNotFound,
    );
    expect(
      appErrorMessage(const ConflictError(), l10n),
      l10n.commonErrorConflict,
    );
  });

  test('validation and server errors use stable localized copy', () {
    expect(
      appErrorMessage(
        const ValidationError(message: 'raw backend validation'),
        l10n,
      ),
      l10n.commonErrorValidation,
    );
    expect(
      appErrorMessage(
        const ServerError(message: 'raw server body', statusCode: 500),
        l10n,
      ),
      l10n.commonErrorServer,
    );
  });

  test('unknown technical exception uses the supplied feature fallback', () {
    final message = appErrorMessage(
      FormatException('raw malformed response'),
      l10n,
      fallback: 'Không thể tải nội dung.',
    );

    expect(message, 'Không thể tải nội dung.');
    expect(message, isNot(contains('FormatException')));
    expect(message, isNot(contains('raw malformed response')));
  });
}
