import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/actor_field.dart';
import 'package:moneymoneymoney/placeholder/placeholder_box_painter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
  );

  testWidgets('paints one box per actor', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is PlaceholderBoxPainter);
    expect(painters.length, ActorCatalog.animals.length);
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));
    expect(
      find.descendant(
        of: find.byType(ActorField),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('actors move as time advances', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));

    PlaceholderBoxPainter first() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<PlaceholderBoxPainter>()
        .first;

    final before = first().position;
    await tester.pump(const Duration(seconds: 2));
    expect(first().position, isNot(before));
  });
}