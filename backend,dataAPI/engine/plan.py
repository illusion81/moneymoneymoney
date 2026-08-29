"""Transactions + allocation params -> the '计划' (plan) and its adherence score.

Adherence is the single number that drives the tower's health, so it has to be
defensible. Rules:
  - living / reward: coming in UNDER target is good. Over target is the miss.
  - invest / stable: hitting target is good. Under target is the miss.
  - Each bucket scores 0..1, weighted by its target share.
"""
from __future__ import annotations

import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Allocation, Bucket, BucketPlan, Plan, Transaction, BUCKETS

SPEND_BUCKETS: set[Bucket] = {"living", "reward"}

# Moving money between accounts, or sending it to a person, is neither spending
# nor saving. Counting it wrecks the adherence score: one $3,500 PayID transfer
# was showing up as 94% of a user's "stable" bucket.
EXCLUDED_CATEGORIES = {"transfer", "transfer-in", "transfer-out"}


def build_plan(txns: list[Transaction], alloc: Allocation, fallback_income: float,
               period_days: int = 30) -> Plan:
    income = sum(t.amount for t in txns if t.amount > 0 and t.category == "income")
    if income <= 0:
        income = fallback_income
    income = max(income, 1.0)

    spend: dict[str, float] = {b: 0.0 for b in BUCKETS}
    for t in txns:
        if t.category in EXCLUDED_CATEGORIES:
            continue
        if t.amount < 0:
            spend[t.bucket] += -t.amount
        elif t.bucket in ("invest", "stable") and t.category != "income":
            spend[t.bucket] += t.amount

    alloc_map = alloc.model_dump()
    plans: list[BucketPlan] = []
    score = 0.0

    for b in BUCKETS:
        pct = float(alloc_map[b])
        target = income * pct
        actual = round(spend[b], 2)
        variance = round(actual - target, 2)

        if b in SPEND_BUCKETS:
            # ratio of budget used; 1.0 or less is a pass
            used = actual / target if target else 0.0
            bucket_score = 1.0 if used <= 1.0 else max(0.0, 1.0 - (used - 1.0))
            on_track = used <= 1.05
        else:
            filled = actual / target if target else 1.0
            bucket_score = min(filled, 1.0)
            on_track = filled >= 0.95

        score += bucket_score * pct
        plans.append(BucketPlan(bucket=b, target_pct=round(pct, 4),
                                target_amount=round(target, 2), actual_amount=actual,
                                variance=variance, on_track=on_track))

    adherence = round(min(max(score, 0.0), 1.0), 3)
    worst = min(plans, key=lambda p: (p.on_track, -abs(p.variance)))

    if adherence >= 0.85:
        headline = "Tower is growing. Every floor is holding."
    elif adherence >= 0.6:
        headline = f"Mostly on plan — {worst.bucket} is the floor that's cracking."
    else:
        headline = f"Tower is losing height. {worst.bucket} is ${abs(worst.variance):.0f} off plan."

    return Plan(period_days=period_days, income_observed=round(income, 2),
                buckets=plans, adherence=adherence, headline=headline)
