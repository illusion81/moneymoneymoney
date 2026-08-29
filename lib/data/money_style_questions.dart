import '../models/money_style.dart';

/// The v2 question pool: 6 dimensions × 4 questions (1 opener + 3 follow-up
/// branches) = 24 questions. A single session shows 12 of them — the 6 openers
/// (fixed, pages 1–2) plus one follow-up per dimension chosen adaptively
/// (pages 3–4). Copy is verbatim from the approved design doc §D.
///
/// Question IDs are stable and must not be renumbered: they are the storage
/// and analytics identity for both `selected_answers` and `shown_question_ids`.
///
///  1–3   page-1 openers (Revolving Debt, Convenience-Impulse, Price-Anchoring)
///  4–6   page-2 openers (Subscriptions, Savings, Financial Avoidance)
///  7–24  follow-ups, three per dimension: bad-drill, good-drill, mixed-clarify

MoneyStyleAnswer _bad(
  String id,
  String text,
  Dimension dimension,
  Object pole,
  String reveals,
) => MoneyStyleAnswer(
  id: id,
  text: text,
  dimension: dimension,
  pole: pole,
  band: PoleBand.bad,
  reveals: reveals,
);

MoneyStyleAnswer _mixed(
  String id,
  String text,
  Dimension dimension,
  Object pole,
  String reveals,
) => MoneyStyleAnswer(
  id: id,
  text: text,
  dimension: dimension,
  pole: pole,
  band: PoleBand.mixed,
  reveals: reveals,
);

MoneyStyleAnswer _good(
  String id,
  String text,
  Dimension dimension,
  Object pole,
  String reveals,
) => MoneyStyleAnswer(
  id: id,
  text: text,
  dimension: dimension,
  pole: pole,
  band: PoleBand.good,
  reveals: reveals,
);

MoneyStyleQuestion _q({
  required int id,
  required Dimension dimension,
  required QuestionBranch branch,
  required String scenario,
  required String prompt,
  required List<MoneyStyleAnswer> answers,
}) => MoneyStyleQuestion(
  id: id,
  dimension: dimension,
  branch: branch,
  scenario: scenario,
  prompt: prompt,
  answers: answers,
);

const _rd = Dimension.revolvingDebtNeglect;
const _ci = Dimension.convenienceImpulse;
const _sb = Dimension.subscriptionBlindness;
const _sa = Dimension.savingsAvoidance;
const _pa = Dimension.priceAnchoring;
const _fa = Dimension.financialAvoidance;

