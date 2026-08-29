"""Bank data providers.

Two implementations behind one interface:

  MockProvider   - seeded, deterministic, always works. Use for dev + as the
                   stage fallback if wifi dies.
  BasiqProvider  - real Australian open banking via Basiq (au-api.basiq.io).

The demo NEVER hard-depends on the network: main.py falls back to Mock if the
Basiq call raises. Set BASIQ_API_KEY to enable the real path.

Lane A: run `python bootstrap.py` rather than poking at this file by hand.
"""
from __future__ import annotations

import os
import re
import csv
import time
import random
import datetime as dt
from typing import Protocol, Optional

import httpx

from models import Account, Transaction, ConnectionStatus, Bucket

# Load backend/.env if python-dotenv is installed. Optional on purpose — the
# mock path must never fail because a dependency is missing.
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
except Exception:
    pass

BASIQ_BASE = "https://au-api.basiq.io"
BASIQ_VERSION = "3.0"
CONSENT_URL = "https://consent.basiq.io/home"

# The Hooli test bank. Only institution you need for the demo.
TEST_INSTITUTION = "AU00000"


# ---------------------------------------------------------------- categorisation

# Basiq enriches transactions with its own class/subClass. That is far better
# than keyword matching, so we map it FIRST and only fall back to keywords.
# Basiq's `class` values, mapped to our four buckets.
BASIQ_CLASS_MAP: dict[str, tuple[str, Bucket]] = {
    "bank-fee":            ("fees", "living"),
    "payment":             ("other", "living"),
    "cash-withdrawal":     ("cash", "living"),
    "transfer":            ("transfer", "stable"),
    "loan-interest":       ("debt", "living"),
    "refund":              ("refund", "living"),
    "direct-credit":       ("income", "living"),
    "interest":            ("savings", "stable"),
    "loan-repayment":      ("debt", "living"),
}

# Keyword rules. Order matters: first hit wins.
CATEGORY_RULES: list[tuple[tuple[str, ...], str, Bucket]] = [
    (("rent", "real estate", "mortgage", "body corp", "property"), "housing", "living"),
    (("energy", "electricity", "water corp", "internet", "telstra", "optus",
      "vodafone", "agl", "origin energy", "belong"), "utilities", "living"),
    (("translink", "go card", "uber trip", "didi", "ola ", "fuel", "ampol",
      "bp ", "7-eleven", "caltex", "parking"), "transport", "living"),
    (("coles", "woolworths", "aldi", "iga", "grocer", "foodworks", "costco"),
     "groceries", "living"),
    (("medicare", "chemist", "pharmacy", "doctor", "dental", "optical",
      "physio", "bupa", "medibank", "hcf"), "health", "living"),
    # NB: bare "uq " was too greedy — it swallowed "MERLO COFFEE UQ ST LUCIA".
    # Campus merchants must stay eating-out; only fees/services are education.
    (("unihub", "tuition", "textbook", "student services", "uq union",
      "student centre", "enrolment", "sa fee"), "education", "living"),
    (("netflix", "spotify", "disney", "youtube premium", "apple.com/bill",
      "google storage", "adobe", "chatgpt", "openai", "microsoft 365",
      "amazon prime", "binge", "stan ", "kayo", "subscription", "audible",
      "patreon", "notion", "canva"), "subscriptions", "reward"),
    (("uber eats", "ubereats", "menulog", "doordash", "deliveroo", "cafe",
      "coffee", "restaurant", "guzman", "mcdonald", "kfc", "hungry jack",
      "domino", "subway", "sushi", "noodle", "bakery", "boost juice",
      "gong cha", "chatime"), "eating-out", "reward"),
    (("steam", "playstation", "xbox", "nintendo", "cinema", "event cinemas",
      "ticketek", "ticketmaster", "bar ", "hotel", "bottle", "liquor", "bws",
      "dan murphy", "kmart", "big w", "target", "cotton on", "uniqlo", "h&m",
      "sephora", "mecca", "jb hi-fi", "gym", "fitness"), "lifestyle", "reward"),
    (("vanguard", "betashares", "stake", "commsec", "selfwealth", "pearler",
      "etf", "swyftx", "coinspot", "binance", "raiz", "spaceship", "superhero"),
     "investment", "invest"),
    (("savings", "term deposit", "high interest", "offset", "goal saver"),
     "savings", "stable"),
    (("afterpay", "zip pay", "zippay", "klarna", "humm", "latitude"),
     "bnpl", "reward"),
    # Money leaving to another person or another of the user's own accounts.
    # NOT spending and NOT saving — plan.py excludes this from every bucket.
    (("transfer to", "payid", "osko", "bpay to", "internal transfer"),
     "transfer-out", "living"),
]

