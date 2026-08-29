"""Shared data models. FROZEN CONTRACT — do not change field names without telling the team."""
from __future__ import annotations

from typing import Literal, Optional
from pydantic import BaseModel, Field

Bucket = Literal["invest", "stable", "living", "reward"]

BUCKETS: list[Bucket] = ["invest", "stable", "living", "reward"]


# ---------- Survey / profile ----------

class SurveyAnswers(BaseModel):
    """Six questions. Keep it to six — anything longer and demo users bail."""
    monthly_income: float = Field(..., description="AUD per month, self-reported")
    fixed_costs: float = Field(..., description="rent + bills + transport, AUD/month")
    risk_appetite: int = Field(..., ge=1, le=5, description="1 = cash under mattress, 5 = full send")
    horizon_months: int = Field(..., ge=1, description="how far ahead they plan")
    has_emergency_fund: bool
    top_worry: Literal["subscriptions", "food", "impulse", "rent", "none"]


class Allocation(BaseModel):
    invest: float
    stable: float
    living: float
    reward: float

    def normalised(self) -> "Allocation":
        total = self.invest + self.stable + self.living + self.reward
        if total <= 0:
            return Allocation(invest=0.25, stable=0.15, living=0.50, reward=0.10)
        return Allocation(
            invest=round(self.invest / total, 4),
            stable=round(self.stable / total, 4),
            living=round(self.living / total, 4),
            reward=round(self.reward / total, 4),
        )


class Profile(BaseModel):
    user_id: str
    archetype: str
    archetype_blurb: str
    allocation: Allocation
    monthly_income: float
    discretionary: float
    guardrail_note: Optional[str] = None


# ---------- Bank ----------

class Account(BaseModel):
    id: str
    name: str
    kind: str            # transaction | savings | credit-card | loan
    balance: float
    currency: str = "AUD"


class Transaction(BaseModel):
    id: str
    account_id: str
    post_date: str       # ISO-8601
    description: str
    amount: float        # negative = money out
    category: str        # normalised category
    bucket: Bucket


class ConnectionStatus(BaseModel):
    provider: Literal["basiq", "mock"]
    connected: bool
    institution: Optional[str] = None
    persona: Optional[str] = None
    message: str = ""


# ---------- Plan ----------

class BucketPlan(BaseModel):
    bucket: Bucket
    target_pct: float
    target_amount: float
    actual_amount: float
    variance: float          # actual - target, negative = under budget (good for living)
    on_track: bool


class Plan(BaseModel):
    period_days: int
    income_observed: float
    buckets: list[BucketPlan]
    adherence: float         # 0..1, drives tower health
    headline: str


# ---------- Missions ----------

class Mission(BaseModel):
    id: str
    title: str
    detail: str
    bucket: Bucket
    kind: Literal["streak", "threshold", "one_off"]
    target: float
    progress: float
    complete: bool
    claimed: bool
    verified: bool = True   # True = completion derived from bank data.
                            # False = user asserts it; we cannot see it in the feed.
    xp: int
    coins: int
    expires_in_days: int


class ClaimResult(BaseModel):
    mission_id: str
    xp_awarded: int
    coins_awarded: int
    levelled_up: bool
    progression: "Progression"


# ---------- Progression / tower ----------

class Progression(BaseModel):
    xp: int
    level: int
    xp_into_level: int
    xp_for_next_level: int
    coins: int
    streak_days: int
    unlocked_skins: list[str]
    active_skin: str


class TowerFloor(BaseModel):
    index: int
    bucket: Bucket
    height: float        # 0..1, how built-out this floor is
    health: float        # 0..1, decays when the bucket is off-plan


class TowerState(BaseModel):
    stage: int           # 1..6 visual stage, derived from level
    floors: list[TowerFloor]
    health: float        # 0..1 overall — withers on overspend
    weather: Literal["clear", "overcast", "storm"]
    caption: str


class ShopItem(BaseModel):
    id: str
    name: str
    cost: int
    kind: Literal["skin", "booster"]
    owned: bool
    description: str


ClaimResult.model_rebuild()
