import 'package:capitals/ui/components/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'When light mode and toggle button then'
      ' and callback is called', (widgetTester) async {
    var counter = 0;

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemeSwitch(
            isDark: false,
            onToggle: () => counter++,
          ),
        ),
      ),
    );

    final button = find.byType(IconButton);

    expect(button, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && Icons.nightlight_round == widget.icon,
      ),
      findsOneWidget,
    );
    expect(counter, 0);

    await widgetTester.tap(button);
    await widgetTester.pumpAndSettle();

    expect(button, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && Icons.nightlight_round == widget.icon,
      ),
      findsOneWidget,
    );
    expect(counter, 1);
  });

  testWidgets(
      'When dark mode and toggle button then'
      ' and callback is called', (widgetTester) async {
    var counter = 0;

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemeSwitch(
            isDark: true,
            onToggle: () => counter++,
          ),
        ),
      ),
    );

    final button = find.byType(IconButton);

    expect(button, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && Icons.wb_sunny_outlined == widget.icon,
      ),
      findsOneWidget,
    );
    expect(counter, 0);

    await widgetTester.tap(button);
    await widgetTester.pumpAndSettle();

    expect(button, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && Icons.wb_sunny_outlined == widget.icon,
      ),
      findsOneWidget,
    );
    expect(counter, 1);
  });
}
