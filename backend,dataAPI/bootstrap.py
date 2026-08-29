#!/usr/bin/env python3
"""Lane A: one command that takes you from an API key to real bank data.

    python bootstrap.py

It will:
  1. check your key works
  2. create a Basiq user (or reuse BASIQ_USER_ID)
  3. print a consent URL for you to open and log in as a test persona
  4. wait for the connection to go active
  5. wait for Basiq to finish retrieving accounts + transactions
  6. print what it found, plus a categorisation audit
  7. tell you exactly what to paste into .env

Everything is resumable. If step 4 times out, re-run it — it reuses the user.

Flags:
    --audit-only     skip consent, just re-read data for the saved user
    --mock           run the audit against the mock provider (no key needed)
    --refresh        force Basiq to re-pull before reading
    --days N         window for transactions (default 30)
"""
from __future__ import annotations

import os
import sys
import argparse
from collections import Counter, defaultdict

from bank import BasiqProvider, MockProvider, BasiqError, classify  # noqa: F401

ENV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")

G, Y, R, B, DIM, RESET = "\033[32m", "\033[33m", "\033[31m", "\033[36m", "\033[2m", "\033[0m"
if not sys.stdout.isatty() or os.getenv("NO_COLOR"):
    G = Y = R = B = DIM = RESET = ""


def step(n: int, text: str) -> None:
    print(f"\n{B}[{n}]{RESET} {text}")


def ok(text: str) -> None:
    print(f"    {G}✓{RESET} {text}")


def warn(text: str) -> None:
    print(f"    {Y}!{RESET} {text}")


def die(text: str) -> None:
    print(f"\n    {R}✗ {text}{RESET}\n")
    sys.exit(1)


# ---------------------------------------------------------------- audit

def audit(txns, accounts, days: int) -> None:
    print(f"\n{B}── Accounts ─────────────────────────────────────────{RESET}")
    if not accounts:
        warn("no accounts returned")
    for a in accounts:
        print(f"    {a.name:<28} {a.kind:<14} ${a.balance:>10,.2f}")

    print(f"\n{B}── Transactions ({days}d) ────────────────────────────{RESET}")
    if not txns:
        die("zero transactions. Consent may have completed but retrieval failed — "
            "re-run with --refresh, or check the job output above.")

    inflow = sum(t.amount for t in txns if t.amount > 0)
    outflow = -sum(t.amount for t in txns if t.amount < 0)
    print(f"    {len(txns)} transactions   in ${inflow:,.0f}   out ${outflow:,.0f}")

    by_bucket: dict[str, float] = defaultdict(float)
    for t in txns:
        if t.amount < 0:
            by_bucket[t.bucket] += -t.amount
    print(f"\n    {DIM}spend by bucket{RESET}")
    for b in ("invest", "stable", "living", "reward"):
        amt = by_bucket.get(b, 0.0)
        pct = (amt / outflow * 100) if outflow else 0
        bar = "█" * int(pct / 3)
        print(f"    {b:<9} ${amt:>9,.0f}  {pct:>5.1f}%  {B}{bar}{RESET}")

    cats = Counter(t.category for t in txns if t.amount < 0)
    print(f"\n    {DIM}spend by category{RESET}")
    for cat, n in cats.most_common():
        amt = sum(-t.amount for t in txns if t.amount < 0 and t.category == cat)
        flag = f"  {Y}<- unclassified{RESET}" if cat == "other" else ""
        print(f"    {cat:<16} {n:>4} txns  ${amt:>9,.0f}{flag}")

    # the number Lane A actually cares about
    other = [t for t in txns if t.amount < 0 and t.category == "other"]
    other_amt = sum(-t.amount for t in other)
    coverage = 100 - (other_amt / outflow * 100 if outflow else 0)

    print(f"\n{B}── Categorisation coverage ──────────────────────────{RESET}")
    colour = G if coverage >= 85 else Y if coverage >= 70 else R
    print(f"    {colour}{coverage:.1f}%{RESET} of spend is classified "
          f"({len(other)} txns, ${other_amt:,.0f} fell through to 'other')")

    if other:
        print(f"\n    {DIM}Top unmatched merchants — add these to CATEGORY_RULES in bank.py:{RESET}")
        unmatched = Counter(t.description for t in other)
        for desc, n in unmatched.most_common(12):
            amt = sum(-t.amount for t in other if t.description == desc)
            print(f"      {desc[:44]:<46} {n:>3}×  ${amt:>8,.0f}")

    if coverage < 85:
        warn("Under 85%. Missions are generated from categories, so anything in "
             "'other' is invisible to the game. Fix the top offenders above.")
    else:
        ok("Good enough for the demo.")

    # mission-relevant signals
    subs = sum(-t.amount for t in txns if t.category == "subscriptions")
    eat = sum(-t.amount for t in txns if t.category == "eating-out")
    print(f"\n{B}── Mission triggers ─────────────────────────────────{RESET}")
    print(f"    subscriptions  ${subs:>8,.0f}   {'✓ sweep mission will fire' if subs > 0 else '✗ no subscription mission'}")
    print(f"    eating-out     ${eat:>8,.0f}   {'✓ cook-at-home mission will fire' if eat > 60 else '✗ under $60 threshold'}")
    if subs == 0 or eat <= 60:
        warn("A persona with no subscriptions makes for a weak demo. "
             "Try 'Whistler' (BNPL + subscriptions) or 'gavinBelson'.")


