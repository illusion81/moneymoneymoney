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
from bank import MockProvider, BasiqProvider, BasiqError
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


def provider():
    """Basiq if it's configured AND healthy, mock otherwise. Never raises."""
    global _basiq
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
    claimed = store.user(UID)["claimed"]
    for m in missions:
        m.claimed = m.id in claimed
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

    before = build_progression(u["xp"], u["coins"], u["streak"], u["skins"], u["active_skin"])
    u["xp"] += m.xp
    u["coins"] += m.coins
    u["claimed"].add(m.id)
    after = build_progression(u["xp"], u["coins"], u["streak"], u["skins"], u["active_skin"])

    return ClaimResult(mission_id=m.id, xp_awarded=m.xp, coins_awarded=m.coins,
                       levelled_up=after.level > before.level, progression=after)


# ------------------------------------------------------------------ progression + tower

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


@app.get("/api/health")
def health() -> dict:
    p = provider()
    return {"ok": True, "provider": "basiq" if isinstance(p, BasiqProvider) else "mock"}
