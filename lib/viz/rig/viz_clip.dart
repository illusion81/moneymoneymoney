/// The animation clips every rig speaks. Non-locomoting rigs reinterpret walk
/// and run rather than omitting them, so UI controls stay uniform.
enum VizClip { breathe, walk, run }

extension VizClipInfo on VizClip {
  String get label => switch (this) {
    VizClip.breathe => 'Breathe',
    VizClip.walk => 'Walk',
    VizClip.run => 'Run',
  };

  /// One full loop at 1.0x speed.
  Duration get period => switch (this) {
    VizClip.breathe => const Duration(milliseconds: 3200),
    VizClip.walk => const Duration(milliseconds: 900),
    VizClip.run => const Duration(milliseconds: 520),
  };
}
