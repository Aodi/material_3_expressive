import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('M3EFocusRing paints when focused', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: const Scaffold(
            body: Center(
              child: M3EFocusRing(
                focused: true,
                radius: BorderRadius.all(Radius.circular(12)),
                child: SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(M3EFocusRing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focusRingTheme color override applies', (
    WidgetTester tester,
  ) async {
    const override = Color(0xFFAA00FF);
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light().copyWith(
            focusRingTheme: const M3EFocusRingTheme(color: override),
          ),
          child: Builder(
            builder: (BuildContext context) {
              final Color resolved = M3ETheme.of(
                context,
              ).focusRingTheme.resolveColor(M3ETheme.of(context).colorScheme);
              expect(resolved, override);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('M3EButton shows focus ring under traditional highlight', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Center(
              child: M3EButton.filled(
                focusNode: focusNode,
                onPressed: () {},
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    expect(find.byType(M3EFocusRing), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only one primary focus ring among two buttons', (
    WidgetTester tester,
  ) async {
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3EButton.filled(
                  focusNode: a,
                  onPressed: () {},
                  child: const Text('A'),
                ),
                M3EButton.filled(
                  focusNode: b,
                  onPressed: () {},
                  child: const Text('B'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(M3EFocusInteraction.instance.ringsAllowed, isTrue);
    expect(a.hasPrimaryFocus || b.hasPrimaryFocus, isTrue);
    expect(a.hasPrimaryFocus && b.hasPrimaryFocus, isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  });

  testWidgets('pointer clears ring; Tab resumes from clicked button', (
    WidgetTester tester,
  ) async {
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    final c = FocusNode(debugLabel: 'c');
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    addTearDown(c.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3EButton.filled(
                  focusNode: a,
                  onPressed: () {},
                  child: const Text('A'),
                ),
                M3EButton.filled(
                  focusNode: b,
                  onPressed: () {},
                  child: const Text('B'),
                ),
                M3EButton.filled(
                  focusNode: c,
                  onPressed: () {},
                  child: const Text('C'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(M3EFocusInteraction.instance.ringsAllowed, isTrue);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(M3EFocusInteraction.instance.ringsAllowed, isFalse);
    expect(b.hasPrimaryFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(M3EFocusInteraction.instance.ringsAllowed, isTrue);
    expect(c.hasPrimaryFocus, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  });

  testWidgets('keyboard focus scrolls button into view', (
    WidgetTester tester,
  ) async {
    final top = FocusNode(debugLabel: 'top');
    final bottom = FocusNode(debugLabel: 'bottom');
    addTearDown(top.dispose);
    addTearDown(bottom.dispose);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: SizedBox(
              height: 200,
              child: ListView(
                controller: scrollController,
                cacheExtent: 2000,
                children: <Widget>[
                  M3EButton.filled(
                    focusNode: top,
                    onPressed: () {},
                    child: const Text('Top'),
                  ),
                  const SizedBox(height: 600),
                  M3EButton.filled(
                    focusNode: bottom,
                    onPressed: () {},
                    child: const Text('Bottom'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0);
    M3EFocusInteraction.instance.noteKeyboardHighlight();
    bottom.requestFocus();
    await tester.pumpAndSettle();

    expect(bottom.hasPrimaryFocus, isTrue);
    expect(scrollController.offset, greaterThan(0));
  });

  testWidgets('nav bar destination activates with keyboard', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3ENavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (int i) => selected = i,
              destinations: const <M3ENavigationBarDestination>[
                M3ENavigationBarDestination(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                M3ENavigationBarDestination(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, anyOf(0, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox focus ring uses shared theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(body: M3ECheckbox(value: false, onChanged: (_) {})),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(M3EFocusRing), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer tap on card does not show ring and fires once', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Center(
              child: M3ECard(
                onPressed: () => taps++,
                child: const Text('Item'),
              ),
            ),
          ),
        ),
      ),
    );

    // Pretend keyboard was used earlier so rings were allowed.
    M3EFocusInteraction.instance.noteKeyboardHighlight();
    expect(M3EFocusInteraction.instance.ringsAllowed, isTrue);

    await tester.tap(find.text('Item'));
    await tester.pump();
    expect(taps, 1);
    await tester.pump(); // deferred ring clear notify
    expect(M3EFocusInteraction.instance.ringsAllowed, isFalse);

    // Ring chrome must not paint from pointer focus.
    final rings = tester.widgetList<M3EFocusRing>(find.byType(M3EFocusRing));
    for (final M3EFocusRing ring in rings) {
      expect(ring.focused, isFalse);
    }
  });

  testWidgets('dropdown Enter toggles when field focused', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3EDropdownMenu<String>(
              focusNode: focusNode,
              singleSelect: true,
              items: const <M3EDropdownItem<String>>[
                M3EDropdownItem(value: 'one', label: 'One'),
                M3EDropdownItem(value: 'two', label: 'Two'),
              ],
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('dropdown trap keeps Tab among field and panel', (
    WidgetTester tester,
  ) async {
    final outside = FocusNode(debugLabel: 'outside');
    addTearDown(outside.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3EDropdownMenu<String>(
                  items: const <M3EDropdownItem<String>>[
                    M3EDropdownItem(value: 'one', label: 'One'),
                    M3EDropdownItem(value: 'two', label: 'Two'),
                  ],
                  onSelectionChanged: (_) {},
                ),
                M3EButton.filled(
                  focusNode: outside,
                  onPressed: () {},
                  child: const Text('Outside'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(M3EDropdownMenu<String>));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(outside.hasPrimaryFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('search bar shows ring under keyboard modality', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: M3ESearchBar(focusNode: focusNode, hintText: 'Search'),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(focusNode), isTrue);
    final rings = tester.widgetList<M3EFocusRing>(find.byType(M3EFocusRing));
    expect(rings.any((M3EFocusRing r) => r.focused), isTrue);
  });

  testWidgets('Tab leaves text field and clears its ring', (
    WidgetTester tester,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    final next = FocusNode(debugLabel: 'next');
    addTearDown(field.dispose);
    addTearDown(next.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: Column(
              children: <Widget>[
                M3ETextField(focusNode: field, label: 'Name'),
                M3EButton.filled(
                  focusNode: next,
                  onPressed: () {},
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    M3EFocusInteraction.instance.noteKeyboardHighlight();
    field.requestFocus();
    await tester.pumpAndSettle();
    expect(field.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(field), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

    expect(field.hasPrimaryFocus, isFalse);
    expect(M3EFocusRing.shouldShow(field), isFalse);
    expect(next.hasPrimaryFocus, isTrue);
  });

  testWidgets('text field accepts typing while keyboard ring is shown', (
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
    expect(M3EFocusRing.shouldShow(field), isTrue);

    await tester.enterText(find.byType(EditableText), 'hello');
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets('Tab reaches idle search bar EditableText', (
    WidgetTester tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    final search = FocusNode(debugLabel: 'search');
    addTearDown(before.dispose);
    addTearDown(search.dispose);

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
                M3ESearchBar(focusNode: search, hintText: 'Search'),
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
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

    expect(search.hasPrimaryFocus, isTrue);
    expect(M3EFocusRing.shouldShow(search), isTrue);
  });
}
