import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Regressions for keyboard Tab / focus-ring interaction bugs.
void main() {
  setUp(() {
    M3EFocusInteraction.resetForTest();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    M3EFocusInteraction.resetForTest();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }

  FocusScopeNode? findMenuScope() {
    FocusScopeNode? found;
    void walk(FocusNode node) {
      if (node is FocusScopeNode && node.debugLabel == 'M3EFabMenu') {
        found = node;
        return;
      }
      for (final FocusNode child in node.children) {
        walk(child);
        if (found != null) {
          return;
        }
      }
    }

    walk(FocusManager.instance.rootScope);
    return found;
  }

  testWidgets('FAB menu Tab visits every item (not FocusScope oscillation)', (
    WidgetTester tester,
  ) async {
    const labels = <String>['Image', 'Video', 'Audio', 'Document'];
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: M3EFabMenu(
                items: <M3EFabMenuItem>[
                  for (final label in labels)
                    M3EFabMenuItem(
                      icon: const Icon(Icons.add),
                      label: label,
                      onPressed: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(M3EFab));
    await tester.pumpAndSettle();
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }

    final FocusScopeNode menuScope = findMenuScope()!;
    final Set<FocusNode> itemNodes = menuScope.traversalDescendants
        .where((FocusNode n) => n.canRequestFocus && !n.skipTraversal)
        .toSet();
    expect(itemNodes, hasLength(labels.length));

    // Opening moves focus into the menu (scope skips parent Tab traversal).
    expect(
      itemNodes.contains(FocusManager.instance.primaryFocus),
      isTrue,
      reason: 'Open should focus a menu item, not the trigger FAB',
    );

    final visited = <FocusNode>{FocusManager.instance.primaryFocus!};
    for (var i = 0; i < labels.length + 1; i++) {
      await pumpTab(tester);
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      expect(
        primary?.debugLabel,
        isNot('M3EFabMenu'),
        reason: 'FocusScope must skipTraversal so Tab walks items',
      );
      expect(
        itemNodes.contains(primary),
        isTrue,
        reason: 'Tab should stay on menu item nodes, got $primary',
      );
      visited.add(primary!);
    }

    expect(
      visited,
      unorderedEquals(itemNodes),
      reason: 'Tab must reach every FAB menu item node',
    );
  });

  testWidgets('Search bar stays focused and editable after Tab shows ring', (
    WidgetTester tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    final search = FocusNode(debugLabel: 'search');
    final controller = TextEditingController();
    addTearDown(before.dispose);
    addTearDown(search.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: <Widget>[
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(0),
                    child: M3EButton.filled(
                      focusNode: before,
                      onPressed: () {},
                      child: const Text('Before'),
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: SizedBox(
                      width: 240,
                      child: M3ESearchBar(
                        focusNode: search,
                        controller: controller,
                        hintText: 'Search',
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: M3EButton.filled(
                      onPressed: () {},
                      child: const Text('After'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    before.requestFocus();
    await tester.pumpAndSettle();
    await pumpTab(tester);

    expect(search.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(search), isTrue);
    expect(
      tester.testTextInput.hasAnyClients,
      isTrue,
      reason: 'Search EditableText must keep a text-input client with ring on',
    );

    tester.testTextInput.enterText('query');
    await tester.pump();
    expect(controller.text, 'query');
    expect(search.hasPrimaryFocus, isTrue);
  });

  testWidgets('Text field keeps text-input client after Tab shows ring', (
    WidgetTester tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    final field = FocusNode(debugLabel: 'field');
    final controller = TextEditingController();
    addTearDown(before.dispose);
    addTearDown(field.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3EButton.filled(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before'),
                ),
                M3ETextField(
                  focusNode: field,
                  controller: controller,
                  label: 'Name',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    before.requestFocus();
    await tester.pumpAndSettle();
    await pumpTab(tester);

    expect(field.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(field), isTrue);
    expect(
      tester.testTextInput.hasAnyClients,
      isTrue,
      reason:
          'Focus ring must not remount EditableText (client was dropped before)',
    );

    tester.testTextInput.enterText('hi');
    await tester.pump();
    expect(controller.text, 'hi');
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets('M3EFocusRing focused toggle does not remount child Element', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EFocusRing(
              focused: false,
              radius: BorderRadius.circular(8),
              child: SizedBox(key: key, width: 40, height: 40),
            ),
          ),
        ),
      ),
    );
    final before = key.currentContext! as Element;

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EFocusRing(
              focused: true,
              radius: BorderRadius.circular(8),
              child: SizedBox(key: key, width: 40, height: 40),
            ),
          ),
        ),
      ),
    );
    final after = key.currentContext! as Element;
    expect(
      identical(before, after),
      isTrue,
      reason: 'Toggling focused must reuse the child Element',
    );
  });

  testWidgets('Escape unfocuses text field during keyboard ring', (
    WidgetTester tester,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3ETextField(focusNode: field, label: 'Name'),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    field.requestFocus();
    await tester.pumpAndSettle();
    expect(field.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(field), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);

    expect(field.hasPrimaryFocus, isFalse);
    expect(M3EFocusRing.shouldShow(field), isFalse);
  });

  testWidgets('FAB menu Escape closes open menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: M3EFabMenu(
                items: <M3EFabMenuItem>[
                  M3EFabMenuItem(
                    icon: const Icon(Icons.add),
                    label: 'Image',
                    onPressed: () {},
                  ),
                  M3EFabMenuItem(
                    icon: const Icon(Icons.add),
                    label: 'Video',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(M3EFab));
    await tester.pumpAndSettle();
    expect(find.text('Image'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);

    expect(find.text('Image'), findsNothing);
  });

  testWidgets('SearchAnchor.bar is a Tab stop with focus ring', (
    WidgetTester tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3EButton.filled(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before'),
                ),
                M3ESearchAnchor.bar(
                  searchController: M3ESearchController(),
                  suggestionsBuilder:
                      (
                        BuildContext context,
                        M3ESearchController controller,
                      ) async {
                        return const <Widget>[];
                      },
                  barHintText: 'Anchored search',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    before.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(before.hasPrimaryFocus, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'M3ESearchAnchorBar',
    );
    expect(
      M3EFocusRing.shouldShow(FocusManager.instance.primaryFocus!),
      isTrue,
    );
  });

  testWidgets('Dropdown chip and clear are Tab stops with rings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EDropdownMenu<String>(
              items: const <M3EDropdownItem<String>>[
                M3EDropdownItem(value: 'one', label: 'One', selected: true),
                M3EDropdownItem(value: 'two', label: 'Two', selected: true),
              ],
              showChipAnimation: true,
              fieldStyle: const M3EDropdownFieldStyle(showClearIcon: true),
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

    var ringStops = 0;
    for (var i = 0; i < 6; i++) {
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      if (primary != null &&
          primary.canRequestFocus &&
          M3EFocusRing.shouldShow(primary)) {
        ringStops++;
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    }

    expect(
      ringStops,
      greaterThanOrEqualTo(2),
      reason: 'Expected multiple field/chip/clear ring stops, got $ringStops',
    );
    expect(find.text('One'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });

  testWidgets('Enter on dropdown clear removes all selections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EDropdownMenu<String>(
              items: const <M3EDropdownItem<String>>[
                M3EDropdownItem(value: 'one', label: 'One', selected: true),
                M3EDropdownItem(value: 'two', label: 'Two', selected: true),
              ],
              showChipAnimation: true,
              fieldStyle: const M3EDropdownFieldStyle(showClearIcon: true),
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    M3EFocusInteraction.instance.noteKeyboardHighlight();

    var foundClear = false;
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      final Element iconEl = find.byIcon(Icons.clear).evaluate().first;
      final FocusableActionDetector? detector = iconEl
          .findAncestorWidgetOfExactType<FocusableActionDetector>();
      final FocusNode? node = detector?.focusNode;
      if (node != null && node.hasPrimaryFocus) {
        foundClear = true;
        break;
      }
    }
    expect(foundClear, isTrue, reason: 'Tab should reach the clear control');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);

    expect(find.text('One'), findsNothing);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('Enter on dropdown chip removes that selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EDropdownMenu<String>(
              items: const <M3EDropdownItem<String>>[
                M3EDropdownItem(value: 'one', label: 'One', selected: true),
                M3EDropdownItem(value: 'two', label: 'Two', selected: true),
              ],
              showChipAnimation: true,
              fieldStyle: const M3EDropdownFieldStyle(showClearIcon: true),
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    M3EFocusInteraction.instance.noteKeyboardHighlight();

    var foundChip = false;
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      final Element chipText = find.text('One').evaluate().first;
      final FocusableActionDetector? detector = chipText
          .findAncestorWidgetOfExactType<FocusableActionDetector>();
      final FocusNode? node = detector?.focusNode;
      if (node != null && node.hasPrimaryFocus) {
        foundChip = true;
        break;
      }
    }
    expect(foundChip, isTrue, reason: 'Tab should reach the One chip');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);

    expect(find.text('One'), findsNothing);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('Web-style ButtonActivateIntent activates focused button', (
    WidgetTester tester,
  ) async {
    var pressed = 0;
    final focusNode = FocusNode(debugLabel: 'btn');
    addTearDown(focusNode.dispose);

    // Mimic WidgetsApp web shortcuts: Enter → ButtonActivateIntent.
    await tester.pumpWidget(
      MaterialApp(
        shortcuts: <ShortcutActivator, Intent>{
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.enter):
              const ButtonActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.numpadEnter):
              const ButtonActivateIntent(),
        },
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EButton.filled(
              focusNode: focusNode,
              onPressed: () => pressed++,
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);

    expect(pressed, 1);
  });
}
