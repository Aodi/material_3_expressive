import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:motor/motor.dart';

import '../../../foundations/foundations.dart';
import '../../cards/m3e_cards.dart';
import '../enums/m3e_expandable_enums.dart';
import '../enums/m3e_list_selection_enums.dart';
import '../styles/m3e_expandable_style.dart';
import '../styles/m3e_list_reorder_state.dart';
import '../styles/m3e_list_selection_state.dart';
import '../utils/m3e_expandable_spring_motion.dart';
import '../utils/m3e_list_immediate_tap.dart';
import '../utils/m3e_list_selection_fill.dart';
import '../utils/m3e_measure_size.dart';
import 'm3e_card_list_item.dart';
import 'm3e_expandable_expanded.dart';
import 'm3e_expandable_header_tap_scope.dart';
import 'm3e_expandable_nest_scope.dart';
import 'm3e_expandable_snap_collapse.dart';
import 'm3e_expandable_sublist.dart';
import 'm3e_list_feature_scope.dart';
import 'm3e_list_reorder_exclude.dart';

part 'm3e_expandable_item_body.dart';

/// M3EExpandableHeaderBuilder.

typedef M3EExpandableHeaderBuilder =
    Widget Function(BuildContext context, int index, double progress);

/// M3EExpandableBodyBuilder.
typedef M3EExpandableBodyBuilder =
    Widget Function(BuildContext context, int index, double progress);

/// M3EExpandableItem.

class M3EExpandableItem extends StatefulWidget {
  /// M3EExpandableItem.
  const M3EExpandableItem({
    super.key,
    required this.index,
    required this.totalCount,
    required this.isExpanded,
    required this.headerBuilder,
    required this.bodyBuilder,
    required this.decoration,
    required this.expandMotion,
    required this.collapseMotion,
    required this.onToggle,
    this.expanded,
  });

  /// index.

  final int index;

  /// totalCount.
  final int totalCount;

  /// isExpanded.
  final bool isExpanded;

  /// headerBuilder.
  final M3EExpandableHeaderBuilder headerBuilder;

  /// bodyBuilder.
  final M3EExpandableBodyBuilder bodyBuilder;

  /// Optional expanded content (list rows or freeform child).
  final M3EExpandableExpanded? expanded;

  /// decoration.
  final M3EExpandableStyle decoration;

  /// expandMotion.
  final M3ESpring expandMotion;

  /// collapseMotion.
  final M3ESpring collapseMotion;

  /// onToggle.
  final VoidCallback onToggle;

  @override
  State<M3EExpandableItem> createState() => _M3EExpandableItemState();
}

