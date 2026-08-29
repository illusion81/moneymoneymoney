import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/primitives/market_art_tile.dart';

/// Palette literals used by the market art tiles. Every value is a design.md
/// token (§1.1 / §1.2); Looks schemes and the lavender pairing are the only
/// invented colours (design.md: Looks are re-theming colour schemes).
const Color _white = Color(0xFFFFFFFF);
const Color _ink = Color(0xFF33251A);
const Color _paper = Color(0xFFFFFCF3);
const Color _honey = Color(0xFFF5B322);
const Color _honeyLight = Color(0xFFFFD972);
const Color _honeyDeep = Color(0xFFE08C1B);
const Color _brownLight = Color(0xFF8B6039);
const Color _brownDeep = Color(0xFF553519);
const Color _teal = Color(0xFF5C8C86);
const Color _tealLight = Color(0xFF7FB0A8);
const Color _tealDeep = Color(0xFF3F6E68);
const Color _clay = Color(0xFFC4634C);
const Color _clayLight = Color(0xFFD98572);
const Color _clayDeep = Color(0xFFAE5641);
const Color _surfaceWarm = Color(0xFFF8F3E6);
const Color _lavender = Color(0xFFB9A7D9);
const Color _lavenderLight = Color(0xFFD5C9EC);
const Color _gold = Color(0xFFB8860B);
const Color _goldLight = Color(0xFFFFE08A);
const Color _royal = Color(0xFF5C4A8C);
const Color _royalLight = Color(0xFFB9A7D9);
const Color _midnight = Color(0xFF2A2A33);
const Color _mint = Color(0xFF3F6E68);
const Color _mintLight = Color(0xFF7FB0A8);

/// Per-tab blurb lines (design.md §Market "Blurb line").
const String kBoostsBlurb =
    'Spend honey to soften the week — the streak still has to be earned.';
const String kLooksBlurb =
    'Restyle the whole hive in a new palette. Switch looks anytime.';
const String kDreamsBlurb =
    'Free to start — each dream grows its own check-ins and its own pot.';
const String kRewardsBlurb = 'Turn honey into something real. The streak pays out here.';
const String kHoneyBlurb =
    'Buying honey skips the grind, not the check-ins — spending still needs a streak.';

/// Blurb lookup keyed by tab, for the Market screen.
const Map<MarketTab, String> kMarketBlurbs = {
  MarketTab.boosts: kBoostsBlurb,
  MarketTab.looks: kLooksBlurb,
  MarketTab.dreams: kDreamsBlurb,
  MarketTab.rewards: kRewardsBlurb,
  MarketTab.honey: kHoneyBlurb,
};

