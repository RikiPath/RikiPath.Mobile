import 'package:flutter/widgets.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

export 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsVi();
}
