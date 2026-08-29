# Economy Reconciliation Decision: Forest Client vs. Tower Server

**Date:** 2026-08-29  
**Decision:** Adopt server-authoritative architecture. Migrate progression compute from client (Forest) to server (Tower), use Forest's cosmetic-only shop boundary, Tower's mission-based dynamic progression, and Tower's fairness rules. Retire the client-side fixed-point loop and Tower's progression accelerator item once migration completes.

---

## Summary

The `feat/progression-economy` branch and `main` have grown two parallel, incompatible economies:

1. **Forest (client-side, this branch):** XP/coins recomputed client-side from daily history, 8 static rule-based achievements, cosmetic shop, restoration mechanic, 4-pass fixed-point convergence loop to reconcile achievement unlocks with progression.
2. **Wealth Tower (server-side, main):** XP/coins would be server-authoritative but currently in-memory only, mission-based dynamic progression from spending categories, includes a progression-accelerator shop item (`boost-double`), fairness rule framework (FAIR_GAME/PROTECTED spend categories).

Both are incomplete and incompatible at the architecture level. This document resolves the conflict by deciding: **server-authoritative for trustworthiness and auditability**, pulling the best features from each side.

---

## Feature-by-Feature Verdict

### XP curve & leveling
| Aspect | Verdict |
|--------|---------|
| **Forest** | Rejected as final. Formula `100(L-1)+25(L-1)(L-2)` is mathematically elegant (closed-form pair, self-consistent by construction), fully test-covered, max level 50. But the quadratic coefficient makes late levels grind-heavy; backend players hit level 50 quickly if running Tower's curve in parallel. |
| **Tower** | Rejected. Formula `100 × N^1.35` has nice front-loaded feel (40 XP for level 2, 100 XP for level 3, motivates early play), but zero test coverage and demo-only validation against a hardcoded user. |
| **Decision** | Use Forest's closed-form structure (correct by construction, testable) but tune the constants. Lower the quadratic coefficient, cap at level 30–40 instead of 50, to match Tower's faster early progression feel. Implement and validate server-side; client just displays the level. |

### Achievement / mission concept
| Aspect | Verdict |
|--------|---------|
| **Forest** | Rejected as sole mechanism. 8 inline-predicate achievements (first sapling, 3-day streak, budget guardian, recovery day, forest builder, second wind, curator, seedling scholar) are deterministic and auditable but static and binary — they never adapt to a user's actual spending patterns or weak spots. |
| **Tower** | **Winner**. `missions.py::generate()` creates missions dynamically from real transaction history (subscription-sweep, cook-at-home, BNPL break, bucket-shortfall, daily checkin, buffer-building). The `verified` field allows both self-reported and audited missions. Untested but more honest to the user's actual situation than static rules. |
| **Decision** | Adopt Tower's mission generator wholesale. Port `missions.py` logic as a pure function onto the server progression compute (it mostly already is). Sunset Forest's 8 static achievements once the server API serves missions; keep the achievement model but populate it from missions at compute time. Add test suite matching Forest's 44-test baseline. |

### Shop model & monetization boundary
| Aspect | Verdict |
|--------|---------|
| **Forest** | **Winner**. 11 cosmetic-only items, level-gated (sky background, tree skin variants, ground effects). `ShopItemCategory` enum has no non-cosmetic case — type-level enforcement means a pay-to-win item can't be added without a schema change. Correct principle. |
| **Tower** | Rejected. SHOP includes `{"id": "boost-double", "name": "Double XP Weekend", "cost": 150, "kind": "booster", "description": "2x mission XP for 48 hours."}` — a coin-priced progression accelerator that violates cosmetic-only. Currently dead code (`/api/shop/buy` only handles `kind=="skin"`), but the item exists and represents a design risk. |
| **Decision** | Keep Forest's cosmetic-only category enum. Delete `boost-double` from Tower's SHOP. Extend Forest's shop frontend with Tower's ability to preview/compare multiple cosmetics at once (UX win). |

