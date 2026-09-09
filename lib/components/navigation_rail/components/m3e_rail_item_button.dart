import 'package:material_3_expressive/components/navigation_rail/components/m3e_nav_selection_indicator.dart'
    show M3ENavSelectionIndicator;
import 'package:material_3_expressive/components/navigation_rail/styles/m3e_navigation_rail_theme.dart'
    show M3ENavigationRailTheme;
import 'package:material_ui/material_ui.dart';

import '../../../foundations/foundations.dart';
import '../enums/m3e_navigation_rail_enums.dart';
import '../res/m3e_navigation_rail_layout.dart';
import 'm3e_nav_icon_scale.dart';
import 'm3e_rail_badge_view.dart';

/// Internal button used by the NavigationRail item that can look like
/// an IconButton (collapsed) or a text button (expanded) without
/// switching widget types. This avoids animation hitches when the
/// rail animates between collapsed and expanded.
class M3ERailItemButton extends StatelessWidget {
  /// Creates a [M3ERailItemButton].
  const M3ERailItemButton({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.isSelected,
    required this.onPressed,
    required this.expanded,
    required this.labelBehavior,
    required this.label,
    this.semanticLabel,
    this.suppressInk = false,
    this.badgeCount,
    this.heightOverride,
    this.useLocalIndicator = true,
    this.indicatorKey,
    this.haptic = M3EHapticFeedback.none,
  });

  /// Icon to display.
  final Widget icon;

  /// Optional icon to display when [isSelected] is true; falls back to [icon].
  final Widget? selectedIcon;

  /// Whether this destination is currently selected.
  final bool isSelected;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  /// Whether the rail is in expanded layout.
  final bool expanded;

  /// Controls when the text label is visible in collapsed mode.
  final M3ENavigationRailLabelBehavior labelBehavior;

  /// Text label for the destination.
  final String label;

  /// Semantic label used for accessibility (and tooltip when collapsed).
  final String? semanticLabel;

  /// If true, suppresses Ink splash/hover effects.
  final bool suppressInk;

  /// Optional numeric badge value to show.
  final int? badgeCount;

  /// Optional min height to enforce for the tap target. When null, defaults
  /// to the theme's [M3ENavigationRailTheme.itemExpandedHeight] or
  /// [M3ENavigationRailTheme.itemCollapsedHeight] depending on [expanded].
  final double? heightOverride;

  /// When false, selection fill is drawn by [M3ENavSelectionIndicator] instead.
  final bool useLocalIndicator;

  /// Key for the local indicator when [useLocalIndicator] is true.
  final GlobalKey? indicatorKey;

  /// Haptic intensity on tap. Defaults to [M3EHapticFeedback.none].
  final M3EHapticFeedback haptic;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context).navigationRailTheme;
    final m3e = M3ETheme.of(context);
    final scheme = m3e.colorScheme;
    final double height =
        heightOverride ??
        (expanded ? theme.itemExpandedHeight : theme.itemCollapsedHeight);
    final bool selected = isSelected;
    final Color iconFg = selected
        ? theme.activeIconColor(scheme)
        : theme.inactiveIconAndLabelColor(scheme);
    final Color labelFg = selected
        ? (expanded
              ? theme.activeIconAndLabelColor(scheme)
              : theme.activeLabelColor(scheme))
        : theme.inactiveIconAndLabelColor(scheme);
    final Widget scaledIcon = M3ENavIconScale(
      selected: selected,
      child: IconTheme.merge(
        data: IconThemeData(color: iconFg, size: theme.iconSize),
        child: selected && selectedIcon != null ? selectedIcon! : icon,
      ),
    );
    final Widget content = expanded
        ? _buildExpandedContent(
            m3e: m3e,
            theme: theme,
            labelFg: labelFg,
            scaledIcon: scaledIcon,
          )
        : _buildCollapsedContent(
            m3e: m3e,
            theme: theme,
            labelFg: labelFg,
            scaledIcon: scaledIcon,
          );
    final material = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          M3EHaptics.trigger(haptic);
          onPressed();
        },
        splashFactory: NoSplash.splashFactory,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: Padding(
          // The icon/indicator keeps the same leading anchor in both rail
          // states. The collapsed 56dp indicator is centered by the 20dp
          // insets inside the 96dp rail, without changing its x-position.
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: M3ENavigationRailLayout.horizontalInset,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconTheme.merge(
              data: IconThemeData(color: iconFg, size: theme.iconSize),
              child: content,
            ),
          ),
        ),
      ),
    );
    final Widget sized = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: material,
    );
    final Widget withTooltip = expanded
        ? sized
        : Tooltip(
            message: semanticLabel ?? label,
            preferBelow: false,
            child: sized,
          );
    return Semantics(
      button: true,
      selected: selected,
      label: expanded ? null : (semanticLabel ?? label),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: withTooltip),
    );
  }

  Widget _buildExpandedContent({
    required M3EThemeData m3e,
    required M3ENavigationRailTheme theme,
    required Color labelFg,
    required Widget scaledIcon,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        scaledIcon,
        Flexible(child: SizedBox(width: theme.iconLabelGap)),
        Flexible(child: _buildExpandedLabel(m3e, labelFg)),
        if (badgeCount != null)
          Padding(
            padding: EdgeInsets.only(left: theme.iconLabelGap),
            child: M3ERailBadge(count: badgeCount),
          ),
      ],
    );
    final pill = Container(
      key: indicatorKey,
      height: theme.itemExpandedHeight,
      padding: EdgeInsetsDirectional.only(
        start: theme.indicatorLeading,
        end: theme.indicatorTrailing,
      ),
      decoration: BoxDecoration(
        color: useLocalIndicator && isSelected
            ? theme.activeIndicatorColorResolved(m3e.colorScheme)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );
    return Align(alignment: AlignmentDirectional.centerStart, child: pill);
  }

  /// Reveals the expanded label from its leading edge while keeping its
  /// position fixed. Android's NavigationRail label transition clips/reveals
  /// the label; translating the text itself makes it visibly slide.
  Widget _buildExpandedLabel(M3EThemeData m3e, Color labelFg) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: semanticLabel ?? label,
      style: m3e.typeScale.labelLarge.copyWith(color: labelFg),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: M3EMotion.medium2,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: value,
          child: child,
        ),
      ),
      child: text,
    );
  }

  Widget _buildCollapsedContent({
    required M3EThemeData m3e,
    required M3ENavigationRailTheme theme,
    required Color labelFg,
    required Widget scaledIcon,
  }) {
    final bool showLabel =
        labelBehavior == M3ENavigationRailLabelBehavior.alwaysShow ||
        (isSelected &&
            labelBehavior != M3ENavigationRailLabelBehavior.alwaysHide);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(
          key: indicatorKey,
          child: SizedBox(
            width: 56,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: useLocalIndicator && isSelected
                    ? theme.activeIndicatorColorResolved(m3e.colorScheme)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: scaledIcon),
            ),
          ),
        ),
        if (showLabel)
          Padding(
            padding: EdgeInsets.only(top: theme.iconLabelGap),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: semanticLabel ?? label,
              style: m3e.typeScale.labelMedium.copyWith(color: labelFg),
            ),
          ),
      ],
    );
  }
}
