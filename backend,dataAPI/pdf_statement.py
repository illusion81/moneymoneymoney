"""Read transactions out of a bank statement PDF (ANZ Plus format).

Why this exists: ANZ's app exports statements as PDF, not CSV, and plenty of
people will never complete a CDR consent flow. "Upload your statement" is a
real onboarding path, not just a demo workaround.

The hard part: ANZ prints Credit and Debit in separate columns, but extracted
text collapses them, so a row looks the same either way:

    30 Jul VISA DEBIT PURCHASE ... $8.21 $7,201.79
    30 Jul ANZ ATM TOOWONG ...     $5,000.00 $7,210.00

One is money out, the other money in. The running balance is what disambiguates:
rows are newest-first, so a row's signed amount is its balance minus the balance
of the row below it. We use that instead of guessing from the description.
"""
from __future__ import annotations

import os
import re
import datetime as dt

from models import Account, Transaction, ConnectionStatus
from bank import classify

MONTHS = "jan feb mar apr may jun jul aug sep oct nov dec".split()
MONTH_N = {m: i + 1 for i, m in enumerate(MONTHS)}

ROW = re.compile(r"^\s*(\d{1,2})\s+(%s)[a-z]*\s+(.+)$" % "|".join(MONTHS), re.I)
AMOUNT = re.compile(r"\$?-?\d{1,3}(?:,\d{3})*\.\d{2}")
PERIOD = re.compile(r"(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\s*[-–]\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})")
OPENING = re.compile(r"opening balance\s+\$?(-?[\d,]+\.\d{2})", re.I)

# Account numbers, BSBs, card fragments, reference numbers.
SCRUB = re.compile(r"(\b\d{3}[- ]\d{3}[- ]?\d{6,}\b|\b\d{6,}\b|#\d+|\bCARD \d{4}\b)")

NOISE = ("effective date", "opening balance", "closing balance", "account opened",
         "please check your statement", "if you notice any errors",
         "australia and new zealand banking", "afsl", "page ", "account name",
         "branch number", "transactions", "date description")


def _num(s: str) -> float:
    return float(s.replace("$", "").replace(",", ""))


class PdfStatementProvider:
    def __init__(self, path: str | None = None):
        self.path = path or os.getenv("WEALTH_PDF", "")
        if not self.path or not os.path.exists(self.path):
            raise FileNotFoundError(f"PDF not found: {self.path!r}")
        self._rows = self._parse()

    # ---------------------------------------------------------------- parse
    def _lines(self) -> list[str]:
        try:
            import pdfplumber
        except ImportError:
            raise RuntimeError("pdfplumber not installed:  .venv/bin/pip install pdfplumber")
        out: list[str] = []
        with pdfplumber.open(self.path) as pdf:
            for page in pdf.pages:
                out.extend((page.extract_text() or "").split("\n"))
        return out

    def _parse(self) -> list[Transaction]:
        lines = self._lines()
        blob = "\n".join(lines)

        # statement period gives us the year(s) the bare "30 Jul" dates belong to
        year_end = dt.date.today().year
        year_start = year_end
        m = PERIOD.search(blob)
        if m:
            year_start, year_end = int(m.group(3)), int(m.group(6))

        opening = None
        mo = OPENING.search(blob)
        if mo:
            opening = _num(mo.group(1))

        # 1. gather raw rows, folding continuation lines into the description
        raw: list[dict] = []
        for line in lines:
            low = line.lower().strip()
            if not low:
                continue
            m = ROW.match(line)
            if m:
                if any(k in low for k in NOISE):
                    continue
                day, mon, rest = int(m.group(1)), m.group(2).lower()[:3], m.group(3)
                amounts = AMOUNT.findall(rest)
                if len(amounts) < 2:
                    # no amount + balance pair — probably a wrapped line
                    if raw:
                        raw[-1]["desc"] += " " + rest.strip()
                    continue
                desc = AMOUNT.split(rest)[0].strip()
                raw.append({"day": day, "mon": MONTH_N[mon], "desc": desc,
                            "amount": _num(amounts[-2]), "balance": _num(amounts[-1])})
            elif raw and not any(k in low for k in NOISE):
                # continuation of the previous description
                if not AMOUNT.search(line):
                    raw[-1]["desc"] += " " + line.strip()

        # 2. sign each amount from the balance it produced.
        #    Rows are newest-first, so previous balance = the next row's balance.
        out: list[Transaction] = []
        for i, r in enumerate(raw):
            prev_bal = raw[i + 1]["balance"] if i + 1 < len(raw) else opening
            if prev_bal is None:
                signed = -r["amount"]          # last resort: assume money out
            else:
                delta = round(r["balance"] - prev_bal, 2)
                signed = delta if abs(abs(delta) - r["amount"]) < 0.01 else (
                    r["amount"] if delta > 0 else -r["amount"])

            year = year_end if r["mon"] == (12 if year_end != year_start else r["mon"]) else year_end
            if year_start != year_end and r["mon"] >= 7:
                year = year_start
            try:
                date = dt.date(year, r["mon"], r["day"]).isoformat()
            except ValueError:
                date = dt.date.today().isoformat()

            desc = SCRUB.sub("****", r["desc"])
            # Strip payment-rail boilerplate so the merchant is what shows on
            # screen: "VISA DEBIT PURCHASE CARD 9691 ANTHROPIC" -> "ANTHROPIC".
            desc = re.sub(r"^\s*(VISA DEBIT PURCHASE|EFTPOS PURCHASE|EFTPOS|"
                          r"PAYMENT TO|PAYMENT|DIRECT DEBIT|OSKO PAYMENT TO)\b",
                          "", desc, flags=re.I)
            desc = re.sub(r"\*{2,}", " ", desc)
            desc = re.sub(r"\s{2,}", " ", desc).strip(" -,")
            # collapse "ANTHROPIC ANTHROPIC.COM" -> "ANTHROPIC.COM"
            parts = desc.split()
            if len(parts) > 1 and parts[1].lower().startswith(parts[0].lower()):
                desc = " ".join(parts[1:])
            # "PAYMENT TO Firstname Lastname" is a person-to-person transfer,
            # not spending. A business name in the same slot is not.
            raw_desc = r["desc"]
            is_p2p = (re.match(r"^\s*(PAYMENT|OSKO PAYMENT|TRANSFER)\s+TO\b", raw_desc, re.I)
                      and re.match(r"^[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2}$", desc))
            if is_p2p:
                cat, bucket = "transfer-out", "living"
            else:
                cat, bucket = classify(desc, signed)
            out.append(Transaction(id=f"pdf-{i+1}", account_id="pdf", post_date=date,
                                   description=desc, amount=signed,
                                   category=cat, bucket=bucket))
        out.sort(key=lambda t: t.post_date, reverse=True)
        return out

    # ---------------------------------------------------------------- provider
    def connect(self, persona: str = "pdf") -> ConnectionStatus:
        return ConnectionStatus(
            provider="mock", connected=True,
            institution=f"Statement PDF ({os.path.basename(self.path)})",
            persona=persona,
            message=f"{len(self._rows)} transactions parsed locally. Nothing sent anywhere.")

    def accounts(self) -> list[Account]:
        bal = self._rows[0].amount if self._rows else 0.0
        return [Account(id="pdf", name="Imported statement", kind="transaction",
                        balance=round(sum(t.amount for t in self._rows), 2))]

    def transactions(self, days: int = 30) -> list[Transaction]:
        cutoff = (dt.date.today() - dt.timedelta(days=days)).isoformat()
        return [t for t in self._rows if t.post_date >= cutoff]
