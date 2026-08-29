import json
import random
import re
import urllib.request

random.seed(42)

TEACHER = "granite4.1:3b"
URL = "http://localhost:11434/api/chat"
NATIONAL = {"housing": 30, "food": 15, "transport": 15, "entertainment": 5, "other": 15}
CATEGORIES = ["housing", "food", "transport", "entertainment", "other"]

SLOTS = ["{SURPLUS}", "{SAVINGS_RATE}", "{NET_WORTH}", "{FUTURE_VALUE}",
         "{TOTAL_INTEREST}", "{OVERSPEND}"]

SYSTEM = (
    "You write concise, encouraging personal-finance summaries. "
    "NEVER write any digits or numbers. Replace every number with one of these "
    "placeholder tokens: {SURPLUS} (monthly surplus), {SAVINGS_RATE} (savings "
    "rate as a percentage), {NET_WORTH} (net worth), {FUTURE_VALUE} (projected "
    "savings in 10 years), {TOTAL_INTEREST} (total interest earned), "
    "{OVERSPEND} (comma-separated overspent categories). Reply with 2-4 "
    "sentences of plain prose using only these tokens."
)


def future_value(current, monthly, annual_rate, years):
    r = annual_rate / 12
    n = years * 12
    return current * (1 + r) ** n + monthly * (((1 + r) ** n - 1) / r)


def sample_profile():
    income = random.choice([3000, 4000, 5000, 6000, 7000, 8000, 10000, 12000])
    shares = {"housing": random.uniform(0.22, 0.38), "food": random.uniform(0.08, 0.16),
              "transport": random.uniform(0.05, 0.12), "entertainment": random.uniform(0.03, 0.10),
              "other": random.uniform(0.06, 0.14)}
    expenses = {c: round(income * shares[c], 2) for c in CATEGORIES}
    savings_goal = round(income * random.uniform(0.05, 0.25), 2)
    assets = {"savings": round(income * random.uniform(0.5, 6.0), 2),
              "retirement": round(income * random.uniform(1.0, 20.0), 2)}
    liabilities = {"credit card": round(income * random.uniform(0.0, 1.5), 2),
                   "loan": round(income * random.uniform(0.0, 8.0), 2)}
    return income, expenses, savings_goal, assets, liabilities


def compute_tools(income, expenses, savings_goal, assets, liabilities):
    total_expenses = sum(expenses.values())
    surplus = income - total_expenses
    savings_rate = max(0.0, min(1.0, surplus / income)) if income > 0 else 0.0
    cat_pct = {c: (expenses[c] / total_expenses * 100 if total_expenses > 0 else 0.0)
               for c in CATEGORIES}
    total_assets = sum(assets.values())
    total_liabilities = sum(liabilities.values())
    net_worth = total_assets - total_liabilities
    fv = future_value(assets.get("savings", 0.0), savings_goal, 0.05, 10)
    interest = fv - (assets.get("savings", 0.0) + savings_goal * 120)
    overspend = [c for c in CATEGORIES if cat_pct[c] > NATIONAL[c] + 5.0]
    return {
        "budget": {"totalExpenses": round(total_expenses, 2), "surplus": round(surplus, 2),
                   "savingsRate": round(savings_rate, 4)},
        "netWorth": {"netWorth": round(net_worth, 2)},
        "savings": {"futureValue": round(fv, 2), "totalInterest": round(interest, 2)},
        "cashFlow": {"averageSurplus": round(surplus, 2), "negativeMonths": 0 if surplus >= 0 else 1},
        "benchmark": {"overspendFlags": overspend},
    }


def ask(prompt):
    body = json.dumps({"model": TEACHER, "stream": False,
                       "messages": [{"role": "system", "content": SYSTEM},
                                    {"role": "user", "content": prompt}],
                       "options": {"temperature": 0.7, "num_predict": 200}}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())["message"]["content"].strip()


def fallback(tools):
    b, nw, s = tools["budget"], tools["netWorth"], tools["savings"]
    flags = tools["benchmark"]["overspendFlags"]
    parts = []
    if b["surplus"] > 0:
        parts.append("Your budget shows a healthy surplus of {SURPLUS}.")
    else:
        parts.append("Your budget is in deficit by {SURPLUS}.")
    parts.append("Your savings rate is {SAVINGS_RATE} and your net worth is {NET_WORTH}.")
    parts.append("Over ten years this path could grow savings to {FUTURE_VALUE} with {TOTAL_INTEREST} in interest.")
    parts.append("Watch {OVERSPEND}." if flags else "No category is over the benchmark.")
    return " ".join(parts)


def good(text):
    if re.search(r"\d", text):
        return False
    return any(s in text for s in SLOTS)


def build_example(i):
    income, expenses, savings_goal, assets, liabilities = sample_profile()
    tools = compute_tools(income, expenses, savings_goal, assets, liabilities)
    prompt = ("Here are a user's deterministic financial results as JSON. "
              "Write a short, motivating summary using only the placeholder tokens.\n\n"
              + json.dumps(tools))
    for _ in range(3):
        text = ask(prompt)
        if good(text):
            return {"messages": [{"role": "user", "content": prompt},
                                 {"role": "assistant", "content": text}]}
    return {"messages": [{"role": "user", "content": prompt},
                         {"role": "assistant", "content": fallback(tools)}]}


def main():
    examples = []
    for i in range(200):
        examples.append(build_example(i))
        if (i + 1) % 20 == 0:
            print(f"generated {i + 1}/200", flush=True)
    random.shuffle(examples)
    train, val = examples[:180], examples[180:]
    with open("train.jsonl", "w") as f:
        for e in train:
            f.write(json.dumps(e) + "\n")
    with open("val.jsonl", "w") as f:
        for e in val:
            f.write(json.dumps(e) + "\n")
    print(f"wrote {len(train)} train / {len(val)} val examples", flush=True)


if __name__ == "__main__":
    main()