INCOME_HINTS = ("salary", "wage", "pay ", "payroll", "centrelink", "austudy",
                "scholarship", "abstudy", "youth allowance", "stipend")


def classify(description: str, amount: float,
             basiq_class: Optional[str] = None,
             basiq_subclass: Optional[str] = None) -> tuple[str, Bucket]:
    """-> (our category, our bucket).

    Priority: keywords (most specific) -> Basiq's own class -> fallback.
    Keywords win because 'Netflix' is a subscription to us but merely a
    'payment' to Basiq, and the subscription framing is the whole mission.
    """
    d = (description or "").lower()
    sub = (basiq_subclass or "").lower()
    haystack = f"{d} {sub}".strip()

    if amount > 0:
        if any(h in haystack for h in INCOME_HINTS) or basiq_class == "direct-credit":
            return "income", "living"
        return "transfer-in", "stable"

    for needles, cat, bucket in CATEGORY_RULES:
        if any(n in haystack for n in needles):
            return cat, bucket

    if basiq_class and basiq_class in BASIQ_CLASS_MAP:
        return BASIQ_CLASS_MAP[basiq_class]

    return "other", "living"


# ---------------------------------------------------------------- interface

class BankProvider(Protocol):
    def connect(self, persona: str) -> ConnectionStatus: ...
    def accounts(self) -> list[Account]: ...
    def transactions(self, days: int) -> list[Transaction]: ...


# ---------------------------------------------------------------- mock

MERCHANTS = [
    ("Coles Toowong", -60, -140, 8),
    ("Woolworths St Lucia", -45, -110, 6),
    ("UberEats", -18, -42, 11),
    ("Guzman y Gomez", -14, -24, 5),
    ("Merlo Coffee UQ", -5, -9, 18),
    ("Translink Go Card", -12, -30, 8),
    ("Netflix Subscription", -22.99, -22.99, 1),
    ("Spotify Subscription", -13.99, -13.99, 1),
    ("Adobe Subscription", -29.99, -29.99, 1),
    ("Kmart Indooroopilly", -25, -95, 2),
    ("Event Cinemas", -21, -38, 2),
    ("Steam Games", -15, -60, 2),
    ("Energex Electricity", -95, -150, 1),
    ("Telstra Internet", -79, -79, 1),
    ("Vanguard Investments", -200, -200, 1),
]


class MockProvider:
    """Seeded so every run of the demo tells the same story."""

    def __init__(self, seed: int = 20260829):
        self.seed = seed
        self._persona = "student-au"

    def connect(self, persona: str = "student-au") -> ConnectionStatus:
        self._persona = persona
        return ConnectionStatus(
            provider="mock", connected=True, institution="Hooli Test Bank (offline sim)",
            persona=persona, message="Simulated account — no network required.",
        )

    def accounts(self) -> list[Account]:
        return [
            Account(id="acc-txn", name="Everyday Access", kind="transaction", balance=1842.55),
            Account(id="acc-sav", name="Goal Saver", kind="savings", balance=3120.00),
            Account(id="acc-cc", name="Low Rate Card", kind="credit-card", balance=-612.40),
        ]

    def transactions(self, days: int = 30) -> list[Transaction]:
        rng = random.Random(self.seed)
        today = dt.date.today()
        out: list[Transaction] = []
        n = 0

        for wk in range(0, days, 14):
            d = today - dt.timedelta(days=wk)
            n += 1
            cat, bucket = classify("Salary - Campus Job", 1350.0)
            out.append(Transaction(id=f"tx-{n}", account_id="acc-txn", post_date=d.isoformat(),
                                   description="Salary - Campus Job", amount=1350.0,
                                   category=cat, bucket=bucket))

        for name, lo, hi, freq in MERCHANTS:
            hits = max(1, round(freq * days / 30))
            for _ in range(hits):
                d = today - dt.timedelta(days=rng.randint(0, days - 1))
                amt = round(rng.uniform(min(lo, hi), max(lo, hi)), 2)
                n += 1
                cat, bucket = classify(name, amt)
                out.append(Transaction(id=f"tx-{n}", account_id="acc-txn", post_date=d.isoformat(),
                                       description=name, amount=amt, category=cat, bucket=bucket))

        out.sort(key=lambda t: t.post_date, reverse=True)
        return out


