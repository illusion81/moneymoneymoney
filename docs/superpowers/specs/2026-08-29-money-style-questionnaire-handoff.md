# Money Style Questionnaire — Product and Psychology Handoff

**Status:** design recommendation; no product implementation included

**Audience:** product, questionnaire psychology/research, content design, and engineering teams

## 1. Decision

Replace the calculator-first onboarding with **Discover your Money Style**: a short, entertaining, SBTI-style behavioural reflection for financially stressed adults.

The experience should give a shareable, strengths-led archetype before it asks for any financial amounts. It must never present itself as a clinical assessment, a measure of financial competence, or financial advice.

The selected direction is intentionally distinct from a budget calculator:

```
current: exact income/expenses/savings -> report -> plan
proposed: everyday scenarios -> Money Style archetype -> optional ideas -> optional plan ranges -> exact values only by user choice
```

## 2. Findings from the current prototype

The current entry form asks for exact monthly income, fixed expenses, and a savings goal before users receive value. It also labels users using `risk preference` and `recent spending pressure`. For financially stressed adults, this can feel evaluative, exposing, and prematurely prescriptive.

The current report then converts those values into a daily budget and gives direct instructions such as protecting savings before flexible spending, avoiding new debt, or learning investment basics. This is too forceful for the revised entry moment.

The product opportunity is not to conceal a budget calculator under a personality quiz. It is to build trust first, offer recognition, then obtain consent for increasingly concrete financial support.

## 3. Product principles

1. **Earn precision.** Do not request numerical data before the archetype result.
2. **Recognise, do not diagnose.** The result describes a current money style, not a personality truth, disorder, score, or capability ranking.
3. **Make every option dignified.** Each answer must be plausible for someone with limited money, time, energy, privacy, or support.
4. **Punch up at money chaos, never down at the user.** Humour can be self-aware and slightly sarcastic; it cannot ridicule hardship, debt, work status, emergency spending, identity, or self-control.
5. **Result before remediation.** The first result is archetype plus strengths only. Advice, plans, and financial data are opt-in second steps.
6. **Keep scope factual.** Later product flows may provide calculations, trends, reminders, and user-controlled scenarios. They must not make personalised recommendations about financial products.

## 4. Experience specification

### 4.1 Entry screen

- Title: **Discover your Money Style**
- Supporting line: **Twelve everyday choices. No dollar amounts. No judgement.**
- Time expectation: **about 2–3 minutes**
- Required disclosure: **A light reflection on your current habits — not financial, mental-health, or clinical advice.**
- Primary action: **Find my style**
- Do not use: `Money Profile`, `assessment`, `risk preference`, `spending pressure`, `wealth report`, or a numerical form on this screen.

### 4.2 Question interaction

- 12 questions; one scenario per screen.
- Three responses per question; use `What feels closest?`, never `What should you do?`.
- Include a visible **Skip for now** action. Skips lower result confidence but never block a result.
- Show progress, for example `4 of 12`; do not display a score.
- Randomise answer order and mix the behavioural direction of questions to limit social-desirability answering.
- Do not collect income, debt balances, credit score, employment, household status, bank data, or savings amount in this flow.

### 4.3 Result interaction

1. Archetype reveal.
2. One playful descriptor.
3. Three specific strengths.
4. Short neutral interpretation of the selected patterns.
5. Optional action: **Explore ideas that fit my style**.
6. Separate optional action: **Build a practical plan with ranges, not exact numbers**.

There is no weakness list, warning, risk rating, percentile, compatibility score, or corrective action on the initial result screen.

## 5. Behavioural framework for questionnaire psychologists

This is a product taxonomy, not a validated psychometric instrument. Psychologists should use it to draft and test item language, not to claim diagnostic, clinical, or financial-literacy validity.

| Product dimension | High-level poles | Purpose |
| --- | --- | --- |
| Money rhythm | steady routines / responsive bursts | How people regain footing when plans change. |
| Decision style | pause-and-compare / momentum-and-decide | How people approach discretionary or time-sensitive choices. |
| Support style | self-directed / collaborative reassurance | How people seek information, reassurance, or accountability. |

Use four items per dimension. One response can contribute to a primary pole and, at most, a pre-defined tie-breaker. Do not derive hidden hardship scores, emotional-health claims, debt-risk labels, or intervention eligibility from these answers.

## 6. Draft question briefs

These are content briefs, not final validated items. The research team owns final wording and answer mapping.

| # | Everyday scene | What it should explore |
| --- | --- | --- |
| 1 | An automatic payment is due tomorrow at inconvenient timing. | First recovery response. |
| 2 | A limited-time offer appears for something useful-ish. | Pause, compare, or decide momentum. |
| 3 | An unexpected $120 cost appears in an ordinary week. | Flexibility without judging financial capacity. |
| 4 | A friend suggests a last-minute social plan. | Boundaries and social spending navigation. |
| 5 | You receive a small amount of unexpected money. | Security, enjoyment, or purposeful allocation instincts. |
| 6 | A money task has been sitting in the background for a week. | Task-start rhythm, not procrastination labelling. |
| 7 | You notice a subscription or recurring charge you barely use. | Review and follow-through style. |
| 8 | A purchase leaves you with a mixed feeling afterwards. | Reflection style without shame. |
| 9 | You are choosing between two acceptable ways to pay for something. | Information gathering and decision confidence. |
| 10 | A family member or friend mentions money stress. | Social support orientation and boundaries. |
| 11 | Your week becomes busier than expected. | How financial routines flex under load. |
| 12 | You imagine a calmer money week. | Preferred sense of control and support. |

