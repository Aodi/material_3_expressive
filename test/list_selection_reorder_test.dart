import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'list-owned selection fills and supports single-select',
    _listOwnedSelection,
  );
  testWidgets(
    'list prefers ancestor M3ESelectionScope controller',
    _listPrefersAncestorScope,
  );
  testWidgets('card list onReorder fires after drop', _cardListReorder);
  testWidgets('expandable sublist appears when expanded', _expandableSublist);
  testWidgets(
    'single tap is not delayed by double-tap trigger',
    _tapNotDelayed,
  );
  testWidgets(
    'dismissible list selection fill and double-tap',
    _dismissibleSelection,
  );
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    M3EMaterialApp(
      data: M3EThemeData.light(seedColor: const Color(0xFF6750A4)),
      home: Scaffold(body: home),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _rowColor(WidgetTester tester, String headline) {
  final Finder card = find.ancestor(
    of: find.text(headline),
    matching: find.byType(M3ECard),
  );
  return tester.widget<M3ECard>(card.first).color;
}

Future<void> _listOwnedSelection(WidgetTester tester) async {
  Set<int>? last;
  await _pump(
    tester,
    M3ECardList(
      selection: true,
      selectionState: const M3EListSelectionState(
        mode: M3EListSelectionMode.single,
        selectedIcon: Icon(M3EIcons.check_circle),
      ),
      onSelectionChanged: (Set<int> s) => last = s,
      itemCount: 3,
      itemBuilder: (BuildContext context, int index) => M3EListItem(
        headline: 'Item $index',
        leading: const Icon(M3EIcons.inbox),
      ),
    ),
  );

  expect(find.byType(M3ESelectionFlip), findsNWidgets(3));
  await tester.tap(find.byType(M3ESelectionFlip).at(1));
  await tester.pumpAndSettle();
  expect(last, <int>{1});

  final M3EColorScheme scheme = M3EThemeData.light(
    seedColor: const Color(0xFF6750A4),
  ).colorScheme;
  expect(_rowColor(tester, 'Item 1'), scheme.secondaryContainer);

  await tester.tap(find.text('Item 0'));
  await tester.pumpAndSettle();
  expect(last, <int>{0});
  expect(_rowColor(tester, 'Item 0'), scheme.secondaryContainer);
  expect(_rowColor(tester, 'Item 1'), isNot(scheme.secondaryContainer));
}

Future<void> _listPrefersAncestorScope(WidgetTester tester) async {
  final M3ESelectionController controller = M3ESelectionController()..select(2);
  addTearDown(controller.dispose);

  await _pump(
    tester,
    M3ESelection(
      controller: controller,
      itemCount: 3,
      appBar: const M3ESelectionAppBar(idle: SizedBox(height: 32)),
      body: M3ECardList(
        selection: true,
        itemCount: 3,
        itemBuilder: (BuildContext context, int index) =>
            M3EListItem(headline: 'Row $index'),
      ),
    ),
  );

  final M3EColorScheme scheme = M3EThemeData.light(
    seedColor: const Color(0xFF6750A4),
  ).colorScheme;
  expect(_rowColor(tester, 'Row 2'), scheme.secondaryContainer);
  expect(controller.isSelected(2), isTrue);
  // No selectedIcon → no flip widgets.
  expect(find.byType(M3ESelectionFlip), findsNothing);
}

Future<void> _cardListReorder(WidgetTester tester) async {
  final List<String> items = <String>['A', 'B', 'C'];
  await _pump(
    tester,
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return M3ECardList(
          reorder: true,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              final String item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            });
          },
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) => M3EListItem(
            headline: items[index],
            trailing: const Icon(M3EIcons.chevron_right),
          ),
        );
      },
    ),
  );

  // Drag handle replaces trailing chevron.
  expect(find.byIcon(M3EIcons.drag_handle), findsNWidgets(3));
  expect(find.byIcon(M3EIcons.chevron_right), findsNothing);

  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.text('A')),
  );
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  await gesture.moveBy(const Offset(0, 140));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();

  expect(items.first, isNot('A'));
  expect(find.text('A'), findsOneWidget);
  expect(find.text('B'), findsOneWidget);
  expect(find.text('C'), findsOneWidget);
}

