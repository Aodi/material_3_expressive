import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show CircleBorder, InkWell, Material, MaterialType;

/// Minimum tap target for an interactive selection flip.
///
/// Larger than Material's 48dp minimum so list leading select is easy to hit
/// without changing icon layout size.
const double kM3ESelectionFlipMinTapSize = 64;

/// Flips horizontally between [child] and [selectedChild] when [selected].
///
/// Used for list selection icons at leading or trailing placement.
class M3ESelectionFlip extends StatefulWidget {
  /// Creates a selection flip.
  const M3ESelectionFlip({
    required this.selected,
    required this.selectedChild,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.onTap,
    this.minTapSize = kM3ESelectionFlipMinTapSize,
    super.key,
  });

  /// Whether the selected face is shown.
  final bool selected;

  /// Unselected face.
  final Widget child;

  /// Selected face.
  final Widget selectedChild;

  /// Flip duration.
  final Duration duration;

  /// Optional tap handler on the flip target only.
  final VoidCallback? onTap;

  /// Minimum hit-test size when [onTap] is set.
  ///
  /// Layout size stays the visual icon size; only the tappable region grows
  /// (centered). Defaults to [kM3ESelectionFlipMinTapSize].
  final double minTapSize;

  @override
  State<M3ESelectionFlip> createState() => _M3ESelectionFlipState();
}

class _M3ESelectionFlipState extends State<M3ESelectionFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(M3ESelectionFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.selected != widget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget face = AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        final double angle = _controller.value * math.pi;
        final bool showSelected = angle > math.pi / 2;
        final double displayAngle = showSelected ? math.pi - angle : angle;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(displayAngle),
          child: showSelected ? widget.selectedChild : widget.child,
        );
      },
    );

    final Widget sized = _FlipSize(
      unselected: widget.child,
      selected: widget.selectedChild,
      child: face,
    );

    if (widget.onTap == null) {
      return sized;
    }

    // Keep layout at the icon size; enlarge only the hit / splash region.
    return _ExpandTapTarget(
      minSize: widget.minTapSize,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          child: sized,
        ),
      ),
    );
  }
}

/// Reserves the larger of both faces so the flip does not jump layout.
class _FlipSize extends StatelessWidget {
  const _FlipSize({
    required this.unselected,
    required this.selected,
    required this.child,
  });

  final Widget unselected;
  final Widget selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IgnorePointer(child: Opacity(opacity: 0, child: unselected)),
        IgnorePointer(child: Opacity(opacity: 0, child: selected)),
        child,
      ],
    );
  }
}

/// Layouts as [child], but hit-tests a centered square of at least [minSize].
class _ExpandTapTarget extends SingleChildRenderObjectWidget {
  const _ExpandTapTarget({required this.minSize, required super.child});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderExpandTapTarget(minSize: minSize);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderExpandTapTarget renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

class _RenderExpandTapTarget extends RenderProxyBox {
  _RenderExpandTapTarget({required this._minSize});

  double _minSize;

  double get minSize => _minSize;

  set minSize(double value) {
    if (_minSize == value) {
      return;
    }
    _minSize = value;
    markNeedsPaint();
  }

  Rect get _expandedRect {
    final double dx = math.max(0, (_minSize - size.width) / 2);
    final double dy = math.max(0, (_minSize - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_expandedRect.contains(position)) {
      return false;
    }
    // Map out-of-bounds taps onto the child so InkWell still wins.
    final clamped = Offset(
      position.dx.clamp(0.0, size.width),
      position.dy.clamp(0.0, size.height),
    );
    if (child != null &&
        result.addWithPaintOffset(
          offset: Offset.zero,
          position: clamped,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        )) {
      return true;
    }
    return result.addWithPaintOffset(
      offset: Offset.zero,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        if (!_expandedRect.contains(transformed)) {
          return false;
        }
        result.add(BoxHitTestEntry(this, transformed));
        return true;
      },
    );
  }
}