# ---------------------------------------------------------------- main

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit-only", action="store_true")
    ap.add_argument("--mock", action="store_true")
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--days", type=int, default=30)
    args = ap.parse_args()

    if args.mock:
        print(f"{B}Wealth Tower — mock provider audit{RESET}")
        m = MockProvider()
        audit(m.transactions(args.days), m.accounts(), args.days)
        return

    print(f"{B}Wealth Tower — Basiq bootstrap{RESET}")

    step(1, "Checking API key")
    try:
        b = BasiqProvider()
        b._server_token()
    except BasiqError as e:
        die(str(e))
    ok("key accepted, server token issued")

    step(2, "User")
    if b.user_id:
        ok(f"reusing BASIQ_USER_ID={b.user_id}")
    else:
        try:
            uid = b.create_user()
        except BasiqError as e:
            die(str(e))
        ok(f"created user {uid}")
        print(f"\n    {Y}Paste this into {ENV_PATH}:{RESET}")
        print(f"    BASIQ_USER_ID={uid}\n")

    if not args.audit_only:
        conn = None
        try:
            conn = b.active_connection()
        except BasiqError as e:
            die(str(e))

        if conn:
            step(3, "Connection")
            ok(f"already active: {conn.get('id')}")
        else:
            step(3, "Consent — this part needs a human")
            try:
                url = b.consent_url()
            except BasiqError as e:
                die(str(e))
            print(f"\n    Open this in a browser:\n\n    {B}{url}{RESET}\n")
            print(f"    {DIM}Pick 'Hooli' (AU00000). For the open-banking flow use{RESET}")
            print(f"    {DIM}member number 374829 and OTP 227470.{RESET}")
            print(f"    {DIM}For the login flow, best demo persona is Whistler / ShowBox.{RESET}")
            print(f"\n    Waiting for you to finish (5 min timeout)…")

            def tick(n):
                print(f"    {DIM}… {n} connection(s) so far{RESET}")

            try:
                conn = b.wait_for_connection(on_tick=tick)
            except BasiqError as e:
                die(str(e))
            ok(f"connection {conn.get('id')} is active")

        step(4, "Waiting for data retrieval")
        job_id = None
        for link_key in ("jobs", "job"):
            link = (conn.get("links") or {}).get(link_key, "") if conn else ""
            if link:
                job_id = link.rstrip("/").split("/")[-1]
                break
        if job_id:
            def jtick(states):
                for t, s in states:
                    mark = "✓" if s == "success" else "…"
                    print(f"    {DIM}{mark} {t}: {s}{RESET}")
            try:
                b.wait_for_job(job_id, on_tick=jtick)
                ok("all retrieval steps succeeded")
            except BasiqError as e:
                warn(f"{e}  — reading whatever landed anyway")
        else:
            warn("no job link on the connection; skipping the wait")

    if args.refresh:
        step(5, "Forcing a refresh")
        try:
            b.refresh()
            ok("refresh queued — give it ~20s before trusting the numbers")
        except BasiqError as e:
            warn(str(e))

    step(6, "Reading data")
    try:
        accounts = b.accounts()
        txns = b.transactions(args.days)
        if not txns:
            warn("no transactions yet — Basiq is probably still retrieving. Polling…")

            def ttick(n, left):
                print(f"    {DIM}… still empty (attempt {n}, {left}s left){RESET}")

            txns = b.wait_for_transactions(args.days, on_tick=ttick)
    except BasiqError as e:
        die(str(e))
    ok(f"{len(accounts)} accounts, {len(txns)} transactions")

    audit(txns, accounts, args.days)

    print(f"\n{B}── Next ─────────────────────────────────────────────{RESET}")
    print(f"    1. Make sure .env has BASIQ_API_KEY and BASIQ_USER_ID={b.user_id}")
    print(f"    2. Restart uvicorn, then: curl localhost:8000/api/health")
    print(f"       It should say {G}\"provider\": \"basiq\"{RESET}")
    print(f"    3. Tell Lane B the data is live.\n")


if __name__ == "__main__":
    main()
