import '../models/money_style.dart';

MoneyStyleAnswer _a(
  String id,
  String text,
  Dimension d,
  dynamic pole, {
  bool breaker = false,
}) => MoneyStyleAnswer(
  id: id,
  text: text,
  dimension: d,
  pole: pole,
  isBreaker: breaker,
);
MoneyStyleQuestion _q(
  int id,
  Dimension d,
  String scene,
  List<MoneyStyleAnswer> answers,
) => MoneyStyleQuestion(
  id: id,
  dimension: d,
  scenario: scene,
  prompt: 'What feels closest to your first move?',
  answers: answers,
);

/// Draft scenarios, structurally balanced 6/6 per dimension.
final moneyStyleQuestions = <MoneyStyleQuestion>[
  _q(
    1,
    Dimension.moneyRhythm,
    'An automatic payment is due tomorrow. Rude timing.',
    [
      _a(
        'q01_plan',
        'I check what can move around, then make a small plan.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.steady,
        breaker: true,
      ),
      _a(
        'q01_adjust',
        'I handle it, then sort the rest when I have headspace.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.responsive,
        breaker: true,
      ),
      _a(
        'q01_talk',
        'I talk through what to shift before deciding.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.responsive,
        breaker: true,
      ),
    ],
  ),
  _q(
    2,
    Dimension.decisionStyle,
    'A limited-time offer appears for something useful-ish.',
    [
      _a(
        'q02_compare',
        'I compare it with alternatives first.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
      ),
      _a(
        'q02_decide',
        'I decide from what I know and move on.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
      ),
      _a(
        'q02_wait',
        'I leave it for a moment and return later.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
      ),
    ],
  ),
  _q(
    3,
    Dimension.moneyRhythm,
    'An unexpected \$120 cost appears in an ordinary week.',
    [
      _a(
        'q03_pause',
        'I pause other plans and map a way through.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.steady,
      ),
      _a(
        'q03_adjust',
        'I adjust as I go and revisit the week later.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.responsive,
      ),
      _a(
        'q03_check',
        'I check a couple of options before acting.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.responsive,
      ),
    ],
  ),
  _q(
    4,
    Dimension.supportStyle,
    'A friend suggests a last-minute social plan.',
    [
      _a(
        'q04_talk',
        'I talk it through before deciding.',
        Dimension.supportStyle,
        SupportStylePole.collaborative,
      ),
      _a(
        'q04_self',
        'I check in with myself and decide privately.',
        Dimension.supportStyle,
        SupportStylePole.selfDirected,
      ),
      _a(
        'q04_message',
        'I send a quick message for another perspective.',
        Dimension.supportStyle,
        SupportStylePole.collaborative,
      ),
    ],
  ),
  _q(
    5,
    Dimension.moneyRhythm,
    'You receive a small amount of unexpected money.',
    [
      _a(
        'q05_setaside',
        'I set it aside for a purpose.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.steady,
      ),
      _a(
        'q05_now',
        'I use it for what would help most now.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.responsive,
      ),
      _a(
        'q05_enjoy',
        'I split it between now and later.',
        Dimension.moneyRhythm,
        MoneyRhythmPole.steady,
      ),
    ],
  ),
  _q(
    6,
    Dimension.decisionStyle,
    'A money task has waited in the background for a week.',
    [
      _a(
        'q06_start',
        'I start with one small action.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
      ),
      _a(
        'q06_list',
        'I make a short list first.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
      ),
      _a(
        'q06_do',
        'I pick a next step while I can.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
      ),
    ],
  ),
  _q(
    7,
    Dimension.supportStyle,
    'You notice a recurring charge you barely use.',
    [
      _a(
        'q07_review',
        'I review it on my own.',
        Dimension.supportStyle,
        SupportStylePole.selfDirected,
      ),
      _a(
        'q07_ask',
        'I ask someone with similar experience.',
        Dimension.supportStyle,
        SupportStylePole.collaborative,
      ),
      _a(
        'q07_note',
        'I make a note to return to it.',
        Dimension.supportStyle,
        SupportStylePole.selfDirected,
      ),
    ],
  ),
  _q(
    8,
    Dimension.decisionStyle,
    'A purchase leaves you with a mixed feeling afterwards.',
    [
      _a(
        'q08_reflect',
        'I reflect before the next similar choice.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
        breaker: true,
      ),
      _a(
        'q08_move',
        'I take what I learned and keep moving.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
        breaker: true,
      ),
      _a(
        'q08_compare',
        'I compare what happened with expectations.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
        breaker: true,
      ),
    ],
  ),
  _q(
    9,
    Dimension.decisionStyle,
    'You are choosing between two acceptable ways to pay.',
    [
      _a(
        'q09_pick',
        'I choose what feels workable and move ahead.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
      ),
      _a(
        'q09_compare',
        'I compare details before choosing.',
        Dimension.decisionStyle,
        DecisionStylePole.pause,
      ),
      _a(
        'q09_try',
        'I choose one and revisit it if needed.',
        Dimension.decisionStyle,
        DecisionStylePole.momentum,
      ),
    ],
  ),
  _q(10, Dimension.supportStyle, 'A friend mentions money stress.', [
    _a(
      'q10_listen',
      'I listen and think through my response privately.',
      Dimension.supportStyle,
      SupportStylePole.selfDirected,
    ),
    _a(
      'q10_share',
      'I make room to talk it through together.',
      Dimension.supportStyle,
      SupportStylePole.collaborative,
    ),
    _a(
      'q10_boundary',
      'I offer a brief check-in with clear boundaries.',
      Dimension.supportStyle,
      SupportStylePole.selfDirected,
    ),
  ]),
  _q(11, Dimension.supportStyle, 'Your week becomes busier than expected.', [
    _a(
      'q11_self',
      'I reset my own reminders.',
      Dimension.supportStyle,
      SupportStylePole.selfDirected,
      breaker: true,
    ),
    _a(
      'q11_checkin',
      'I arrange a quick check-in.',
      Dimension.supportStyle,
      SupportStylePole.collaborative,
      breaker: true,
    ),
    _a(
      'q11_share',
      'I let someone know I may need encouragement.',
      Dimension.supportStyle,
      SupportStylePole.collaborative,
      breaker: true,
    ),
  ]),
  _q(12, Dimension.moneyRhythm, 'You imagine a calmer money week.', [
    _a(
      'q12_routine',
      'I picture a simple repeatable routine.',
      Dimension.moneyRhythm,
      MoneyRhythmPole.steady,
    ),
    _a(
      'q12_flex',
      'I picture room to adapt.',
      Dimension.moneyRhythm,
      MoneyRhythmPole.responsive,
    ),
    _a(
      'q12_anchor',
      'I picture one reliable anchor.',
      Dimension.moneyRhythm,
      MoneyRhythmPole.steady,
    ),
  ]),
];
