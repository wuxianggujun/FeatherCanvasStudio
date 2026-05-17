import 'package:flutter/material.dart';

const double workspacePadding = 12;
const double sectionGap = 12;
const double fieldGap = 12;
const double layoutGap = 12;
const double panelPadding = 14;

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double workspacePadding = 12;
  static const double sectionGap = 12;
  static const double fieldGap = 12;
  static const double layoutGap = 12;
  static const double panelPadding = 14;
}

class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill =
      BorderRadius.all(Radius.circular(pill));
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 720;
  static const double medium = 900;
  static const double expanded = 980;
  static const double railShortHeight = 720;
  static const double railShortMinWidth = 780;
}

class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
}

class AppElevation {
  const AppElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;
}

class AppIconSize {
  const AppIconSize._();

  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
}
