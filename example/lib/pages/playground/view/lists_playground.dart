import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../widgets/playground/control_panel.dart';
import '../../../widgets/playground/controls/play_enum_menu.dart';
import '../../../widgets/playground/controls/play_switch.dart';
import '../../../widgets/playground/controls/play_text_field.dart';
import '../../../widgets/playground/play_preview_card.dart';
import '../../../widgets/playground/playground_body.dart';

enum _ListKind { item, cardList, dismissible, expandable }

/// Live playground for list components.
class ListsPlayground extends StatefulWidget {
  /// Creates the lists playground.
  const ListsPlayground({super.key});

  @override
  State<ListsPlayground> createState() => _ListsPlaygroundState();
}

class _ListsPlaygroundState extends State<ListsPlayground> {
  _ListKind _kind = _ListKind.item;
  M3ECardVariant _variant = M3ECardVariant.outlined;
  bool _showLeading = true;
  bool _showTrailing = true;
  bool _selection = false;
  bool _nestedSelection = false;
  bool _reorder = false;
  bool _singleSelect = false;
  bool _doubleTapTrigger = false;
  bool _useSublist = true;
  bool _showSelectedIcon = true;
  String _headline = 'Wireless charging';
  String _supporting = 'On · Fast charge enabled';
  List<String> _order = <String>['0', '1', '2'];

