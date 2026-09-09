import 'package:flutter/widgets.dart';

/// Static layout constants for the navigation rail.
abstract final class M3ENavigationRailLayout {
  /// Delay before committing a deferred selection/expansion change.
  static const Duration selectionDelay = Duration(milliseconds: 320);

  /// Duration of the rail's width/expansion animation.
  static const Duration expandDuration = Duration(milliseconds: 280);

  /// Insets around rail chrome (menu, FAB and trailing content).
  static const EdgeInsetsDirectional sectionPadding =
      EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 16);

  /// Horizontal inset for rail content.
  static const double horizontalInset = 20;

  /// Vertical gap inserted above the first section.
  static const double topGap = 44;
}
