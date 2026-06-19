#!/usr/bin/env python3
"""
plot-vault-graph.py
PNG snapshot of the vault snowflake: Knowledge (centre) + Sources (left) + People (right).
Scanning logic and colours copied from vault_snowflake.py; layout/rendering via matplotlib.
"""
import os, sys, argparse, math
from pathlib import Path

os.environ.pop("MPLBACKEND", None)
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

VAULT = Path(
    "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure"
    "/Renaissance_Vault_Structure"
)
OUT = "/tmp/vault-graph.png"

SKIP_FOLDERS = {".obsidian", "Attachments", "Templates", "html",
                "XX_SCRATCH_XX", "Dailies", "Music Library"}

# ── Colours (from vault_snowflake.py, Ukiyo palette) ─────────────────────────
BG          = "#2b2723"
FG          = "#ccc2b7"
EDGE_COL    = "#504431"
ROOT_COL    = "#ba945f"
DEFAULT_COL = "#868074"

SUBJECT_COLORS = {
    "Physics":                  "#d4956a",
    "Mathematics":              "#6a9fd4",
    "Philosophy":               "#a07ec8",
    "Computation":              "#6abd9a",
    "Humanities & Arts":        "#d4c04a",
    "Body & Movement":          "#9abd6a",
    "Craft & Material Culture": "#c87e6a",
    "Languages":                "#d46a9a",
    "Meta":                     "#8aa4bd",
    "Interdisiplinary Physics": "#d4956a",
}
SRC_COLORS  = {"Books": "#c8905a", "Papers": "#9ab8d0", "Youtube": "#d46a6a"}
PEOPLE_COL  = "#7e9abd"


# ── Data scanning (copied verbatim from vault_snowflake.py) ───────────────────

def skip(name: str) -> bool:
    return name.startswith("-") or name.startswith(".")

def rel(path: Path) -> str:
    return str(path.relative_to(VAULT)).replace("\\", "/")