### State authority / persistence — **DECIDED: server-end**
| Aspect | Verdict |
|--------|---------|
| **Forest** | Rejected. In-memory client state (recomputed from `days` history each call, nice purity property), lost on app restart, not tamper-resistant, no cross-device sync. Wrong tier for anything users perceive as "real" progress (XP/level/coins should not be trustable if computed purely on-device). |
| **Tower** | **Winner in principle, incomplete in practice**. Server-authoritative is the correct tier for a fintech app (XP/coins/achievements shouldn't be trustable if computed on-device; users expect server backup). But `store.py` today is a single in-memory dict keyed to hardcoded `demo` user — not durable, not multi-user, not real persistence. |
| **Decision** | **Adopt Tower's server-authoritative tier as architecture.** Move `ProgressionEngine.compute()` (the recompute-from-history pattern — it's correct regardless of tier) into `backend,dataAPI/engine/progression.py`. Back it with real per-user persistence (SQLite/Postgres, per `store.py`'s own stated roadmap). Make Flutter client a thin display/API-client layer that calls `/api/progression` for XP/coins/achievement state rather than computing locally. Compute is deterministic from source data (days/missions) on every request; no stored deltas. |

### Restoration / recovery mechanic
| Aspect | Verdict |
|--------|---------|
| **Forest** | **Winner, with a one-line fix required**. Design is sound (escalating cost 60→150, 30-day window cap, recovery note required, restored days never retroactively award XP/coins — honest record). Spec and boundary-tested. BUT has confirmed off-by-one bug (window should be 0–6 days, not 0–7) at `forest_engine.dart:162`, fixed in Part 1. |
| **Tower** | Not used. No equivalent concept. |
| **Decision** | Port Forest's restoration mechanic server-side as-is with the Part 1 fix applied. Coins deducted server-side at restoration time, day marked restored in the events log. |

### Fairness rules
| Aspect | Verdict |
|--------|---------|
| **Forest** | Rejected as sole source. No explicit fairness rule. All thresholds applied uniformly; doesn't address low-income users, who may not have discretionary spend to cut. |
| **Tower** | **Winner**. `FAIR_GAME = {"subscriptions", "eating-out", "lifestyle", "bnpl", "other"}` / `PROTECTED = {"housing", "utilities", "groceries", "health", "education", "transport"}` enforces that missions never target essentials. Principled, documented, and grounded in user research ("fairness answer when a judge asks about low-income users"). |
| **Decision** | Adopt wholesale. Make enforcement structural: assert in mission generation that no mission's category target is in PROTECTED, so it's a build-time guarantee, not a runtime filter. |

### Presentation / metaphor
| Aspect | Verdict |
|--------|---------|
| **Forest** | **Winner** for base app tone. Forest/tree/streak metaphor is warm, low-stakes, matches a daily-habit product, composes cleanly with existing screens/onboarding/animations. |
| **Tower** | Rejected for the base app but notable. Tower stage/health/weather is smart for visualizing multi-bucket plan adherence (richer than Forest's healthy/withered binary), but heavier metaphor that requires full re-skin. |
| **Decision** | Keep Forest's tree/forest metaphor as primary for the client. Layer Tower's "weather" signal as a secondary visual (clear/overcast/storm) derived from per-bucket plan adherence (`adherence >= 0.8` → clear, etc.). Enhances the tree metaphor without replacing it. |

### Reconciliation / computation strategy
| Aspect | Verdict |
|--------|---------|
| **Forest** | Rejected as implemented. `main.dart::_recomputeProgression` fixed-point-iterates for 4 passes, then silently exits even if unconverged. Worst-case cycle (Curator ← shop, Seedling Scholar ← level, level ← achievement XP) consumes exactly 4 passes with zero margin. Part 1 fixed this with budget→6 + assertion, but it's a symptom, not a solution. |
| **Tower** | Not applicable on client. Server-side missions don't feed back into progression (missions just have static XP/coins values, achievement list is separate), so no cycle. |
| **Decision** | **Short-term (before server migration):** Partition achievements into forest-derived (no progression dependency: first sapling, streak, budget guardian, recovery day, forest builder, second wind) and progression-derived (Curator, Seedling Scholar). Evaluate forest-derived once per compute, progression-derived after level stabilizes. Removes the cycle entirely, simpler than fixed-point loops, and shapes the logic correctly for server migration. **Long-term (post-migration):** Server compute calls `ProgressionEngine.compute(history) → LevelProgress`, then `missions.py::generate(profile, plan, txns) → List[Mission]`, then achievement rules sync off the two. Single-pass deterministic compute per request, no convergence issues. |

---

## Migration Roadmap

### Phase 1: Land Part 1 bug fixes (NOW)
- Restoration window off-by-one fixed in `forest_engine.dart:162` (boundary tested).
- Convergence loop budget raised to 6, assertion added for non-convergence (tested worst-case cascade).
- Ship on this branch; merges to `main` as-is.

### Phase 2: Partition achievements & prepare for server (NEXT)
Refactor `ForestEngine._achievements()` to separate forest-derived (deterministic) and progression-derived (Curator, Seedling Scholar) sets. Update `main.dart::_recomputeProgression` to compute once and check progression-derived after levels stabilize. This removes the cycle entirely and is the shape needed for the server migration.

### Phase 3: Stand up server persistence & compute (NEXT)
- Extend `backend,dataAPI/store.py` from in-memory demo dict to multi-user SQLite/Postgres.
- Move `ProgressionEngine.compute()` logic to `backend,dataAPI/engine/progression.py`.
- Implement `/api/progression/{user_id}` endpoint: takes `days_json`, returns `{ level, xp, coins, achievements }`.
- Implement `/api/missions/{user_id}` endpoint: takes `profile_json`, `plan_json`, `transactions_json`, returns `List[Mission]`.
- Sunset Forest's client-side `ProgressionEngine` and `_recomputeProgression` loop once the API is live and tested.

### Phase 4: Adopt Tower's features server-side
- Port `missions.py::generate()` to the server (already mostly pure function; add test suite).
- Enforce fairness rules: assert no mission targets PROTECTED categories at generation time.
- Tune XP curve: lower the quadratic coefficient in Forest's formula, cap at level 30–40, validate.
- Delete `boost-double` from SHOP.

### Phase 5: Update client to call the API
- Replace `ProgressionEngine.compute()` calls with `POST /api/progression/{user_id}` requests.
- Update HomeScreen to display server-returned level/coins/achievements instead of deriving them.
- Keep ForestEngine for local check-in logic (mark today healthy/withered, streak tracking), but have it call the server for final progression/achievement state once the day is recorded.

### Phase 6: Sunset Tower's incomplete code
- Close the `/api/shop/buy` endpoint on Tower's side (Forest's shop is the source of truth).
- Archive Tower's in-memory SHOP and Progression models once the migration is complete.
- Update API docs to reflect server-authoritative single-economy design.

---

## Rationale

**Why server-authoritative?**  
XP/coins are progress markers that users expect to be persistent and auditable. On-device computation is fast and fun for a game, but for a fintech tool (this is a budget app, not a game engine), trustworthiness matters. Server persistence and audit logs are table-stakes for anything involving real money or high-stakes habits.

**Why Forest's shop boundary?**  
Type-level enforcement of cosmetic-only (via enum) is correct. It prevents accidental pay-to-win items and grounds the design principle in code. Tower's `boost-double` is a warning sign — a progression accelerator on a fintech app is a red flag for fairness (low-income users can't afford it, high-income users get ahead faster, increases perception of pay-to-win).

