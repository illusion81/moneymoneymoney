"""In-memory state. Swap for SQLite/Postgres only if you have spare time —
you almost certainly do not. A dict survives a 3-minute demo just fine.

If a teammate wants persistence: keep this interface, back it with sqlite3.
"""
from __future__ import annotations

from typing import Any

_STATE: dict[str, dict[str, Any]] = {}

DEFAULT_USER = "demo"


def user(uid: str = DEFAULT_USER) -> dict[str, Any]:
    if uid not in _STATE:
        _STATE[uid] = {
            "profile": None,
            "connection": None,
            "xp": 0,
            "coins": 120,
            "streak": 1,
            "skins": ["skin-default"],
            "active_skin": "skin-default",
            "claimed": set(),
            "self_done": set(),
            "missions": [],
            "goals": {},
            "circle": None,
            "display_name": None,
            "cheers": [],
        }
    return _STATE[uid]


def reset(uid: str = DEFAULT_USER) -> None:
    _STATE.pop(uid, None)
