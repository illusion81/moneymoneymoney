import 'package:flutter/material.dart';

import '../widgets/primitives/honey_jar.dart';

/// The honey-pot jar layers, bottom-anchored (README "Honey pot card").
///
/// Fractions are of the jar's inner height, 0 at the bottom. The Debt band is
/// hatched (fill + stripe); the others are solid fills.
const List<PotLayer> kPotLayers = [
  PotLayer(
    id: 'debt',
    label: 'Debt',
    fromFrac: 0,
    toFrac: 22 / 130,
    fill: Color(0xFFC4634C), // clay
    stripe: Color(0xFFAE5641), // clayDeep
  ),
  PotLayer(
    id: 'invested',
    label: 'Invested',
    fromFrac: 22 / 130,
    toFrac: 56 / 130,
    fill: Color(0xFF5C8C86), // teal
  ),
  PotLayer(
    id: 'savings',
    label: 'Savings',
    fromFrac: 56 / 130,
    toFrac: 98 / 130,
    fill: Color(0xFFF5B322), // honey
  ),
  PotLayer(
    id: 'cash',
    label: 'Cash',
    fromFrac: 98 / 130,
    toFrac: 1.0,
    fill: Color(0xFFFFDD8A), // honeyLight alt (cash jar layer)
  ),
];

/// Per-layer dollar amounts for the pot legend (README "Honey pot card").
const Map<String, double> kPotAmounts = {
  'cash': 3210,
  'savings': 8150,
  'invested': 11180,
  'debt': -4120,
};
