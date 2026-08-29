# Money Style System Redesign — Research-First Implementation

**Date:** 2026-08-29  
**Scope:** Audit findings (F-01 through F-09) fixed via research-informed parameter system redesign  
**Outcome:** New personality-to-archetype model with no internal contradictions, migration-safe persistence, integrated defect repairs  
**Agent Autonomy:** Make reasonable calls; document in commit messages; follow existing repo patterns  

---

## Executive Summary

The Money Style onboarding flow has 9 documented findings ranging from critical (fabricated traits from empty sessions, 2:1 scoring bias) to medium (missing persistence, UI stubs). Rather than patch each defect, this design:

1. **Research phase:** Explore validated financial personality frameworks (Big Five, MBTI financial variants, behavioral studies)
2. **Diagnosis:** Analyze current system contradictions in light of research findings
3. **Redesign:** Propose new parameter system grounded in research, no internal contradictions
4. **Integrated implementation:** Fix audit findings while building new system; migrate old data safely

Raw `AnswerSession` objects are the source of truth (never deleted), so results recompute automatically after any scoring fix.

---

## Context

**Audit findings:** See `docs/superpowers/reports/2026-08-29-money-style-onboarding-audit.md`

**Current system state:**
- 3 binary dimensions: Money Rhythm (steady/responsive), Decision Style (pause/momentum), Support Style (self-directed/collaborative)
- 8 archetypes (2³)
- Question bank: 12 questions × 3 answers each
- Imbalance: 4 steady / 8 responsive (and same for other dimensions) — 2:1 bias
- Scoring: simple tally, no weighting
- Confidence: `earlySnapshot` if ≤3 answers, `fullClarity` if 12+
- Persistence: none (in-memory only)
- Backend: no `/api/money-style` endpoint

**Critical defects:**
- **F-01:** Empty session produces "The Calm Comparator" from hardcoded tie-break defaults
- **F-02:** 4/8 distribution biases toward majority pole 2:1 across all dimensions
- **F-03:** Header comment claims 6/7 and 6/5 splits (impossible, since each dimension = 12 answers)
- **F-04:** Minority pole always `answers[0]`, compounded by socially-desirable wording; primacy bias masks F-02
- **F-05:** No persistence; navigating away loses session permanently
- **F-06:** Result screen CTAs are stubs ("coming soon")
- **F-07:** Exact-number financial form shown first, Money Style quiz buried inside it
- **F-08:** (Outside Money Style proper) `hasEmergencyFund` inferred from *not* selecting emergency fund as a goal
- **F-09:** Test suite doesn't cover empty session or pole balance; widget tests make live HTTP calls

---

## Phase 1: Research

### Objectives

Gather evidence on what personality dimensions actually predict financial outcomes, how validated systems structure them, and what confidence/certainty models exist.

### Research Scope

**Frameworks to explore:**
- Big Five (OCEAN) and its application to financial behavior
- MBTI and financial personality variants
- Existing fintech personality systems (robo-advisors, budgeting apps, financial wellness platforms)

**Studies to research (Google Scholar):**
- Financial decision-making and personality
- Spending discipline and personality traits
- Risk tolerance measurement
- Social influence on financial choices
- Confidence and decision quality in financial contexts

**Output document:** `docs/research/financial-personality-frameworks.md`

Should include:
- Summary of each framework (Big Five, MBTI, others)
- How each maps behavior → archetypes
- Which dimensions predict financial outcomes with empirical support
- Confidence/certainty models from validated systems
- Gaps in the current system relative to research

### Success Criteria

- Research summary is specific (not generic personality intro), citing studies
- Proposes concrete dimension/parameter candidates for new system
- Identifies which dimensions can be reliably scored from quiz responses

---

## Phase 2: Diagnosis

### Objectives

Analyze current system contradictions in light of research findings.

### Diagnosis Tasks

1. **Map current system to research:** Where does current 3D model align with validated frameworks? Where does it diverge?
2. **Identify root causes of F-02/F-03:** Why is the bank imbalanced 4/8? Was it intentional, oversight, or fundamental design flaw?
3. **Evaluate dimension choices:** Are Rhythm, Decision Style, and Support Style the right dimensions to score financial behavior? Or does research suggest different parameters?
4. **Assess confidence logic:** Does current `earlySnapshot` / `fullClarity` model match validated confidence scoring?

### Output Document

`docs/research/system-diagnosis.md`

Should include:
- How current system contradicts research findings
- Whether 3 dimensions is the right structure, or if new system should have different dimensionality
- Specific recommendations for new parameter names and poles
- Updated archetype taxonomy (how parameters map to user archetypes)
- Validation criteria (how to measure whether new system is better)

### Approval Gate

**You review diagnosis doc before implementation proceeds.** If findings suggest a different structure than expected, this is the point to redirect before code changes.

---

## Phase 3: Parameter System Redesign

### Deliverables

Based on research + diagnosis, define:

