import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/api_client.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/screens/circle_screen.dart';

class _FakeApiClient extends ApiClient {
  @override
  Future<Circle> leaderboard() async => const Circle(
    code: 'SAVE',
    name: 'Money mates',
    memberCount: 2,
    headline: 'Everyone is close this week.',
    entries: [
      LeaderboardEntry(
        rank: 1,
        displayName: 'You',
        isYou: true,
        adherence: 0.92,
        level: 4,
        towerStage: 2,
        streakDays: 8,
        trend: 'up',
      ),
    ],
  );

  @override
  Future<void> cheer(String toName, {String message = 'Keep going'}) async {}
}

void main() {
  testWidgets(
    'circle frames the leaderboard as daily saving and streak competition',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CircleScreen(api: _FakeApiClient())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily saving race'), findsOneWidget);
      expect(find.textContaining('streak battle'), findsOneWidget);
      expect(find.text('daily saved'), findsOneWidget);
      expect(find.textContaining('8d streak'), findsOneWidget);
    },
  );
}
