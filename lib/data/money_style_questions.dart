import '../models/money_style.dart';

// All 12 Money Style questions with exact scoring
// Money Rhythm: 6 Steady, 7 Responsive (Q2 breaks ties)
// Decision Style: 6 Pause, 5 Momentum (Q8 breaks ties)
// Support Style: 3 Self-directed, 9 Collaborative (Q11 breaks ties)

const List<MoneyStyleQuestion> moneyStyleQuestions = [
  // Q1: Money Rhythm
  MoneyStyleQuestion(
    id: 1,
    scenario: 'Your income increases slightly each month.',
    prompt: 'How do you typically adjust your spending?',
    answers: [
      MoneyStyleAnswer(
        text: 'I keep my spending plan steady and put the extra toward savings.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.steady,
      ),
      MoneyStyleAnswer(
        text: 'I adjust my spending a little based on how much is available.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
      MoneyStyleAnswer(
        text: 'I loosen my spending limits when money comes in.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
    ],
  ),

  // Q2: Money Rhythm (TIE-BREAKER)
  MoneyStyleQuestion(
    id: 2,
    scenario: 'An unexpected expense appears—a car repair or medical bill.',
    prompt: 'What\'s your first instinct?',
    answers: [
      MoneyStyleAnswer(
        text: 'I check my budget categories and adjust other spending to cover it.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.steady,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I pull from savings or find cash quickly without much deliberation.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I figure out how to pay for it and move on.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
    ],
  ),

  // Q3: Decision Style
  MoneyStyleQuestion(
    id: 3,
    scenario: 'You\'re thinking about a new subscription service.',
    prompt: 'How do you decide whether to sign up?',
    answers: [
      MoneyStyleAnswer(
        text: 'I take time to research, read reviews, and compare options.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.pause,
      ),
      MoneyStyleAnswer(
        text: 'I try it for a month to see if I actually use it.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
      MoneyStyleAnswer(
        text: 'I commit if the value seems clear, then cancel if I don\'t use it.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
    ],
  ),

  // Q4: Support Style
  MoneyStyleQuestion(
    id: 4,
    scenario: 'You\'re stressed about money.',
    prompt: 'Who do you talk to?',
    answers: [
      MoneyStyleAnswer(
        text: 'I work through it myself first, then share updates if needed.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.selfDirected,
      ),
      MoneyStyleAnswer(
        text: 'I talk to my partner, friends, or family right away.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
      MoneyStyleAnswer(
        text: 'I bring it up in conversation and think out loud with others.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
    ],
  ),

  // Q5: Money Rhythm
  MoneyStyleQuestion(
    id: 5,
    scenario: 'Your spending patterns shift seasonally (holidays, vacations, etc.).',
    prompt: 'How do you plan for these changes?',
    answers: [
      MoneyStyleAnswer(
        text: 'I save monthly to an "irregular expenses" fund and stick to it.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.steady,
      ),
      MoneyStyleAnswer(
        text: 'I adjust my spending month-to-month based on what\'s coming up.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
      MoneyStyleAnswer(
        text: 'I handle it as it comes, knowing I\'ll tighten up afterward if needed.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
    ],
  ),

  // Q6: Decision Style
  MoneyStyleQuestion(
    id: 6,
    scenario: 'A major purchase is on your horizon (car, home, appliance).',
    prompt: 'When do you usually decide?',
    answers: [
      MoneyStyleAnswer(
        text: 'I spend weeks researching specs, prices, and long-term value.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.pause,
      ),
      MoneyStyleAnswer(
        text: 'I compare a few options and decide fairly quickly.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
      MoneyStyleAnswer(
        text: 'I find one that fits my needs and budget, then buy it.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
    ],
  ),

  // Q7: Support Style
  MoneyStyleQuestion(
    id: 7,
    scenario: 'A friend asks for financial advice.',
    prompt: 'How do you respond?',
    answers: [
      MoneyStyleAnswer(
        text: 'I listen and suggest resources they can explore on their own.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.selfDirected,
      ),
      MoneyStyleAnswer(
        text: 'I share what I\'ve learned and help them think through options.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
      MoneyStyleAnswer(
        text: 'I ask clarifying questions and brainstorm ideas together.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
    ],
  ),

  // Q8: Decision Style (TIE-BREAKER)
  MoneyStyleQuestion(
    id: 8,
    scenario: 'A spontaneous opportunity appears (travel deal, event ticket, experience).',
    prompt: 'What\'s your move?',
    answers: [
      MoneyStyleAnswer(
        text: 'I pause and think about whether it fits my current priorities.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.pause,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I go for it if the budget allows and I genuinely want it.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I jump on it—some opportunities don\'t wait.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
    ],
  ),

  // Q9: Support Style
  MoneyStyleQuestion(
    id: 9,
    scenario: 'You\'re not sure whether a financial decision is wise.',
    prompt: 'How do you get clarity?',
    answers: [
      MoneyStyleAnswer(
        text: 'I read articles, listen to podcasts, or study examples on my own.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.selfDirected,
      ),
      MoneyStyleAnswer(
        text: 'I ask a trusted friend or family member what they\'d do.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
      MoneyStyleAnswer(
        text: 'I talk it through with someone I trust to help me see different angles.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
    ],
  ),

  // Q10: Money Rhythm
  MoneyStyleQuestion(
    id: 10,
    scenario: 'You receive a bonus or windfall.',
    prompt: 'What do you typically do?',
    answers: [
      MoneyStyleAnswer(
        text: 'I allocate it systematically across savings, debt, and goals.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.steady,
      ),
      MoneyStyleAnswer(
        text: 'I decide based on what I need most right now.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
      MoneyStyleAnswer(
        text: 'I treat myself a little, then save the rest.',
        dimension: Dimension.moneyRhythm,
        pole: MoneyRhythmPole.responsive,
      ),
    ],
  ),

  // Q11: Support Style (TIE-BREAKER)
  MoneyStyleQuestion(
    id: 11,
    scenario: 'You want to improve your money habits.',
    prompt: 'What approach appeals to you most?',
    answers: [
      MoneyStyleAnswer(
        text: 'I design a plan myself and track my progress independently.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.selfDirected,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I work with a partner, coach, or group to stay accountable.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
        isBreaker: true,
      ),
      MoneyStyleAnswer(
        text: 'I build a plan with someone and check in regularly.',
        dimension: Dimension.supportStyle,
        pole: SupportStylePole.collaborative,
      ),
    ],
  ),

  // Q12: Decision Style
  MoneyStyleQuestion(
    id: 12,
    scenario: 'Your financial situation has changed (job, family, expenses).',
    prompt: 'How do you respond?',
    answers: [
      MoneyStyleAnswer(
        text: 'I sit down and carefully reassess my entire financial plan.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.pause,
      ),
      MoneyStyleAnswer(
        text: 'I adjust my plan where needed and adapt as I go.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
      MoneyStyleAnswer(
        text: 'I make quick changes and figure out any fine-tuning later.',
        dimension: Dimension.decisionStyle,
        pole: DecisionStylePole.momentum,
      ),
    ],
  ),
];