1. **Parameter structure** (exact names, poles, rationale):
   - Example: if research supports 3 dimensions, they might be named differently (e.g., "Spending Discipline" instead of "Rhythm")
   - Or: if evidence suggests 4-5 dimensions, update structure accordingly
   - Each parameter has two poles; each pole should have 50% representation in question bank

2. **Question bank** (`lib/data/money_style_questions.dart`):
   - Update 12 questions to map cleanly to new parameters
   - No internal contradictions: each question maps exactly one parameter
   - Answers randomized (not fixed to minority-pole-first)
   - Balanced: 6 answers per pole per parameter across 12 questions
   - Removed: header comments that don't match actual data

3. **Archetype taxonomy** (`lib/models/money_style_archetype.dart`):
   - If 3 dimensions: 8 archetypes (2³)
   - If 4 dimensions: 16 archetypes (2⁴), or combine into 8-12 if research suggests clustering
   - Each archetype: name, description, financial profile (what this archetype typically does)
   - Rationale: why this grouping makes sense for financial planning

4. **Scoring logic** (`lib/services/money_style_parameters.dart`):
   - Input: `AnswerSession` (raw user answers)
   - Output: `ParameterResult` (scores per parameter + archetype)
   - Logic: tally answers per parameter, no weighting (keep it simple)
   - Confidence model: how confident are we in the result? (related to answer count, answer variance)

### No Internal Contradictions Requirement

- Question bank counts must match header comment
- Answer distribution must be verifiable (6/6 per parameter)
- Archetype naming/description must be internally consistent
- Scoring logic must be deterministic (same answers → same archetype, always)

---

## Phase 4: Implementation

### Defect Fixes (in order)

1. **F-01 (Critical): Gate empty result**
   - Make `MoneyStyleEngine.generateResult()` return `ParameterResult?` instead of non-nullable
   - Return null if insufficient answers to compute any parameter (e.g., < 3 answers)
   - Add test: empty `AnswerSession` → returns null, not a default archetype

