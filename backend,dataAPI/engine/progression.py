"""XP / coins / levels / 财富塔 tower state.

Curve: level N needs 100 * N^1.35 XP. Fast early levels (dopamine in the first
90 seconds of the demo), slowing later.
"""
from __future__ import annotations

import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Progression, TowerFloor, TowerState, Plan, BUCKETS

MAX_LEVEL = 30


def xp_for_level(level: int) -> int:
    return int(100 * (level ** 1.35))


def level_from_xp(xp: int) -> tuple[int, int, int]:
    """-> (level, xp_into_level, xp_needed_for_next)"""
    level, remaining = 1, xp
    while level < MAX_LEVEL:
        need = xp_for_level(level)
        if remaining < need:
            return level, remaining, need
        remaining -= need
        level += 1
    return MAX_LEVEL, 0, 0


def progression(xp: int, coins: int, streak: int, skins: list[str], active: str) -> Progression:
    level, into, need = level_from_xp(xp)
    return Progression(xp=xp, level=level, xp_into_level=into, xp_for_next_level=need,
                       coins=coins, streak_days=streak, unlocked_skins=skins, active_skin=active)


def tower(plan: Plan, prog: Progression) -> TowerState:
    """Height comes from level. Health comes from adherence. Both are visible."""
    stage = min(6, 1 + prog.level // 5)
    health = plan.adherence

    floors: list[TowerFloor] = []
    for i, b in enumerate(BUCKETS):
        bp = next(p for p in plan.buckets if p.bucket == b)
        # a floor is 'built' in proportion to level, and 'healthy' per bucket
        built = min(1.0, (prog.level / 10) + 0.25)
        if b in ("living", "reward"):
            used = bp.actual_amount / bp.target_amount if bp.target_amount else 0
            fh = 1.0 if used <= 1 else max(0.1, 1 - (used - 1))
        else:
            fh = min(1.0, bp.actual_amount / bp.target_amount) if bp.target_amount else 1.0
        floors.append(TowerFloor(index=i, bucket=b, height=round(built, 3), health=round(fh, 3)))

    weather = "clear" if health >= 0.8 else "overcast" if health >= 0.55 else "storm"
    caption = {
        "clear": "Clear skies. The tower is gaining a floor.",
        "overcast": "Clouds gathering — one bucket is drifting off plan.",
        "storm": "Storm. Overspend is eroding the tower; finish a mission to stop the decay.",
    }[weather]

    return TowerState(stage=stage, floors=floors, health=round(health, 3),
                      weather=weather, caption=caption)


SHOP = [
    {"id": "skin-default", "name": "Sandstone", "cost": 0, "kind": "skin",
     "description": "The starting tower."},
    {"id": "skin-neon", "name": "Neon Brisbane", "cost": 250, "kind": "skin",
     "description": "Purple-on-black city glow."},
    {"id": "skin-jade", "name": "Jade Pagoda", "cost": 400, "kind": "skin",
     "description": "Tiered pagoda silhouette with jade roofing."},
    {"id": "skin-orbital", "name": "Orbital", "cost": 900, "kind": "skin",
     "description": "The tower breaks atmosphere. Level 15+."},
    {"id": "boost-double", "name": "Double XP Weekend", "cost": 150, "kind": "booster",
     "description": "2x mission XP for 48 hours."},
]
