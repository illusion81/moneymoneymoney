"""Wealth Tower API.

Run:  uvicorn main:app --reload --port 8000
Docs: http://localhost:8000/docs

Every endpoint here is part of the frozen contract in docs/API.md.
Frontend devs: you can build against this the moment it boots — the seeded
mock provider returns real-shaped data with no bank connection at all.
"""
from __future__ import annotations

import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import store
from models import (SurveyAnswers, Profile, ConnectionStatus, Account, Transaction,
                    Plan, Mission, ClaimResult, Progression, TowerState, ShopItem)
from bank import MockProvider, BasiqProvider, BasiqError, CsvProvider
from engine.allocation import build_profile
from engine.plan import build_plan
from engine.missions import generate as generate_missions
from engine.progression import progression as build_progression, tower as build_tower, SHOP

app = FastAPI(title="Wealth Tower API", version="0.1.0")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"],
)

UID = store.DEFAULT_USER
_mock = MockProvider()
_basiq: BasiqProvider | None = None

# Demo control. The real Basiq sandbox persona has one merchant (Afterpay) and
# nothing else, which makes for a dead demo. This lets us prove the live bank
# connection to judges, then flip to the rich seeded data for the walkthrough —
# without a code change or a restart on stage.
_forced_provider: str | None = None


_csv = None


def _csv_provider():
    """Local CSV export. Cached; returns None if unset or unreadable."""
    global _csv
    if _csv is None and os.getenv("WEALTH_CSV"):
        try:
            _csv = CsvProvider()
        except Exception:
            return None
    return _csv


def provider():
    """CSV > Basiq > mock, unless overridden. Never raises."""
    global _basiq
    if _forced_provider == "mock":
        return _mock
    if _forced_provider == "csv" or (_forced_provider is None and os.getenv("WEALTH_CSV")):
        c = _csv_provider()
        if c is not None:
            return c
    if os.getenv("BASIQ_API_KEY"):
        try:
            if _basiq is None:
                _basiq = BasiqProvider()
            return _basiq
        except BasiqError:
            return _mock
    return _mock


def _safe(fn, *a, **kw):
    """Call a provider method; fall back to mock on any network/API failure."""
    try:
        return fn(*a, **kw)
    except Exception:
        name = fn.__name__
        return getattr(_mock, name)(*a, **kw)


def data_trusted() -> bool:
    """Can the user have tampered with this data before we saw it?

    Only true for a direct bank connection (CDR/Basiq), where transactions come
    from the institution and never pass through the user's hands. A CSV export
    is editable in Excel; mock data is invented. Neither can back a claim that
    a mission was 'verified by your bank'.
    """
    return isinstance(provider(), BasiqProvider)


def _require_profile() -> Profile:
    p = store.user(UID)["profile"]
    if p is None:
        raise HTTPException(409, "No profile yet — POST /api/survey first.")
    return p


# ------------------------------------------------------------------ survey

@app.post("/api/survey", response_model=Profile)
def submit_survey(answers: SurveyAnswers) -> Profile:
    profile = build_profile(UID, answers)
    store.user(UID)["profile"] = profile
    return profile


@app.get("/api/profile", response_model=Profile)
def get_profile() -> Profile:
    return _require_profile()


# ------------------------------------------------------------------ bank

class ConnectBody(BaseModel):
    persona: str = "Wentworth-Smith"


@app.post("/api/bank/connect", response_model=ConnectionStatus)
def connect_bank(body: ConnectBody) -> ConnectionStatus:
    status = _safe(provider().connect, body.persona)
    store.user(UID)["connection"] = status
    return status


@app.get("/api/bank/accounts", response_model=list[Account])
def get_accounts() -> list[Account]:
    return _safe(provider().accounts)


@app.get("/api/bank/transactions", response_model=list[Transaction])
def get_transactions(days: int = 30) -> list[Transaction]:
    return _safe(provider().transactions, days)


# ------------------------------------------------------------------ plan

@app.get("/api/plan", response_model=Plan)
def get_plan(days: int = 30) -> Plan:
    profile = _require_profile()
    txns = _safe(provider().transactions, days)
    return build_plan(txns, profile.allocation, profile.monthly_income, days)


# ------------------------------------------------------------------ missions

@app.get("/api/missions", response_model=list[Mission])
def get_missions(days: int = 30) -> list[Mission]:
    profile = _require_profile()
    txns = _safe(provider().transactions, days)
    plan = build_plan(txns, profile.allocation, profile.monthly_income, days)
    missions = generate_missions(profile, plan, txns)
    u = store.user(UID)
    claimed = u["claimed"]
    self_done = u.setdefault("self_done", set())
    for m in missions:
        m.claimed = m.id in claimed
        # Unverifiable missions only complete when the user says so.
        if not m.verified and m.id in self_done:
            m.complete = True
    store.user(UID)["missions"] = missions
    return missions