2. **F-02/F-03/F-04 (Critical/High): Rebalance + randomize**
   - Update question bank to new structure (already described in Phase 3)
   - Fix header comment to match actual counts
   - Randomize answer order (don't assume `answers[0]` is minority pole)
   - Add test: answer counts are 6/6 per parameter across all 12 questions

3. **F-05 (High): Persist raw session**
   - Create `MoneyStyleCompletion` model: holds both raw `AnswerSession` and optional `ParameterResult`
   - Save to `shared_preferences` under key `money_style_completion`
   - Add `POST /api/money-style` endpoint (FastAPI): accepts `AnswerSession`, returns persisted ID
   - Add test: session persists across app restart

4. **F-06 (Medium): Wire result screen**
   - "Explore ideas" CTA: navigate to ideas page (stub implementation OK: show snackbar "ideas page - coming soon")
   - "Build a plan" CTA: navigate to plan builder (stub: "plan builder - coming soon")
   - Both replaceable later without changing Money Style code

5. **F-07 (Medium): Move Money Style to first-run**
   - Update `lib/main.dart`: `AppView.onboarding` → `AppView.moneyStyleQuiz` (new view)
   - After quiz completion, offer exact-number form as explicit next step (not required)
   - Rationale: earn trust via personality quiz before asking for exact financial data

6. **F-08 (Medium, optional): Survey adapter logic**
   - `lib/data/survey_adapter.dart:42`: `_hasBuffer` currently infers buffer from *not* selecting emergency fund
   - Fix: change to explicit "Do you have an emergency buffer?" question or default to false
   - Rationale: don't infer financial facts from absence of selection
   - **Flag:** If this touches allocation logic downstream, flag for your review before committing

7. **F-09 (Medium): Test suite**
   - Add unit tests: empty session, pole balance, confidence tiers
   - De-network widget tests: mock HTTP calls instead of making live requests
   - Ensure `flutter test` passes with no console errors

### File Changes Summary

| File | Change | Reason |
|------|--------|--------|
| `lib/services/money_style_parameters.dart` | **New** | Parameter definitions, scoring logic |
| `lib/models/money_style_archetype.dart` | **New** | Archetype definitions, financial profiles |
| `lib/data/money_style_questions.dart` | **Update** | New questions, balanced answers, randomized order |
| `lib/services/money_style_engine.dart` | **Update** | Use new parameters, nullable return for empty session |
| `lib/models/money_style_completion.dart` | **New** | Raw session + optional result (persistence model) |
| `lib/main.dart` | **Update** | Money Style quiz as first-run view |
| `lib/screens/money_style_result_screen.dart` | **Update** | Wire CTA handlers |
| `lib/data/survey_adapter.dart` | **Update** | Fix `_hasBuffer` logic (F-08, optional) |
| `test/money_style_engine_test.dart` | **Update** | Add pole balance, empty session, confidence tests |
| `test/widget_test.dart` | **Update** | De-network, mock HTTP calls |
| `docs/research/financial-personality-frameworks.md` | **New** | Research summary (Phase 1) |
| `docs/research/system-diagnosis.md` | **New** | Diagnosis analysis (Phase 2) |

---

## Phase 5: Migration Strategy

### Design Principle

**Raw `AnswerSession` is the source of truth.** Results are computed, never stored. This guarantees recomputation after any scoring fix.

### Migration Flow

1. **Old data:** Existing sessions stored only as `AnswerSession` (or reconstructed from answers)
2. **On app upgrade:** Old answer sessions are loaded; results recomputed under new parameter system automatically
3. **Storage:** New system persists `MoneyStyleCompletion(rawSession, computedResult)` to both local (`shared_preferences`) and backend (`/api/money-style`)
4. **No data loss:** Old answers + old results both retained; new system generates new results alongside

### Testing

- Add migration test: load old-format answer session → verify it recomputes under new model
- Verify backward compatibility: if stored session lacks certain fields, graceful degradation

---

## Phase 6: Testing & Verification

### Unit Tests

**File:** `test/money_style_engine_test.dart`

- ✓ Empty session returns null (not default archetype)
- ✓ Parameter balance: exactly 6/6 per parameter across 12 questions
- ✓ Confidence tiers: match validated model (e.g., if ≤3 answers → low confidence)
- ✓ Answer randomization: presenting same question multiple times produces varying answer positions
- ✓ Scoring determinism: same `AnswerSession` always produces same `ParameterResult`
- ✓ Archetype assignment: parameter values deterministically map to archetypes

### Integration Tests

**File:** `test/money_style_integration_test.dart` (new)

- ✓ First-run flow: launch → Money Style quiz → completion screen → result persists locally
- ✓ Backend persistence: completed session sent to `/api/money-style`, returns ID
- ✓ Migration: old-format answer session recomputed under new model

### Widget Tests

**File:** `test/widget_test.dart`

- ✓ Flow from app launch → Money Style quiz → result screen (no network calls)
- ✓ Result screen CTA navigation (both stubs should not crash)
- ✓ De-networked: mock HTTP calls; test passes regardless of backend availability

### Verification Gates

**Before marking complete:**
- ✓ `flutter analyze` → "No issues found!"
- ✓ `flutter test` → all tests pass (0 failures)
- ✓ `flutter build apk` → builds successfully
- ✓ Audit findings F-01 through F-07 are no longer possible:
  - Can't produce trait from empty session (F-01)
  - Can't observe 2:1 bias in random answering (F-02)
  - Question bank header matches reality (F-03)
  - Answer order is randomized (F-04)
  - Session persists across restart (F-05)
  - CTA handlers are wired (F-06)
  - Money Style is first-run view (F-07)

---

## Commit Strategy

**Each commit should:**
- Address one specific concern (research, diagnosis, rebalance, gate, persist, etc.)
- Include a clear message: what changed and why
- Reference audit findings when applicable (e.g., "fixes F-01: gate empty result")
- Note any agent decisions made during implementation

**Recommended order:**

1. `docs: research financial personality frameworks` — Research summary (Phase 1 output)
2. `docs: diagnose Money Style system against research` — Diagnosis document (Phase 2 output)
3. `refactor: redesign Money Style parameter system` — New parameter/archetype models (Phase 3 output)
4. `refactor: rebalance question bank, fix header comment` — F-02/F-03 fixes
5. `feat: randomize answer presentation order` — F-04 fix
6. `feat: gate empty result with null return` — F-01 fix
7. `feat: persist money style session locally` — F-05 (local storage)
8. `feat: add money style backend persistence` — F-05 (backend `/api/money-style`)
9. `feat: wire result screen actions` — F-06 fix
10. `feat: move money style quiz to first-run view` — F-07 fix
11. `test: add money style parameter + integration tests` — Phase 6 test coverage
12. `fix: correct survey adapter emergency fund logic` — F-08 (optional)

---

## Success Criteria

1. **No internal contradictions:** Question bank counts match reality; parameter balance is 6/6; archetype mapping is deterministic
2. **All audit findings resolved:** F-01 through F-07 are no longer possible; F-08/F-09 are addressed or explicitly deferred
3. **Persistence works:** Session survives app restart and backend roundtrip
4. **Tests pass:** `flutter test` → 0 failures; coverage includes pole balance and empty session
5. **Research-grounded:** Parameter system is informed by validated frameworks, with rationale documented
6. **Migration-safe:** Old sessions recompute under new model without data loss
7. **Agent-autonomous:** All commits and decisions are documented in commit messages; no back-and-forth needed

---

## References

- Audit report: `docs/superpowers/reports/2026-08-29-money-style-onboarding-audit.md`
- Existing repair plan: `docs/superpowers/plans/2026-08-29-money-style-onboarding-repair.md`
- Engine code: `lib/services/money_style_engine.dart`
- Question bank: `lib/data/money_style_questions.dart`
- Result screen: `lib/screens/money_style_result_screen.dart`
- App entry: `lib/main.dart`
- Survey adapter: `lib/data/survey_adapter.dart`

---

## Sign-Off

**Spec reviewed and approved by:** [user name/date]

**Agent implementation window:** [start/end dates if applicable]

**Notes:** [any special constraints or exceptions]
