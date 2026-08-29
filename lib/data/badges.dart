import '../models/models.dart';

/// The 10 Comb badges (README "Comb"), nine unlocked and the last locked.
///
/// Glyphs render in JetBrains Mono 700 on the badge cells; the locked cell
/// uses "·" (design.md §1.2 locked badge cell).
const List<Badge> kBadges = [
  Badge(
    id: 'first-comb',
    label: 'First comb',
    glyph: '1',
    category: BadgeCategory.habit,
    unlocked: true,
  ),
  Badge(
    id: '7-day-run',
    label: '7-day run',
    glyph: '7',
    category: BadgeCategory.habit,
    unlocked: true,
  ),
  Badge(
    id: 'cut-a-bill',
    label: 'Cut a bill',
    glyph: '✂',
    category: BadgeCategory.saving,
    unlocked: true,
  ),
  Badge(
    id: 'no-spend-x5',
    label: 'No-spend ×5',
    glyph: '5',
    category: BadgeCategory.habit,
    unlocked: true,
  ),
  Badge(
    id: 'debt-dented',
    label: 'Debt dented',
    glyph: '−',
    category: BadgeCategory.debt,
    unlocked: true,
  ),
  Badge(
    id: 'half-saved',
    label: 'Half saved',
    glyph: '½',
    category: BadgeCategory.saving,
    unlocked: true,
  ),
  Badge(
    id: 'rainy-pot',
    label: 'Rainy pot',
    glyph: '☔',
    category: BadgeCategory.saving,
    unlocked: true,
  ),
  Badge(
    id: 'nudged-5',
    label: 'Nudged 5',
    glyph: '5',
    category: BadgeCategory.hive,
    unlocked: true,
  ),
  Badge(
    id: '30-check-ins',
    label: '30 check-ins',
    glyph: '30',
    category: BadgeCategory.habit,
    unlocked: true,
  ),
  Badge(
    id: 'frugal-forager',
    label: 'Frugal Forager',
    glyph: '·',
    category: BadgeCategory.habit,
    unlocked: false,
  ),
];
