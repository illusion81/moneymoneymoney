"""Shared data models. FROZEN CONTRACT — do not change field names without telling the team."""
from __future__ import annotations

from typing import Literal, Optional
from pydantic import BaseModel, Field, model_validator

Bucket = Literal["invest", "stable", "living", "reward"]

BUCKETS: list[Bucket] = ["invest", "stable", "living", "reward"]

ConfidenceTierName = Literal["early_snapshot", "standard", "full_clarity"]


class MoneyStyleSubmission(BaseModel):
    """Behavioural reflection, deliberately separate from financial facts."""
    session_id: str = Field(..., min_length=1)
    question_version: str = Field(..., min_length=1)
    selected_answers: dict[int, str]
    skipped_question_ids: list[int]
    answered_count: int = Field(..., ge=0, le=12)
    confidence_tier: Optional[ConfidenceTierName] = None
    archetype_id: Optional[str] = None

    @model_validator(mode="after")
    def validate_counts(self) -> "MoneyStyleSubmission":
        if self.answered_count != len(self.selected_answers):
            raise ValueError("answered_count must match selected_answers")
        if set(self.selected_answers).intersection(self.skipped_question_ids):
            raise ValueError("a question cannot be answered and skipped")
        if any(question_id < 1 or question_id > 12 for question_id in self.selected_answers):
            raise ValueError("question ids must be between 1 and 12")
        return self


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


ConsentState = Literal[
    "never_connected",   # no bank ever linked
    "active",            # healthy
    "expiring_soon",     # inside the renewal window — prompt now, before it lapses
    "expired",           # ran out; CDR consent is capped at 12 months
    "revoked",           # the user killed it from their bank or from us
]


class ConsentStatus(BaseModel):
    """CDR consent lifecycle.

    Consent is granted once for up to 12 months, and the user can revoke it at
    any time from their bank's dashboard or from inside our app — effective
    immediately. Both endings must be handled gracefully: the tower freezes at
    its last known state, it is never erased.
    """
    state: ConsentState
    granted_at: Optional[str] = None
    expires_at: Optional[str] = None
    days_remaining: Optional[int] = None
    action_required: bool = False
    headline: str
    detail: str
    reconnect_url: Optional[str] = None


class ConnectionStatus(BaseModel):
    provider: Literal["basiq", "mock"]
    connected: bool
    institution: Optional[str] = None
    persona: Optional[str] = None
    consent_url: Optional[str] = None   # open this in a browser to link a bank
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
    stale: bool = False          # True = last known good data, feed is down
    period_days: int
    income_observed: float
    buckets: list[BucketPlan]
    adherence: float         # 0..1, drives tower health
    headline: str


# ---------- Social ----------

class JoinCircle(BaseModel):
    display_name: str
    code: str = "UQ2026"        # circles are joined by a short code, no accounts


class LeaderboardEntry(BaseModel):
    """Deliberately contains no dollar figures.

    Ranking students by how much they save rewards whoever has the wealthiest
    parents. We rank by adherence to your OWN plan — a percentage of a target
    the app set for you — so someone on $400 a month can beat someone on $4,000.
    """
    rank: int
    display_name: str
    is_you: bool
    adherence: float            # 0..1 against their own plan
    level: int
    tower_stage: int
    streak_days: int
    trend: Literal["up", "flat", "down"]
    badge: Optional[str] = None


class Circle(BaseModel):
    code: str
    name: str
    member_count: int
    your_rank: Optional[int] = None
    headline: str
    entries: list[LeaderboardEntry]


class Cheer(BaseModel):
    from_name: str
    to_name: str
    message: str
    sent_at: str


# ---------- Goals ----------

class GoalCreate(BaseModel):
    """A large planned expense: concert tickets, a flight, a laptop.

    The point is that it changes the plan. Without this, a one-off $400 purchase
    looks like overspending and cracks the tower, when actually they saved for
    it deliberately. Saving toward something is not the same as blowing a budget.
    """
    name: str
    target_amount: float = Field(..., gt=0)
    target_date: str            # ISO date, when they need the money
    saved_so_far: float = 0.0


class Goal(BaseModel):
    id: str
    name: str
    target_amount: float
    target_date: str
    saved_so_far: float
    remaining: float
    days_left: int
    weeks_left: float
    per_week_needed: float      # what they must set aside from here
    per_month_needed: float
    on_track: bool
    share_of_discretionary: float   # 0..1 — how much of their spare cash this eats
    headline: str
    warning: Optional[str] = None


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
    stale: bool = False          # True = frozen at last sync; do not erase it
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
