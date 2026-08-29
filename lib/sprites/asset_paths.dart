/// Paths into the two vendored sprite packs.
///
/// Ids are the on-disk filenames, including the animal pack's own spelling of
/// `chiken`. See `docs/superpowers/sprite-assets/spec.md` for provenance.
class SpriteAssets {
  const SpriteAssets._();

  static const String animalDir = 'assets/animals';
  static const String iconDir = 'assets/icons';

  /// The 25 animals in the pixel pack. No raccoon, deer or hummingbird.
  static const List<String> animalIds = <String>[
    'bear',
    'cat',
    'chiken',
    'cow',
    'crocodile',
    'dog',
    'elephant',
    'fox',
    'frog',
    'giraffe',
    'goat',
    'gorilla',
    'hippo',
    'lion',
    'monkey',
    'moose',
    'mouse',
    'panda',
    'penguin',
    'pig',
    'rabbit',
    'snake',
    'tiger',
    'turtle',
    'zebra',
  ];

  /// The 30 market icons, in sheet reading order.
  static const List<String> iconNames = <String>[
    'badge_rosette',
    'bank',
    'stamp',
    'coin',
    'tag_framed',
    'tag_rounded',
    'note_dashed',
    'note_dashed_wide',
    'banner_ribbon',
    'banner_ribbon_wide',
    'banner_ribbon_flat',
    'sparkle_six',
    'sparkle_eight',
    'cross_badge',
    'cross_badge_notched',
    'cross_badge_bevel',
    'seal_capsule',
    'seal_ellipse',
    'ribbon_zigzag',
    'tag_tall',
    'tag_tall_round',
    'padlock',
    'tag_hanging',
    'envelope',
    'card',
    'ticket',
    'ticket_wide',
    'ticket_alt',
    'note_cash',
    'vault',
  ];

  static String animal(String id) => '$animalDir/$id.png';

  static String icon(String name) => '$iconDir/$name.png';

  static List<String> get allPaths => <String>[
    ...animalIds.map(animal),
    ...iconNames.map(icon),
  ];
}
