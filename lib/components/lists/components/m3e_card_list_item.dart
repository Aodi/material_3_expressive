import 'package:flutter/widgets.dart';

import '../../../foundations/foundations.dart';
import '../../cards/m3e_cards.dart';
import '../enums/m3e_list_enums.dart';
import 'm3e_card_radius_motion.dart';
import 'm3e_list_drag_proxy_scope.dart';
import 'm3e_list_item_scope.dart';

/// Internal helper to calculate [M3ECardPosition] based on index and total.
M3ECardPosition calculateCardPosition(int index, int total) => total == 1
    ? M3ECardPosition.single
    : index == 0
    ? M3ECardPosition.first
    : index == total - 1
    ? M3ECardPosition.last
    : M3ECardPosition.middle;

/// Internal helper to calculate [BorderRadius] based on [M3ECardPosition].
///
/// When [embedded] is true, every position uses [innerRadius] (no outer
/// first/last/single extremities) so the list can sit under another card row.
BorderRadius calculateCardRadius({
  required M3ECardPosition position,
  required double outerRadius,
  required double innerRadius,
  bool embedded = false,
}) {
  if (embedded) {
    return BorderRadius.circular(innerRadius);
  }
  switch (position) {
    case M3ECardPosition.single:
      return BorderRadius.circular(outerRadius);
    case M3ECardPosition.first:
      return BorderRadius.vertical(
        top: Radius.circular(outerRadius),
        bottom: Radius.circular(innerRadius),
      );
    case M3ECardPosition.last:
      return BorderRadius.vertical(
        top: Radius.circular(innerRadius),
        bottom: Radius.circular(outerRadius),
      );
    case M3ECardPosition.middle:
      return BorderRadius.circular(innerRadius);
  }
}

/// A single card item within an [M3ECardList].
class M3ECardListItem extends StatelessWidget {
  /// M3ECardListItem.
  const M3ECardListItem({
    required this.index,
    required this.position,
    required this.child,
    required this.outerRadius,
    required this.innerRadius,
    required this.gap,
    this.embedded = false,
    this.color,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.mouseCursor,
    this.haptic = M3EHapticFeedback.none,
    this.variant = M3ECardVariant.filled,
    this.border,
    this.resolvedColor,
    this.resolvedBorderRadius,
    super.key,
  });

  /// index.

  final int index;

  /// position.
  final M3ECardPosition position;

  /// child.
  final Widget child;

  /// outerRadius.
  final double outerRadius;

  /// innerRadius.
  final double innerRadius;

  /// gap.
  final double gap;

  /// When true, first/last/single use [innerRadius] like middle items.
  final bool embedded;

  /// color.
  final Color? color;

  /// padding.
  final EdgeInsetsGeometry? padding;

  /// Function.
  final void Function(int index)? onTap;

  /// Function.
  final void Function(int index)? onLongPress;

  /// semanticLabel.
  final String? semanticLabel;

  /// mouseCursor.
  final MouseCursor? mouseCursor;

  /// haptic.
  final M3EHapticFeedback haptic;

  /// Card variant for this item.
  final M3ECardVariant variant;

  /// Optional card outline.
  final BorderSide? border;

  /// Per-item color override. When null for an index, uses [color].
  final Color? resolvedColor;

  /// Per-item radius override. When null, uses position-based radii.
  final BorderRadius? resolvedBorderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final cardListTheme = theme.listTheme.cardList;
    final M3EListDragProxyScope? dragProxy = M3EListDragProxyScope.maybeOf(
      context,
    );

    final BorderRadius borderRadius = dragProxy != null
        ? BorderRadius.circular(dragProxy.radius)
        : (resolvedBorderRadius ??
              calculateCardRadius(
                position: position,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
                embedded: embedded,
              ));

    final M3ECardVariant effectiveVariant = dragProxy != null
        ? M3ECardVariant.filled
        : variant;
    final BorderSide? effectiveBorder = dragProxy != null ? null : border;
    final Color? effectiveColor = dragProxy != null
        ? dragProxy.color
        : (resolvedColor ??
              color ??
              (variant == M3ECardVariant.outlined
                  ? null
                  : cardListTheme.backgroundColor(scheme)));

    final bool isLast =
        position == M3ECardPosition.last || position == M3ECardPosition.single;

    final VoidCallback? wrappedOnTap = onTap != null
        ? () => onTap!(index)
        : null;
    final VoidCallback? wrappedOnLongPress = onLongPress != null
        ? () => onLongPress!(index)
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
      child: M3ECardRadiusMotion(
        radius: borderRadius,
        builder: (BuildContext context, BorderRadius animatedRadius) {
          return M3ECard(
            variant: effectiveVariant,
            border: effectiveBorder,
            borderRadius: animatedRadius,
            color: effectiveColor,
            padding: padding ?? cardListTheme.itemPadding,
            onPressed: dragProxy != null ? null : wrappedOnTap,
            onLongPress: dragProxy != null ? null : wrappedOnLongPress,
            mouseCursor: mouseCursor,
            semanticLabel: semanticLabel,
            haptic: haptic,
            width: double.infinity,
            elevation: dragProxy != null ? 0 : null,
            animationDuration: Duration.zero,
            child: M3EListItemScope(child: child),
          );
        },
      ),
    );
  }
}
