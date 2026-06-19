#!/usr/bin/env python3
import os, re, sys, argparse
from datetime import datetime

os.environ.pop("MPLBACKEND", None)
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

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

ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %d"))
ax.xaxis.set_major_locator(mdates.AutoDateLocator())
for sp in ax.spines.values():
    sp.set_color(SPINE)
ax.tick_params(colors=FG, labelsize=7)
ax.set_ylabel("kg", color=FG, fontsize=7)
ax.legend(fontsize=6, framealpha=0, labelcolor=FG, loc="upper right")

fig.autofmt_xdate(rotation=25)
plt.tight_layout(pad=0.3)
plt.savefig(OUT, dpi=DPI, facecolor=BG)
plt.close()
print(OUT)