# ---------------------------------------------------------------- basiq

class BasiqError(RuntimeError):
    """Every Basiq failure surfaces as this, with the API's own message attached."""


def _request(method: str, url: str, **kw) -> httpx.Response:
    """Every Basiq call goes through here so transport failures — dead wifi, DNS,
    a corporate proxy, a timeout — surface as BasiqError and hit main.py's mock
    fallback, instead of dumping a traceback mid-demo.
    """
    try:
        return httpx.request(method, url, **kw)
    except httpx.TimeoutException as e:
        raise BasiqError(f"Basiq timed out ({e.__class__.__name__}). Falling back to mock data.") from e
    except httpx.TransportError as e:
        raise BasiqError(
            f"Could not reach Basiq ({e.__class__.__name__}). Check the network — "
            f"the app will keep running on mock data."
        ) from e


def _explain(r: httpx.Response) -> str:
    """Basiq returns structured errors. Show the useful part, not raw JSON."""
    try:
        errs = r.json().get("data", [])
        if errs:
            e = errs[0]
            bits = [e.get("title"), e.get("detail")]
            code = e.get("code")
            msg = " — ".join(b for b in bits if b)
            return f"[{r.status_code}/{code}] {msg}" if code else f"[{r.status_code}] {msg}"
    except Exception:
        pass
    return f"[{r.status_code}] {r.text[:200]}"