def scan(folder: Path, depth: int, max_depth: int) -> dict:
    node = {"name": folder.name, "path": rel(folder),
            "type": "folder", "depth": depth, "children": []}
    if depth >= max_depth:
        return node
    try:
        entries = sorted(folder.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
    except PermissionError:
        return node
    for e in entries:
        if skip(e.name):
            continue
        if e.is_dir():
            if e.name in SKIP_FOLDERS:
                continue
            node["children"].append(scan(e, depth + 1, max_depth))
        elif e.suffix == ".md":
            node["children"].append({"name": e.stem, "path": rel(e),
                                      "type": "file", "depth": depth + 1, "children": []})
    return node

def build_knowledge():
    k = VAULT / "Knowledge"
    root = scan(k, depth=0, max_depth=4)
    root["name"] = "Knowledge"; root["type"] = "root"
    return root

def build_sources():
    folder = VAULT / "Sources"
    root = {"name": "Sources", "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    books_dir = folder / "Books"
    if books_dir.exists():
        books = {"name": "Books", "type": "folder", "depth": 1, "children": []}
        for adir in sorted(books_dir.iterdir()):
            if not adir.is_dir() or skip(adir.name):
                continue
            author = {"name": adir.name, "type": "author", "depth": 2, "children": []}
            for f in sorted(adir.glob("*.md")):
                if not skip(f.name):
                    author["children"].append({"name": f.stem, "type": "book",
                                               "depth": 3, "children": []})
            if author["children"]:
                books["children"].append(author)
        if books["children"]:
            root["children"].append(books)
    for sub in sorted(folder.iterdir()):
        if not sub.is_dir() or skip(sub.name) or sub.name == "Books" or sub.name in SKIP_FOLDERS:
            continue
        branch = {"name": sub.name, "type": "folder", "depth": 1, "children": []}
        for f in sorted(sub.glob("*.md")):
            if not skip(f.name):
                branch["children"].append({"name": f.stem, "type": "source",
                                            "depth": 2, "children": []})
        if branch["children"]:
            root["children"].append(branch)
    return root

def build_people():
    folder = VAULT / "People"
    root = {"name": "People", "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    for f in sorted(folder.glob("*.md")):
        if not skip(f.name) and f.stem != "Birthdays":
            root["children"].append({"name": f.stem, "type": "person",
                                      "depth": 1, "children": []})
    return root


# ── Colour walking ────────────────────────────────────────────────────────────

def walk_k_color(node, subject=None):
    node["_col"] = ROOT_COL if node["depth"] == 0 else (
        SUBJECT_COLORS.get(subject or node["name"], DEFAULT_COL))
    for child in node["children"]:
        walk_k_color(child, subject if node["depth"] != 1 else node["name"])

def walk_src_color(node, src_type=None):
    node["_col"] = ROOT_COL if node["depth"] == 0 else (
        SRC_COLORS.get(src_type or node["name"], "#a07040"))
    for child in node["children"]:
        walk_src_color(child, src_type if node["depth"] != 1 else node["name"])

def walk_people_color(node):
    node["_col"] = ROOT_COL if node["depth"] == 0 else PEOPLE_COL
    for child in node["children"]: walk_people_color(child)


# ── Radial cluster layout ─────────────────────────────────────────────────────

def _leaves(node):
    return [node] if not node["children"] else [
        l for c in node["children"] for l in _leaves(c)]

def _max_depth(node):
    return node["depth"] if not node["children"] else max(_max_depth(c) for c in node["children"])

def assign_angles(node, start=0.0, end=2 * math.pi):
    """Leaves get equal angular slices; internal nodes get the centroid of their children."""
    leaves = _leaves(node)
    if not node["children"]:
        node["angle"] = (start + end) / 2
        return
    step, offset = (end - start) / len(leaves), start
    for child in node["children"]:
        nl = len(_leaves(child))
        assign_angles(child, offset, offset + nl * step)
        offset += nl * step
    node["angle"] = sum(c["angle"] for c in node["children"]) / len(node["children"])

def assign_radii(node, R, max_d=None):
    if max_d is None:
        max_d = _max_depth(node)
    node["r"] = R * node["depth"] / max_d if max_d else 0
    for child in node["children"]:
        assign_radii(child, R, max_d)

def layout(root, R):
    assign_angles(root)
    assign_radii(root, R)


# ── Drawing ───────────────────────────────────────────────────────────────────

def polar_xy(node, cx=0.0, cy=0.0):
    a = node["angle"] - math.pi / 2   # 0 = up, like D3
    return cx + node["r"] * math.cos(a), cy + node["r"] * math.sin(a)

def _nrad(depth):
    return {0: 9, 1: 6, 2: 4, 3: 2.5}.get(depth, 1.5)

def draw_flake(ax, root, cx, cy, label_depth, fs_scale):
    # Edges first
    def edges(n):
        x0, y0 = polar_xy(n, cx, cy)
        for child in n["children"]:
            x1, y1 = polar_xy(child, cx, cy)
            lw = 1.4 if n["depth"] == 0 else (0.9 if n["depth"] == 1 else 0.45)
            ax.plot([x0, x1], [y0, y1], color=EDGE_COL, lw=lw, zorder=1, solid_capstyle="round")
            edges(child)
    edges(root)

    # Nodes + labels
    def nodes(n):
        x, y = polar_xy(n, cx, cy)
        r   = _nrad(n["depth"])
        col = n.get("_col", DEFAULT_COL)
        ec  = "#e0ba86" if n["depth"] == 0 else "#2b2723"
        lw  = 1.4 if n["depth"] == 0 else 0.35
        ax.add_patch(mpatches.Circle((x, y), r, color=col, ec=ec, lw=lw, zorder=3))

        if 1 <= n["depth"] <= label_depth:
            fs = (9.5 if n["depth"] == 1 else 7.5 if n["depth"] == 2 else 5.5) * fs_scale
            fc = FG if n["depth"] == 1 else col
            a  = n["angle"]
            ha = "left" if a % (2 * math.pi) < math.pi else "right"
            ox = (r + 3) * math.cos(a - math.pi / 2)
            oy = (r + 3) * math.sin(a - math.pi / 2)
            label = n["name"][:22] + "…" if len(n["name"]) > 22 else n["name"]
            ax.text(x + ox, y + oy, label, ha=ha, va="center",
                    color=fc, fontsize=fs, zorder=4)
        for child in n["children"]:
            nodes(child)

    nodes(root)
    ax.text(cx, cy, "⬡", ha="center", va="center", color=ROOT_COL, fontsize=11, zorder=5)


# ── Entry point ───────────────────────────────────────────────────────────────

p = argparse.ArgumentParser()
p.add_argument("--cols", type=int, default=80)
args = p.parse_args()

k = build_knowledge(); walk_k_color(k);      layout(k, 300)
s = build_sources();   walk_src_color(s);    layout(s, 175)
pp = build_people();   walk_people_color(pp); layout(pp, 130)

R_k, R_s, R_p = 300, 175, 130
GAP   = R_k * 0.38
sep_s = R_k + GAP + R_s
sep_p = R_k + GAP + R_p

# Figure dimensions
DPI   = 110
span_x = (sep_s + R_s + 55) + (sep_p + R_p + 55)   # total data width
span_y = 2 * (R_k + 70)

figw = max(args.cols * 9 / DPI, 5.0)
figh = figw * span_y / span_x  # preserve aspect ratio

fs_scale = figw / 9.5  # font scale: 1.0 at 9.5-inch width

fig, ax = plt.subplots(figsize=(figw, figh))
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_aspect("equal")
ax.axis("off")

draw_flake(ax, k,  cx=0,      cy=0, label_depth=3, fs_scale=fs_scale)
draw_flake(ax, s,  cx=-sep_s, cy=0, label_depth=2, fs_scale=fs_scale * 0.85)
draw_flake(ax, pp, cx= sep_p, cy=0, label_depth=2, fs_scale=fs_scale * 0.80)

for x_pos, name, col in [(-sep_s, "Sources", "#c8905a"), (sep_p, "People", PEOPLE_COL)]:
    ax.text(x_pos, R_k + 22, name, ha="center", va="bottom",
            color=col, fontsize=9 * fs_scale, alpha=0.75, zorder=4)

ax.set_xlim(-(sep_s + R_s + 55), sep_p + R_p + 55)
ax.set_ylim(-(R_k + 70), R_k + 70)

plt.tight_layout(pad=0.15)
plt.savefig(OUT, dpi=DPI, facecolor=BG, bbox_inches="tight")
plt.close()
print(OUT)
