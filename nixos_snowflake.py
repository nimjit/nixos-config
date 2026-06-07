#!/usr/bin/env python3
"""
nixos_snowflake.py
Generates a static radial snowflake of the NixOS configuration.
  · modules/   — centre  (system-level config)
  · home/      — left    (Home Manager modules, large)
  · hosts/     — right   (machine-specific configs)
  · plans/     — small right (documentation)

Run:    python3 /etc/nixos/nixos_snowflake.py
Output: /etc/nixos/nixos_snowflake.html  (open in any browser)
        clicking a file opens it via file:// for quick reading
"""

import json
from pathlib import Path

ROOT   = Path("/etc/nixos")
OUTPUT = ROOT / "nixos_snowflake.html"

# Colours per section (Ukiyo palette)
SECTION_COLORS = {
    "modules": "#d4956a",   # system, warm orange
    "home":    "#6abd9a",   # user space, teal
    "hosts":   "#6a9fd4",   # machine-specific, blue
    "plans":   "#d4c04a",   # documentation, yellow
    "themes":  "#a07ec8",   # appearance, purple
}

SKIP_FILES = {"flake.lock", "nixos_snowflake.html", "nixos_snowflake.py",
              "README.md", "hardware-configuration.nix"}
SKIP_DIRS  = {".git", "__pycache__"}
CODE_EXTS  = {".nix", ".md", ".py", ".json", ".toml"}

