import 'package:flutter/material.dart';

import '../models/models.dart';

/// The default "Classic" skin — matches the original beeIn/beeOut literals
/// (design.md §1.1 `Bee literals`).
const BeeSkin kClassicSkin = BeeSkin(
  id: 'classic',
  label: 'Classic',
  body: Color(0xFF4A3520),
  stripe: Color(0xFFFFD972),
  wing: Color(0xCCFFFFFF),
  outBody: Color(0xFFF0DFC4),
  outStripe: Color(0xFF6E4826),
  outWing: Color(0x8CFFFFFF),
);

/// Every selectable bee skin. Invented palettes (like the Market Looks), each
/// restyling the swarm + queen.
const List<BeeSkin> kBeeSkins = <BeeSkin>[
  kClassicSkin,
  BeeSkin(
    id: 'gold',
    label: 'Gold',
    body: Color(0xFFB8860B),
    stripe: Color(0xFFFFE08A),
    wing: Color(0xCCFFFFFF),
    outBody: Color(0xFFF3D79A),
    outStripe: Color(0xFFB8860B),
    outWing: Color(0x8CFFFFFF),
  ),
  BeeSkin(
    id: 'royal',
    label: 'Royal',
    body: Color(0xFF5C4A8C),
    stripe: Color(0xFFB9A7D9),
    wing: Color(0xCCFFFFFF),
    outBody: Color(0xFFD5C9EC),
    outStripe: Color(0xFF5C4A8C),
    outWing: Color(0x8CFFFFFF),
  ),
  BeeSkin(
    id: 'mint',
    label: 'Mint',
    body: Color(0xFF3F6E68),
    stripe: Color(0xFF7FB0A8),
    wing: Color(0xCCFFFFFF),
    outBody: Color(0xFFBFD9D4),
    outStripe: Color(0xFF3F6E68),
    outWing: Color(0x8CFFFFFF),
  ),
  BeeSkin(
    id: 'midnight',
    label: 'Midnight',
    body: Color(0xFF2A2A33),
    stripe: Color(0xFFF5B322),
    wing: Color(0x99FFFFFF),
    outBody: Color(0xFF6B6B7A),
    outStripe: Color(0xFF2A2A33),
    outWing: Color(0x80FFFFFF),
  ),
];

/// Resolves a skin id to its [BeeSkin], falling back to [kClassicSkin].
BeeSkin beeSkinById(String id) {
  for (final BeeSkin skin in kBeeSkins) {
    if (skin.id == id) {
      return skin;
    }
  }
  return kClassicSkin;
}
