"""Large planned expenses.

A concert ticket is not overspending — it is a deliberate purchase someone
saved for. Treating the two the same is the fastest way to make a budgeting app
feel stupid, so goals get their own maths:

  - the required weekly contribution comes out of discretionary money BEFORE
    the reward bucket is judged, so saving for something does not read as a miss
  - if the goal needs more than the user has spare, we say so plainly instead of
    setting them up to fail
"""
from __future__ import annotations

import sys, os, hashlib, datetime as dt
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Goal, GoalCreate, Profile


def _money(v: float) -> str:
    return f"${v:,.0f}" if abs(v) >= 100 else f"${v:,.2f}"


def build_goal(g: GoalCreate, profile: Profile, goal_id: str | None = None) -> Goal:
    today = dt.date.today()
    try:
        target = dt.date.fromisoformat(g.target_date)
    except ValueError:
        target = today + dt.timedelta(days=30)

    days_left = max((target - today).days, 0)
    weeks_left = max(days_left / 7, 0.14)          # never divide by zero
    remaining = max(g.target_amount - g.saved_so_far, 0.0)

    per_week = remaining / weeks_left
    per_month = per_week * 4.345

    # What is genuinely spare each month: income minus fixed costs, minus what
    # the plan already earmarks for essentials.
    discretionary = max(profile.discretionary, 1.0)
    share = min(per_month / discretionary, 2.0)

    if remaining <= 0:
        headline = f"{g.name} is fully funded."
        warning = None
        on_track = True
    elif days_left == 0:
        headline = f"{g.name} is due today — {_money(remaining)} short."
        warning = "The date has arrived and the goal is not funded."
        on_track = False
    else:
        headline = (f"Set aside {_money(per_week)} a week for {int(weeks_left)} weeks "
                    f"and {g.name} is covered.")
        on_track = share <= 0.6
        warning = None
        if share > 1.0:
            warning = (f"This needs {_money(per_month)} a month but you only have about "
                       f"{_money(discretionary)} spare. Either push the date back or "
                       f"lower the target — we are not going to pretend this fits.")
        elif share > 0.6:
            warning = (f"This will take {share*100:.0f}% of your spare cash. Doable, "
                       f"but there will be very little room for anything else.")

    gid = goal_id or hashlib.sha1(f"{g.name}{g.target_date}".encode()).hexdigest()[:10]
    return Goal(
        id=gid, name=g.name, target_amount=g.target_amount, target_date=target.isoformat(),
        saved_so_far=g.saved_so_far, remaining=round(remaining, 2), days_left=days_left,
        weeks_left=round(weeks_left, 1), per_week_needed=round(per_week, 2),
        per_month_needed=round(per_month, 2), on_track=on_track,
        share_of_discretionary=round(share, 3), headline=headline, warning=warning,
    )


def monthly_commitment(goals: list[Goal]) -> float:
    """Total the plan should reserve each month across all open goals."""
    return round(sum(g.per_month_needed for g in goals if g.remaining > 0), 2)
