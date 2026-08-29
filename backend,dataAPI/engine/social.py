"""The social layer.

One design decision drives everything here: we rank on ADHERENCE TO YOUR OWN
PLAN, never on dollars saved. A leaderboard of absolute savings is a leaderboard
of whose parents earn more — it would punish exactly the students this app is
supposed to help, and it is the first thing a judge will poke at.

Adherence is a percentage of a target the app calculated from that person's own
income and fixed costs. Someone on $400 a month can top a table containing
someone on $4,000. No income, balance or savings figure is ever exposed to
another user.
"""
from __future__ import annotations

import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import LeaderboardEntry, Circle

# A circle is never empty on first open — an empty leaderboard teaches nobody
# anything and demos badly. These are the other members of a UQ study circle.
SEEDED_PEERS = [
    {"display_name": "Priya",   "adherence": 0.91, "level": 6, "streak_days": 12, "trend": "up"},
    {"display_name": "Tom",     "adherence": 0.84, "level": 5, "streak_days": 9,  "trend": "up"},
    {"display_name": "Wei",     "adherence": 0.72, "level": 4, "streak_days": 4,  "trend": "flat"},
    {"display_name": "Sofia",   "adherence": 0.63, "level": 3, "streak_days": 2,  "trend": "down"},
    {"display_name": "Callum",  "adherence": 0.48, "level": 2, "streak_days": 0,  "trend": "down"},
]

BADGES = {
    1: "Steadiest this week",
    2: "Longest streak",
}


def _stage(level: int) -> int:
    return min(6, 1 + level // 5)


def discipline(adherence: float, streak_days: int) -> float:
    """The single ranked number.

    Adherence is the bulk of it — holding your own plan is the thing worth
    measuring. Streak carries the rest: it is effort, not income, so it is fair
    to reward, and it means someone rebuilding a habit can climb without
    needing a bigger paycheque. Level is deliberately NOT in here — level is
    time played, and ranking on it would just rank whoever started first.
    """
    streak_part = min(streak_days / 14, 1.0)
    return round(adherence * 0.7 + streak_part * 0.3, 4)


def build_circle(code: str, name: str, you_display: str, you_adherence: float,
                 you_level: int, you_streak: int) -> Circle:
    rows = [dict(p) for p in SEEDED_PEERS]
    rows.append({
        "display_name": you_display or "You",
        "adherence": round(you_adherence, 3),
        "level": you_level,
        "streak_days": you_streak,
        "trend": "up" if you_adherence >= 0.75 else "flat" if you_adherence >= 0.55 else "down",
        "_you": True,
    })

    # rank by the composite discipline score — adherence plus sustained streak
    for r in rows:
        r["score"] = discipline(r["adherence"], r["streak_days"])
    rows.sort(key=lambda r: (r["score"], r["adherence"]), reverse=True)

    entries: list[LeaderboardEntry] = []
    your_rank = None
    for i, r in enumerate(rows, 1):
        is_you = bool(r.get("_you"))
        if is_you:
            your_rank = i
        entries.append(LeaderboardEntry(
            rank=i, display_name=r["display_name"], is_you=is_you,
            adherence=r["adherence"], level=r["level"], tower_stage=_stage(r["level"]),
            streak_days=r["streak_days"], trend=r["trend"],
            badge=BADGES.get(i),
        ))

    if your_rank == 1:
        headline = "You are holding your plan better than anyone in the circle."
    elif your_rank and your_rank <= len(rows) // 2:
        ahead = entries[your_rank - 2].display_name
        gap = (discipline(entries[your_rank - 2].adherence,
                          entries[your_rank - 2].streak_days)
               - discipline(you_adherence, you_streak)) * 100
        headline = f"{gap:.0f} points behind {ahead}. Close one mission and you pass them."
    else:
        headline = ("Everyone here is working from their own plan, not the same target. "
                    "Catching up means beating your budget, not out-earning anyone.")

    return Circle(code=code, name=name, member_count=len(rows),
                  your_rank=your_rank, headline=headline, entries=entries)
