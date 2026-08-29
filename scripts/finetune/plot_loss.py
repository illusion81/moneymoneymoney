import json

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

h = json.load(open("log_history.json"))

train_steps = [int(e["step"]) for e in h if "loss" in e]
train_loss = [float(e["loss"]) for e in h if "loss" in e]
eval_steps = [int(e["step"]) for e in h if "eval_loss" in e]
eval_loss = [float(e["eval_loss"]) for e in h if "eval_loss" in e]

fig, ax = plt.subplots(figsize=(9, 5.5))

ax.plot(train_steps, train_loss, color="#2f7d50", alpha=0.3, linewidth=1,
        label="train loss (per step)")

if len(train_loss) >= 5:
    w = 7
    sm = [sum(train_loss[max(0, i - w + 1):i + 1]) / min(i + 1, w)
          for i in range(len(train_loss))]
    ax.plot(train_steps, sm, color="#2f7d50", linewidth=2,
            label=f"train loss (rolling {w})")

if eval_steps:
    ax.plot(eval_steps, eval_loss, color="#c0392b", marker="s", ms=5,
            linestyle="--", label="eval loss")

ax.set_xlabel("Training step")
ax.set_ylabel("Cross-entropy loss")
ax.set_title("SmolLM2-360M-Instruct fine-tune\n(200 narrative pairs, LoRA r=16, 3 epochs)")
ax.legend()
ax.grid(alpha=0.3)
fig.tight_layout()
fig.savefig("loss_curve.png", dpi=150)
print("saved loss_curve.png")
print(f"steps={len(train_loss)} first_loss={train_loss[0]:.3f} final_loss={train_loss[-1]:.3f}")
if eval_loss:
    print(f"first_eval={eval_loss[0]:.3f} final_eval={eval_loss[-1]:.3f}")
