import '../models/money_style.dart';

// All 8 Money Style Archetypes
const Map<String, ArchetypeInfo> archetypeMap = {
  // Steady + Pause + Self
  'steady_pause_self': ArchetypeInfo(
    name: 'The Calm Comparator',
    playfulDescriptor: 'The thoughtful steward',
    strengths: [
      'Plans deliberately and sticks to goals without constant second-guessing',
      'Evaluates options thoroughly before making big financial moves',
      'Builds reliable, predictable money habits that compound over time',
    ],
    interpretation:
        'You take a measured, independent approach to money. You prefer to think things through before making decisions and trust your own judgment. Your steady rhythm gives you consistency, and your careful pace lets you make choices you feel confident about. You\'re at your best when you have time to research and space to make decisions on your own terms.',
    pattern: 'Steady Pause Self-Directed',
  ),

  // Steady + Pause + Collaborative
  'steady_pause_collaborative': ArchetypeInfo(
    name: 'The Intentional Protector',
    playfulDescriptor: 'The collaborative guardian',
    strengths: [
      'Balances careful planning with input from people you trust',
      'Protects family or shared interests through thoughtful decisions',
      'Creates sustainable systems that work for everyone involved',
    ],
    interpretation:
        'You\'re someone who values both stability and teamwork. You like to take time with decisions and involve people you care about in the process. You build money systems that work reliably for a household or group, and you think long-term while staying open to others\' perspectives. You\'re at your best when you can plan carefully with support around you.',
    pattern: 'Steady Pause Collaborative',
  ),

  // Steady + Momentum + Self
  'steady_momentum_self': ArchetypeInfo(
    name: 'The Quiet Builder',
    playfulDescriptor: 'The independent executor',
    strengths: [
      'Acts decisively on plans without needing external validation',
      'Builds wealth steadily through consistent, independent action',
      'Stays the course even when markets or circumstances shift around you',
    ],
    interpretation:
        'You\'re a self-reliant executor. You have a steady financial rhythm and make decisions quickly and independently. You trust yourself to move forward without endless deliberation or external input. You build wealth reliably through quiet, consistent action, and you\'re comfortable being the sole decision-maker in your financial life.',
    pattern: 'Steady Momentum Self-Directed',
  ),

  // Steady + Momentum + Collaborative
  'steady_momentum_collaborative': ArchetypeInfo(
    name: 'The Steady Improviser',
    playfulDescriptor: 'The collaborative pragmatist',
    strengths: [
      'Adapts plans quickly with input from trusted partners or advisors',
      'Keeps money moving and decisions rolling forward as a team',
      'Maintains steady financial habits while staying flexible in tactics',
    ],
    interpretation:
        'You\'re someone who combines steady financial habits with collaborative decision-making. You move forward quickly, but you like to check in with people you trust as you go. You maintain reliable financial structures while staying open to feedback and adaptation. You\'re at your best when you can make prompt decisions as part of a team.',
    pattern: 'Steady Momentum Collaborative',
  ),

  // Responsive + Pause + Self
  'responsive_pause_self': ArchetypeInfo(
    name: 'The Flexible Pathfinder',
    playfulDescriptor: 'The adaptive strategist',
    strengths: [
      'Adjusts to life changes thoughtfully without rigid plans holding you back',
      'Evaluates new opportunities carefully before pivoting direction',
      'Trusts yourself to navigate uncertainty with intention and reflection',
    ],
    interpretation:
        'You\'re naturally adaptable and thoughtful. You prefer to roll with changes in income or circumstances, but you take time to evaluate what each shift means for your direction. You like to think through options before committing, and you trust your own judgment to guide your path. You\'re at your best when you can be flexible and reflective at your own pace.',
    pattern: 'Responsive Pause Self-Directed',
  ),

  // Responsive + Pause + Collaborative
  'responsive_pause_collaborative': ArchetypeInfo(
    name: 'The Community Navigator',
    playfulDescriptor: 'The collaborative explorer',
    strengths: [
      'Draws on community wisdom to navigate financial transitions smoothly',
      'Stays adaptable while building strong support networks around money',
      'Explores options thoughtfully with people who understand your world',
    ],
    interpretation:
        'You\'re someone who thrives on adaptability and connection. You adjust your money approach based on life changes, and you like to explore options and talk them through with people you trust. You navigate uncertainty better with support, and you value others\' perspectives as you chart your course. You\'re at your best when you have both flexibility and community.',
    pattern: 'Responsive Pause Collaborative',
  ),

  // Responsive + Momentum + Self
  'responsive_momentum_self': ArchetypeInfo(
    name: 'The Resourceful Resetter',
    playfulDescriptor: 'The agile independent',
    strengths: [
      'Bounces back quickly from financial setbacks or unexpected changes',
      'Makes fast adjustments without needing permission or consensus',
      'Finds creative solutions and pivots direction decisively on your own',
    ],
    interpretation:
        'You\'re nimble and resourceful. You respond quickly to financial changes and make decisions fast without needing to consult others. You adapt your money approach as circumstances shift, and you trust yourself to find solutions. You\'re energized by new directions and comfortable taking independent action to reset when life changes.',
    pattern: 'Responsive Momentum Self-Directed',
  ),

  // Responsive + Momentum + Collaborative
  'responsive_momentum_collaborative': ArchetypeInfo(
    name: 'The Momentum Maker',
    playfulDescriptor: 'The dynamic team player',
    strengths: [
      'Rallies teams to take action quickly on emerging opportunities',
      'Adapts money strategies in real-time with collaborative input',
      'Energizes others and keeps financial momentum moving forward',
    ],
    interpretation:
        'You\'re someone who thrives on energy and teamwork. You adapt quickly to changes and like to make decisions fast—often with input from people around you. You\'re energized by action and collaboration, and you can rally others to move forward. You\'re at your best when you can be flexible, decisive, and part of a team.',
    pattern: 'Responsive Momentum Collaborative',
  ),
};

// Helper function to get archetype by pattern
ArchetypeInfo getArchetypeByPattern(
  bool isMoneyRhythmSteady,
  bool isDecisionStylePause,
  bool isSupportStyleSelf,
) {
  final rhythm = isMoneyRhythmSteady ? 'steady' : 'responsive';
  final decision = isDecisionStylePause ? 'pause' : 'momentum';
  final support = isSupportStyleSelf ? 'self' : 'collaborative';
  final key = '${rhythm}_${decision}_$support';
  return archetypeMap[key] ?? archetypeMap['steady_pause_self']!;
}