  M3EListSelectionState get _selectionState => M3EListSelectionState(
    mode: _singleSelect
        ? M3EListSelectionMode.single
        : M3EListSelectionMode.multiple,
    selectedIcon: _showSelectedIcon ? const Icon(M3EIcons.check_circle) : null,
    trigger: _doubleTapTrigger
        ? M3EListSelectionTrigger.doubleTap
        : M3EListSelectionTrigger.icon,
  );

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final String item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
  }

  List<PlaySnippet> get _snippets {
    final String headline = playDartString(_headline);
    final String supporting = playDartString(_supporting);
    final String selectionFeature = _selection ? '\n  selection: true,' : '';
    final String features =
        '$selectionFeature${_reorder ? '\n  reorder: true,\n  onReorder: (int a, int b) {},' : ''}';
    final String sample = switch (_kind) {
      _ListKind.item =>
        '''
M3EListItem(
  headline: $headline,
  supportingText: $supporting,${_showLeading ? '\n  leading: const Icon(M3EIcons.schedule),' : ''}${_showTrailing ? '\n  trailing: const Icon(M3EIcons.chevron_right),' : ''}
  onTap: () {},
);''',
      _ListKind.cardList =>
        '''
M3ECardList(
  variant: M3ECardVariant.${_variant.name},$features
  itemCount: 3,
  itemBuilder: (BuildContext context, int index) {
    return M3EListItem(
      headline: $headline,
      supportingText: $supporting,${_showLeading ? '\n      leading: const Icon(M3EIcons.inbox),' : ''}${_showTrailing ? '\n      trailing: const Icon(M3EIcons.chevron_right),' : ''}
    );
  },
);''',
      _ListKind.dismissible =>
        '''
M3EDismissibleColumn(
  itemCount: 3,$selectionFeature
  onDismiss: (int index, DismissDirection direction) async => true,
  itemBuilder: (BuildContext context, int index) {
    return M3EListItem(
      headline: $headline,${_showLeading ? '\n      leading: const Icon(M3EIcons.schedule),' : ''}
    );
  },
);''',
      _ListKind.expandable =>
        '''
M3EExpandableList(${_selection ? '\n  selection: true,' : ''}${_reorder ? '\n  reorder: true,\n  onReorder: (int a, int b) {},' : ''}
  data: <M3EExpandableData>[
    M3EExpandableData(
      title: $headline,
      subtitle: $supporting,${_showLeading ? '\n      leading: const Icon(M3EIcons.battery_alert),' : ''}
      expanded: ${_useSublist ? '''M3EExpandableExpanded.list(
        M3ECardList(
          embedded: true,
          itemCount: 2,${_nestedSelection ? '\n          selection: true,' : ''}
          itemBuilder: (BuildContext context, int index) {
            return M3EListItem(headline: 'Child \${index + 1}');
          },
        ),
      ),''' : '''M3EExpandableExpanded.content(
        const Text('Expanded body'),
      ),'''}
    ),
  ],
);''',
    };
    return <PlaySnippet>[
      PlaySnippet(label: 'List', code: '$kPlaySnippetImport\n$sample'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundBody(
      previews: <Widget>[
        PlayPreviewCard(
          label: 'List',
          child: switch (_kind) {
            _ListKind.item => _ItemPreview(
              headline: _headline,
              supporting: _supporting,
              showLeading: _showLeading,
              showTrailing: _showTrailing,
            ),
            _ListKind.cardList => _CardListPreview(
              headline: _headline,
              supporting: _supporting,
              variant: _variant,
              showLeading: _showLeading,
              showTrailing: _showTrailing,
              selection: _selection,
              reorder: _reorder,
              selectionState: _selectionState,
              order: _order,
              onReorder: _onReorder,
            ),
            _ListKind.dismissible => _DismissiblePreview(
              headline: _headline,
              showLeading: _showLeading,
              selection: _selection,
              selectionState: _selectionState,
              order: _order,
            ),
            _ListKind.expandable => _ExpandablePreview(
              headline: _headline,
              supporting: _supporting,
              showLeading: _showLeading,
              useSublist: _useSublist,
              selection: _selection,
              nestedSelection: _nestedSelection,
              reorder: _reorder,
              selectionState: _selectionState,
              order: _order,
              onReorder: _onReorder,
              nestedOrder: _order,
            ),
          },
        ),
      ],
      snippets: _snippets,
      controls: <Widget>[
        PlayControlPanel(
          title: 'Content',
          children: <Widget>[
            PlayEnumMenu<_ListKind>(
              label: 'Kind',
              value: _kind,
              values: _ListKind.values,
              labelOf: (_ListKind v) => v.name,
              onChanged: (_ListKind v) => setState(() => _kind = v),
            ),
            if (_kind == _ListKind.cardList)
              PlayEnumMenu<M3ECardVariant>(
                label: 'Card variant',
                value: _variant,
                values: M3ECardVariant.values,
                labelOf: (M3ECardVariant v) => v.name,
                onChanged: (M3ECardVariant v) {
                  setState(() => _variant = v);
                },
              ),
            PlayTextField(
              label: 'Headline',
              value: _headline,
              onChanged: (String v) => setState(() => _headline = v),
            ),
            PlayTextField(
              label: 'Supporting',
              value: _supporting,
              onChanged: (String v) => setState(() => _supporting = v),
            ),
            PlaySwitch(
              label: 'Leading',
              value: _showLeading,
              onChanged: (bool v) => setState(() => _showLeading = v),
            ),
            PlaySwitch(
              label: 'Trailing',
              value: _showTrailing,
              onChanged: (bool v) => setState(() => _showTrailing = v),
            ),
            if (_kind == _ListKind.expandable)
              PlaySwitch(
                label: 'List expansion',
                value: _useSublist,
                onChanged: (bool v) => setState(() => _useSublist = v),
              ),
          ],
        ),
        if (_kind == _ListKind.expandable)
          PlayControlPanel(
            title: 'Header selection & reorder',
            children: <Widget>[
              PlaySwitch(
                label: 'Selection',
                value: _selection,
                onChanged: (bool v) => setState(() => _selection = v),
              ),
              PlaySwitch(
                label: 'Reorder',
                value: _reorder,
                onChanged: (bool v) => setState(() => _reorder = v),
              ),
              if (_selection) ...<Widget>[
                PlaySwitch(
                  label: 'Single select',
                  value: _singleSelect,
                  onChanged: (bool v) => setState(() => _singleSelect = v),
                ),
                PlaySwitch(
                  label: 'Selected icon (leading flip)',
                  value: _showSelectedIcon,
                  onChanged: (bool v) {
                    setState(() => _showSelectedIcon = v);
                  },
                ),
                PlaySwitch(
                  label: 'Double-tap trigger',
                  value: _doubleTapTrigger,
                  onChanged: (bool v) {
                    setState(() => _doubleTapTrigger = v);
                  },
                ),
              ],
            ],
          ),
        if (_kind == _ListKind.cardList ||
            _kind == _ListKind.dismissible ||
            (_kind == _ListKind.expandable && _useSublist))
          PlayControlPanel(
            title: _kind == _ListKind.expandable
                ? 'Sublist selection'
                : (_kind == _ListKind.dismissible
                      ? 'Selection'
                      : 'Selection & reorder'),
            children: <Widget>[
              PlaySwitch(
                label: 'Selection',
                value: _kind == _ListKind.expandable
                    ? _nestedSelection
                    : _selection,
                onChanged: (bool v) => setState(() {
                  if (_kind == _ListKind.expandable) {
                    _nestedSelection = v;
                  } else {
                    _selection = v;
                  }
                }),
              ),
              if (_kind == _ListKind.cardList)
                PlaySwitch(
                  label: 'Reorder',
                  value: _reorder,
                  onChanged: (bool v) => setState(() => _reorder = v),
                ),
              if ((_kind == _ListKind.expandable
                      ? _nestedSelection
                      : _selection) &&
                  _kind != _ListKind.expandable) ...<Widget>[
                PlaySwitch(
                  label: 'Single select',
                  value: _singleSelect,
                  onChanged: (bool v) => setState(() => _singleSelect = v),
                ),
                PlaySwitch(
                  label: 'Selected icon (leading flip)',
                  value: _showSelectedIcon,
                  onChanged: (bool v) {
                    setState(() => _showSelectedIcon = v);
                  },
                ),
                PlaySwitch(
                  label: 'Double-tap trigger',
                  value: _doubleTapTrigger,
                  onChanged: (bool v) {
                    setState(() => _doubleTapTrigger = v);
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({
    required this.headline,
    required this.supporting,
    required this.showLeading,
    required this.showTrailing,
  });

  final String headline;
  final String supporting;
  final bool showLeading;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return M3EListItem(
      headline: headline,
      supportingText: supporting,
      leading: showLeading ? const Icon(M3EIcons.schedule) : null,
      trailing: showTrailing ? const Icon(M3EIcons.chevron_right) : null,
      onTap: () {},
    );
  }
}

class _CardListPreview extends StatelessWidget {
  const _CardListPreview({
    required this.headline,
    required this.supporting,
    required this.variant,
    required this.showLeading,
    required this.showTrailing,
    required this.selection,
    required this.reorder,
    required this.selectionState,
    required this.order,
    required this.onReorder,
  });

  final String headline;
  final String supporting;
  final M3ECardVariant variant;
  final bool showLeading;
  final bool showTrailing;
  final bool selection;
  final bool reorder;
  final M3EListSelectionState selectionState;
  final List<String> order;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return M3ECardList(
      variant: variant,
      selection: selection,
      reorder: reorder,
      selectionState: selectionState,
      onReorder: reorder ? onReorder : null,
      itemCount: order.length,
      itemBuilder: (BuildContext context, int index) {
        final String id = order[index];
        return M3EListItem(
          headline: '$headline $id',
          supportingText: supporting,
          leading: showLeading ? const Icon(M3EIcons.inbox) : null,
          trailing: showTrailing ? const Icon(M3EIcons.chevron_right) : null,
        );
      },
    );
  }
}

class _DismissiblePreview extends StatelessWidget {
  const _DismissiblePreview({
    required this.headline,
    required this.showLeading,
    required this.selection,
    required this.selectionState,
    required this.order,
  });

  final String headline;
  final bool showLeading;
  final bool selection;
  final M3EListSelectionState selectionState;
  final List<String> order;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return M3EDismissibleColumn(
      selection: selection,
      selectionState: selectionState,
      itemCount: order.length,
      onDismiss: (int index, DismissDirection direction) async => true,
      style: M3EDismissibleListStyle(
        background: ColoredBox(
          color: theme.colorScheme.success,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(M3EIcons.check),
            ),
          ),
        ),
        secondaryBackground: ColoredBox(
          color: theme.colorScheme.danger,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(M3EIcons.close),
            ),
          ),
        ),
      ),
      itemBuilder: (BuildContext context, int index) {
        return M3EListItem(
          headline: '$headline ${order[index]}',
          supportingText: 'Swipe to dismiss',
          leading: showLeading ? const Icon(M3EIcons.schedule) : null,
        );
      },
    );
  }
}

class _ExpandablePreview extends StatelessWidget {
  const _ExpandablePreview({
    required this.headline,
    required this.supporting,
    required this.showLeading,
    required this.useSublist,
    required this.selection,
    required this.nestedSelection,
    required this.reorder,
    required this.selectionState,
    required this.order,
    required this.onReorder,
    required this.nestedOrder,
  });

  final String headline;
  final String supporting;
  final bool showLeading;
  final bool useSublist;
  final bool selection;
  final bool nestedSelection;
  final bool reorder;
  final M3EListSelectionState selectionState;
  final List<String> order;
  final ReorderCallback onReorder;
  final List<String> nestedOrder;

  M3EExpandableData _section(BuildContext context, String id) {
    final M3EThemeData theme = M3ETheme.of(context);
    final bool isPrimary = id == '0';
    return M3EExpandableData(
      title: isPrimary ? headline : 'System update $id',
      subtitle: isPrimary ? supporting : 'Version 2.4.0 is ready',
      leading: showLeading
          ? Icon(isPrimary ? M3EIcons.battery_alert : M3EIcons.system_update)
          : null,
      expanded: useSublist && isPrimary
          ? M3EExpandableExpanded.list(
              M3ECardList(
                embedded: true,
                selection: nestedSelection,
                selectionState: selectionState,
                itemCount: nestedOrder.length,
                itemBuilder: (BuildContext context, int index) {
                  final String nestedId = nestedOrder[index];
                  return M3EListItem(
                    headline: 'Nested $nestedId',
                    supportingText: 'Sublist row',
                    leading: const Icon(M3EIcons.folder),
                  );
                },
              ),
            )
          : M3EExpandableExpanded.content(
              isPrimary
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Expanded body content for the list item.',
                          style: theme.typeScale.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        M3EButton(
                          style: M3EButtonStyle.tonal,
                          onPressed: () {},
                          child: const Text('Action'),
                        ),
                      ],
                    )
                  : Text(
                      'Security fixes and performance improvements.',
                      style: theme.typeScale.bodyMedium,
                    ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return M3EExpandableList(
      initiallyExpanded: const <int>{0},
      selection: selection,
      selectionState: selectionState,
      reorder: reorder,
      onReorder: reorder ? onReorder : null,
      data: <M3EExpandableData>[
        for (final String id in order) _section(context, id),
      ],
    );
  }
}