Future<void> _expandableSublist(WidgetTester tester) async {
  await _pump(
    tester,
    M3EExpandableList(
      data: <M3EExpandableData>[
        M3EExpandableData(
          title: 'Parent',
          subtitle: 'Tap to expand',
          expanded: M3EExpandableExpanded.list(
            M3ECardList(
              embedded: true,
              itemCount: 2,
              itemBuilder: (BuildContext context, int index) {
                return M3EListItem(headline: 'Child ${index + 1}');
              },
            ),
          ),
        ),
      ],
    ),
  );

  expect(find.text('Child 1'), findsNothing);
  await tester.tap(find.text('Parent'));
  await tester.pumpAndSettle();
  expect(find.text('Child 1'), findsOneWidget);
  expect(find.text('Child 2'), findsOneWidget);
}

Future<void> _tapNotDelayed(WidgetTester tester) async {
  final List<int> taps = <int>[];
  await _pump(
    tester,
    M3ECardList(
      selection: true,
      selectionState: const M3EListSelectionState(
        trigger: M3EListSelectionTrigger.doubleTap,
      ),
      onTap: taps.add,
      itemCount: 1,
      itemBuilder: (BuildContext context, int index) =>
          const M3EListItem(headline: 'Tap me'),
    ),
  );

  await tester.tap(find.text('Tap me'));
  // Immediate — no need to wait past double-tap timeout.
  await tester.pump();
  expect(taps, <int>[0]);
}

Future<void> _dismissibleSelection(WidgetTester tester) async {
  Set<int>? last;
  await _pump(
    tester,
    M3EDismissibleColumn(
      selection: true,
      selectionState: const M3EListSelectionState(
        mode: M3EListSelectionMode.single,
        selectedIcon: Icon(M3EIcons.check_circle),
      ),
      onSelectionChanged: (Set<int> s) => last = s,
      itemCount: 2,
      onDismiss: (int index, DismissDirection direction) async => false,
      itemBuilder: (BuildContext context, int index) {
        return M3EListItem(
          headline: 'Row $index',
          leading: const Icon(M3EIcons.schedule),
        );
      },
    ),
  );

  expect(find.byType(M3ESelectionFlip), findsNWidgets(2));
  await tester.tap(find.byType(M3ESelectionFlip).at(0));
  await tester.pumpAndSettle();
  expect(last, <int>{0});

  final M3EColorScheme scheme = M3EThemeData.light(
    seedColor: const Color(0xFF6750A4),
  ).colorScheme;
  expect(_rowColor(tester, 'Row 0'), scheme.secondaryContainer);

  // Equal outer corners when selected (same as card list).
  final Finder card = find.ancestor(
    of: find.text('Row 0'),
    matching: find.byType(M3ECard),
  );
  final BorderRadius? radius = tester.widget<M3ECard>(card.first).borderRadius;
  expect(radius?.topLeft, radius?.bottomLeft);
  expect(radius?.topLeft, radius?.topRight);

  // Double-tap trigger on second row.
  await tester.pumpWidget(
    M3EMaterialApp(
      data: M3EThemeData.light(seedColor: const Color(0xFF6750A4)),
      home: Scaffold(
        body: M3EDismissibleColumn(
          selection: true,
          selectionState: const M3EListSelectionState(
            trigger: M3EListSelectionTrigger.doubleTap,
          ),
          onSelectionChanged: (Set<int> s) => last = s,
          itemCount: 1,
          onDismiss: (int index, DismissDirection direction) async => false,
          itemBuilder: (BuildContext context, int index) {
            return const M3EListItem(headline: 'Double');
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  last = null;
  await tester.tap(find.text('Double'));
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tap(find.text('Double'));
  await tester.pumpAndSettle();
  expect(last, <int>{0});
}
