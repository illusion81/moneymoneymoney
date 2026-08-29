# API contract — FROZEN

Three people are coding against this at once. **Field names do not change
without a message in the team chat.** If you need a new field, add it; never
rename or remove one.

Base: `http://localhost:8000`. The Vite dev server proxies `/api/*` to it, so
the frontend only ever writes `/api/...`.

| Method | Path | Body | Returns | Owner |
|---|---|---|---|---|
| `POST` | `/api/survey` | `SurveyAnswers` | `Profile` | Engine |
| `GET` | `/api/profile` | — | `Profile` (409 if no survey yet) | Engine |
| `POST` | `/api/money-style` | `MoneyStyleSubmission` | `MoneyStyleSubmission` | Onboarding |
| `GET` | `/api/money-style` | — | `MoneyStyleSubmission` (404 if absent) | Onboarding |
| `POST` | `/api/bank/connect` | `{persona}` | `ConnectionStatus` | Data |
| `GET` | `/api/bank/accounts` | — | `Account[]` | Data |
| `GET` | `/api/bank/transactions?days=30` | — | `Transaction[]` | Data |
| `GET` | `/api/plan?days=30` | — | `Plan` | Engine |
| `GET` | `/api/missions` | — | `Mission[]` | Engine |
| `POST` | `/api/missions/{id}/claim` | — | `ClaimResult` | Engine |
| `GET` | `/api/progression` | — | `Progression` | Engine |
| `GET` | `/api/tower` | — | `TowerState` | Game |
| `GET` | `/api/shop` | — | `ShopItem[]` | Game |
| `POST` | `/api/shop/buy` | `{item_id}` | `Progression` | Game |
| `POST` | `/api/demo/reset` | — | `{ok}` | anyone |
| `GET` | `/api/health` | — | `{ok, provider}` | anyone |

Live schema for every type: <http://localhost:8000/docs> (FastAPI generates it
from `models.py` — that file is the single source of truth).

## Money Style boundary

Money Style is behavioural reflection only. It stores answer IDs and skips, and
does not create a financial profile, allocation, plan, or mission. Financial
calculations require separate user-provided facts through `/api/survey` or
opted-in bank data.

## The four buckets

`invest` · `stable` · `living` · `reward` — in that order, everywhere. The
whiteboard split was 25 / 15 / 50 / 10; that's now the *base* the survey
adjusts from, not a hard rule.

## Shapes you'll use most

```jsonc
// Profile
{ "archetype": "The Guardian", "archetype_blurb": "...",
  "allocation": { "invest": 0.13, "stable": 0.24, "living": 0.56, "reward": 0.07 },
  "monthly_income": 2700, "discretionary": 1200, "guardrail_note": "..." }

// Plan
{ "income_observed": 4050, "adherence": 0.608,
  "headline": "Mostly on plan — stable is the floor that's cracking.",
  "buckets": [ { "bucket": "invest", "target_pct": 0.13, "target_amount": 539.87,
                 "actual_amount": 200, "variance": -339.87, "on_track": false } ] }

// TowerState
{ "stage": 1, "health": 0.608, "weather": "overcast", "caption": "...",
  "floors": [ { "index": 0, "bucket": "invest", "height": 0.35, "health": 0.37 } ] }

// ClaimResult
{ "mission_id": "a2167f9cd8", "xp_awarded": 250, "coins_awarded": 100,
  "levelled_up": true, "progression": { "level": 2, "xp_into_level": 150, ... } }
```

## Rules everyone follows

1. **Never call `fetch` from a component.** Everything goes through
   `frontend/src/lib/api.js`.
2. **Never import a provider directly in a route.** Use `provider()` in
   `main.py` so the mock fallback keeps working.
3. `adherence` (0–1) is the one number that drives tower health. If you want
   the tower to look different, change `engine/plan.py`, not the SVG.
4. Money is a float in AUD. Format only at render time (`money()` in `api.js`).
