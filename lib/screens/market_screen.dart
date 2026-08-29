import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/market_catalog.dart';
import '../models/models.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/primitives/primitives.dart';

// ── Colour literals (design.md §1.1 alternates, used in their exact context) ─
/// honeyText on honeyTint — balance count + market tag chips.
const Color _honeyTextOnTint = Color(0xFF8A5E12);

/// inkMuted `.5` — inactive tab text, blurb, descriptions, owned buttons.
const Color _ink50 = Color(0x8033251A);

/// ink @ 40% — unaffordable honey price.
const Color _ink40 = Color(0x6633251A);

/// surfaceSunk alternate `#EFE7D6` — owned / unaffordable price buttons.
const Color _ownedBg = Color(0xFFEFE7D6);

/// honeyTint — balance pill and tag chip background.
const Color _honeyTint = Color(0xFFFFF3D6);

/// The Market screen (README "Market", design.md §Market).
class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HiveState state = ref.watch(hiveStateProvider);
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);

    final List<MarketItem> items = kMarketCatalog
        .where((MarketItem i) => i.tab == state.marketTab)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
      children: <Widget>[
        _buildHeader(state),
        const SizedBox(height: 14),
        if (state.flash != null) ...<Widget>[
          _buildFlash(state.flash!),
          const SizedBox(height: 14),
        ],
        _buildTabs(state, notifier),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            kMarketBlurbs[state.marketTab] ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: _ink50,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 14),
          _buildItemRow(items[i], state, notifier),
        ],
      ],
    );
  }

  /// "Trade your honey" title + honey-balance pill.
  Widget _buildHeader(HiveState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Trade your honey',
              style: GoogleFonts.caveat(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: HiveColors.light.ink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _honeyTint,
            borderRadius: BorderRadius.circular(11),
            boxShadow: HiveShadows.pillHoney,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const JarGlyph(),
              const SizedBox(width: 7),
              Text(
                _comma(state.honey),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _honeyTextOnTint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The one-line purchase toast (auto-clears in state after 3.2 s).
  Widget _buildFlash(String flash) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: HiveColors.light.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        flash,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.12,
          color: HiveColors.light.cream,
        ),
      ),
    );
  }

  /// Five equal-width tab chips (README "Market").
  Widget _buildTabs(HiveState state, HiveNotifier notifier) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < MarketTab.values.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _TabChip(
              tab: MarketTab.values[i],
              active: MarketTab.values[i] == state.marketTab,
              onTap: () => notifier.setMarketTab(MarketTab.values[i]),
            ),
          ),
        ],
      ],
    );
  }

  /// One catalogue row: art tile + title/description + price button.
  Widget _buildItemRow(
    MarketItem item,
    HiveState state,
    HiveNotifier notifier,
  ) {
    final bool owned = state.ownedMarketIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: owned ? HiveShadows.ownedCard : HiveShadows.card,
      ),
      child: Row(
        children: <Widget>[
          MarketArtTile(art: item.art, size: 46),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.13,
                          color: HiveColors.light.ink,
                        ),
                      ),
                    ),
                    if (item.tag != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _honeyTint,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.tag!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.51,
                            color: _honeyTextOnTint,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                    color: _ink50,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _buildPriceButton(item, state, notifier),
        ],
      ),
    );
  }

  /// The right-hand price button, per item kind (README "Market").
  Widget _buildPriceButton(
    MarketItem item,
    HiveState state,
    HiveNotifier notifier,
  ) {
    final bool owned = state.ownedMarketIds.contains(item.id);

    if (item.isDream) {
      return _pillButton(
        label: owned ? 'Started' : 'Start',
        background: owned ? _ownedBg : HiveColors.light.ink,
        foreground: owned ? _ink50 : HiveColors.light.cream,
        onTap: owned ? null : () => notifier.startDream(item.id),
      );
    }

    if (item.moneyCost != null) {
      final String dollars = item.moneyCost!.toStringAsFixed(2);
      final bool isPro = item.title == 'Hivewise Pro';
      return _pillButton(
        label: owned
            ? (isPro ? 'Active' : 'Owned')
            : (isPro ? '\$$dollars/mo' : '\$$dollars'),
        background: owned ? _ownedBg : HiveColors.light.money,
        foreground: owned ? _ink50 : HiveColors.light.moneyOn,
        onTap: owned ? null : () => notifier.buyItem(item.id),
      );
    }

    // Honey item.
    final int cost = item.honeyCost!;
    final bool afford = state.honey >= cost;
    return _pillButton(
      label: owned ? 'Owned' : _comma(cost),
      background: owned ? _ownedBg : (afford ? HiveColors.light.ink : _ownedBg),
      foreground: owned ? _ink50 : (afford ? HiveColors.light.cream : _ink40),
      jar: !owned,
      onTap: owned ? null : () => notifier.buyItem(item.id),
    );
  }

  /// Shared 34 dp price pill.
  Widget _pillButton({
    required String label,
    required Color background,
    required Color foreground,
    bool jar = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (jar) ...<Widget>[
              const JarGlyph(width: 10, height: 12),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One market tab chip (README "Market").
class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final MarketTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 33,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? HiveColors.light.ink : HiveColors.light.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? HiveShadows.marketTabActive
              : HiveShadows.marketTabInactive,
        ),
        child: Text(
          tab.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? HiveColors.light.cream : _ink50,
          ),
        ),
      ),
    );
  }
}

/// "1240" -> "1,240" (matches the state layer's `_withCommas`).
String _comma(int value) {
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return out.toString();
}
