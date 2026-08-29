import json
import random
import re

import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer

MODEL = "HuggingFaceTB/SmolLM2-360M-Instruct"
ADAPTER = "./out"
SLOTS = ["{SURPLUS}", "{SAVINGS_RATE}", "{NET_WORTH}", "{FUTURE_VALUE}",
         "{TOTAL_INTEREST}", "{OVERSPEND}"]
NATIONAL = {"housing": 30, "food": 15, "transport": 15, "entertainment": 5, "other": 15}
CATEGORIES = ["housing", "food", "transport", "entertainment", "other"]

tokenizer = AutoTokenizer.from_pretrained(MODEL)
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token


def fv(current, monthly, rate, years):
    r = rate / 12
    n = years * 12
    return current * (1 + r) ** n + monthly * (((1 + r) ** n - 1) / r)


def sample(income):
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


def tools_of(income, expenses, savings_goal, assets, liabilities):
    te = sum(expenses.values())
    surplus = income - te
    sr = max(0.0, min(1.0, surplus / income)) if income > 0 else 0.0
    pct = {c: (expenses[c] / te * 100 if te > 0 else 0.0) for c in CATEGORIES}
    nw = sum(assets.values()) - sum(liabilities.values())
    proj = fv(assets.get("savings", 0.0), savings_goal, 0.05, 10)
    interest = proj - (assets.get("savings", 0.0) + savings_goal * 120)
    flags = [c for c in CATEGORIES if pct[c] > NATIONAL[c] + 5.0]
    return {"budget": {"surplus": round(surplus, 2), "savingsRate": round(sr, 4)},
            "netWorth": {"netWorth": round(nw, 2)},
            "savings": {"futureValue": round(proj, 2), "totalInterest": round(interest, 2)},
            "benchmark": {"overspendFlags": flags}}


random.seed(123)
test_cases = [tools_of(*sample(random.choice([3500, 5500, 9000, 11000]))) for _ in range(24)]


def generate(model, tools):
    prompt = ("Here are a user's deterministic financial results as JSON. "
              "Write a short, motivating summary using only the placeholder tokens.\n\n"
              + json.dumps(tools))
    text = tokenizer.apply_chat_template([{"role": "user", "content": prompt}], tokenize=False)
    inputs = tokenizer(text, return_tensors="pt").to("cuda")
    with torch.no_grad():
        out = model.generate(**inputs, max_new_tokens=120, do_sample=True,
                             temperature=0.3, top_p=0.9)
    return tokenizer.decode(out[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True).strip()


def score(out):
    digits = bool(re.search(r"\d", out))
    slots = [s for s in SLOTS if s in out]
    return (not digits) and len(slots) >= 1, len(slots), digits


def run(model, label):
    ok = 0
    total_slots = 0
    with_digits = 0
    for i, tc in enumerate(test_cases):
        out = generate(model, tc)
        good, nslots, digits = score(out)
        ok += good
        total_slots += nslots
        with_digits += digits
        if i < 4:
            print(f"  [{label}][{i}] {out[:130]}")
    print(f"{label}: success={ok}/{len(test_cases)} "
          f"({ok/len(test_cases):.0%}), avg_slots={total_slots/len(test_cases):.2f}, "
          f"outputs_with_digits={with_digits}/{len(test_cases)}")


base = AutoModelForCausalLM.from_pretrained(MODEL, torch_dtype=torch.bfloat16, device_map="auto")
print("===== BASE (no adapter) =====")
run(base, "base")

ft = PeftModel.from_pretrained(base, ADAPTER)
print("\n===== FINE-TUNED (r=64, slot data) =====")
run(ft, "ft")