/// The full 24-question pool, in ID order.
final List<MoneyStyleQuestion> moneyStyleQuestionPool = <MoneyStyleQuestion>[
  // ---------------------------------------------- D.1 Revolving Debt Neglect
  _q(
    id: 1,
    dimension: _rd,
    branch: QuestionBranch.opening,
    scenario: 'Think back to your last two credit card statements.',
    prompt: 'What actually happened?',
    answers: [
      _bad(
        'rd_open_minimum',
        'I paid the minimum both times and let the rest carry over.',
        _rd,
        RevolvingDebtNeglectPole.balanceCarrier,
        'minimum-payment revolving',
      ),
      _mixed(
        'rd_open_full_but_blind',
        'I paid it in full, but honestly couldn’t tell you the interest rate or the exact due date if you asked.',
        _rd,
        RevolvingDebtNeglectPole.dueDateBlind,
        'paid off but attention-blind on rate/date',
      ),
      _good(
        'rd_open_autopay_full',
        'My autopay is set to pay the full statement balance, not just the minimum — and I’ve got a rough idea of my APR and due date without needing to check.',
        _rd,
        RevolvingDebtNeglectPole.autopayFullBalance,
        'automated full-balance payoff + APR awareness',
      ),
    ],
  ),
  _q(
    id: 7,
    dimension: _rd,
    branch: QuestionBranch.badDrill,
    scenario: 'Think about your last 3 credit card statements.',
    prompt: 'How many of those did you carry a balance into the next one?',
    answers: [
      _bad(
        'rd_bad_all_three',
        'All 3 — it’s pretty much always there.',
        _rd,
        RevolvingDebtNeglectPole.balanceCarrier,
        'chronic revolving balance',
      ),
      _mixed(
        'rd_bad_one_or_two',
        '1 or 2 — I paid some down, then put new purchases on before it hit zero.',
        _rd,
        RevolvingDebtNeglectPole.balanceCarrier,
        'intermittent revolving, restart pattern',
      ),
      _good(
        'rd_bad_none_checked',
        'None — and I checked at statement time, so I know roughly what my APR and due date are.',
        _rd,
        RevolvingDebtNeglectPole.autopayFullBalance,
        'consistent full payoff + routine rate awareness',
      ),
    ],
  ),
  _q(
    id: 8,
    dimension: _rd,
    branch: QuestionBranch.goodDrill,
    scenario:
        'Think about how your credit card payment actually happens each month.',
    prompt: 'Which is closest to true right now?',
    answers: [
      _bad(
        'rd_good_manual',
        'No autopay — I pay manually when I remember, and I’ve missed the window before.',
        _rd,
        RevolvingDebtNeglectPole.balanceCarrier,
        'no automation, attention-lapse risk',
      ),
      _mixed(
        'rd_good_autopay_minimum',
        'Autopay is on, but only for the minimum — paying it off in full is still a decision I make separately each month.',
        _rd,
        RevolvingDebtNeglectPole.dueDateBlind,
        'partial automation, decision still live monthly',
      ),
      _good(
        'rd_good_autopay_full',
        'Autopay is set to the full statement balance — I made that call once and don’t think about it monthly anymore.',
        _rd,
        RevolvingDebtNeglectPole.autopayFullBalance,
        'commitment device / decision removed',
      ),
    ],
  ),
  _q(
    id: 9,
    dimension: _rd,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Picture the last time you actually looked at the interest-charged line on a card statement.',
    prompt: 'When was that, and what did you take away from it?',
    answers: [
      _bad(
        'rd_mix_never_looked',
        'Can’t remember ever really looking — I just pay whatever the app tells me to pay.',
        _rd,
        RevolvingDebtNeglectPole.balanceCarrier,
        'no rate awareness at all',
      ),
      _mixed(
        'rd_mix_crisis_only',
        'I’ve looked when a balance was bigger than expected, but not otherwise.',
        _rd,
        RevolvingDebtNeglectPole.dueDateBlind,
        'reactive-only rate awareness',
      ),
      _good(
        'rd_mix_routine_check',
        'I glance at it most months, even when the balance is paid in full — it’s just part of reading the statement.',
        _rd,
        RevolvingDebtNeglectPole.autopayFullBalance,
        'routine rate-check habit, not just crisis response',
      ),
    ],
  ),

  // ------------------------------------------- D.2 Convenience-Impulse Spend
  _q(
    id: 2,
    dimension: _ci,
    branch: QuestionBranch.opening,
    scenario:
        'Think about the last time you were running low on time or energy after work.',
    prompt:
        'In a typical week, how often do you end up ordering delivery or grabbing a rideshare mainly because planning ahead — cooking, leaving earlier, taking transit — felt like too much in the moment?',
    answers: [
      _bad(
        'ci_open_default',
        'A few times a week — it’s basically my default when I’m tired.',
        _ci,
        ConvenienceImpulsePole.rideOrDeliveryReflex,
        'end-of-day convenience impulse',
      ),
      _mixed(
        'ci_open_rough_day',
        'Once or twice a week, usually after a rough day.',
        _ci,
        ConvenienceImpulsePole.looseUnmonitored,
        'fatigue-triggered, lower frequency',
      ),
      _good(
        'ci_open_rule',
        'Rarely — I’ve got a rough rule for myself, like “if it’s raining or past 9, delivery’s fine, otherwise I sort myself out,” and I mostly stick to it.',
        _ci,
        ConvenienceImpulsePole.preDecidedRule,
        'implementation-intention rule set in advance',
      ),
    ],
  ),
  _q(
    id: 10,
    dimension: _ci,
    branch: QuestionBranch.badDrill,
    scenario:
        'Think about the last month, specifically times you had food at home you could’ve made.',
    prompt: 'Be honest — how many times did you order delivery anyway?',
    answers: [
      _bad(
        'ci_bad_most_weeks',
        'More than I’d like to admit — it happens most weeks.',
        _ci,
        ConvenienceImpulsePole.rideOrDeliveryReflex,
        'delivery-over-available-food default',
      ),
      _mixed(
        'ci_bad_late_night',
        'A handful of times, usually late at night.',
        _ci,
        ConvenienceImpulsePole.looseUnmonitored,
        'late-night convenience impulse',
      ),
      _good(
        'ci_bad_meal_prep',
        'Almost never — I do a weekly grocery run or meal-prep, so there’s usually something ready to go, which makes cooking the easy option.',
        _ci,
        ConvenienceImpulsePole.preDecidedRule,
        'friction pre-commitment via batched meal prep',
      ),
    ],
  ),
  _q(
    id: 11,
    dimension: _ci,
    branch: QuestionBranch.goodDrill,
    scenario:
        'Think about how you actually decide whether a rideshare or delivery order is “worth it.”',
    prompt: 'Which is closest to how it goes?',
    answers: [
      _bad(
        'ci_good_in_the_moment',
        'I decide in the moment, mostly based on how I feel right then.',
        _ci,
        ConvenienceImpulsePole.rideOrDeliveryReflex,
        'no pre-set rule, decided at lowest-willpower moment',
      ),
      _mixed(
        'ci_good_loose_rule',
        'I’ve got a rough sense of when it’s worth it, but I don’t really check whether I’m actually sticking to it.',
        _ci,
        ConvenienceImpulsePole.looseUnmonitored,
        'informal rule, unmonitored',
      ),
      _good(
        'ci_good_spend_check',
        'I check my rideshare/delivery spend every month or so, and if it’s crept up, I dial it back on purpose.',
        _ci,
        ConvenienceImpulsePole.preDecidedRule,
        'periodic monitoring + active correction',
      ),
    ],
  ),
  _q(
    id: 12,
    dimension: _ci,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Think about a one-click checkout or “buy now” button — on a shopping app, a food app, anywhere.',
    prompt:
        'How often do you hit it before you’ve really decided you want the thing?',
    answers: [
      _bad(
        'ci_mix_rush_shipping',
        'Pretty often — I’ll pay for rush shipping or same-day just to avoid waiting a few days.',
        _ci,
        ConvenienceImpulsePole.rideOrDeliveryReflex,
        'pay-for-speed impulse',
      ),
      _mixed(
        'ci_mix_small_purchases',
        'Sometimes, mostly for stuff under \$20 where it doesn’t feel like it matters.',
        _ci,
        ConvenienceImpulsePole.looseUnmonitored,
        'small-purchase impulse tolerance',
      ),
      _good(
        'ci_mix_cooling_off',
        'Rarely — if I’m not sure, I leave it in the cart and check back the next day before buying.',
        _ci,
        ConvenienceImpulsePole.preDecidedRule,
        'deliberate delay/cooling-off habit',
      ),
    ],
  ),

  // ---------------------------------------------- D.3 Subscription Blindness
  _q(
    id: 4,
    dimension: _sb,
    branch: QuestionBranch.opening,
    scenario:
        'Think about the subscriptions and recurring charges on your card or bank statement right now — streaming, apps, memberships, delivery passes, anything on autopay.',
    prompt:
        'If you had to name every recurring charge on there from memory, how confident are you you’d get them all?',
    answers: [
      _bad(
        'sb_open_forgotten',
        'Not very — I’d bet there’s at least one I forgot I’m even paying for.',
        _sb,
        SubscriptionBlindnessPole.forgottenCharge,
        'forgotten recurring charge',
      ),
      _mixed(
        'sb_open_unused',
        'I could probably name most, but I’ve definitely got one or two I don’t actually use anymore.',
        _sb,
        SubscriptionBlindnessPole.neverAudits,
        'known-but-unused subscription, no follow-through',
      ),
      _good(
        'sb_open_recent_audit',
        'Pretty confident — I went through my statement line by line in the last few months and checked what’s actually on there.',
        _sb,
        SubscriptionBlindnessPole.recentAudit,
        'recent proactive subscription audit',
      ),
    ],
  ),
  _q(
    id: 13,
    dimension: _sb,
    branch: QuestionBranch.badDrill,
    scenario:
        'Think about the last time you actually sat down and looked through your recurring charges line by line.',
    prompt: 'When was that?',
    answers: [
      _bad(
        'sb_bad_never',
        'Honestly can’t remember — maybe never.',
        _sb,
        SubscriptionBlindnessPole.neverAudits,
        'never audits subscriptions',
      ),
      _mixed(
        'sb_bad_six_months',
        'It’s been at least 6 months, probably longer.',
        _sb,
        SubscriptionBlindnessPole.neverAudits,
        'infrequent/lapsed auditing',
      ),
      _good(
        'sb_bad_recent_with_recall',
        'I did it recently, and I can tell you roughly how many I’ve got and what they add up to.',
        _sb,
        SubscriptionBlindnessPole.recentAudit,
        'recent audit with recall of count/total',
      ),
    ],
  ),
  _q(
    id: 14,
    dimension: _sb,
    branch: QuestionBranch.goodDrill,
    scenario: 'Think about the last free trial you signed up for.',
    prompt: 'What actually happened when the trial was ending?',
    answers: [
      _bad(
        'sb_good_rolled_over',
        'It rolled into a paid subscription and I didn’t notice until later.',
        _sb,
        SubscriptionBlindnessPole.forgottenCharge,
        'status-quo bias, no trial-exit follow-through',
      ),
      _mixed(
        'sb_good_noticed_kept',
        'I noticed it converted, but I’ve just kept paying since canceling felt like a hassle.',
        _sb,
        SubscriptionBlindnessPole.neverAudits,
        'awareness without action, inertia',
      ),
      _good(
        'sb_good_cancelled_in_window',
        'I canceled before it converted, because I knew I wasn’t actually going to keep using it.',
        _sb,
        SubscriptionBlindnessPole.recentAudit,
        'successful trial-window cancellation',
      ),
    ],
  ),
  _q(
    id: 15,
    dimension: _sb,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Think about roughly how much you spend on subscriptions and recurring charges each month, all added up.',
    prompt: 'How sure are you of that number?',
    answers: [
      _bad(
        'sb_mix_no_idea',
        'I’ve genuinely got no idea — could be way more than I think.',
        _sb,
        SubscriptionBlindnessPole.forgottenCharge,
        'no aggregate awareness',
      ),
      _mixed(
        'sb_mix_rough_guess',
        'I could guess, but I’d honestly be surprised if I added it all up and it matched.',
        _sb,
        SubscriptionBlindnessPole.neverAudits,
        'low-confidence estimate',
      ),
      _good(
        'sb_mix_confident_estimate',
        'I’ve got a decent estimate — I can name roughly how many subscriptions I have and what they come to.',
        _sb,
        SubscriptionBlindnessPole.recentAudit,
        'aggregated subscription awareness',
      ),
    ],
  ),

  // --------------------------------------------------- D.4 Savings Avoidance
  _q(
    id: 5,
    dimension: _sa,
    branch: QuestionBranch.opening,
    scenario:
        'Think about the last time an unplanned expense in the few-hundred-to-a-thousand-dollar range actually hit you — a car repair, a vet bill, a broken phone. (If it’s been a while, picture it happening this week.)',
    prompt: 'How would you actually cover it?',
    answers: [
      _bad(
        'sa_open_no_buffer',
        'I’d have to put it on a card or borrow from someone — I don’t have that sitting anywhere.',
        _sa,
        SavingsAvoidancePole.noBuffer,
        'no emergency buffer',
      ),
      _mixed(
        'sa_open_thin_buffer',
        'I could cover it, but it would wipe out pretty much everything I’ve got saved.',
        _sa,
        SavingsAvoidancePole.thinBuffer,
        'thin/fragile buffer',
      ),
      _good(
        'sa_open_automated',
        'I’ve got at least one automatic transfer set up that moves money into savings without me having to think about it, so there’s usually something there.',
        _sa,
        SavingsAvoidancePole.automatedTransfer,
        'automated savings mechanism',
      ),
    ],
  ),
  _q(
    id: 16,
    dimension: _sa,
    branch: QuestionBranch.badDrill,
    scenario:
        'Think about the last time money landed in your account that wasn’t already spoken for — a bonus, a tax refund, extra freelance income, a gift.',
    prompt: 'What actually happened to most of it?',
    answers: [
      _bad(
        'sa_bad_absorbed',
        'It went to covering things I was already behind on, or just into everyday spending.',
        _sa,
        SavingsAvoidancePole.noBuffer,
        'extra income absorbed by gaps/spending',
      ),
      _mixed(
        'sa_bad_deferred',
        'I told myself I’d save it, but most of it got spent within a few weeks.',
        _sa,
        SavingsAvoidancePole.thinBuffer,
        'savings-intention that doesn’t survive contact with spending',
      ),
      _good(
        'sa_bad_redirected',
        'I moved at least some of it straight into savings before it had a chance to get absorbed into everyday spending.',
        _sa,
        SavingsAvoidancePole.automatedTransfer,
        'deliberate windfall redirection',
      ),
    ],
  ),
  _q(
    id: 17,
    dimension: _sa,
    branch: QuestionBranch.goodDrill,
    scenario:
        'Think about how money actually gets into your savings — not how you wish it worked, how it actually happens.',
    prompt: 'Which is closest to true?',
    answers: [
      _bad(
        'sa_good_no_mechanism',
        'It doesn’t, really — anything left over just stays in checking, if there’s anything left.',
        _sa,
        SavingsAvoidancePole.noBuffer,
        'no savings mechanism',
      ),
      _mixed(
        'sa_good_manual_only',
        'I move money over sometimes, but it’s a manual decision I have to remember to make each time.',
        _sa,
        SavingsAvoidancePole.thinBuffer,
        'savings depends on remembered manual action',
      ),
      _good(
        'sa_good_pay_yourself_first',
        'It’s automatic — a set amount moves to savings on payday whether I think about it or not.',
        _sa,
        SavingsAvoidancePole.automatedTransfer,
        'automated “pay yourself first” habit',
      ),
    ],
  ),
  _q(
    id: 18,
    dimension: _sa,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Think about whether you’ve got a specific savings goal in mind right now — an amount, a purpose, anything.',
    prompt: 'What’s closest to true?',
    answers: [
      _bad(
        'sa_mix_no_goal',
        'No real goal — I’m not really tracking toward anything specific.',
        _sa,
        SavingsAvoidancePole.noBuffer,
        'no named target',
      ),
      _mixed(
        'sa_mix_vague_goal',
        'I’ve got a rough goal in my head, but nothing written down or tracked.',
        _sa,
        SavingsAvoidancePole.thinBuffer,
        'informal, unmeasured goal',
      ),
      _good(
        'sa_mix_named_target',
        'I’ve got a specific number in mind for an emergency fund, and I can tell you roughly how close I am to it.',
        _sa,
        SavingsAvoidancePole.automatedTransfer,
        'named, tracked emergency-fund target',
      ),
    ],
  ),

  // ------------------------------------- D.5 Price-Anchoring / Status Spending
  _q(
    id: 3,
    dimension: _pa,
    branch: QuestionBranch.opening,
    scenario:
        'Think about the last few times you picked where to eat or drink with other people.',
    prompt:
        'When you’re picking the restaurant or the round, what usually happens?',
    answers: [
      _bad(
        'pa_open_priciest',
        'I gravitate toward the pricier or nicer-looking option without really comparing.',
        _pa,
        PriceAnchoringPole.priciestDefault,
        'default-to-priciest, no comparison',
      ),
      _mixed(
        'pa_open_upsell',
        'I’ll compare places first, but once I’m there I say yes to almost every add-on — the appetizer, the extra round, the upsell.',
        _pa,
        PriceAnchoringPole.upsellAccepter,
        'checkout-moment upsell acceptance despite comparing',
      ),
      _good(
        'pa_open_anchor',
        'I usually have a rough sense of what dinner out should cost before I even look at a menu, and I’ll speak up for the cheaper option if I think it’s gotten out of hand.',
        _pa,
        PriceAnchoringPole.priceAnchorSet,
        'pre-set price anchor + willingness to push back on group spend',
      ),
    ],
  ),
  _q(
    id: 19,
    dimension: _pa,
    branch: QuestionBranch.badDrill,
    scenario:
        'Think about the last big-ish purchase you made — a gadget, an appliance, plane tickets, anything over \$100 or so.',
    prompt:
        'When that came up, how much did you actually compare prices first?',
    answers: [
      _bad(
        'pa_bad_barely',
        'Barely — I saw something I liked and went with it.',
        _pa,
        PriceAnchoringPole.priciestDefault,
        'no price comparison, first-option anchoring',
      ),
      _mixed(
        'pa_bad_upgraded',
        'I compared a little, but ended up going with the nicer or more expensive version anyway.',
        _pa,
        PriceAnchoringPole.upsellAccepter,
        'upgrade-anchoring despite comparing',
      ),
      _good(
        'pa_bad_compared',
        'I compared prices at more than one place before deciding, even though it was a bit annoying to slow down and do it.',
        _pa,
        PriceAnchoringPole.priceAnchorSet,
        'deliberate comparison shopping despite friction',
      ),
    ],
  ),
  _q(
    id: 20,
    dimension: _pa,
    branch: QuestionBranch.goodDrill,
    scenario:
        'Think about the last time a group was splitting a bill or deciding where to go.',
    prompt: 'What was your actual role in that?',
    answers: [
      _bad(
        'pa_good_went_along',
        'I went along with whatever the group picked, even when I suspected it was pricier than I’d have chosen myself.',
        _pa,
        PriceAnchoringPole.priciestDefault,
        'social-loss-aversion driven passive overspend',
      ),
      _mixed(
        'pa_good_silent_compensation',
        'I noticed the cost but didn’t say anything — I just quietly ordered less to even things out.',
        _pa,
        PriceAnchoringPole.upsellAccepter,
        'self-correcting without addressing the group pattern',
      ),
      _good(
        'pa_good_spoke_up',
        'I spoke up for the cheaper spot or the smaller round — or I was glad someone else did.',
        _pa,
        PriceAnchoringPole.priceAnchorSet,
        'resistance to social-spending pressure',
      ),
    ],
  ),
  _q(
    id: 21,
    dimension: _pa,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Think about the things you actually spend on without much hesitation — versus the things you always double-check.',
    prompt: 'Which is closer to true?',
    answers: [
      _bad(
        'pa_mix_no_filter',
        'Honestly, not much distinction — if it looks appealing in the moment, price isn’t really part of the decision.',
        _pa,
        PriceAnchoringPole.priciestDefault,
        'no values-based spending filter at all',
      ),
      _mixed(
        'pa_mix_unexamined_split',
        'There’s a rough split, but I couldn’t really tell you what the pattern is.',
        _pa,
        PriceAnchoringPole.upsellAccepter,
        'some selectivity exists but isn’t conscious',
      ),
      _good(
        'pa_mix_values_anchored',
        'There’s a clear split — I’ll spend more on the couple of things I actually care about, and barely think twice about skipping the rest.',
        _pa,
        PriceAnchoringPole.priceAnchorSet,
        'values-based selective spending',
      ),
    ],
  ),

  // ------------------------------------------- D.6 Financial Avoidance
  _q(
    id: 6,
    dimension: _fa,
    branch: QuestionBranch.opening,
    scenario: 'Think about your bank or budgeting app right now.',
    prompt:
        'In a normal week, how often do you actually open it and look at your balance or recent transactions?',
    answers: [
      _bad(
        'fa_open_avoid',
        'Maybe once, if that — I mostly just... don’t.',
        _fa,
        FinancialAvoidancePole.routineAvoidance,
        'routine balance-checking avoidance',
      ),
      _mixed(
        'fa_open_skim',
        'A couple times, but I skim past anything that looks like a lower balance than I want.',
        _fa,
        FinancialAvoidancePole.acuteAvoidance,
        'selective/skimming avoidance',
      ),
      _good(
        'fa_open_weekly',
        'About once a week, pretty regularly — whether or not I’m expecting good news.',
        _fa,
        FinancialAvoidancePole.regularCheckIn,
        'fixed-cadence checking regardless of anticipated news',
      ),
    ],
  ),
  _q(
    id: 22,
    dimension: _fa,
    branch: QuestionBranch.badDrill,
    scenario:
        'Think about the last time you made a bigger purchase, or had a rough month financially.',
    prompt:
        'In the days right after that, what did you do with the app or your statements?',
    answers: [
      _bad(
        'fa_bad_avoided',
        'Avoided opening it for longer than usual — didn’t want to see the damage.',
        _fa,
        FinancialAvoidancePole.acuteAvoidance,
        'post-event avoidance spike',
      ),
      _mixed(
        'fa_bad_unread',
        'Let a notification or email about it sit unread for a while before I looked.',
        _fa,
        FinancialAvoidancePole.acuteAvoidance,
        'unread bill/notification avoidance',
      ),
      _good(
        'fa_bad_same_as_always',
        'Checked about the same as I always do — I didn’t put it off just because I expected it to look worse.',
        _fa,
        FinancialAvoidancePole.regularCheckIn,
        'checking cadence unaffected by anticipated bad news',
      ),
    ],
  ),
  _q(
    id: 23,
    dimension: _fa,
    branch: QuestionBranch.goodDrill,
    scenario:
        'Think about how you actually feel right before you open your banking app.',
    prompt: 'Which is closest to true most of the time?',
    answers: [
      _bad(
        'fa_good_dread',
        'A flicker of dread, most times — enough that I sometimes put it off.',
        _fa,
        FinancialAvoidancePole.routineAvoidance,
        'affective avoidance trigger',
      ),
      _mixed(
        'fa_good_indifferent',
        'Not dread exactly, more just... I don’t think about it until something prompts me to.',
        _fa,
        FinancialAvoidancePole.acuteAvoidance,
        'low salience, not avoidance but not routine either',
      ),
      _good(
        'fa_good_calm',
        'Pretty neutral, honestly — it’s just part of the routine, not something I brace for.',
        _fa,
        FinancialAvoidancePole.regularCheckIn,
        'habituated, low-anxiety engagement',
      ),
    ],
  ),
  _q(
    id: 24,
    dimension: _fa,
    branch: QuestionBranch.mixedClarify,
    scenario:
        'Think about a bill or statement notification landing in your inbox or mailbox.',
    prompt: 'What typically happens?',
    answers: [
      _bad(
        'fa_mix_overdue',
        'It sits there for a while — sometimes I don’t get to it until it’s overdue.',
        _fa,
        FinancialAvoidancePole.routineAvoidance,
        'chronic unread-bill backlog',
      ),
      _mixed(
        'fa_mix_few_days',
        'I usually open it within a few days, once I get around to it.',
        _fa,
        FinancialAvoidancePole.acuteAvoidance,
        'moderate delay, not chronic',
      ),
      _good(
        'fa_mix_prompt',
        'I usually open it within a day or so of it arriving.',
        _fa,
        FinancialAvoidancePole.regularCheckIn,
        'prompt bill/statement engagement',
      ),
    ],
  ),
];

