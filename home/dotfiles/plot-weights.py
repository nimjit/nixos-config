#!/usr/bin/env python3
import os, re, sys, argparse
from datetime import datetime

os.environ.pop("MPLBACKEND", None)
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker

WEIGHTS_FILE = (
    "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure"
    "/Renaissance_Vault_Structure/Knowledge/Body & Movement/Bodybuilding/Stats/Weights list.md"
)
OUT = "/tmp/weight-plot.png"

BG     = "#372d29"
FG     = "#ccc2b7"
SPINE  = "#8a7a6e"
C_REC  = "#cc9966"  # recorded  — Ukiyo accent
C_7    = "#6abf8b"  # 7d MA     — muted green
C_21   = "#7fa8c9"  # 21d MA    — muted blue
C_30   = "#c47eb0"  # 1m MA     — muted purple

p = argparse.ArgumentParser()
p.add_argument("--n",    type=int, default=85, help="Start from Nth row (1-based, matches vault JS N=85)")
p.add_argument("--cols", type=int, default=80, help="Terminal width in columns")
args = p.parse_args()

dates, recorded, ma7, ma21, ma30 = [], [], [], [], []
try:
    with open(WEIGHTS_FILE) as f:
        for line in f:
            m = re.match(
                r"\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)",
                line,
            )
            if m:
                dates.append(datetime.strptime(m.group(1), "%Y-%m-%d"))
                recorded.append(float(m.group(2)))
                ma7.append(float(m.group(3)))
                ma21.append(float(m.group(4)))
                ma30.append(float(m.group(5)))
except OSError:
    sys.exit(1)

if not dates:
    sys.exit(1)

idx = max(args.n - 1, 0)
dates    = dates[idx:]
recorded = recorded[idx:]
ma7      = ma7[idx:]
ma21     = ma21[idx:]
ma30     = ma30[idx:]

if not dates:
    sys.exit(1)

def _slope_kgweek(dates_seq, vals_seq, n_points):
    d = dates_seq[-n_points:]
    v = vals_seq[-n_points:]
    if len(d) < 2:
        return None
    x = [(dt - d[0]).total_seconds() / 86400 for dt in d]
    n = len(x)
    sx  = sum(x);  sv  = sum(v)
    sxx = sum(xi**2 for xi in x)
    sxv = sum(x[i] * v[i] for i in range(n))
    den = n * sxx - sx * sx
    return None if den == 0 else (n * sxv - sx * sv) / den * 7

DPI  = 110
figw = max(args.cols * 9 / DPI, 5.0)
figh = round(figw * 0.28, 2)

fig, ax = plt.subplots(figsize=(figw, figh))
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)

ax.plot(dates, ma30,     color=C_30,  linewidth=0.9, label="1m MA")
ax.plot(dates, ma21,     color=C_21,  linewidth=0.9, label="21d MA")
ax.plot(dates, ma7,      color=C_7,   linewidth=1.1, label="7d MA")
ax.plot(dates, recorded, color=C_REC, linewidth=1.4, label="recorded")

ax.xaxis.set_major_locator(mdates.MonthLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter("%b '%y"))
ax.yaxis.set_major_locator(mticker.MultipleLocator(1.0))
for sp in ax.spines.values():
    sp.set_color(SPINE)
ax.tick_params(colors=FG, labelsize=11)
ax.set_ylabel("kg", color=FG, fontsize=11)
ax.grid(True, color=SPINE, linewidth=0.3, alpha=0.4)
ax.legend(fontsize=10, framealpha=0, labelcolor=FG, loc="upper right")

slope_7  = _slope_kgweek(dates, ma7,  7)
slope_21 = _slope_kgweek(dates, ma21, 21)
parts = []
if slope_7  is not None: parts.append(f"7d:  {slope_7:+.2f} kg/wk")
if slope_21 is not None: parts.append(f"21d: {slope_21:+.2f} kg/wk")
if parts:
    ax.text(0.98, 0.62, "\n".join(parts),
            transform=ax.transAxes, fontsize=9, color=FG,
            va="top", ha="right",
            bbox=dict(boxstyle="round,pad=0.3",
                      facecolor=BG, alpha=0.8, edgecolor=SPINE))

fig.autofmt_xdate(rotation=25)
plt.tight_layout(pad=0.3)
plt.savefig(OUT, dpi=DPI, facecolor=BG)
plt.close()
print(OUT)
