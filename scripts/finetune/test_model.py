import json

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

MODEL = "HuggingFaceTB/SmolLM2-360M-Instruct"
ADAPTER = "./out"

tokenizer = AutoTokenizer.from_pretrained(MODEL)
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token

test_cases = [
    {"budget": {"totalExpenses": 2400.00, "surplus": 1600.00, "savingsRate": 0.40},
     "netWorth": {"netWorth": 60000.00},
     "savings": {"futureValue": 220000.00, "totalInterest": 52000.00},
     "cashFlow": {"averageSurplus": 1600.00, "negativeMonths": 0},
     "benchmark": {"overspendFlags": []}},
    {"budget": {"totalExpenses": 5200.00, "surplus": -200.00, "savingsRate": 0.0},
     "netWorth": {"netWorth": -4500.00},
     "savings": {"futureValue": 18000.00, "totalInterest": 3000.00},
     "cashFlow": {"averageSurplus": -200.00, "negativeMonths": 1},
     "benchmark": {"overspendFlags": ["food", "entertainment"]}},
    {"budget": {"totalExpenses": 3100.00, "surplus": 900.00, "savingsRate": 0.225},
     "netWorth": {"netWorth": 12500.00},
     "savings": {"futureValue": 95000.00, "totalInterest": 21000.00},
     "cashFlow": {"averageSurplus": 900.00, "negativeMonths": 0},
     "benchmark": {"overspendFlags": ["transport"]}},
    {"budget": {"totalExpenses": 9800.00, "surplus": 4200.00, "savingsRate": 0.30},
     "netWorth": {"netWorth": 350000.00},
     "savings": {"futureValue": 800000.00, "totalInterest": 150000.00},
     "cashFlow": {"averageSurplus": 4200.00, "negativeMonths": 0},
     "benchmark": {"overspendFlags": []}},
]


def generate(model, tools):
    prompt = ("Here are a user's deterministic financial results as JSON. "
              "Write a short, motivating summary.\n\n" + json.dumps(tools))
    text = tokenizer.apply_chat_template([{"role": "user", "content": prompt}],
                                         tokenize=False)
    inputs = tokenizer(text, return_tensors="pt").to("cuda")
    with torch.no_grad():
        out = model.generate(**inputs, max_new_tokens=120, do_sample=True,
                             temperature=0.7, top_p=0.9)
    return tokenizer.decode(out[0][inputs["input_ids"].shape[1]:],
                            skip_special_tokens=True).strip()


base = AutoModelForCausalLM.from_pretrained(MODEL, torch_dtype=torch.bfloat16,
                                            device_map="auto")

print("===== BASE MODEL =====")
base_outs = [generate(base, t) for t in test_cases]
for i, o in enumerate(base_outs):
    print(f"[{i}] {o}")

ft = PeftModel.from_pretrained(base, ADAPTER)

print("\n===== FINE-TUNED MODEL =====")
ft_outs = [generate(ft, t) for t in test_cases]
for i, o in enumerate(ft_outs):
    print(f"[{i}] {o}")