/// Lookup by stable question ID.
final Map<int, MoneyStyleQuestion> moneyStyleQuestionsById = {
  for (final question in moneyStyleQuestionPool) question.id: question,
};

/// The six unconditional openers, in the order pages 1–2 present them
/// (design §C.3). Page 1 is the first three, page 2 the last three.
final List<MoneyStyleQuestion> moneyStyleOpeners = [
  ...kPageOneDimensions.map(_openerFor),
  ...kPageTwoDimensions.map(_openerFor),
];

MoneyStyleQuestion _openerFor(Dimension dimension) =>
    moneyStyleQuestionPool.firstWhere(
      (q) => q.dimension == dimension && q.branch == QuestionBranch.opening,
    );

/// Follow-up lookup keyed by (dimension, branch) — the routing function's
/// only entry point into the other 18 questions (design §F.2).
final Map<Dimension, Map<QuestionBranch, MoneyStyleQuestion>>
moneyStyleQuestionsByBranch = {
  for (final dimension in Dimension.values)
    dimension: {
      for (final question in moneyStyleQuestionPool.where(
        (q) => q.dimension == dimension,
      ))
        question.branch: question,
    },
};

MoneyStyleQuestion questionFor(Dimension dimension, QuestionBranch branch) =>
    moneyStyleQuestionsByBranch[dimension]![branch]!;
