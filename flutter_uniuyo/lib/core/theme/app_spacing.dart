import 'package:flutter/material.dart';

/// Consistent spacing system across the entire app
/// Following 8pt grid system (standard in Material Design)
class AppSpacing {
  // Base spacing scale (8pt grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Screen padding
  static const double screenHorizontal = md; // 16px
  static const double screenVertical = md; // 16px
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);

  // Card & Container
  static const double cardPadding = md; // 16px
  static const double cardMargin = sm; // 8px
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(md);
  static const EdgeInsets cardMarginAll = EdgeInsets.all(sm);

  // List items
  static const double listItemVertical = md; // 16px
  static const double listItemHorizontal = md; // 16px
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // Buttons
  static const double buttonHeight = 48.0;
  static const double buttonRadius = 12.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Input fields
  static const double inputHeight = 56.0;
  static const double inputRadius = 12.0;
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // Icons
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 64.0;

  // Sections & Dividers
  static const double sectionSpacing = lg; // 24px between sections
  static const double itemSpacing = md; // 16px between items
  static const double tightSpacing = sm; // 8px for tight grouping
  static const double looseSpacing = xl; // 32px for loose grouping

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusCircle = 999.0;

  // Map controls
  static const double mapControlSize = 48.0;
  static const double mapControlSpacing = sm;
  static const double mapControlRadius = radiusMd;

  // Bottom sheets & Dialogs
  static const double dialogPadding = lg;
  static const double dialogRadius = radiusXl;
  static const EdgeInsets dialogPaddingAll = EdgeInsets.all(lg);

  // AppBar
  static const double appBarHeight = 56.0;
}