class BasiqProvider:
    """Real open banking.

    Full flow (bootstrap.py drives all of it for you):
      1. POST /token  scope=SERVER_ACCESS                -> server token (60 min)
      2. POST /users                                      -> userId
      3. POST /token  scope=CLIENT_ACCESS&userId=...      -> client token
      4. Human opens consent.basiq.io/home?token=<client> -> picks Hooli, logs in
      5. GET  /users/{id}/connections                     -> wait for status 'active'
      6. GET  /jobs/{id}                                  -> wait for steps to succeed
      7. GET  /users/{id}/accounts | /transactions        -> the data
    """

    def __init__(self, api_key: str | None = None, user_id: str | None = None,
                 timeout: float = 20.0):
        self.api_key = api_key or os.getenv("BASIQ_API_KEY", "")
        self.user_id = user_id or os.getenv("BASIQ_USER_ID") or None
        self.timeout = timeout
        self._token: str | None = None
        self._token_expiry = dt.datetime.min
        if not self.api_key:
            raise BasiqError(
                "BASIQ_API_KEY is not set. Copy backend/.env.example to backend/.env "
                "and paste the key from dashboard.basiq.io -> Developers."
            )

    # -- auth ------------------------------------------------------
    def _post_token(self, data: dict) -> dict:
        r = _request("POST",
            f"{BASIQ_BASE}/token",
            headers={
                "Authorization": f"Basic {self.api_key}",
                "Content-Type": "application/x-www-form-urlencoded",
                "basiq-version": BASIQ_VERSION,
            },
            data=data, timeout=self.timeout,
        )
        if r.status_code >= 400:
            hint = ""
            if r.status_code in (401, 403):
                hint = ("  Hint: the key must be the raw base64 string from the dashboard, "
                        "with no 'Basic ' prefix and no quotes in .env.")
            raise BasiqError(f"token request failed: {_explain(r)}{hint}")
        return r.json()

    def _server_token(self) -> str:
        if self._token and dt.datetime.utcnow() < self._token_expiry:
            return self._token
        body = self._post_token({"scope": "SERVER_ACCESS"})
        self._token = body["access_token"]
        self._token_expiry = dt.datetime.utcnow() + dt.timedelta(
            seconds=int(body.get("expires_in", 3600)) - 300)
        return self._token

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self._server_token()}",
                "Accept": "application/json"}

    def _get(self, url: str) -> dict:
        r = _request("GET", url, headers=self._headers(), timeout=self.timeout)
        if r.status_code >= 400:
            raise BasiqError(f"GET {url.replace(BASIQ_BASE, '')} failed: {_explain(r)}")
        return r.json()

    # -- user + consent -------------------------------------------
    def create_user(self, email: str = "demo@wealthtower.app",
                    mobile: str = "+61410000000") -> str:
        r = _request("POST", f"{BASIQ_BASE}/users", headers=self._headers(),
                     json={"email": email, "mobile": mobile}, timeout=self.timeout)
        if r.status_code >= 400:
            raise BasiqError(f"create user failed: {_explain(r)}")
        self.user_id = r.json()["id"]
        return self.user_id

    def ensure_user(self, **kw) -> str:
        return self.user_id or self.create_user(**kw)

    def client_token(self) -> str:
        uid = self.ensure_user()
        return self._post_token({"scope": "CLIENT_ACCESS", "userId": uid})["access_token"]

    def consent_url(self) -> str:
        """Open this in a browser. A human must complete it — that's the point of consent."""
        return f"{CONSENT_URL}?token={self.client_token()}"

    # -- connections + jobs ---------------------------------------
    def connections(self) -> list[dict]:
        uid = self.ensure_user()
        return self._get(f"{BASIQ_BASE}/users/{uid}/connections").get("data", [])

    def active_connection(self) -> Optional[dict]:
        for c in self.connections():
            if (c.get("status") or "").lower() == "active":
                return c
        return None

    def wait_for_connection(self, timeout_s: int = 300, poll_s: int = 5,
                            on_tick=None) -> dict:
        """Block until the human finishes the consent flow. Raises on timeout."""
        deadline = time.time() + timeout_s
        while time.time() < deadline:
            conns = self.connections()
            for c in conns:
                st = (c.get("status") or "").lower()
                if st == "active":
                    return c
                if st in ("invalid", "expired"):
                    raise BasiqError(
                        f"connection ended with status '{st}'. Re-run consent — "
                        f"for Hooli open banking use member 374829 / OTP 227470."
                    )
            if on_tick:
                on_tick(len(conns))
            time.sleep(poll_s)
        raise BasiqError(f"no active connection after {timeout_s}s — was the consent flow completed?")

    def job(self, job_id: str) -> dict:
        return self._get(f"{BASIQ_BASE}/jobs/{job_id}").get("data", {})

    def wait_for_job(self, job_id: str, timeout_s: int = 240, poll_s: int = 4,
                     on_tick=None) -> dict:
        """Consent finishing != data being ready. Basiq retrieves in steps.

        Steps look like: verify-credentials, retrieve-accounts, retrieve-transactions.
        Each has status pending | in-progress | success | failed.
        """
        deadline = time.time() + timeout_s
        last: dict = {}
        while time.time() < deadline:
            last = self.job(job_id)
            steps = last.get("steps", []) or []
            states = [(s.get("title", "?"), (s.get("status") or "").lower()) for s in steps]
            if on_tick:
                on_tick(states)
            if states and all(st == "success" for _, st in states):
                return last
            failed = [t for t, st in states if st == "failed"]
            if failed:
                detail = ""
                for s in steps:
                    if (s.get("status") or "").lower() == "failed":
                        res = s.get("result") or {}
                        detail = res.get("detail") or res.get("title") or ""
                        break
                raise BasiqError(f"job step failed: {', '.join(failed)}. {detail}")
            time.sleep(poll_s)
        raise BasiqError(f"job {job_id} still running after {timeout_s}s")

    def wait_for_transactions(self, days: int = 30, timeout_s: int = 240,
                              poll_s: int = 5, on_tick=None) -> list:
        """Consent going active does NOT mean transactions have landed.

        Basiq keeps retrieving for a while afterwards, and the job id only comes
        back on the POST that creates the connection — it is not on the
        connection object we read later. So rather than chase a job link that
        may not be there, poll the thing we actually care about.
        """
        deadline = time.time() + timeout_s
        attempt = 0
        while time.time() < deadline:
            attempt += 1
            txns = self.transactions(days)
            if txns:
                return txns
            if on_tick:
                on_tick(attempt, int(deadline - time.time()))
            time.sleep(poll_s)
        return []

    # CDR consent is capped at 12 months. Basiq exposes consent objects on
    # newer API versions, but the field names have moved around, so we read
    # what we can and fall back to "granted + 12 months" rather than guessing
    # a schema. The fallback is conservative: it can only prompt too early.
    CONSENT_MAX_DAYS = 365

    def consent(self) -> dict:
        """-> {granted_at, expires_at, revoked} — best effort, never raises past BasiqError."""
        uid = self.ensure_user()
        granted = expires = None
        revoked = False

        try:
            body = self._get(f"{BASIQ_BASE}/users/{uid}/consents")
            for c in body.get("data", []):
                st = (c.get("status") or "").lower()
                if st in ("revoked", "withdrawn"):
                    revoked = True
                granted = granted or c.get("created") or c.get("createdDate")
                expires = expires or c.get("expiryDate") or c.get("expiresAt")
        except BasiqError:
            # endpoint absent on this API version — fall through to connections
            pass

        if granted is None or expires is None:
            for c in self.connections():
                st = (c.get("status") or "").lower()
                if st in ("invalid", "expired"):
                    revoked = True
                granted = granted or c.get("createdDate") or c.get("lastUsed")

        return {"granted_at": (granted or "")[:10] or None,
                "expires_at": (expires or "")[:10] or None,
                "revoked": revoked}

    def refresh(self) -> list[dict]:
        """Force Basiq to re-pull. Useful the morning of the pitch."""
        uid = self.ensure_user()
        r = _request("POST", f"{BASIQ_BASE}/users/{uid}/connections/refresh",
                     headers=self._headers(), timeout=self.timeout)
        if r.status_code >= 400:
            raise BasiqError(f"refresh failed: {_explain(r)}")
        return r.json().get("data", [])

    # -- provider interface ---------------------------------------
    def connect(self, persona: str = "Whistler") -> ConnectionStatus:
        """Non-blocking: reports state, and hands back a consent URL if needed.

        The API can't complete consent on its own — a human clicks through it.
        So this returns the URL rather than pretending to connect.
        """
        uid = self.ensure_user()
        conn = self.active_connection()
        if conn:
            inst = (conn.get("institution") or {}).get("id", TEST_INSTITUTION)
            return ConnectionStatus(
                provider="basiq", connected=True, institution=f"Hooli ({inst})",
                persona=persona, message=f"Connection {conn.get('id')} active for user {uid}.",
            )
        return ConnectionStatus(
            provider="basiq", connected=False, institution=None, persona=persona,
            message=f"Consent required. Open: {self.consent_url()}",
        )

    def accounts(self) -> list[Account]:
        uid = self.ensure_user()
        out = []
        for a in self._get(f"{BASIQ_BASE}/users/{uid}/accounts").get("data", []):
            out.append(Account(
                id=a["id"],
                name=a.get("name") or a.get("accountNo") or "Account",
                kind=(a.get("class") or {}).get("type", "transaction"),
                balance=float(a.get("balance") or 0),
                currency=a.get("currency", "AUD"),
            ))
        return out

    def transactions(self, days: int = 30) -> list[Transaction]:
        uid = self.ensure_user()
        since = (dt.date.today() - dt.timedelta(days=days)).isoformat()
        url = (f"{BASIQ_BASE}/users/{uid}/transactions"
               f"?filter=transaction.postDate.gt('{since}')&limit=500")
        out: list[Transaction] = []
        pages = 0
        while url and pages < 20:          # hard stop; sandbox is capped anyway
            body = self._get(url)
            for t in body.get("data", []):
                desc = t.get("description") or "Transaction"
                amt = float(t.get("amount") or 0)
                cls = (t.get("class") or None)
                if isinstance(cls, dict):
                    cls = cls.get("type")
                sub = ((t.get("subClass") or {}) or {}).get("title")
                cat, bucket = classify(desc, amt, basiq_class=cls, basiq_subclass=sub)
                out.append(Transaction(
                    id=t["id"],
                    account_id=(t.get("account") or {}).get("id")
                               if isinstance(t.get("account"), dict) else (t.get("account") or "unknown"),
                    post_date=(t.get("postDate") or t.get("transactionDate") or "")[:10],
                    description=desc, amount=amt, category=cat, bucket=bucket,
                ))
            url = (body.get("links") or {}).get("next")
            pages += 1
        return out

