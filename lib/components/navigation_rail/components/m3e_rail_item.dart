import 'package:material_ui/material_ui.dart';

import '../../../foundations/foundations.dart';
import '../enums/m3e_navigation_rail_enums.dart';
import '../models/m3e_navigation_rail_destination.dart';
import 'm3e_rail_item_button.dart';

/// Single rail item (private to package). One class per file.
class M3ERailItem extends StatelessWidget {
  /// Creates a single navigation rail item.
  const M3ERailItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.expanded,
    required this.labelBehavior,
    this.suppressInk = false,
    this.useLocalIndicator = true,
    this.indicatorKey,
  });

  /// Destination data driving this item.
  final M3ENavigationRailDestination destination;

  /// Whether this item is currently selected.
  final bool selected;

  /// Called when the item is tapped.
  final VoidCallback onTap;

  /// Whether the rail is expanded (shows label and badges inline).
  final bool expanded;

  /// Whether this item's label should be visible.
  final M3ENavigationRailLabelBehavior labelBehavior;

  /// When true, disables splash/hover/highlight effects to prevent flicker during transitions.
  final bool suppressInk;

  /// When false, selection fill is drawn by the shared liquid indicator.
  final bool useLocalIndicator;

  /// Key for the shared selection indicator target.
  final GlobalKey? indicatorKey;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context).navigationRailTheme;
    final height = expanded
        ? theme.itemExpandedHeight
        : theme.itemCollapsedHeight;

    final Widget button = M3ERailItemButton(
      icon: destination.icon,
      selectedIcon: destination.selectedIcon,
      isSelected: selected,
      onPressed: onTap,
      expanded: expanded,
      labelBehavior: labelBehavior,
      label: destination.label,
      semanticLabel: destination.semanticLabel,
      suppressInk: suppressInk,
      badgeCount: destination.badgeCount,
      useLocalIndicator: useLocalIndicator,
      indicatorKey: indicatorKey,
    );

    // Keep one stable full-width target in both states. Replacing this with a
    // Row/Expanded tree during collapse causes a transient center layout
    // before the rail width animation settles, which is visible as a jump.
    final core = SizedBox(
      width: double.infinity,
      height: height,
      child: button,
    );

    return Semantics(selected: selected, button: true, child: core);
  }
}
