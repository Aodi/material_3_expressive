import 'package:flutter/widgets.dart';

import '../theme/m3e_theme.dart';
import 'm3e_focus_interaction.dart';
import 'm3e_focus_ring_theme.dart';

/// Draws the Material 3 Expressive keyboard focus ring around [child].
///
/// When [focused] is false, returns [child] unchanged. Geometry and color come
/// from [M3EThemeData.focusRingTheme] unless local overrides are provided.
class M3EFocusRing extends StatelessWidget {
  /// Creates a focus ring decorator.
  const M3EFocusRing({
    required this.radius,
    required this.child,
    this.focused = false,
    this.animationDuration = Duration.zero,
    this.color,
    this.width,
    this.gap,
    super.key,
  });

  /// Outer border radius of the focused surface.
  final BorderRadius radius;

  /// Content to wrap.
  final Widget child;

  /// Whether the keyboard focus ring should be painted.
  final bool focused;

  /// Optional animation for ring appearance.
  final Duration animationDuration;

  /// Optional color override; defaults to [M3EFocusRingTheme.resolveColor].
  final Color? color;

  /// Optional stroke width override.
  final double? width;

  /// Optional gap override between surface and ring.
  final double? gap;

  /// Theme outset (`gap + width`) for layout clearance.
  static double outsetOf(BuildContext context) {
    return M3ETheme.of(context).focusRingTheme.outset;
  }

  /// Theme tokens for the ambient [M3ETheme].
  static M3EFocusRingTheme themeOf(BuildContext context) {
    return M3ETheme.of(context).focusRingTheme;
  }

  /// Whether [node] should show a keyboard focus ring.
  static bool shouldShow(FocusNode node) {
    if (!node.hasPrimaryFocus) {
      return false;
    }
    if (!M3EFocusInteraction.instance.ringsAllowed) {
      return false;
    }
    return FocusManager.instance.highlightMode ==
        FocusHighlightMode.traditional;
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final ringTheme = theme.focusRingTheme;
    final resolvedColor = color ?? ringTheme.resolveColor(theme.colorScheme);
    final resolvedGap = gap ?? ringTheme.gap;
    final resolvedWidth = width ?? ringTheme.width;
    final outset = resolvedGap + resolvedWidth;

    final adjustedRadius = BorderRadius.only(
      topLeft: Radius.circular(radius.topLeft.x + outset),
      topRight: Radius.circular(radius.topRight.x + outset),
      bottomLeft: Radius.circular(radius.bottomLeft.x + outset),
      bottomRight: Radius.circular(radius.bottomRight.x + outset),
    );

    // Always use the same [Stack] structure. Switching between a bare child and
    // a [Stack] when [focused] flips remounts descendants — that drops an
    // [EditableText] text-input client while the [FocusNode] stays focused
    // (ring visible, typing dead) and can yank Tab off search fields.
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          child,
          if (focused)
            Positioned(
              top: -outset,
              bottom: -outset,
              left: -outset,
              right: -outset,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: resolvedColor,
                      width: resolvedWidth,
                    ),
                    borderRadius: adjustedRadius,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
