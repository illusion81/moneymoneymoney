import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/actor_field.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';
import 'package:moneymoneymoney/placeholder/placeholder_box_painter.dart';
import 'package:moneymoneymoney/sprites/sprite_cache.dart';
import 'package:moneymoneymoney/sprites/sprite_painter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
  );

  Future<ui.Image> stubImage() {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 32, 32),
      Paint()..color = const Color(0xffff0000),
    );
    return recorder.endRecording().toImage(32, 32);
  }

  // A few animals is enough; the full 25 only makes the tests slower.
  List<PlaceholderActor> someAnimals() => ActorCatalog.animals.take(4).toList();

  setUp(SpriteCache.instance.clear);
  tearDown(SpriteCache.instance.clear);

  testWidgets('paints one box per actor', (tester) async {
    final actors = someAnimals();
    await tester.pumpWidget(host(ActorField(actors: actors)));
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is PlaceholderBoxPainter);
    expect(painters.length, actors.length);
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: someAnimals())));
    expect(
      find.descendant(
        of: find.byType(ActorField),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('actors move as time advances', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: someAnimals())));

    // Pumping a real duration gives the preload a chance to finish, so the
    // first actor may be drawn by either painter. Movement is what matters.
    Offset firstPosition() {
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere(
            (p) => p is PlaceholderBoxPainter || p is SpriteActorPainter,
          );
      return switch (painter) {
        PlaceholderBoxPainter(:final position) => position,
        SpriteActorPainter(:final position) => position,
        _ => throw StateError('no actor painter'),
      };
    }

    final before = firstPosition();
    await tester.pump(const Duration(seconds: 2));
    expect(firstPosition(), isNot(before));
  });

  testWidgets('draws sprites once their images are cached', (tester) async {
    final image = await stubImage();
    final actors = ActorCatalog.animals.take(3).toList();
    for (final actor in actors) {
      SpriteCache.instance.put(actor.sprite!.assetPath, image);
    }

    await tester.pumpWidget(host(ActorField(actors: actors)));

    final sprites = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is SpriteActorPainter);
    expect(sprites, hasLength(3));
  });

  testWidgets('falls back to a box while a sprite is still decoding', (
    tester,
  ) async {
    final actors = ActorCatalog.animals.take(2).toList();
    await tester.pumpWidget(host(ActorField(actors: actors)));

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter);
    expect(painters.whereType<PlaceholderBoxPainter>(), hasLength(2));
    expect(painters.whereType<SpriteActorPainter>(), isEmpty);
  });

  testWidgets('an actor with no sprite always uses a box', (tester) async {
    const bare = PlaceholderActor(
      id: 'bare',
      label: 'BARE',
      color: Color(0xff333333),
      size: Size(40, 40),
      kind: ActorKind.animal,
    );
    await tester.pumpWidget(
      host(const ActorField(actors: <PlaceholderActor>[bare])),
    );

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter);
    expect(painters.whereType<PlaceholderBoxPainter>(), hasLength(1));
  });
}
