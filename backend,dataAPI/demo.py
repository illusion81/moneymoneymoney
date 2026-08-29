#!/usr/bin/env python3
"""Narrated walkthrough of the whole backend. For showing teammates.

    .venv/bin/uvicorn main:app --port 8000     # terminal 1
    .venv/bin/python demo.py                   # terminal 2

Deterministic and safe to re-run — it resets state first. Read the bold lines
out loud; they are the story, not the code.
"""
import sys, time, json, urllib.request

BASE = "http://localhost:8000"
B, D, G, Y, R = "\033[1m", "\033[2m", "\033[32m", "\033[33m", "\033[31m"
X = "\033[0m"
if not sys.stdout.isatty():
    B = D = G = Y = R = X = ""


def call(method, path, body=None):
    req = urllib.request.Request(
        BASE + path, method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read() or "null")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or "null")
    except urllib.error.URLError:
        print(f"{R}Backend not running. Start it first:{X}\n"
              f"  .venv/bin/uvicorn main:app --port 8000")
        sys.exit(1)


def beat(n, title, say):
    print(f"\n{B}[{n}] {title}{X}")
    print(f"{D}    \"{say}\"{X}\n")
    time.sleep(0.4)


call("POST", "/api/demo/reset")
print(f"{B}Wealth Tower — backend walkthrough{X}")

beat(1, "Where the data comes from",
     "Everything downstream runs off one feed. Mock, a bank CSV export, or live open banking.")
_, h = call("GET", "/api/health")
print(f"    provider = {G}{h['provider']}{X}   bank-direct data: {h['data_trusted']}")
_, c = call("GET", "/api/bank/consent")
print(f"    consent  = {c['state']} — {c['headline']}")

beat(2, "Six questions, then we never ask again",
     "The survey generates their allocation. It is not a template — it moves with their fixed costs.")
_, p = call("POST", "/api/survey", {
    "monthly_income": 2700, "fixed_costs": 1500, "risk_appetite": 4,
    "horizon_months": 24, "has_emergency_fund": False, "top_worry": "subscriptions"})
a = p["allocation"]
print(f"    {p['archetype']} — {p['archetype_blurb']}")
print(f"    invest {a['invest']:.0%}  stable {a['stable']:.0%}  "
      f"living {a['living']:.0%}  reward {a['reward']:.0%}")
if p.get("guardrail_note"):
    print(f"    {Y}guardrail: {p['guardrail_note']}{X}")

beat(3, "Their spending, scored against that plan",
     "This is the number the whole game runs on. One score, zero to one.")
_, plan = call("GET", "/api/plan")
for b in plan["buckets"]:
    mark = f"{G}on track{X}" if b["on_track"] else f"{Y}off plan{X}"
    print(f"    {b['bucket']:<8} ${b['actual_amount']:>8,.0f} / ${b['target_amount']:>8,.0f}   {mark}")
print(f"\n    adherence {B}{plan['adherence']:.2f}{X} — {plan['headline']}")

beat(4, "The gap becomes missions",
     "Generated from their weak spots. Never from rent, groceries or medicine — that is enforced in code.")
_, missions = call("GET", "/api/missions")
for m in missions:
    tag = f"{G}bank-verified{X}" if m["verified"] else f"{Y}self-reported{X}"
    print(f"    {m['title']:<28} {m['xp']:>4} XP  {tag}")

beat(5, "You cannot fake a mission",
     "Claim is checked server-side against the transaction feed. The button is not the source of truth.")
locked = next(m for m in missions if m["verified"] and not m["complete"])
code, err = call("POST", f"/api/missions/{locked['id']}/claim")
print(f"    claiming '{locked['title']}' -> {R}{code}{X}  {err['detail']}")

beat(6, "What the feed cannot see, we label honestly",
     "We cannot watch someone cancel Netflix. So we say self-reported instead of pretending we checked.")
self_rep = next(m for m in missions if not m["verified"])
code, err = call("POST", f"/api/missions/{self_rep['id']}/claim")
print(f"    claim before marking -> {R}{code}{X}  {err['detail']}")
call("POST", f"/api/missions/{self_rep['id']}/mark_done")
_, r = call("POST", f"/api/missions/{self_rep['id']}/claim")
print(f"    mark done, then claim -> {G}+{r['xp_awarded']} XP, +{r['coins_awarded']} coins{X}"
      f"{'  ' + B + 'LEVEL UP' + X if r['levelled_up'] else ''}")

beat(7, "And the tower moves",
     "Height comes from level. Health comes from adherence. Overspend and it cracks.")
_, t = call("GET", "/api/tower")
print(f"    stage {t['stage']}  health {t['health']:.2f}  weather {t['weather']}")
print(f"    {t['caption']}")
for f in t["floors"]:
    bar = "#" * int(f["health"] * 20)
    print(f"    {f['bucket']:<8} {bar:<20} {f['health']:.0%}")

beat(8, "Lose the bank, keep the tower",
     "If they revoke access the tower freezes exactly where it was. We never delete someone's progress.")
_, prog = call("GET", "/api/progression")
print(f"    level {prog['level']}  {prog['coins']} coins  skins {prog['unlocked_skins']}")
print(f"    {D}progression lives with us, not with the bank — revoking costs them nothing{X}")

print(f"\n{B}That is the loop.{X} Survey -> bank -> plan -> missions -> XP -> tower.\n")
