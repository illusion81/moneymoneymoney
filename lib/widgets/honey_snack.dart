import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hive_colors.dart';

/// Shows the hive's own SnackBar: a dark-comb bar with honey lettering.
///
/// Demo dressing — the sponsor strip on the hive, the quiz call-to-action on
/// the report — uses this to say out loud that nothing is wired up behind it,
/// so a tap during a walkthrough reads as deliberate rather than broken.
void showHoneySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: HiveColors.light.honeyLight,
          ),
        ),
        backgroundColor: HiveColors.light.brownDeep,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
