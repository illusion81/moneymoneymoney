import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

MODEL = "HuggingFaceTB/SmolLM2-360M-Instruct"
ADAPTER = "./out"
OUT = "./merged"

base = AutoModelForCausalLM.from_pretrained(MODEL, torch_dtype=torch.bfloat16)
model = PeftModel.from_pretrained(base, ADAPTER)
model = model.merge_and_unload()
model.save_pretrained(OUT)

tok = AutoTokenizer.from_pretrained(MODEL)
tok.save_pretrained(OUT)
print("merged to", OUT)
