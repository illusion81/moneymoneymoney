import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../collect/models/wallet.dart';
import '../eggs/egg.dart';
import '../eggs/egg_rarity.dart';
import '../placeholder/motion/squash_stretch.dart';
import '../sprites/asset_paths.dart';
import '../sprites/egg_sprites.dart';
import '../sprites/sprite_cache.dart';
import '../sprites/sprite_painter.dart';
import '../sprites/sprite_strip.dart';
import '../ui/market_icon.dart';

/// The lootbox: buy eggs with coins and hatch them into animals.
///
/// Self-contained for the session — it starts from [wallet] and spends its own
/// copy, matching the rest of the economy (no persistence). Route it with, for
/// example:
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => EggScreen(wallet: wallet)),
/// );
/// ```
class EggScreen extends StatefulWidget {
  const EggScreen({super.key, required this.wallet});

  /// Starting coin balance; purchases decrement the screen's own copy.
  final Wallet wallet;

  @override
  State<EggScreen> createState() => _EggScreenState();
}

class _EggScreenState extends State<EggScreen>
    with SingleTickerProviderStateMixin {
  late Wallet _wallet = widget.wallet;
  final math.Random _random = math.Random();

  Egg? _egg;
  bool _revealed = false;

  late final AnimationController _controller;

  static const Duration _waitDuration = Duration(milliseconds: 1400);

  /// Rare shells hop in place while they wait; common shells rock.
  EggClip _waitingClip(EggVariant variant) =>
      variant.index < 2 ? EggClip.rock : EggClip.bounce;

  Duration get _hatchDuration =>
      EggSprites.strip(_egg!.variant, EggClip.hatch).duration;

  Duration get _totalDuration => _waitDuration + _hatchDuration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    unawaited(_loadSprites(<String>[
      for (final variant in EggVariant.values)
        EggSprites.path(variant, EggClip.idle),
    ]));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSprites(List<String> paths) async {
    try {
      await SpriteCache.instance.loadAll(paths);
    } catch (_) {
      // Assets may be absent under test; the placeholder box covers it.
    }
    if (mounted) setState(() {});
  }

  void _buy(EggVariant variant) {
    final price = variant.priceCoins;
    if (!_wallet.canAfford(price)) return;

    final egg = Egg.locked(variant, _random.nextInt(1 << 30));
    setState(() {
      _wallet = _wallet.spend(price);
      _egg = egg;
      _revealed = false;
    });

    unawaited(_loadSprites(<String>[
      EggSprites.path(variant, _waitingClip(variant)),
      EggSprites.path(variant, EggClip.hatch),
      SpriteAssets.animal(egg.animalId),
    ]));

    setState(() => _egg = _egg!.to(EggState.ready).startHatching());
    _controller.duration = _totalDuration;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _egg = _egg!.reveal();
        _revealed = true;
      });
    });
  }

  void _reset() {
    setState(() {
      _egg = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eggs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const MarketIconImage(icon: MarketIcon.coin, size: 18),
                const SizedBox(width: 4),
                Text('${_wallet.coins}'),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _egg == null ? _idleView() : _hatchView(),
          ),
        ),
      ),
    );
  }

  Widget _idleView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final variant in EggVariant.values) ...[
          _eggCard(variant),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _eggCard(EggVariant variant) {
    final affordable = _wallet.canAfford(variant.priceCoins);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _spriteLayer(
                EggSprites.strip(variant, EggClip.idle),
                0,
                const Size(56, 56),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(variant.tier.label),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: affordable ? () => _buy(variant) : null,
              child: Text('${variant.priceCoins}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hatchView() {
    if (_revealed) return _revealView();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final egg = _egg!;
        final elapsedMs = _controller.value * _totalDuration.inMilliseconds;
        final waiting = elapsedMs < _waitDuration.inMilliseconds;

        final SpriteStrip strip;
        final int frame;
        if (waiting) {
          strip = EggSprites.strip(egg.variant, _waitingClip(egg.variant));
          frame = strip.frameAt(elapsedMs / 1000.0, loop: true);
        } else {
          strip = EggSprites.strip(egg.variant, EggClip.hatch);
          frame = strip.frameAt(
            (elapsedMs - _waitDuration.inMilliseconds) / 1000.0,
            loop: false,
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: _spriteLayer(strip, frame, const Size(128, 128)),
              ),
              const SizedBox(height: 16),
              Text(waiting ? 'It is moving…' : 'Hatching!'),
            ],
          ),
        );
      },
    );
  }

  Widget _revealView() {
    final egg = _egg!;
    final animalStrip = SpriteStrip.single(SpriteAssets.animal(egg.animalId));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: _spriteLayer(animalStrip, 0, const Size(128, 128)),
          ),
          const SizedBox(height: 16),
          Text(
            egg.animalId.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(egg.animalTier.label),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _reset, child: const Text('Hatch another')),
        ],
      ),
    );
  }

  Widget _spriteLayer(SpriteStrip strip, int frame, Size designSize) {
    final image = SpriteCache.instance.peek(strip.assetPath);
    if (image == null) {
      return Container(
        width: designSize.width,
        height: designSize.height,
        decoration: BoxDecoration(
          color: const Color(0xffefe3cd),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return CustomPaint(
      size: designSize,
      painter: SpriteActorPainter(
        image: image,
        strip: strip,
        position: Offset.zero,
        designSize: designSize,
        scale: const ScalePair(1, 1),
        frame: frame,
      ),
    );
  }
}