# ---------------------------------------------------------------- csv

class CsvProvider:
    """Real bank data from a CSV export — no credentials, no third party.

    Built for CommBank/NetBank exports but column-sniffs, so ANZ/NAB/Westpac
    exports work too. CommBank's default export is headerless:
        Date, Amount, Description, Balance      (dates as DD/MM/YYYY)

    Privacy: account numbers, BSBs and long digit runs are scrubbed out of
    descriptions on load. The file never leaves the machine and nothing is
    sent to Basiq.
    """

    DATE_KEYS = ("date", "transaction date", "posting date", "processed date")
    DESC_KEYS = ("description", "narrative", "details", "transaction", "merchant")
    AMT_KEYS = ("amount", "value")
    DEBIT_KEYS = ("debit", "withdrawal", "debit amount")
    CREDIT_KEYS = ("credit", "deposit", "credit amount")

    # BSB (123-456), long digit runs, card numbers
    _SCRUB = re.compile(r"\b(\d{3}-\d{3}|\d{6,})\b")

    def __init__(self, path: str | None = None):
        self.path = path or os.getenv("WEALTH_CSV", "")
        if not self.path or not os.path.exists(self.path):
            raise FileNotFoundError(
                f"CSV not found: {self.path!r}. Set WEALTH_CSV to your export."
            )
        self._rows = self._load()

    # -- parsing ---------------------------------------------------
    @staticmethod
    def _parse_date(v: str) -> str:
        v = (v or "").strip().strip('"')
        for fmt in ("%d/%m/%Y", "%d/%m/%y", "%Y-%m-%d", "%d-%m-%Y", "%d %b %Y", "%d %B %Y"):
            try:
                return dt.datetime.strptime(v, fmt).date().isoformat()
            except ValueError:
                continue
        return dt.date.today().isoformat()

    @staticmethod
    def _parse_amount(v: str) -> float:
        v = (v or "").strip().replace("$", "").replace(",", "").replace('"', "")
        if not v:
            return 0.0
        neg = v.startswith("(") and v.endswith(")")
        v = v.strip("()")
        try:
            n = float(v)
        except ValueError:
            return 0.0
        return -n if neg else n

    def _scrub(self, desc: str) -> str:
        return self._SCRUB.sub("****", desc).strip()

    def _pick(self, header: list[str], keys) -> int | None:
        for i, h in enumerate(header):
            if h.strip().lower() in keys:
                return i
        return None

    def _load(self) -> list[Transaction]:
        with open(self.path, newline="", encoding="utf-8-sig") as f:
            rows = [r for r in csv.reader(f) if any(c.strip() for c in r)]
        if not rows:
            return []

        first = rows[0]
        has_header = any(c.strip().lower() in
                         self.DATE_KEYS + self.DESC_KEYS + self.AMT_KEYS for c in first)

        if has_header:
            header = [c.strip().lower() for c in first]
            body = rows[1:]
            i_date = self._pick(header, self.DATE_KEYS)
            i_desc = self._pick(header, self.DESC_KEYS)
            i_amt = self._pick(header, self.AMT_KEYS)
            i_deb = self._pick(header, self.DEBIT_KEYS)
            i_cred = self._pick(header, self.CREDIT_KEYS)
        else:
            # CommBank headerless: Date, Amount, Description, Balance
            body = rows
            i_date, i_amt, i_desc, i_deb, i_cred = 0, 1, 2, None, None

        out: list[Transaction] = []
        for n, r in enumerate(body, 1):
            def cell(i):
                return r[i] if i is not None and i < len(r) else ""

            if i_amt is not None:
                amt = self._parse_amount(cell(i_amt))
            else:
                debit = self._parse_amount(cell(i_deb))
                credit = self._parse_amount(cell(i_cred))
                amt = credit - abs(debit)
            if amt == 0:
                continue

            desc = self._scrub(cell(i_desc) or "Transaction")
            cat, bucket = classify(desc, amt)
            out.append(Transaction(
                id=f"csv-{n}", account_id="csv", post_date=self._parse_date(cell(i_date)),
                description=desc, amount=amt, category=cat, bucket=bucket,
            ))

        out.sort(key=lambda t: t.post_date, reverse=True)
        return out

    # -- provider interface ---------------------------------------
    def connect(self, persona: str = "csv") -> ConnectionStatus:
        return ConnectionStatus(
            provider="mock", connected=True,
            institution=f"CSV export ({os.path.basename(self.path)})",
            persona=persona,
            message=f"{len(self._rows)} transactions loaded locally. Nothing sent anywhere.",
        )

    def accounts(self) -> list[Account]:
        bal = sum(t.amount for t in self._rows)
        return [Account(id="csv", name="Imported account", kind="transaction",
                        balance=round(bal, 2))]

    def transactions(self, days: int = 30) -> list[Transaction]:
        cutoff = (dt.date.today() - dt.timedelta(days=days)).isoformat()
        return [t for t in self._rows if t.post_date >= cutoff]
