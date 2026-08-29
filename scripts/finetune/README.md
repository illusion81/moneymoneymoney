# SmolLM2 Fine-Tuning for the FRPS Slot-SLM

Scripts to fine-tune `HuggingFaceTB/SmolLM2-360M-Instruct` into the FRPS
slot-based narrative model, run on `decker` (RTX 4070 Ti, 12 GB VRAM).

## The idea

The FRPS SLM must never emit a number (numbers come from the deterministic
tools in `lib/frps/financial_tools/`). So the model is trained to write prose
using placeholder tokens only — `{SURPLUS}`, `{SAVINGS_RATE}`, `{NET_WORTH}`,
`{FUTURE_VALUE}`, `{TOTAL_INTEREST}`, `{OVERSPEND}` — and a Dart
`fillNarrative()` (see `lib/frps/slm/slot_slm.dart`) substitutes the exact
values at runtime. This makes hallucinated numbers impossible.

## Pipeline

```text
generate_data.py   -> train.jsonl / val.jsonl (slot-format pairs)
finetune.py        -> ./out (LoRA adapter, rank 64)
plot_loss.py       -> loss_curve.png
test_slots.py      -> success rate (base vs fine-tuned)
merge.py           -> ./merged (adapter merged into base weights)
+ llama.cpp        -> smollm2-360m-slots.Q4_K_M.gguf (on-device)
```

### 1. Generate training data (local teacher)

Uses a local model (`granite4.1:3b` via ollama) to write slot-prose. The
deterministic tool-outputs JSON is the input; prose with `{TOKEN}` placeholders
is the target. A template fallback guarantees every example is digit-free.

```sh
python3 generate_data.py    # writes train.jsonl / val.jsonl (180/20)
```

Note: `qwen3` returns empty output in non-thinking mode — use a non-thinking
teacher like `granite4.1:3b`.

### 2. Fine-tune (LoRA, rank 64)

Uses plain `torch.Dataset` + `transformers.Trainer` + `peft` (not `datasets`/
`trl`, whose vendored dill breaks under Python 3.14).

```sh
python3 finetune.py         # trains + saves LoRA adapter to ./out + log_history.json
python3 plot_loss.py        # loss_curve.png
python3 test_slots.py       # prints success rate (expect ~100% for the fine-tuned model)
```

### 3. Merge and export GGUF

```sh
python3 merge.py            # merge adapter into base -> ./merged
# one-time setup:
#   git clone --depth 1 https://github.com/ggml-org/llama.cpp
#   pip install gguf  (and cmake via brew if missing)
python3 llama.cpp/convert_hf_to_gguf.py ./merged --outfile smollm2-360m-slots-f16.gguf --outtype f16
cmake -B llama.cpp/build -S llama.cpp -DLLAMA_CURL=OFF -DLLAMA_BLAS=OFF -DGGML_NATIVE=ON
cmake --build llama.cpp/build --target llama-quantize -j20
./llama.cpp/build/bin/llama-quantize smollm2-360m-slots-f16.gguf smollm2-360m-slots.Q4_K_M.gguf Q4_K_M
```

Produces `smollm2-360m-slots.Q4_K_M.gguf` (~270 MB) for on-device inference
via llama.cpp.

## Results

- Slot fine-tune (rank 64): **24/24 (100%)** success — zero digits emitted,
  ~4 slot tokens per summary.
- Base 360M: 0/24 — ignores the placeholder instruction, emits raw digits.

The fine-tuned GGUF lives on decker at
`~/frps-ft/smollm2-360m-slots.Q4_K_M.gguf`.
