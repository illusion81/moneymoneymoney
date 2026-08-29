import 'package:flutter/material.dart';

import '../widgets/primitives/market_art_tile.dart';

/// The five Market tabs (design.md §Market / README "Market").
enum MarketTab {
  boosts('Boosts'),
  looks('Looks'),
  dreams('Dreams'),
  rewards('Rewards'),
  honey('Honey');

  const MarketTab(this.label);

  /// Tab chip label shown in the Market screen.
  final String label;
}

/// A daily check-in task (design.md §Hive "Check-ins").
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.sub,
    required this.reward,
    this.done = false,
  });

  final String id;
  final String title;
  final String sub;

  /// Honey earned on completion (positive number).
  final int reward;
  final bool done;

  Task copyWith({bool? done}) => Task(
        id: id,
        title: title,
        sub: sub,
        reward: reward,
        done: done ?? this.done,
      );
}

/// One catalogue row in the Market screen (design.md §Market).
class MarketItem {
  const MarketItem({
    required this.id,
    required this.title,
    required this.description,
    required this.tab,
    required this.art,
    this.honeyCost,
    this.moneyCost,
    this.isDream = false,
    this.tag,
    this.owned = false,
    this.beeSkinId,
  });

  final String id;
  final String title;
  final String description;
  final MarketTab tab;

  /// Honey price — set for Boosts, Looks and Rewards items.
  final int? honeyCost;

  /// Real-money price in dollars — set for Honey items only.
  final double? moneyCost;

  /// True for Dreams items: free to start, no cost, button reads "Start".
  final bool isDream;

  /// Optional tag chip: 'POPULAR' | 'NEW' | 'BEST'.
  final String? tag;

  /// The 46×53 hex-clipped art tile (gradient + shapes).
  final ArtTile art;

  final bool owned;

  /// When set, purchasing this item applies the matching [BeeSkin] to the
  /// swarm + queen (a purchasable bee skin in the Looks tab).
  final String? beeSkinId;
}

/// Comb badge categories (design.md §Comb — category colour map).
enum BadgeCategory { saving, debt, habit, hive }

/// One unlocked/locked cell in the Comb honeycomb (design.md §Comb).
class Badge {
  const Badge({
    required this.id,
    required this.label,
    required this.glyph,
    required this.category,
    required this.unlocked,
  });

  final String id;
  final String label;

  /// Single character (or short run) rendered in JetBrains Mono 700.
  final String glyph;
  final BadgeCategory category;
  final bool unlocked;
}

/// A hive-mate in the Hive-mates screen (design.md §Hive-mates).
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.honey,
    required this.streak,
    required this.status,
    this.isYou = false,
  });

  final String id;
  final String name;
  final int honey;

  /// Current streak in days.
  final int streak;

  /// Status line under the name, e.g. "31 days of one-liners · 2,480 honey".
  final String status;

  /// True for the signed-in user's own row.
  final bool isYou;
}

/// One "What the hive suggests" card (design.md §Report).
class Suggestion {
  const Suggestion({
    required this.id,
    required this.body,
    required this.source,
    required this.taskTitle,
    required this.taskSub,
    required this.taskReward,
  });

  final String id;
  final String body;

  /// Source line, e.g. "from 12 check-ins + Chase".
  final String source;
  final String taskTitle;
  final String taskSub;
  final int taskReward;
}

/// A bee "skin": the palette used to paint the wandering swarm bees and the
/// queen bee. `body`/`stripe`/`wing` colour the inbound bees, the `out*`
/// variants colour the outbound bees (design.md §1.1 `Bee literals`).
class BeeSkin {
  const BeeSkin({
    required this.id,
    required this.label,
    required this.body,
    required this.stripe,
    required this.wing,
    required this.outBody,
    required this.outStripe,
    required this.outWing,
  });

  final String id;
  final String label;

  /// Inbound-bee body colour.
  final Color body;

  /// Inbound-bee stripe colour.
  final Color stripe;

  /// Inbound-bee wing colour.
  final Color wing;

  /// Outbound-bee body colour.
  final Color outBody;

  /// Outbound-bee stripe colour.
  final Color outStripe;

  /// Outbound-bee wing colour.
  final Color outWing;
}
