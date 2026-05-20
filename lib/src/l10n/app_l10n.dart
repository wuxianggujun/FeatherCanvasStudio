import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

AppLocalizations appL10nOf(BuildContext context) {
  return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      lookupAppLocalizations(const Locale('zh'));
}