class _M3EExpandableItemState extends State<M3EExpandableItem>
    with TickerProviderStateMixin {
  late final SingleMotionController _expandCtrl;

  bool _isPressed = false;

  /// Node of the item's single toggle target (whole card or header row).
  final FocusNode _toggleFocusNode = FocusNode();
  bool _focused = false;

  double? _collapsedHeight;
  double? _expandedHeight;

  @override
  void initState() {
    super.initState();
    final motion = widget.isExpanded
        ? widget.expandMotion.toMotion()
        : widget.collapseMotion.toMotion();

    _expandCtrl = SingleMotionController(motion: motion, vsync: this)
      ..value = widget.isExpanded ? 1.0 : 0.0;
    _toggleFocusNode.addListener(_handleToggleFocusChanged);
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChanged);
    M3EFocusInteraction.instance.addListener(_handleToggleFocusChanged);
  }

  void _handleHighlightModeChanged(FocusHighlightMode mode) {
    _handleToggleFocusChanged();
  }

  @override
  void didUpdateWidget(covariant M3EExpandableItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isExpanded != widget.isExpanded) {
      final bool snap = M3EExpandableSnapCollapse.of(context);
      if (snap) {
        _expandCtrl.value = widget.isExpanded ? 1.0 : 0.0;
      } else {
        final motion = widget.isExpanded
            ? widget.expandMotion.toMotion()
            : widget.collapseMotion.toMotion();
        _expandCtrl.motion = motion;
        _expandCtrl.animateTo(widget.isExpanded ? 1.0 : 0.0);
      }
    }
  }

  void _handleTapDown() => setState(() => _isPressed = true);
  void _handleTapUp() => setState(() => _isPressed = false);
  void _handleTapCancel() => setState(() => _isPressed = false);

  void _handleCardStateChanged(M3EInteractionState state) {
    if (_isPressed == state.pressed) {
      return;
    }
    setState(() => _isPressed = state.pressed);
  }

  void _handleToggleFocusChanged() {
    if (!mounted) {
      return;
    }
    final bool show = M3EFocusRing.shouldShow(_toggleFocusNode, context);
    if (_focused != show) {
      setState(() => _focused = show);
    }
  }

  @override
  void dispose() {
    M3EFocusInteraction.instance.removeListener(_handleToggleFocusChanged);
    FocusManager.instance.removeHighlightModeListener(
      _handleHighlightModeChanged,
    );
    _toggleFocusNode
      ..removeListener(_handleToggleFocusChanged)
      ..dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  bool get _hasListExpansion {
    final M3EExpandableExpanded? expanded = widget.expanded;
    return expanded != null && expanded.isList;
  }

  BorderRadius _buildEffectiveRadius() {
    final d = widget.decoration;
    final BorderRadius? selectedRadius = m3eSelectionRadius(
      context,
      widget.index,
      outerRadius: d.outerRadius,
    );
    if (selectedRadius != null) {
      return selectedRadius;
    }

    if (_hasListExpansion) {
      return m3eExpandableParentRadius(
        globalPosition: calculateCardPosition(widget.index, widget.totalCount),
        outerRadius: d.outerRadius,
        innerRadius: _isPressed ? d.pressedRadius : d.innerRadius,
        isExpanded: widget.isExpanded,
        hasSublist: true,
      );
    }

    final isFirst = widget.index == 0;
    final isLast = widget.index == widget.totalCount - 1;
    final isSingle = widget.totalCount == 1;

    if (widget.isExpanded && d.expandedRadius != null) {
      return BorderRadius.circular(d.expandedRadius!);
    }

    if (isSingle) {
      return BorderRadius.circular(d.outerRadius);
    }

    final effectiveInnerRadius = _isPressed ? d.pressedRadius : d.innerRadius;

    if (isFirst) {
      return BorderRadius.vertical(
        top: Radius.circular(d.outerRadius),
        bottom: Radius.circular(effectiveInnerRadius),
      );
    }
    if (isLast) {
      return BorderRadius.vertical(
        top: Radius.circular(effectiveInnerRadius),
        bottom: Radius.circular(d.outerRadius),
      );
    }
    return BorderRadius.circular(effectiveInnerRadius);
  }

  VoidCallback? _selectionDoubleTap() {
    final M3EListFeatureScope? features = M3EListFeatureScope.maybeOf(context);
    if (features == null ||
        !features.selectionEnabled ||
        features.selectionState.trigger != M3EListSelectionTrigger.doubleTap) {
      return null;
    }
    return () => features.onToggleSelection(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final d = widget.decoration;
    final isLast = widget.index == widget.totalCount - 1;
    final bool hasList = _hasListExpansion;
    final M3EListFeatureScope? features = M3EListFeatureScope.maybeOf(context);
    final bool selectionOn = features?.selectionEnabled ?? false;
    // Leading flip owns its own InkWell — keep expand off the card surface so
    // icon tap-to-select cannot also toggle expand/collapse.
    final bool separateLeadingSelect =
        selectionOn &&
        features!.selectionState.hasSelectedIcon &&
        features.selectionState.trigger == M3EListSelectionTrigger.icon;

    final canTapHeader = d.tapHeaderToToggle;
    final canTapBody =
        (widget.isExpanded && d.tapBodyToCollapse) ||
        (!widget.isExpanded && d.tapBodyToExpand);
    final entireCardTappable =
        !separateLeadingSelect &&
        !d.tapIconToToggle &&
        canTapHeader &&
        canTapBody &&
        !hasList;

    final bool expandOnHeader =
        !entireCardTappable && canTapHeader && !d.tapIconToToggle;
    final bool pressForSelection = selectionOn && canTapHeader;

    VoidCallback? rawHeaderOrOuter;
    if (entireCardTappable ||
        expandOnHeader ||
        pressForSelection ||
        separateLeadingSelect) {
      rawHeaderOrOuter = () {
        if (selectionOn && (features?.controller?.isSelectionMode ?? false)) {
          features!.onToggleSelection(widget.index);
          return;
        }
        if (entireCardTappable || expandOnHeader || separateLeadingSelect) {
          widget.onToggle();
        }
      };
    }

    final VoidCallback? outerTap = entireCardTappable && !separateLeadingSelect
        ? rawHeaderOrOuter
        : null;
    final VoidCallback? headerTap =
        !entireCardTappable &&
            !separateLeadingSelect &&
            rawHeaderOrOuter != null
        ? rawHeaderOrOuter
        : null;

    final String? outerTooltip = entireCardTappable
        ? (widget.isExpanded ? d.collapseTooltip : d.expandTooltip)
        : null;

    final VoidCallback? doubleTap = _selectionDoubleTap();

    Widget headerCard = M3EListTapBinder(
      onTap: separateLeadingSelect ? rawHeaderOrOuter : (outerTap ?? headerTap),
      onDoubleTap: doubleTap,
      builder: (BuildContext context, VoidCallback? onPressed) {
        final Widget card = _buildAnimatedContainer(
          scheme,
          d,
          separateLeadingSelect
              ? null
              : (entireCardTappable ? onPressed : null),
          separateLeadingSelect
              ? null
              : (!entireCardTappable ? onPressed : null),
          outerTooltip,
          bodyInsideCard: !hasList,
        );
        if (!separateLeadingSelect) {
          return card;
        }
        return M3EExpandableHeaderTapScope(onTap: onPressed, child: card);
      },
    );

    Widget content = headerCard;
    if (hasList) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          headerCard,
          AnimatedBuilder(
            animation: _expandCtrl,
            builder: (BuildContext context, Widget? _) {
              return M3EExpandableSublist(
                progress: _expandCtrl.value,
                style: d,
                topGap: widget.expanded!.topGap,
                child: M3EListReorderExclude(
                  // Block parent list selection/reorder from leaking into
                  // nested lists; nested FeatureHosts still override this.
                  child: M3EListFeatureScope(
                    selectionEnabled: false,
                    reorderEnabled: false,
                    selectionState: M3EListSelectionState.defaults,
                    reorderState: M3EListReorderState.defaults,
                    controller: null,
                    itemCount: 0,
                    onToggleSelection: (_) {},
                    child: M3EExpandableNestScope(
                      closeBottom: isLast,
                      outerRadius: d.outerRadius,
                      child: widget.expanded!.child,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    // Same local reading-order group as dropdown panel items: header, then
    // revealed sublist rows, then the next sibling outside this group.
    content = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: content,
    );

    return RepaintBoundary(
      child: Padding(
        padding: d.margin ?? EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : d.gap),
          child: content,
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer(
    M3EColorScheme scheme,
    M3EExpandableStyle d,
    VoidCallback? outerTap,
    VoidCallback? headerTap,
    String? outerTooltip, {
    required bool bodyInsideCard,
  }) {
    // Card-level press matches [M3ECardList]: pointer cursor + hover state layer.
    // List expansions are header-only cards, so header taps live on the card.
    final VoidCallback? cardPress =
        outerTap ?? (!bodyInsideCard ? headerTap : null);
    final bool cardHandlesTap = cardPress != null;

    Widget content = AnimatedBuilder(
      animation: _expandCtrl,
      builder: (context, child) {
        final progress = _expandCtrl.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              d,
              progress,
              cardHandlesTap ? null : headerTap,
              isEntirelyTappable: outerTap != null || cardHandlesTap,
            ),
            if (bodyInsideCard)
              _buildExpandableBody(
                d,
                progress,
                isEntirelyTappable: outerTap != null || cardHandlesTap,
              ),
          ],
        );
      },
    );

    if (!cardHandlesTap) {
      content = _buildInteractionWrapper(
        d,
        onTap: outerTap,
        tooltip: outerTooltip,
        focusNode: outerTap != null ? _toggleFocusNode : null,
        child: content,
      );
    } else if (outerTooltip != null) {
      content = Tooltip(message: outerTooltip, child: content);
    }

    return TweenAnimationBuilder<BorderRadius?>(
      duration: const Duration(milliseconds: 40),
      curve: Curves.easeOut,
      tween: BorderRadiusTween(
        begin: _buildEffectiveRadius(),
        end: _buildEffectiveRadius(),
      ),
      builder: (context, animatedRadius, child) {
        final BorderRadius radius = animatedRadius ?? _buildEffectiveRadius();
        final Color? fill =
            m3eSelectionFill(context, widget.index) ??
            d.color ??
            scheme.surfaceContainerHighest;
        final Widget card = M3ECard(
          variant: M3ECardVariant.filled,
          borderRadius: radius,
          color: fill,
          elevation: d.elevation,
          border: d.border,
          padding: EdgeInsets.zero,
          width: double.infinity,
          onPressed: cardPress,
          onStateChanged: cardHandlesTap ? _handleCardStateChanged : null,
          mouseCursor: cardHandlesTap ? SystemMouseCursors.click : null,
          child: child!,
        );
        if (cardHandlesTap) {
          // [M3ECard] owns focus ring when interactive.
          return card;
        }
        return M3EFocusRing(focused: _focused, radius: radius, child: card);
      },
      child: content,
    );
  }

  Widget _buildHeader(
    M3EExpandableStyle d,
    double progress,
    VoidCallback? onTap, {
    required bool isEntirelyTappable,
  }) {
    final expandableTheme = M3ETheme.of(context).listTheme.expandable;
    final headerContent = Padding(
      padding: d.headerPadding ?? expandableTheme.headerPadding,
      child: Row(
        crossAxisAlignment: d.headerAlignment == CrossAxisAlignment.stretch
            ? CrossAxisAlignment.center
            : d.headerAlignment,
        textBaseline: d.headerAlignment == CrossAxisAlignment.baseline
            ? TextBaseline.alphabetic
            : null,
        children: [
          if (d.iconPlacement == M3EExpandableIconPlacement.left) ...[
            _buildIcon(d, progress, widget.onToggle),
            Expanded(
              child: widget.headerBuilder(context, widget.index, progress),
            ),
          ] else ...[
            Expanded(
              child: widget.headerBuilder(context, widget.index, progress),
            ),
            _buildIcon(d, progress, widget.onToggle),
          ],
        ],
      ),
    );

    final String? headerTooltip = (d.tapHeaderToToggle && !isEntirelyTappable)
        ? (widget.isExpanded ? d.collapseTooltip : d.expandTooltip)
        : null;

    return _buildInteractionWrapper(
      d,
      onTap: onTap,
      isHeader: true,
      semanticLabel: 'Item ${widget.index + 1} of ${widget.totalCount}',
      semanticHint: widget.isExpanded ? 'Collapse' : 'Expand',
      isExpanded: widget.isExpanded,
      tooltip: headerTooltip,
      focusNode: onTap != null ? _toggleFocusNode : null,
      child: headerContent,
    );
  }

  Widget _buildIcon(
    M3EExpandableStyle d,
    double progress,
    VoidCallback onToggle,
  ) {
    if (d.expandIcon == null && d.collapseIcon == null) {
      return const SizedBox.shrink();
    }

    final bool isExpanded = progress >= 0.5;
    final Widget? icon = isExpanded ? d.collapseIcon : d.expandIcon;

    if (icon == null) {
      return const SizedBox.shrink();
    }

    final double angle = d.iconRotationAngle * progress;

    final String? tooltip = d.tapIconToToggle
        ? (isExpanded ? d.collapseTooltip : d.expandTooltip)
        : null;

    Widget iconWidget = Padding(
      padding: d.iconPadding,
      child: Transform.rotate(angle: angle, child: icon),
    );

    if (d.tapIconToToggle) {
      iconWidget = _buildInteractionWrapper(
        d,
        onTap: onToggle,
        isHeader: true,
        isIcon: true,
        semanticLabel: isExpanded ? 'Collapse button' : 'Expand button',
        isExpanded: isExpanded,
        tooltip: tooltip,
        child: iconWidget,
      );
    } else {
      iconWidget = ExcludeSemantics(child: iconWidget);
    }

    return iconWidget;
  }
}