**Why Tower's missions?**  
Static achievements can't adapt to user reality. Missions that say "you spent $200 on subscriptions, cut one" or "you're $50 short on your stable bucket, move it" are more honest and actionable. They're also better for retention (always something fresh to do, grounded in real weak spots).

**Why partition achievements?**  
The fixed-point loop is a symptom of a deeper issue: achievements that depend on progression (Curator, Seedling Scholar) create a cycle with progression-unlock rewards. Partitioning removes the cycle entirely and is the shape the server-side compute naturally falls into (compute progression, then check progression-dependent achievements). It's also simpler to reason about and test.

---

## Decision Checkpoint

This plan is approved by:
- **Architecture:** server-authoritative, not client-side.
- **Economy:** Forest's shop + Tower's missions + Forest's restoration + Tower's fairness rules.
- **Timeline:** Part 1 ships now (bug fixes), Phase 2–6 land over the next sprint.
- **Rollback:** None. Forest's client-side compute works today; server migration is additive and tested before cutover.

---

## References

- Build report: `docs/superpowers/reports/2026-08-29-progression-economy-report.md`
- Design spec: `docs/superpowers/specs/2026-08-29-progression-economy-design.md`
- Forest client code: `lib/services/forest_engine.dart`, `lib/main.dart`, `lib/models/progression.dart`
- Tower server code: `backend,dataAPI/engine/progression.py`, `backend,dataAPI/engine/missions.py`
- Part 1 changes: `lib/services/forest_engine.dart:162` (restoration window), `lib/main.dart:228–253` (convergence loop)
