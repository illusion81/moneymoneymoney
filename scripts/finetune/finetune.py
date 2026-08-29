import json

import torch
from torch.utils.data import Dataset
from transformers import (AutoModelForCausalLM, AutoTokenizer,
                          DataCollatorForLanguageModeling, Trainer,
                          TrainingArguments)
from peft import LoraConfig, get_peft_model

MODEL = "HuggingFaceTB/SmolLM2-360M-Instruct"
MAXLEN = 1024
OUT = "./out"

tokenizer = AutoTokenizer.from_pretrained(MODEL)
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token


class TokDataset(Dataset):
    def __init__(self, path):
        self.examples = []
        with open(path) as f:
            for line in f:
                row = json.loads(line)
                text = tokenizer.apply_chat_template(row["messages"], tokenize=False)
                enc = tokenizer(text, truncation=True, max_length=MAXLEN)
                self.examples.append({
                    "input_ids": enc["input_ids"],
                    "attention_mask": enc["attention_mask"],
                })

    def __len__(self):
        return len(self.examples)

    def __getitem__(self, i):
        return self.examples[i]


train_ds = TokDataset("train.jsonl")
val_ds = TokDataset("val.jsonl")

model = AutoModelForCausalLM.from_pretrained(MODEL, torch_dtype=torch.bfloat16)

lora = LoraConfig(
    r=64,
    lora_alpha=64,
    lora_dropout=0.0,
    bias="none",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    task_type="CAUSAL_LM",
)
model = get_peft_model(model, lora)

args = TrainingArguments(
    output_dir="./out",
    num_train_epochs=3,
    per_device_train_batch_size=2,
    gradient_accumulation_steps=2,
    learning_rate=2e-4,
    logging_steps=1,
    eval_strategy="steps",
    eval_steps=5,
    save_strategy="no",
    bf16=True,
    report_to="none",
    dataloader_num_workers=0,
)

trainer = Trainer(
    model=model,
    args=args,
    train_dataset=train_ds,
    eval_dataset=val_ds,
    data_collator=DataCollatorForLanguageModeling(tokenizer=tokenizer, mlm=False),
)

trainer.train()

model.save_pretrained(OUT)
tokenizer.save_pretrained(OUT)
print("saved adapter to", OUT, flush=True)

json.dump(trainer.state.log_history, open("log_history.json", "w"), indent=2)
print("saved log_history.json with", len(trainer.state.log_history), "entries")