@app.post("/api/missions/{mission_id}/claim", response_model=ClaimResult)
def claim_mission(mission_id: str) -> ClaimResult:
    u = store.user(UID)
    missions = u["missions"] or get_missions()
    m = next((x for x in missions if x.id == mission_id), None)
    if m is None:
        raise HTTPException(404, "Unknown mission")
    if m.id in u["claimed"]:
        raise HTTPException(409, "Already claimed")
    if not m.complete:
        # The whole point: XP comes from the bank feed, not from tapping a button.
        if m.verified:
            raise HTTPException(
                409, f"Not done yet — {m.progress:.0f} of {m.target:.0f}. "
                     f"This one is checked against your transactions.")
        raise HTTPException(409, "Mark this one done first (POST /mark_done).")

    before = build_progression(u["xp"], u["coins"], u["streak"], u["skins"], u["active_skin"])
    u["xp"] += m.xp
    u["coins"] += m.coins
    u["claimed"].add(m.id)
    after = build_progression(u["xp"], u["coins"], u["streak"], u["skins"], u["active_skin"])

    return ClaimResult(mission_id=m.id, xp_awarded=m.xp, coins_awarded=m.coins,
                       levelled_up=after.level > before.level, progression=after)


# ------------------------------------------------------------------ progression + tower

@app.post("/api/missions/{mission_id}/mark_done", response_model=Mission)
def mark_done(mission_id: str) -> Mission:
    """For missions the bank feed cannot verify — cancelling a subscription,
    a daily streak. The user asserts it; we label it as self-reported rather
    than pretending we checked.

    Roadmap: verification by absence — no charge from that merchant within one
    billing cycle proves the cancellation. Needs the nightly sync job.
    """
    u = store.user(UID)
    missions = u["missions"] or get_missions()
    m = next((x for x in missions if x.id == mission_id), None)
    if m is None:
        raise HTTPException(404, "Unknown mission")
    if m.verified:
        raise HTTPException(409, "This mission is verified from your transactions — "
                                 "it completes on its own.")
    u.setdefault("self_done", set()).add(m.id)
    m.complete = True
    return m


@app.get("/api/progression", response_model=Progression)
def get_progression() -> Progression:
    u = store.user(UID)
    return build_progression(u["xp"], u["coins"], u["streak"], u["skins"], u["active_skin"])


@app.get("/api/tower", response_model=TowerState)
def get_tower(days: int = 30) -> TowerState:
    profile = _require_profile()
    txns = _safe(provider().transactions, days)
    plan = build_plan(txns, profile.allocation, profile.monthly_income, days)
    return build_tower(plan, get_progression())


# ------------------------------------------------------------------ shop

@app.get("/api/shop", response_model=list[ShopItem])
def get_shop() -> list[ShopItem]:
    owned = set(store.user(UID)["skins"])
    return [ShopItem(**item, owned=item["id"] in owned) for item in SHOP]


class BuyBody(BaseModel):
    item_id: str


@app.post("/api/shop/buy", response_model=Progression)
def buy(body: BuyBody) -> Progression:
    u = store.user(UID)
    item = next((i for i in SHOP if i["id"] == body.item_id), None)
    if item is None:
        raise HTTPException(404, "Unknown item")
    if item["id"] in u["skins"]:
        raise HTTPException(409, "Already owned")
    if u["coins"] < item["cost"]:
        raise HTTPException(402, f"Need {item['cost'] - u['coins']} more coins")
    u["coins"] -= item["cost"]
    u["skins"].append(item["id"])
    if item["kind"] == "skin":
        u["active_skin"] = item["id"]
    return get_progression()


# ------------------------------------------------------------------ demo helpers

@app.post("/api/demo/reset")
def demo_reset() -> dict:
    store.reset(UID)
    return {"ok": True}


class ProviderBody(BaseModel):
    provider: str  # "basiq" | "mock" | "auto"


@app.post("/api/demo/provider")
def set_provider(body: ProviderBody) -> dict:
    """Flip the data source at runtime. 'auto' restores normal behaviour."""
    global _forced_provider
    if body.provider not in ("basiq", "mock", "csv", "auto"):
        raise HTTPException(400, "provider must be basiq, mock, csv or auto")
    _forced_provider = None if body.provider in ("auto", "basiq") else body.provider
    return health()


@app.get("/api/health")
def health() -> dict:
    p = provider()
    name = ("basiq" if isinstance(p, BasiqProvider)
            else "csv" if isinstance(p, CsvProvider) else "mock")
    return {
        "ok": True,
        "provider": name,
        # UI contract: when false, show a "demo data" banner and do NOT render
        # any per-mission "verified by your bank" badge.
        "data_trusted": name == "basiq",
        "csv_configured": bool(os.getenv("WEALTH_CSV")),
        "basiq_configured": bool(os.getenv("BASIQ_API_KEY")),
        "forced": _forced_provider,
    }