def rel(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace("\\", "/")

def skip(name: str) -> bool:
    return name.startswith(".") or name in SKIP_FILES

# ── Tree builders ─────────────────────────────────────────────────────────────

def scan_dir(folder: Path, depth: int, max_depth: int = 3) -> dict:
    """Recursively scan a directory for config files."""
    node = {
        "name": folder.name, "id": rel(folder), "path": rel(folder),
        "type": "folder", "depth": depth, "children": [],
    }
    if depth >= max_depth or not folder.exists():
        return node
    try:
        entries = sorted(folder.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
    except PermissionError:
        return node
    for e in entries:
        if skip(e.name) or e.name in SKIP_DIRS:
            continue
        if e.is_dir():
            child = scan_dir(e, depth + 1, max_depth)
            if child["children"] or e.suffix in CODE_EXTS:
                node["children"].append(child)
        elif e.suffix in CODE_EXTS:
            node["children"].append({
                "name": e.name, "id": rel(e), "path": rel(e),
                "type": "file", "depth": depth + 1, "children": [],
            })
    return node


def build_modules() -> dict:
    folder = ROOT / "modules"
    root = {"name": "modules", "id": "modules", "path": "modules",
            "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    for f in sorted(folder.glob("*.nix")):
        if not skip(f.name):
            root["children"].append({
                "name": f.stem, "id": rel(f), "path": rel(f),
                "type": "file", "depth": 1, "children": [],
            })
    return root


def build_home() -> dict:
    folder = ROOT / "home"
    root = {"name": "home", "id": "home", "path": "home",
            "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    # Top-level .nix files
    for f in sorted(folder.glob("*.nix")):
        if not skip(f.name):
            root["children"].append({
                "name": f.stem, "id": rel(f), "path": rel(f),
                "type": "file", "depth": 1, "children": [],
            })
    # dotfiles/ subdirectory — show as a single grouped node with children by app
    dotfiles = folder / "dotfiles"
    if dotfiles.exists():
        df_node = {"name": "dotfiles", "id": rel(dotfiles), "path": rel(dotfiles),
                   "type": "folder", "depth": 1, "children": []}
        for app_dir in sorted(dotfiles.iterdir()):
            if app_dir.is_dir() and not app_dir.name.startswith("."):
                app_node = {"name": app_dir.name, "id": rel(app_dir), "path": rel(app_dir),
                            "type": "folder", "depth": 2, "children": []}
                for f in sorted(app_dir.iterdir()):
                    if f.is_file() and not skip(f.name) and f.suffix in CODE_EXTS | {"", ".conf"}:
                        app_node["children"].append({
                            "name": f.name, "id": rel(f), "path": rel(f),
                            "type": "file", "depth": 3, "children": [],
                        })
                if app_node["children"]:
                    df_node["children"].append(app_node)
        root["children"].append(df_node)
    return root


def build_hosts() -> dict:
    folder = ROOT / "hosts"
    root = {"name": "hosts", "id": "hosts", "path": "hosts",
            "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    for host_dir in sorted(folder.iterdir()):
        if not host_dir.is_dir() or host_dir.name.startswith("."):
            continue
        host_node = {"name": host_dir.name, "id": rel(host_dir), "path": rel(host_dir),
                     "type": "host", "depth": 1, "children": []}
        for f in sorted(host_dir.glob("*.nix")):
            if not skip(f.name):
                host_node["children"].append({
                    "name": f.stem, "id": rel(f), "path": rel(f),
                    "type": "file", "depth": 2, "children": [],
                })
        root["children"].append(host_node)
    return root


def build_plans() -> dict:
    folder = ROOT / "plans"
    root = {"name": "plans", "id": "plans", "path": "plans",
            "type": "root", "depth": 0, "children": []}
    if not folder.exists():
        return root
    for f in sorted(folder.glob("*.md")):
        if not skip(f.name):
            root["children"].append({
                "name": f.stem, "id": rel(f), "path": rel(f),
                "type": "file", "depth": 1, "children": [],
            })
    return root


def count(node: dict) -> int:
    return 1 + sum(count(c) for c in node.get("children", []))


# ── HTML template ─────────────────────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>NixOS Config — Snowflake</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:#2b2723;color:#ccc2b7;font-family:system-ui,sans-serif;overflow:hidden}
  svg{display:block;width:100vw;height:100vh}
  .link-tree{fill:none;stroke:#413632;stroke-opacity:.85}
  .node{cursor:default}
  .node.clickable{cursor:pointer}
  .node circle{transition:r .1s}
  .node.clickable:hover circle{stroke:#e0ba86!important;stroke-width:2!important}
  .label{pointer-events:none;dominant-baseline:central}
  #tip{
    position:fixed;top:0;left:0;padding:7px 12px;
    background:#372d29f0;border:1px solid #504431;border-radius:4px;
    font-size:12px;pointer-events:none;display:none;
    max-width:320px;line-height:1.5;color:#ccc2b7;z-index:10
  }
  #info{position:fixed;bottom:14px;left:14px;font-size:10px;color:#504431;pointer-events:none}
  #legend{
    position:fixed;top:14px;right:14px;
    background:#372d29cc;border:1px solid #504431;
    border-radius:4px;padding:10px 14px;font-size:10px;line-height:1.85;
  }
  #legend h4{color:#868074;font-weight:normal;margin-bottom:4px;font-size:9px;
             letter-spacing:.08em;text-transform:uppercase}
  .li{display:flex;align-items:center;gap:7px}
  .dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
</style>
</head>
<body>
<svg id="chart"></svg>
<div id="tip"></div>
<div id="info">scroll → zoom &nbsp;·&nbsp; drag → pan &nbsp;·&nbsp; click file → open in browser</div>
<div id="legend"></div>

<script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
<script>
const MODULES = %%MODULES%%;
const HOME    = %%HOME%%;
const HOSTS   = %%HOSTS%%;
const PLANS   = %%PLANS%%;

const SCOL = {
  "modules": "#d4956a",
  "home":    "#6abd9a",
  "hosts":   "#6a9fd4",
  "plans":   "#d4c04a",
  "themes":  "#a07ec8",
};

function sectionColor(d, sectionName) {
  if (d.depth === 0) return "#ba945f";
  return SCOL[sectionName] || "#868074";
}

const W = window.innerWidth, H = window.innerHeight, MWMH = Math.min(W, H);
const rxy = (a, r) => [r * Math.cos(a - Math.PI/2), r * Math.sin(a - Math.PI/2)];
const nrad = (d, sc=1) => d.depth===0 ? 9*sc : d.depth===1 ? 6*sc : d.depth===2 ? 4*sc : 2.5*sc;
const trunc = (s, n=26) => s.length > n ? s.slice(0, n-1) + "…" : s;
const isFile = d => d.data.type === "file";

const svg   = d3.select("#chart").attr("width", W).attr("height", H);
const zoom  = d3.zoom().scaleExtent([0.1, 14]).on("zoom", e => gRoot.attr("transform", e.transform));
svg.call(zoom);
const gRoot = svg.append("g");

const tip = document.getElementById("tip");
function showTip(ev, d) {
  tip.style.display = "block";
  tip.style.left = (ev.clientX + 14) + "px";
  tip.style.top  = (ev.clientY - 8) + "px";
  const pathStr = d.data.id ? `/etc/nixos/${d.data.id}` : d.data.name;
  tip.innerHTML = `<strong>${d.data.name}</strong><br>
    <span style="color:#868074;font-size:10px">${pathStr}</span>`;
}

function renderFlake(container, root, colorFn, labelDepth, nodeScale) {
  container.append("g").selectAll("path")
    .data(root.links()).join("path").attr("class","link-tree")
    .attr("stroke-width", d => d.source.depth===0 ? 1.5 : d.source.depth===1 ? 1.1 : 0.7)
    .attr("d", d3.linkRadial().angle(d=>d.x).radius(d=>d.y));

  const nodes = container.append("g").selectAll("g")
    .data(root.descendants()).join("g")
    .attr("class", d => "node" + (isFile(d) ? " clickable" : ""))
    .attr("transform", d => { const [x,y]=rxy(d.x,d.y); return `translate(${x},${y})`; })
    .on("mousemove", showTip)
    .on("mouseleave", () => tip.style.display = "none")
    .on("click", (ev, d) => {
      if (!isFile(d) || !d.data.path) return;
      window.open(`file:///etc/nixos/${d.data.path}`, "_blank");
    });

  nodes.append("circle")
    .attr("r",      d => nrad(d, nodeScale))
    .attr("fill",   d => colorFn(d))
    .attr("stroke", d => d.depth===0 ? "#e0ba86" : "#2b2723")
    .attr("stroke-width", d => d.depth===0 ? 1.5 : 0.4);

  nodes.filter(d => d.depth >= 1 && d.depth <= labelDepth)
    .append("text").attr("class","label")
    .attr("x", d => d.x < Math.PI ? nrad(d,nodeScale)+4 : -(nrad(d,nodeScale)+4))
    .attr("text-anchor", d => d.x < Math.PI ? "start" : "end")
    .text(d => trunc(d.data.name))
    .attr("fill", d => d.depth===1 ? "#ccc2b7" : colorFn(d) + (d.depth>2?"bb":""))
    .attr("font-size", d => d.depth===1 ? "12px" : d.depth===2 ? "10px" : "8.5px");

  container.append("text").attr("text-anchor","middle").attr("dy",".35em")
    .attr("fill","#ba945f").attr("font-size","14px").attr("pointer-events","none").text("⬡");
}

// Layout: modules (centre), home (left, large), hosts (right), plans (small far-right)
const R_m = MWMH * 0.22;
const R_h = MWMH * 0.32;
const R_o = MWMH * 0.14;
const R_p = MWMH * 0.09;
const GAP = MWMH * 0.06;

const mRoot = d3.hierarchy(MODULES).sort((a,b)=>d3.ascending(a.data.name,b.data.name));
d3.cluster().size([2*Math.PI, R_m])(mRoot);
const gM = gRoot.append("g");
renderFlake(gM, mRoot, d => sectionColor(d,"modules"), 2, 1);

const hRoot = d3.hierarchy(HOME).sort((a,b)=>d3.ascending(a.data.name,b.data.name));
d3.cluster().size([2*Math.PI, R_h])(hRoot);
const sepH = R_m + GAP + R_h;
const gH = gRoot.append("g").attr("transform", `translate(${-sepH}, 0)`);
renderFlake(gH, hRoot, d => sectionColor(d,"home"), 3, 0.85);

const oRoot = d3.hierarchy(HOSTS).sort((a,b)=>d3.ascending(a.data.name,b.data.name));
d3.cluster().size([2*Math.PI, R_o])(oRoot);
const sepO = R_m + GAP + R_o;
const gO = gRoot.append("g").attr("transform", `translate(${sepO}, 0)`);
renderFlake(gO, oRoot, d => sectionColor(d,"hosts"), 2, 0.85);

const pRoot = d3.hierarchy(PLANS).sort((a,b)=>d3.ascending(a.data.name,b.data.name));
d3.cluster().size([2*Math.PI, R_p])(pRoot);
const sepP = sepO + R_o + GAP + R_p;
const gP = gRoot.append("g").attr("transform", `translate(${sepP}, 0)`);
renderFlake(gP, pRoot, d => sectionColor(d,"plans"), 2, 0.75);

// Section labels
[[-sepH, R_h, "home/", "#6abd9a"], [sepO, R_o, "hosts/", "#6a9fd4"], [sepP, R_p, "plans/", "#d4c04a"]]
  .forEach(([x, r, name, col]) => {
    gRoot.append("text").attr("transform", `translate(${x}, ${-(r+22)})`)
      .attr("text-anchor","middle").attr("fill",col).attr("font-size","12px")
      .attr("opacity",0.7).attr("pointer-events","none").text(name);
  });

const totalW = sepH + R_h + sepP + R_p + 200;
const totalH = 2*(R_h + 80);
const initScale = Math.min(W/totalW, H/totalH, 1);
svg.call(zoom.transform, d3.zoomIdentity.translate(W/2, H/2).scale(initScale));

document.getElementById("legend").innerHTML = `
  <h4>Sections</h4>
  <div class="li"><span class="dot" style="background:#d4956a"></span>modules/ (system)</div>
  <div class="li"><span class="dot" style="background:#6abd9a"></span>home/ (HM modules)</div>
  <div class="li"><span class="dot" style="background:#6a9fd4"></span>hosts/ (machines)</div>
  <div class="li"><span class="dot" style="background:#d4c04a"></span>plans/</div>`;
</script>
</body>
</html>
"""

# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Scanning /etc/nixos…")
    modules = build_modules()
    home    = build_home()
    hosts   = build_hosts()
    plans   = build_plans()
    print(f"  modules: {count(modules)} nodes")
    print(f"  home:    {count(home)} nodes")
    print(f"  hosts:   {count(hosts)} nodes")
    print(f"  plans:   {count(plans)} nodes")

    html = (
        HTML
        .replace("%%MODULES%%", json.dumps(modules, ensure_ascii=False))
        .replace("%%HOME%%",    json.dumps(home,    ensure_ascii=False))
        .replace("%%HOSTS%%",   json.dumps(hosts,   ensure_ascii=False))
        .replace("%%PLANS%%",   json.dumps(plans,   ensure_ascii=False))
    )

    OUTPUT.write_text(html, encoding="utf-8")
    print(f"Written → {OUTPUT}")
    print(f"Open    → file://{OUTPUT}")