/// The full 25-item Market catalogue (README "Market"), grouped by tab.
const List<MarketItem> kMarketCatalog = [
  // --- Boosts -------------------------------------------------------------
  MarketItem(
    id: 'double-honey-weekend',
    title: 'Double honey weekend',
    description:
        'Every check-in this weekend pays double. Perfect for a slow Friday-to-Sunday stretch.',
    tab: MarketTab.boosts,
    honeyCost: 300,
    art: ArtTile(
      gradient: [_honeyLight, _honeyDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .20, top: .18, width: .60, height: .16, opacity: .9, color: _white),
        ArtShape(kind: 'circle', left: .24, top: .42, width: .20, height: .20, opacity: .85, color: _white),
        ArtShape(kind: 'circle', left: .56, top: .42, width: .20, height: .20, opacity: .85, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'streak-insurance',
    title: 'Streak insurance',
    description:
        'Miss a day without losing your streak. Covers one skipped check-in, used automatically.',
    tab: MarketTab.boosts,
    honeyCost: 450,
    tag: 'POPULAR',
    art: ArtTile(
      gradient: [_tealLight, _tealDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .22, top: .14, width: .56, height: .64, opacity: .8, color: _white),
        ArtShape(kind: 'circle', left: .40, top: .26, width: .20, height: .20, opacity: .95, color: _honey),
      ],
    ),
  ),
  MarketItem(
    id: 'slow-week-mode',
    title: 'Slow week mode',
    description:
        'Lower this week\u2019s targets to match a quiet one. Your streak stays whole.',
    tab: MarketTab.boosts,
    honeyCost: 200,
    art: ArtTile(
      gradient: [_surfaceWarm, _honeyLight],
      shapes: [
        ArtShape(kind: 'circle', left: .28, top: .26, width: .44, height: .44, opacity: .8, color: _honeyDeep),
        ArtShape(kind: 'rect', left: .22, top: .44, width: .56, height: .10, opacity: .9, color: _ink),
      ],
    ),
  ),
  MarketItem(
    id: 'freeze-the-pot',
    title: 'Freeze the pot',
    description:
        'Pause your debt leak for a week. Nothing drips out while it\u2019s frozen.',
    tab: MarketTab.boosts,
    honeyCost: 350,
    art: ArtTile(
      gradient: [_tealLight, _teal],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .16, width: .44, height: .60, opacity: .85, color: _white),
        ArtShape(kind: 'circle', left: .34, top: .26, width: .10, height: .10, opacity: .95, color: _white),
        ArtShape(kind: 'circle', left: .58, top: .48, width: .08, height: .08, opacity: .9, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'scout-bee',
    title: 'Scout bee',
    description:
        'Send a bee to hunt down a bill you forgot. It reports back with what it found.',
    tab: MarketTab.boosts,
    honeyCost: 500,
    art: ArtTile(
      gradient: [_brownLight, _brownDeep],
      shapes: [
        ArtShape(kind: 'circle', left: .40, top: .24, width: .20, height: .20, opacity: .9, color: _honey),
        ArtShape(kind: 'rect', left: .20, top: .30, width: .60, height: .08, opacity: .6, color: _white),
        ArtShape(kind: 'rect', left: .30, top: .50, width: .40, height: .10, rotationDeg: -20, opacity: .6, color: _white),
      ],
    ),
  ),

  // --- Looks --------------------------------------------------------------
  MarketItem(
    id: 'amber-dusk',
    title: 'Amber Dusk',
    description:
        'Warm amber fading into evening. Honey gradients, dusk shadows.',
    tab: MarketTab.looks,
    honeyCost: 600,
    art: ArtTile(
      gradient: [_honeyDeep, _clay],
      shapes: [
        ArtShape(kind: 'circle', left: .34, top: .18, width: .32, height: .32, opacity: .95, color: _honeyLight),
        ArtShape(kind: 'rect', left: .12, top: .58, width: .76, height: .12, opacity: .7, color: _ink),
      ],
    ),
  ),
  MarketItem(
    id: 'paper-comb',
    title: 'Paper Comb',
    description:
        'Clean paper-and-honey. Cream cells with a golden edge.',
    tab: MarketTab.looks,
    honeyCost: 500,
    art: ArtTile(
      gradient: [_paper, _honey],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .20, width: .44, height: .44, rotationDeg: 45, opacity: .7, color: _honey),
        ArtShape(kind: 'rect', left: .28, top: .20, width: .44, height: .44, rotationDeg: -45, opacity: .5, color: _honeyDeep),
      ],
    ),
  ),
  MarketItem(
    id: 'sage-hive',
    title: 'Sage Hive',
    description:
        'Calm sage over deep teal. Green tones for a slower month.',
    tab: MarketTab.looks,
    honeyCost: 700,
    art: ArtTile(
      gradient: [_tealLight, _tealDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .14, top: .22, width: .72, height: .12, opacity: .8, color: _white),
        ArtShape(kind: 'rect', left: .10, top: .42, width: .80, height: .12, opacity: .65, color: _white),
        ArtShape(kind: 'rect', left: .16, top: .62, width: .68, height: .12, opacity: .5, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'lavender-comb',
    title: 'Lavender Comb',
    description:
        'Soft lavender cells with honey rims. For lighter check-ins.',
    tab: MarketTab.looks,
    honeyCost: 700,
    art: ArtTile(
      gradient: [_lavenderLight, _lavender],
      shapes: [
        ArtShape(kind: 'rect', left: .30, top: .16, width: .40, height: .40, rotationDeg: 30, opacity: .8, color: _honey),
        ArtShape(kind: 'circle', left: .44, top: .30, width: .12, height: .12, opacity: .9, color: _honeyDeep),
      ],
    ),
  ),
  MarketItem(
    id: 'midnight-nectar',
    title: 'Midnight Nectar',
    description:
        'Near-black cells with a nectar glow. For late-night check-ins.',
    tab: MarketTab.looks,
    honeyCost: 900,
    tag: 'NEW',
    art: ArtTile(
      gradient: [_ink, _honeyDeep],
      shapes: [
        ArtShape(kind: 'circle', left: .36, top: .16, width: .28, height: .28, opacity: .95, color: _honey),
        ArtShape(kind: 'rect', left: .16, top: .58, width: .68, height: .10, opacity: .6, color: _honeyLight),
      ],
    ),
  ),
  MarketItem(
    id: 'terracotta',
    title: 'Terracotta',
    description:
        'Baked clay and earthen reds. Warm and grounded.',
    tab: MarketTab.looks,
    honeyCost: 650,
    art: ArtTile(
      gradient: [_clayLight, _clayDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .22, top: .28, width: .56, height: .40, rotationDeg: 8, opacity: .8, color: _white),
        ArtShape(kind: 'rect', left: .30, top: .20, width: .56, height: .40, rotationDeg: 8, opacity: .5, color: _clay),
      ],
    ),
  ),

  // --- Bee skins (purchasable restyles for the swarm + queen) --------------
  MarketItem(
    id: 'bee-skin-gold',
    title: 'Gold Bees',
    description:
        'Restyle the swarm and the queen in warm gold. They keep flying either way.',
    tab: MarketTab.looks,
    honeyCost: 400,
    beeSkinId: 'gold',
    art: ArtTile(
      gradient: [_goldLight, _gold],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .32, width: .44, height: .26, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .46, top: .36, width: .08, height: .18, opacity: .95, color: _gold),
      ],
    ),
  ),
  MarketItem(
    id: 'bee-skin-royal',
    title: 'Royal Bees',
    description:
        'Purple bees with a regal crown to match. For a noble hive.',
    tab: MarketTab.looks,
    honeyCost: 600,
    beeSkinId: 'royal',
    art: ArtTile(
      gradient: [_royalLight, _royal],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .32, width: .44, height: .26, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .46, top: .36, width: .08, height: .18, opacity: .95, color: _royal),
      ],
    ),
  ),
  MarketItem(
    id: 'bee-skin-mint',
    title: 'Mint Bees',
    description:
        'Cool teal bees for a slower month. The queen stays calm too.',
    tab: MarketTab.looks,
    honeyCost: 500,
    beeSkinId: 'mint',
    art: ArtTile(
      gradient: [_mintLight, _mint],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .32, width: .44, height: .26, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .46, top: .36, width: .08, height: .18, opacity: .95, color: _mint),
      ],
    ),
  ),
  MarketItem(
    id: 'bee-skin-midnight',
    title: 'Midnight Bees',
    description:
        'Near-black bees with a nectar glow. For late-night check-ins.',
    tab: MarketTab.looks,
    honeyCost: 700,
    tag: 'NEW',
    beeSkinId: 'midnight',
    art: ArtTile(
      gradient: [_midnight, _honeyDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .28, top: .32, width: .44, height: .26, opacity: .9, color: _honey),
        ArtShape(kind: 'rect', left: .46, top: .36, width: .08, height: .18, opacity: .95, color: _midnight),
      ],
    ),
  ),

  // --- Dreams (free to start, no cost) -------------------------------------
  MarketItem(
    id: 'kyoto-fund',
    title: 'Kyoto fund',
    description:
        'Save for the trip in small daily drops. Each check-in sets a little aside.',
    tab: MarketTab.dreams,
    isDream: true,
    art: ArtTile(
      gradient: [_clayLight, _ink],
      shapes: [
        ArtShape(kind: 'circle', left: .36, top: .18, width: .28, height: .28, opacity: .9, color: _honeyLight),
        ArtShape(kind: 'rect', left: .12, top: .56, width: .76, height: .16, opacity: .7, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'deposit-ladder',
    title: 'Deposit ladder',
    description:
        'Climb rungs toward your deposit, one check-in at a time.',
    tab: MarketTab.dreams,
    isDream: true,
    art: ArtTile(
      gradient: [_honeyLight, _teal],
      shapes: [
        ArtShape(kind: 'rect', left: .16, top: .54, width: .20, height: .18, opacity: .85, color: _white),
        ArtShape(kind: 'rect', left: .40, top: .40, width: .20, height: .32, opacity: .85, color: _white),
        ArtShape(kind: 'rect', left: .64, top: .26, width: .20, height: .46, opacity: .85, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'debt-free-by-april',
    title: 'Debt-free by April',
    description:
        'A dated goal with its own check-ins. Watch the debt line fall.',
    tab: MarketTab.dreams,
    isDream: true,
    art: ArtTile(
      gradient: [_clayLight, _honeyLight],
      shapes: [
        ArtShape(kind: 'rect', left: .14, top: .44, width: .72, height: .14, opacity: .8, color: _ink),
        ArtShape(kind: 'circle', left: .70, top: .28, width: .16, height: .16, opacity: .9, color: _honey),
      ],
    ),
  ),
  MarketItem(
    id: '100-no-spend-days',
    title: '100 no-spend days',
    description:
        'Count 100 no-spend days, each one its own small win.',
    tab: MarketTab.dreams,
    isDream: true,
    art: ArtTile(
      gradient: [_teal, _honeyLight],
      shapes: [
        ArtShape(kind: 'circle', left: .26, top: .22, width: .48, height: .48, opacity: .8, color: _white),
        ArtShape(kind: 'circle', left: .40, top: .36, width: .20, height: .20, opacity: .95, color: _tealDeep),
      ],
    ),
  ),
  MarketItem(
    id: 'wedding-jar',
    title: 'Wedding jar',
    description:
        'Fill a jar for the big day. Check-ins add to it automatically.',
    tab: MarketTab.dreams,
    isDream: true,
    art: ArtTile(
      gradient: [_honeyLight, _clayLight],
      shapes: [
        ArtShape(kind: 'rect', left: .34, top: .12, width: .32, height: .12, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .30, top: .26, width: .40, height: .46, opacity: .7, color: _white),
      ],
    ),
  ),

  // --- Rewards ------------------------------------------------------------
  MarketItem(
    id: 'coffee-credit',
    title: '\$5 coffee credit',
    description:
        'Swap 800 honey for a \$5 coffee. On us, for the streak.',
    tab: MarketTab.rewards,
    honeyCost: 800,
    art: ArtTile(
      gradient: [_brownLight, _brownDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .32, top: .14, width: .36, height: .18, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .24, top: .42, width: .52, height: .08, opacity: .8, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'plant-a-tree',
    title: 'Plant a real tree',
    description:
        'Turn honey into a tree, planted for real. We\u2019ll send the proof.',
    tab: MarketTab.rewards,
    honeyCost: 1200,
    art: ArtTile(
      gradient: [_tealLight, _tealDeep],
      shapes: [
        ArtShape(kind: 'circle', left: .32, top: .14, width: .36, height: .36, opacity: .9, color: _honey),
        ArtShape(kind: 'rect', left: .46, top: .44, width: .08, height: .32, opacity: .85, color: _brownDeep),
      ],
    ),
  ),
  MarketItem(
    id: 'give-5-away',
    title: 'Give \$5 away',
    description:
        'Send \$5 to a charity we pick together. Honey becomes good.',
    tab: MarketTab.rewards,
    honeyCost: 1000,
    art: ArtTile(
      gradient: [_honeyLight, _honeyDeep],
      shapes: [
        ArtShape(kind: 'circle', left: .30, top: .24, width: .40, height: .40, opacity: .85, color: _white),
        ArtShape(kind: 'rect', left: .46, top: .16, width: .08, height: .56, opacity: .9, color: _ink),
      ],
    ),
  ),
  MarketItem(
    id: 'cinema-ticket',
    title: 'Cinema ticket',
    description:
        'A movie ticket on us. Pick a night and go.',
    tab: MarketTab.rewards,
    honeyCost: 1500,
    art: ArtTile(
      gradient: [_ink, _brownDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .12, top: .26, width: .76, height: .44, opacity: .85, color: _white),
        ArtShape(kind: 'circle', left: .24, top: .38, width: .16, height: .16, opacity: .6, color: _ink),
        ArtShape(kind: 'circle', left: .60, top: .38, width: .16, height: .16, opacity: .6, color: _ink),
      ],
    ),
  ),
  MarketItem(
    id: 'sticker-pack',
    title: 'Sticker pack',
    description:
        'A pack of bee stickers to your door. Small, sweet, physical.',
    tab: MarketTab.rewards,
    honeyCost: 400,
    art: ArtTile(
      gradient: [_honeyLight, _clayLight],
      shapes: [
        ArtShape(kind: 'rect', left: .18, top: .18, width: .30, height: .30, rotationDeg: -12, opacity: .9, color: _teal),
        ArtShape(kind: 'rect', left: .52, top: .30, width: .30, height: .30, rotationDeg: 18, opacity: .9, color: _clay),
      ],
    ),
  ),

  // --- Honey (real money) --------------------------------------------------
  MarketItem(
    id: 'small-jar',
    title: 'Small jar',
    description:
        'Top up 500 honey for \$1.99. Check-ins still set your streak.',
    tab: MarketTab.honey,
    moneyCost: 1.99,
    art: ArtTile(
      gradient: [_honeyLight, _honeyDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .34, top: .12, width: .32, height: .10, opacity: .9, color: _ink),
        ArtShape(kind: 'rect', left: .28, top: .24, width: .44, height: .50, opacity: .75, color: _white),
      ],
    ),
  ),
  MarketItem(
    id: 'full-jar',
    title: 'Full jar',
    description:
        '1,500 honey for \$4.99. Best value per drop.',
    tab: MarketTab.honey,
    moneyCost: 4.99,
    tag: 'BEST',
    art: ArtTile(
      gradient: [_honey, _honeyDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .34, top: .12, width: .32, height: .10, opacity: .9, color: _white),
        ArtShape(kind: 'rect', left: .28, top: .24, width: .44, height: .50, opacity: .7, color: _white),
        ArtShape(kind: 'circle', left: .40, top: .40, width: .20, height: .20, opacity: .95, color: _honeyLight),
      ],
    ),
  ),
  MarketItem(
    id: 'cellar-jar',
    title: 'Cellar jar',
    description:
        '4,000 honey for \$9.99. The deep reserve.',
    tab: MarketTab.honey,
    moneyCost: 9.99,
    art: ArtTile(
      gradient: [_brownDeep, _honeyDeep],
      shapes: [
        ArtShape(kind: 'rect', left: .34, top: .12, width: .32, height: .10, opacity: .9, color: _honeyLight),
        ArtShape(kind: 'rect', left: .28, top: .24, width: .44, height: .50, opacity: .65, color: _honey),
      ],
    ),
  ),
  MarketItem(
    id: 'tallyhive-pro',
    title: 'TallyHive Pro',
    description:
        'Weekly reports, unlimited looks, 2× earning. \$4.99/mo, billed monthly.',
    tab: MarketTab.honey,
    moneyCost: 4.99,
    art: ArtTile(
      gradient: [_ink, _tealDeep],
      shapes: [
        ArtShape(kind: 'circle', left: .36, top: .16, width: .28, height: .28, opacity: .95, color: _honey),
        ArtShape(kind: 'rect', left: .16, top: .56, width: .68, height: .10, opacity: .7, color: _tealLight),
      ],
    ),
  ),
];
