import '../models/money_style.dart';

/// The 8 Money Style archetypes.
///
/// Identity is a 3-bit key built from the page-1 trio only — Revolving Debt
/// Neglect, Convenience-Impulse Spending, Price-Anchoring — exactly as the
/// design recommends (§F.8 / v1 §D.4). The other three dimensions surface as
/// standalone habit insights on the result screen rather than being folded
/// into the archetype's identity, which keeps this table at 8 entries instead
/// of 64.
///
/// **Zero-score decision (design §F.8 left this open):** each bit is the
/// *sign* of that dimension's running score, and an exact 0 is folded into
/// the "watch" side rather than getting a 4th "balanced" state.
///
/// Why: a 4th per-dimension state would take the key from 8 to 64 archetypes,
/// which is the exact content-dilution problem the 3-bit design exists to
/// avoid. Of the two remaining options — default a 0 to "watch" or to
/// "strength" — "watch" is the honest one: a score of 0 means the user picked
/// the *mixed* option, i.e. they described a habit that is neither failing nor
/// working. Calling that a confirmed strength would over-claim on the user's
/// behalf, which is the failure mode v1 was explicitly redesigned to avoid.
/// Erring toward "worth a look" is recoverable (the copy invites more
/// answers); erring toward "you've got this handled" is not.
const Map<String, ArchetypeInfo> archetypeMap = {
  // key: <debt>_<convenience>_<price>, 'watch' = score <= 0, 'hold' = score > 0
  'watch_watch_watch': ArchetypeInfo(
    id: 'watch_watch_watch',
    name: 'The Improviser',
    playfulDescriptor: 'Decides in the moment, sorts it out later',
    strengths: [
      'Answers honestly about habits most people talk around',
      'Adapts fast — nothing is locked into a system that could break',
      'Has the most room to gain from one small automation',
    ],
    interpretation:
        'Right now, money mostly gets handled in the moment: the card balance, the tired-evening delivery, the pricier option. None of that makes you bad with money — it means very little is on rails yet, so every decision costs you attention at the exact moment you have least of it. The good news is that this is the pattern that changes fastest, because a single automatic payment or pre-decided rule removes a whole category of decisions at once.',
    pattern: 'Debt: watch • Convenience: watch • Price: watch',
  ),
  'watch_watch_hold': ArchetypeInfo(
    id: 'watch_watch_hold',
    name: 'The Careful Chooser',
    playfulDescriptor: 'Knows what things should cost',
    strengths: [
      'Walks in with a price in mind instead of taking the first number offered',
      'Willing to name the cheaper option out loud in a group',
      'Judges value deliberately rather than by how nice something looks',
    ],
    interpretation:
        'You already do the hard part of spending well: you have a sense of what things ought to cost before you are shown a price, and you will say so. Where money still slips away is upstream of that — the card balance carrying over, and the convenience spend that happens when you are too tired to plan. Those are not judgement failures; they are timing failures, and they respond to automation rather than more willpower.',
    pattern: 'Debt: watch • Convenience: watch • Price: hold',
  ),
  'watch_hold_watch': ArchetypeInfo(
    id: 'watch_hold_watch',
    name: 'The Routine Keeper',
    playfulDescriptor: 'Has a rule and mostly sticks to it',
    strengths: [
      'Decided in advance when convenience spending is worth it',
      'Keeps everyday spending from drifting on tired days',
      'Builds habits that survive a bad week',
    ],
    interpretation:
        'Your day-to-day is steadier than most: you have a rule for the tired-evening spend and you mostly keep to it, so the small leaks stay small. The pressure sits elsewhere — on what your credit card does between statements, and on how you anchor to a price when the option in front of you looks good. Both are single-decision problems, not daily-discipline problems.',
    pattern: 'Debt: watch • Convenience: hold • Price: watch',
  ),
  'watch_hold_hold': ArchetypeInfo(
    id: 'watch_hold_hold',
    name: 'The Deliberate Spender',
    playfulDescriptor: 'Spends on purpose, borrows by accident',
    strengths: [
      'Pre-decides both what convenience is worth and what a fair price is',
      'Keeps discretionary spending aligned with what you actually value',
      'Resists both the tired-evening default and the upsell at the counter',
    ],
    interpretation:
        'The spending side of your money life is genuinely in hand — you decide before the moment arrives, and it shows in both convenience and price. What is left is the credit card: a balance that carries, or a rate and due date you could not name without checking. That one is worth attention precisely because everything else is working; it is the piece quietly charging you for a habit you have already outgrown.',
    pattern: 'Debt: watch • Convenience: hold • Price: hold',
  ),
  'hold_watch_watch': ArchetypeInfo(
    id: 'hold_watch_watch',
    name: 'The Autopay Anchor',
    playfulDescriptor: 'Set it once, never thinks about it again',
    strengths: [
      'Removed the monthly card decision entirely by automating it',
      'Keeps roughly aware of your rate and due date without checking',
      'Avoids the most expensive money mistake there is: revolving interest',
    ],
    interpretation:
        'You have already solved the costliest habit on this list — your card gets paid properly without you re-deciding it every month. That is a real, compounding advantage. The spending that still drifts is the in-the-moment kind: the delivery when you are depleted, the nicer option because it was there first. Those cost less individually but they are also the ones a pre-decided rule fixes quickest.',
    pattern: 'Debt: hold • Convenience: watch • Price: watch',
  ),
  'hold_watch_hold': ArchetypeInfo(
    id: 'hold_watch_hold',
    name: 'The Measured Payer',
    playfulDescriptor: 'Good with the big numbers, loose with the tired ones',
    strengths: [
      'Handles credit deliberately instead of by minimum payment',
      'Sets a price expectation before being shown one',
      'Comfortable pushing for a cheaper option when it matters',
    ],
    interpretation:
        'When you are thinking clearly, you are good with money — your card is handled and you know what things should cost. The gap opens at the end of the day, when planning ahead feels like too much and convenience wins. That is not a values problem; it is what happens when a decision is left to your lowest-energy moment. Deciding the rule in advance, once, moves that decision to a time when you are actually able to make it.',
    pattern: 'Debt: hold • Convenience: watch • Price: hold',
  ),
  'hold_hold_watch': ArchetypeInfo(
    id: 'hold_hold_watch',
    name: 'The Steady Operator',
    playfulDescriptor: 'Systems on, price radar off',
    strengths: [
      'Card payments and everyday convenience both run on rules, not willpower',
      'Rarely spends just because you are tired',
      'Keeps the recurring parts of money quietly working',
    ],
    interpretation:
        'The routine parts of your money life run themselves — the card is paid properly and the tired-evening spend has a rule around it. Where the money still goes is at the point of choosing: the pricier option, the first option, the add-on at the counter. That is the one habit here that no automation fixes; it comes from deciding what a thing is worth to you before you see what it costs.',
    pattern: 'Debt: hold • Convenience: hold • Price: watch',
  ),
  'hold_hold_hold': ArchetypeInfo(
    id: 'hold_hold_hold',
    name: 'The Quiet Compounder',
    playfulDescriptor: 'Nothing dramatic, everything working',
    strengths: [
      'Credit, convenience and price are all handled by decisions made in advance',
      'Very little money leaks out through inattention',
      'Free to spend on what you actually care about, without second-guessing',
    ],
    interpretation:
        'All three of the habits this quiz weighs most heavily are already working for you: the card is paid on rails, convenience spending has a rule, and you anchor to a price before the menu does it for you. That combination compounds quietly. The useful next look is the other half of the picture — subscriptions, your savings buffer, and how regularly you actually check in — which is where a well-run money life most often has its one blind spot.',
    pattern: 'Debt: hold • Convenience: hold • Price: hold',
  ),
};

/// Builds the archetype key from the three page-1 dimension signs.
/// `true` means that dimension's score came out positive (a confirmed
/// strength); an exact 0 or a negative score is `false` — see the note above.
ArchetypeInfo getArchetypeByPattern(
  bool debtHolding,
  bool convenienceHolding,
  bool priceHolding,
) {
  String bit(bool value) => value ? 'hold' : 'watch';
  final key =
      '${bit(debtHolding)}_${bit(convenienceHolding)}_${bit(priceHolding)}';
  return archetypeMap[key] ?? archetypeMap['watch_watch_watch']!;
}
