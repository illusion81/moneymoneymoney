"""Survey -> financial-management parameters.

This is the '生成 finance management parameter' box on the whiteboard.
Deterministic, explainable, no LLM needed. Judges ask "how does it decide?" —
you point at this file.
"""
from __future__ import annotations

import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Allocation, Profile, SurveyAnswers

BASE = Allocation(invest=0.25, stable=0.15, living=0.50, reward=0.10)

ARCHETYPES = {
    "builder":   ("The Builder",   "You have room to move and you use it. Growth first, treats earned."),
    "steadier":  ("The Steadier",  "Fixed costs eat most of your income. We protect the floor before we build up."),
    "sprinter":  ("The Sprinter",  "Short horizon, high appetite. Fast feedback loops, tight guardrails."),
    "guardian":  ("The Guardian",  "No buffer yet. Everything routes to a cushion until you have one month covered."),
}


def build_profile(user_id: str, a: SurveyAnswers) -> Profile:
    income = max(a.monthly_income, 0.0)
    fixed = min(max(a.fixed_costs, 0.0), income) if income else 0.0
    fixed_ratio = (fixed / income) if income else 1.0
    discretionary = max(income - fixed, 0.0)

    alloc = Allocation(**BASE.model_dump())

    # 1. Fixed costs are non-negotiable: living floor must cover them.
    living_floor = min(max(fixed_ratio, 0.35), 0.80)
    alloc.living = living_floor

    remaining = max(1.0 - alloc.living, 0.0)

    # 2. No emergency fund -> stability before growth.
    if not a.has_emergency_fund:
        stable_share, invest_share, reward_share = 0.55, 0.30, 0.15
        archetype = "guardian"
    else:
        # risk 1..5 shifts the growth/stability mix
        invest_share = 0.35 + (a.risk_appetite - 3) * 0.10   # 0.15 .. 0.55
        invest_share = min(max(invest_share, 0.15), 0.60)
        stable_share = 0.85 - invest_share - 0.15
        reward_share = 0.15
        archetype = "builder" if fixed_ratio < 0.55 else "steadier"

    # 3. Short horizon = don't lock money away.
    if a.horizon_months <= 6:
        shift = min(invest_share * 0.4, 0.15)
        invest_share -= shift
        stable_share += shift
        if a.has_emergency_fund:
            archetype = "sprinter"

    alloc.invest = remaining * invest_share
    alloc.stable = remaining * stable_share
    alloc.reward = remaining * reward_share
    alloc = alloc.normalised()

    guardrail = None
    if fixed_ratio > 0.75:
        guardrail = (
            "Your fixed costs are over 75% of income. We are not going to gamify you into "
            "skipping rent — missions below only touch discretionary spend."
        )
    elif not a.has_emergency_fund:
        guardrail = "First goal: one month of fixed costs in the stable bucket. Growth unlocks after that."

    name, blurb = ARCHETYPES[archetype]
    return Profile(
        user_id=user_id,
        archetype=name,
        archetype_blurb=blurb,
        allocation=alloc,
        monthly_income=income,
        discretionary=discretionary,
        guardrail_note=guardrail,
    )
