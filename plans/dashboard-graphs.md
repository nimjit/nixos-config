# Dashboard Graphs — inline charts in the neovim vault dashboard

## Goal

Render data from vault markdown tables (starting with `weights_list.md`) as a visual
graph inside the neovim dashboard, the same way Obsidian renders it. Uses kitty's
image protocol + matplotlib to draw a PNG inline in the terminal.

---

## Why this is reasonable

- kitty's graphics protocol already works for thumbnails in `yt-feed.py` and the
  existing image.nvim setup in neovim
- matplotlib is available via `python3` (already used in neovim for python path)
- The dashboard (`lua/dashboard.lua`) already renders markdown and calls external
  commands for section content — adding a graph section follows the same pattern
- The generated PNG can be displayed with `kitty +kitten icat` inline, or via
  `image.nvim` if it supports arbitrary images at a buffer position

---

## Data source: `weights_list.md`

The vault file contains a markdown table like:

```markdown
| Date       | Weight (kg) |
|------------|-------------|
| 2026-05-01 | 74.2        |
| 2026-05-08 | 73.8        |
...
```

The graph script parses this, plots a line chart, and saves a PNG to a temp path.

---

## Approach: Python script → PNG → icat

### `~/.local/bin/plot-weights` (new script)

```python
#!/usr/bin/env python3
"""Parse weights_list.md and emit a PNG to a temp file, then print the path."""
import sys, re, os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime

VAULT = os.path.expanduser("~/Obsidian/Rennaissance_Vault_Structure")
WEIGHTS_FILE = os.path.join(VAULT, "weights_list.md")

dates, weights = [], []
with open(WEIGHTS_FILE) as f:
    for line in f:
        m = re.match(r'\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*([\d.]+)', line)
        if m:
            dates.append(datetime.strptime(m.group(1), "%Y-%m-%d"))
            weights.append(float(m.group(2)))

if not dates:
    sys.exit(1)

# Theme colors from ukiyo palette
BG   = "#372d29"
FG   = "#ccc2b7"
ACC  = "#cc9966"

fig, ax = plt.subplots(figsize=(7, 2.5))
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.plot(dates, weights, color=ACC, linewidth=1.5, marker="o", markersize=3)
ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %d"))
ax.xaxis.set_major_locator(mdates.AutoDateLocator())
for spine in ax.spines.values():
    spine.set_color(FG)
ax.tick_params(colors=FG, labelsize=8)
ax.set_ylabel("kg", color=FG, fontsize=8)
fig.autofmt_xdate(rotation=30)
plt.tight_layout(pad=0.4)

out = "/tmp/yt-feed-weight-plot.png"
plt.savefig(out, dpi=110, facecolor=BG)
print(out)
```

### Dashboard integration

In `lua/dashboard.lua`, add a section that:
1. Runs `plot-weights` via `vim.fn.system()` or `jobstart` to get the PNG path
2. Calls `kitty +kitten icat --place WxH@CxR path` at the desired screen position

Alternatively, if image.nvim is already wired up, use its `render_image` API to
place the image at a specific buffer line.

---

## Sizing

A 7×2.5 inch figure at 110 DPI → 770×275 px. In kitty cells (≈10×20 px each):
`THUMB_W ≈ 77 cols`, `THUMB_H ≈ 14 rows`. This fits comfortably next to text.

Adjust `figsize` and `--place` dimensions to taste once rendered.

---

## Possible extensions

- **Multiple plots**: body fat %, running distance, study hours — all from markdown tables
- **Sparklines**: tiny inline graphs in the greeting header (1-2 rows tall)
- **Live updating**: `r` key in a dashboard mode re-runs the plot script

---

## Packages needed

- `python3Packages.matplotlib` — add to NixOS packages if not already available
  (check: `python3 -c "import matplotlib"`)

---

## Open questions

- Exact path of `weights_list.md` in the vault (may differ from above)
- Does image.nvim have an API to place arbitrary images at buffer coordinates,
  or does direct icat subprocess make more sense?
- Should the graph appear on every dashboard open, or only on a keypress?

---

## Status

- [ ] Confirm matplotlib is available (`python3 -c "import matplotlib"`)
- [ ] Confirm weights_list.md path and table format
- [ ] Write and test `plot-weights` script standalone
- [ ] Integrate into dashboard.lua
- [ ] Tune colors, size, and layout to match dashboard style
