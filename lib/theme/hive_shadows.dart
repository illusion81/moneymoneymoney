import 'package:flutter/material.dart';

/// Shadow recipes from design.md §4.2, ready to drop straight into a
/// `BoxDecoration`. Multi-layer shadows are the array in order.
///
/// Global law: no borders anywhere — depth comes only from these shadows.
abstract final class HiveShadows {
  HiveShadows._();

  /// Default card shadow.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x0D33251A), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(
      color: Color(0x4D33251A),
      offset: Offset(0, 14),
      blurRadius: 30,
      spreadRadius: -12,
    ),
  ];

  /// Owned / accepted card shadow.
  static const List<BoxShadow> ownedCard = <BoxShadow>[
    BoxShadow(color: Color(0x4DE08C1B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x73E08C1B),
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -10,
    ),
  ];

  /// Completed-task (whisper) shadow.
  static const List<BoxShadow> completedTask = <BoxShadow>[
    BoxShadow(color: Color(0x1233251A), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Honey pill shadow (streak pill, balance pill).
  static const List<BoxShadow> pillHoney = <BoxShadow>[
    BoxShadow(color: Color(0x47E08C1B), offset: Offset(0, 2), blurRadius: 5),
  ];

  /// Neutral control pill shadow (settings gear button).
  static const List<BoxShadow> pillNeutral = <BoxShadow>[
    BoxShadow(color: Color(0x2433251A), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Floating tab-bar lift shadow (negative offset casts up; no top hairline).
  static const List<BoxShadow> tabBar = <BoxShadow>[
    BoxShadow(
      color: Color(0x4033251A),
      offset: Offset(0, -8),
      blurRadius: 24,
      spreadRadius: -10,
    ),
  ];

  /// Bottom sheet shadow.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: Color(0x4033251A), offset: Offset(0, -8), blurRadius: 40),
  ];

  /// Active market-tab chip shadow.
  static const List<BoxShadow> marketTabActive = <BoxShadow>[
    BoxShadow(
      color: Color(0x5933251A),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  /// Inactive market-tab chip shadow.
  static const List<BoxShadow> marketTabInactive = <BoxShadow>[
    BoxShadow(color: Color(0x2433251A), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Summary card (amber) shadow.
  static const List<BoxShadow> summaryAmber = <BoxShadow>[
    BoxShadow(color: Color(0x33E08C1B), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Toggle knob shadow.
  static const List<BoxShadow> toggleKnob = <BoxShadow>[
    BoxShadow(color: Color(0x4733251A), offset: Offset(0, 1), blurRadius: 3),
  ];
}
