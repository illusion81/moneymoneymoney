# Wealth Forest App Design

## Goal

Build a single-device Flutter MVP for a wealth-management habit app. On first launch, the user completes an economic questionnaire. The app generates a local AI-style wealth report from the answers, then uses that report to drive a forest-style habit loop: complete daily money actions to grow a tree, or receive a withered tree when the day is missed or spending exceeds the daily budget.

## Scope

This version is a local AI simulation. It does not call Gemini, OpenAI, or any external service. All generated report text, daily tasks, tree growth, penalties, and achievements are computed locally in Dart.

Persistent storage is out of scope for this first implementation. The MVP keeps state in memory while the app is running. A future version can add local persistence without changing the report generator and forest engine interfaces.

## Product Flow

1. First screen: the user answers an economic questionnaire.
2. Submit: the app generates a personalized wealth report.
3. Report screen: the user reads their financial profile, budget target, savings advice, risk note, and daily action list.
4. Start plan: the user enters the main Wealth Forest screen.
5. Daily check-in: the user enters today's spending and marks whether they completed the assigned money action.
6. Success: if the action is complete and spending is within the daily budget, today's tree grows.
7. Penalty: if the action is incomplete or spending exceeds the daily budget, today's tree becomes withered.
8. Achievements screen: the user sees streaks, healthy tree count, withered tree count, and unlocked achievements.

## Questionnaire

The onboarding form collects:

- Monthly income.
- Fixed monthly expenses.
- Monthly savings goal.
- Risk preference: conservative, balanced, or growth.
- Primary financial goal: emergency fund, reduce spending, save for purchase, invest, or debt control.
- Spending pressure: low, medium, or high.

Validation:

- Income must be greater than zero.
- Fixed expenses must be zero or greater.
- Savings goal must be zero or greater.
- Fixed expenses plus savings goal can exceed income, but the report must warn that the target is currently unrealistic.

## Local Report Generation

`ReportGenerator` consumes a `FinanceProfile` and returns a `WealthReport`.

The report includes:

- Profile summary.
- Monthly disposable income.
- Suggested daily flexible budget.
- Savings recommendation.
- Risk recommendation.
- Warning message when expenses and savings goal leave little or negative flexible money.
- Three daily actions tailored to the financial goal and spending pressure.

Rules:

- Disposable income is `monthlyIncome - fixedMonthlyExpenses`.
- Monthly flexible amount is `monthlyIncome - fixedMonthlyExpenses - monthlySavingsGoal`.
- Daily flexible budget is `max(monthlyFlexibleAmount / 30, 0)`.
- High spending pressure creates stricter action text.
- Conservative risk preference recommends cash buffer and low-volatility choices.
- Balanced risk preference recommends splitting between savings and broad investing education.
- Growth risk preference recommends long-term investing language but still warns against overspending.

## Forest Engine

`ForestEngine` owns the core daily habit logic.

Inputs:

- Current list of `ForestDay` records.
- The generated `WealthReport`.
- Today's spending.
- Whether today's action was completed.

Output:

- Updated `ForestDay` for today.
- Updated streak and achievement list.

Rules:

- If action completed and spending is less than or equal to the report's daily budget, status is healthy.
- If action is incomplete, status is withered.
- If spending exceeds the daily budget, status is withered.
- A healthy day increases streak by one.
- A withered day resets streak to zero.
- Tree level is 1 for the first healthy day, 2 for streaks of 3 or more, and 3 for streaks of 7 or more.
- Withered trees always display as level 0.

Achievements:

- First Sapling: unlocked after one healthy tree.
- Three Day Streak: unlocked after a streak of 3.
- Budget Guardian: unlocked after any healthy day with spending under 80 percent of the daily budget.
- Recovery Day: unlocked after a healthy day that follows a withered day.
- Forest Builder: unlocked after 7 healthy trees total.

## Screens

### Onboarding Screen

Purpose: collect questionnaire data and generate the report.

Controls:

- Numeric text fields for income, fixed expenses, and savings goal.
- Segmented or dropdown controls for risk preference, financial goal, and pressure level.
- Submit button.

Behavior:

- Shows validation messages inline.
- On valid submit, creates `FinanceProfile`, calls `ReportGenerator`, and navigates to the report screen.

### Report Screen

Purpose: show the AI-style generated wealth report before the habit loop starts.

Content:

- Financial profile summary.
- Daily budget.
- Savings guidance.
- Risk guidance.
- Warning, if applicable.
- Daily actions.
- Start button to enter the main app.

### Home Screen

Purpose: wealth forest habit loop.

Content:

- Large visual tree area.
- Today's status.
- Daily budget and action.
- Spending input.
- Complete action toggle.
- Check-in button.
- Bottom navigation to report and achievements.

Behavior:

- Successful check-in displays a healthy growing tree.
- Failed check-in displays a withered tree.
- The visual tree state updates immediately after check-in.

### Achievements Screen

Purpose: show progress and motivation.

Content:

- Current streak.
- Healthy tree count.
- Withered tree count.
- Achievement list with locked and unlocked states.

## Architecture

Use small Dart files grouped by responsibility:

- `lib/main.dart`: app shell, theme, and top-level state ownership.
- `lib/models/finance_profile.dart`: questionnaire model and enums.
- `lib/models/wealth_report.dart`: generated report model.
- `lib/models/forest_day.dart`: daily tree record and status enum.
- `lib/services/report_generator.dart`: local AI-style report generation.
- `lib/services/forest_engine.dart`: tree growth, penalty, streak, and achievement rules.
- `lib/screens/onboarding_screen.dart`: questionnaire UI.
- `lib/screens/report_screen.dart`: report UI.
- `lib/screens/home_screen.dart`: forest check-in UI.
- `lib/screens/achievements_screen.dart`: achievements UI.

The app remains dependency-light and uses Flutter Material components only.

## Visual Direction

The UI should feel like a calm personal finance tool rather than a marketing landing page. It should use green, gold, ink, and soft neutral surfaces with enough contrast for scanning. The first usable screen is the questionnaire, not a splash or sales page.

The tree visual can be built with Flutter widgets and icons in this MVP:

- Healthy level 1: small sapling.
- Healthy level 2: medium tree.
- Healthy level 3: mature tree.
- Withered: gray/brown withered tree state.

## Error Handling

- Invalid numeric form values block submission.
- Empty or unparsable spending input blocks check-in.
- Check-in explains whether failure came from missing the action, overspending, or both.
- Unrealistic budget profiles still generate a report, but show a warning and use a daily budget of 0.

## Testing Requirements

Unit tests:

- Report generation calculates disposable income and daily budget.
- Report generation produces warning text for unrealistic budgets.
- Forest engine marks a day healthy when action is complete and spending is within budget.
- Forest engine marks a day withered when action is incomplete.
- Forest engine marks a day withered when spending exceeds budget.
- Forest engine unlocks streak and budget achievements.

Widget tests:

- First app screen shows the questionnaire.
- Valid questionnaire submission shows a generated report.
- Starting the plan shows the forest home screen.
- Successful check-in changes the tree status text to healthy.
- Overspending changes the tree status text to withered.

## Future Extension Points

- Replace `ReportGenerator` with a real AI-backed service.
- Add local persistence with shared preferences, SQLite, or Hive.
- Add calendar history.
- Add notifications for daily check-ins.
- Add authentication and cloud sync.
