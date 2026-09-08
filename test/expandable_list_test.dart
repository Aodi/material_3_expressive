import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

final List<M3EExpandableData> _items = <M3EExpandableData>[
  M3EExpandableData(
    title: 'Battery level low',
    subtitle: 'Plug in your device.',
    expanded: M3EExpandableExpanded.content(
      const Text('Your battery is at 10%.'),
    ),
  ),
  M3EExpandableData(
    title: 'System update available',
    subtitle: 'Version 2.4.0 is ready.',
    expanded: M3EExpandableExpanded.content(
      const Text('This update includes security fixes.'),
    ),
  ),
];

Widget _host(Widget child) {
  return M3EMaterialApp(
    data: M3EThemeData.light(),
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: Center(child: SizedBox(width: 400, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('M3EExpandableList renders item titles', (tester) async {
    await tester.pumpWidget(_host(M3EExpandableList(data: _items)));

    expect(find.text('Battery level low'), findsOneWidget);
    expect(find.text('System update available'), findsOneWidget);
  });

  testWidgets('M3EExpandableList expands item and reports change', (
    tester,
  ) async {
    int? changedIndex;
    bool? changedExpanded;

    await tester.pumpWidget(
      _host(
        M3EExpandableList(
          data: _items,
          onExpansionChanged: (int index, {required bool isExpanded}) {
            changedIndex = index;
            changedExpanded = isExpanded;
          },
        ),
      ),
    );

    await tester.tap(find.text('Battery level low'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(changedIndex, 0);
    expect(changedExpanded, isTrue);
    expect(find.text('Your battery is at 10%.'), findsOneWidget);
  });

  testWidgets('M3EExpandableList single-expand collapses prior item', (
    tester,
  ) async {
    final expandedEvents = <int>[];

    await tester.pumpWidget(
      _host(
        M3EExpandableList(
          data: _items,
          allowMultipleExpanded: false,
          onExpansionChanged: (int index, {required bool isExpanded}) {
            if (isExpanded) {
              expandedEvents.add(index);
            }
          },
        ),
      ),
    );

    await tester.tap(find.text('Battery level low'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(expandedEvents, <int>[0]);

    await tester.tap(find.text('System update available'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(expandedEvents, <int>[0, 1]);
    expect(find.text('This update includes security fixes.'), findsOneWidget);
  });

  testWidgets('expanded sublist participates in Tab traversal after header', (
    WidgetTester tester,
  ) async {
    final List<String> taps = <String>[];
    await tester.pumpWidget(
      _host(
        M3EExpandableList(
          initiallyExpanded: const <int>{0},
          data: <M3EExpandableData>[
            M3EExpandableData(
              title: 'Parent',
              subtitle: 'Has nested rows',
              expanded: M3EExpandableExpanded.list(
                M3ECardList(
                  embedded: true,
                  itemCount: 2,
                  onTap: (int index) => taps.add('nested-$index'),
                  itemBuilder: (BuildContext context, int index) {
                    return M3EListItem(headline: 'Nested $index');
                  },
                ),
              ),
            ),
            M3EExpandableData(
              title: 'Next parent',
              subtitle: 'After sublist',
              expanded: M3EExpandableExpanded.content(const Text('Body')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;

    expect(find.text('Nested 0'), findsOneWidget);
    expect(find.text('Nested 1'), findsOneWidget);

    // Header, then nested rows (dropdown-style reading order).
    expect(primaryFocus?.nextFocus(), isTrue);
    await tester.pumpAndSettle();
    expect(
      primaryFocus?.context?.findAncestorWidgetOfExactType<M3ECardList>(),
      isNull,
    );

    expect(primaryFocus?.nextFocus(), isTrue);
    await tester.pumpAndSettle();
    expect(
      primaryFocus?.context?.findAncestorWidgetOfExactType<M3ECardList>(),
      isNotNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, <String>['nested-0']);

    expect(primaryFocus?.nextFocus(), isTrue);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, <String>['nested-0', 'nested-1']);
  });
}