### Required answer-writing pattern

Each option must describe an immediate, recognisable response and be equally respectful. Example:

> **Scene:** An automatic payment is due tomorrow. Rude timing.
>
> **Prompt:** What feels closest to your first move?
>
> - I check what can move around, then make a small plan.
> - I handle the payment and sort the rest when I have more headspace.
> - I talk it through with someone before deciding what to shift.

Avoid questions or answers that assume disposable cash, stable income, a partner, family assistance, banking access, or the ability to make an automatic transfer.

## 7. Archetype system

Launch with eight archetypes. Eight is sufficiently shareable while preventing the false precision of a large unvalidated typology.

| Archetype | Strength-led copy direction |
| --- | --- |
| The Steady Improviser | Makes a workable plan even when the universe does not cooperate. |
| The Quiet Builder | Trusts small moves that become stronger over time. |
| The Calm Comparator | Lets a decision breathe before it becomes a purchase. |
| The Momentum Maker | Finds a next step without waiting for ideal conditions. |
| The Resourceful Resetter | Rebuilds after a disrupted plan rather than abandoning it. |
| The Community Navigator | Knows money decisions do not need to be a solo endurance sport. |
| The Flexible Pathfinder | Adapts quickly as circumstances change. |
| The Intentional Protector | Naturally seeks stability and breathing room. |

### Copy guardrails

Permitted:

- `Your plan may be a living document, but at least it is alive.`
- `Small moves, suspiciously powerful results.`
- `You make room for everyone; future-you appreciates a calendar invite too.`

Prohibited:

- Any joke about being poor, broke, careless, lazy, impulsive, indebted, unemployed, dependent, traumatised, or financially illiterate.
- Claims that an archetype predicts outcomes or reveals the user's true personality.
- Content that pressures the user to disclose exact financial data to improve their result.

## 8. Scoring and confidence rules

- Score the three dimensions only; map the resulting pattern to one of eight archetypes.
- Use pre-defined tie-breakers rather than a model that infers additional traits.
- Retain an answer-level explanation so the product can explain an archetype in plain language.
- With 0–3 answers, show an `early snapshot` result and invite the user to answer more later; do not fabricate certainty.
- With 4–8 answers, use the standard result with a low-key `based on what you shared today` qualifier.
- With 9–12 answers, use the standard result without numerical confidence language.
- The app must never display raw dimension scores or label one pole better than the other.

## 9. Research, ethics, and validation gates

Before implementation or launch, the psychology team should complete:

1. **Item review:** inspect every scenario for shame, socioeconomic assumptions, cultural specificity, and implied moral ranking.
2. **Cognitive interviews:** test with financially stressed adults. Ask participants to paraphrase each question and explain how each option made them feel.
3. **Comprehension and consent test:** verify participants understand the quiz is entertainment-style reflection, not expert financial or mental-health advice.
4. **Harm review:** specifically test reactions from people experiencing debt, irregular income, caregiving load, disability, recent hardship, or unsafe relationship dynamics.
5. **Result acceptance study:** measure whether users feel recognised rather than judged, whether the archetype is shareable, and whether the optional next step feels voluntary.
6. **Scoring review:** confirm that tied or skipped responses cannot create stigmatising or implausible results.

Do not set a launch threshold until the research team defines a measurement method, sample, and acceptable outcome. Do not claim psychological validity based on completion or sharing alone.

## 10. Data and privacy boundaries

- Store only the minimum required to render a result and improve the product with consent.
- Product analytics may record completion, skips, aggregate archetype distribution, voluntary plan opt-in, and explicit feedback.
- Do not infer income, debt, financial distress, or vulnerability from the archetype.
- Keep personality-style responses separate from any later financial-data import, account connection, or transaction record.
- If the user opts into a later plan, use ranges first. Request exact values only where a calculation cannot be completed otherwise and explain why each value is needed.

## 11. Explicitly out of scope for this handoff

- A clinical or validated psychological assessment.
- Creditworthiness, affordability, debt-risk, hardship, or fraud scoring.
- Product recommendations for loans, investments, insurance, credit cards, or mortgages.
- Automatically connecting accounts or importing financial data from the personality result.
- Replacing the later budgeting or data-reconciliation workflow.

## 12. Product implementation implications (not authorised by this document)

When the team is ready to build, the existing onboarding and report flow will need to be split into independent components:

1. `MoneyStyleQuiz`: scenarios, answers, skips, local progress, and result mapping.
2. `ArchetypeResult`: reveal, strengths, disclosure, and opt-in calls to action.
3. `OptionalPlanIntake`: ranges first, then explicit consent for exact data.
4. `BudgetReport`: current calculation engine, reworded as an optional planning surface.

Do not directly retrofit the current exact-number form as the first quiz screen.

## 13. Acceptance checklist for the next design review

- [ ] Psychology team approves all 12 final questions and their answer mappings.
- [ ] Content design approves the humour and prohibited-language checks.
- [ ] Product approves the eight archetypes and result-only strengths policy.
- [ ] Research confirms the disclosure, skip behaviour, and test protocol.
- [ ] Engineering receives a separate approved implementation plan.
