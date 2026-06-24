#!/usr/bin/env python3
"""
yt-feed — terminal YouTube feed viewer

~/.config/yt-feed/channels.txt format:
  # [category]       ← optional category header (square brackets)
  UCxxxxxxxx         ← YouTube channel ID  (long-form feed via UULF)
  PLxxxxxxxx         ← YouTube playlist ID (fetched directly)
  # plain comment / blank lines ignored
"""

import os
import sys
import json
import time
import random
import select
import signal
import shutil
import threading
import subprocess
import tty
import termios
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed

# ── Config ─────────────────────────────────────────────────────────────────────

CHANNELS_FILE  = os.path.expanduser("~/.config/yt-feed/channels.txt")
CACHE_DIR      = os.path.expanduser("~/.cache/yt-feed")
DUR_CACHE_FILE = os.path.join(CACHE_DIR, "durations.json")
RSS_CACHE_FILE = os.path.join(CACHE_DIR, "rss_cache.json")
MPV_LOG        = os.path.join(CACHE_DIR, "mpv-last.log")
RSS_TTL        = 2 * 3600
MAX_VIDEOS     = 50

LEFT_MARGIN = 20
THUMB_W     = 38
THUMB_H     = 11
TEXT_COL    = LEFT_MARGIN + THUMB_W + 3

os.makedirs(CACHE_DIR, exist_ok=True)

# ── ANSI helpers ───────────────────────────────────────────────────────────────

ESC   = "\x1b"
RESET = f"{ESC}[0m"
BOLD  = f"{ESC}[1m"
DIM   = f"{ESC}[2m"
REV   = f"{ESC}[7m"

def fg(r, g, b): return f"{ESC}[38;2;{r};{g};{b}m"
def move(row, col): sys.stdout.write(f"{ESC}[{row};{col}H")
def erase_line():   sys.stdout.write(f"{ESC}[K")
def hide_cursor():  sys.stdout.write(f"{ESC}[?25l"); sys.stdout.flush()
def show_cursor():  sys.stdout.write(f"{ESC}[?25h"); sys.stdout.flush()

ACCENT  = fg(204, 153, 102)
MUTED   = fg(140, 120, 110)
HILIGHT = fg(230, 210, 190)

def term_size():
    sz = shutil.get_terminal_size()
    return sz.lines, sz.columns

# ── Thumbnails ─────────────────────────────────────────────────────────────────

def thumb_path(vid_id):
    return os.path.join(CACHE_DIR, f"{vid_id}.jpg")

def download_thumb(vid_id, url):
    path = thumb_path(vid_id)
    if os.path.exists(path):
        return path
    try:
        urllib.request.urlretrieve(url, path)
        return path
    except Exception:
        return None

def preload_thumb(video):
    threading.Thread(target=download_thumb,
                     args=(video["id"], video["thumb"]), daemon=True).start()

def _icat_popen(path, row):
    return subprocess.Popen(
        ["kitty", "+kitten", "icat", "--silent",
         "--place", f"{THUMB_W}x{THUMB_H}@{LEFT_MARGIN}x{row}",
         "--transfer-mode=file", path],
        stdout=sys.stdout, stderr=subprocess.DEVNULL,
    )

# ── Duration cache ─────────────────────────────────────────────────────────────

def load_dur_cache():
    try:
        with open(DUR_CACHE_FILE) as f: return json.load(f)
    except Exception:
        return {}

def save_dur_cache(cache):
    try:
        with open(DUR_CACHE_FILE, "w") as f: json.dump(cache, f)
    except Exception:
        pass

def fmt_duration(secs):
    if secs is None: return ""
    h, r = divmod(int(secs), 3600)
    m, s = divmod(r, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"

# ── Channel / playlist loading ─────────────────────────────────────────────────

def load_channels():
    """Return [(feed_id, category_str)] preserving order.

    Category is set by the nearest preceding '# [name]' header.
    Plain comments and blank lines are ignored.
    """
    if not os.path.exists(CHANNELS_FILE):
        os.makedirs(os.path.dirname(CHANNELS_FILE), exist_ok=True)
        open(CHANNELS_FILE, "w").close()
        return []
    result  = []
    current_cat = ""
    with open(CHANNELS_FILE) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("# [") and line.endswith("]"):
                current_cat = line[3:-1].strip()
            elif line.startswith("#"):
                pass  # plain comment
            else:
                result.append((line.split()[0], current_cat))
    return result

# ── RSS fetching ───────────────────────────────────────────────────────────────

def feed_url(feed_id):
    if feed_id.startswith("UC"):
        # Long-form feed: replace UC prefix with UULF, use playlist_id= param
        return "https://www.youtube.com/feeds/videos.xml?playlist_id=UULF" + feed_id[2:]
    else:
        # Playlist IDs (PL…) or anything else use playlist_id= directly
        return "https://www.youtube.com/feeds/videos.xml?playlist_id=" + feed_id

def fetch_rss(feed_id):
    try:
        with urllib.request.urlopen(feed_url(feed_id), timeout=8) as r:
            return r.read()
    except Exception:
        return None

NS = {"yt":    "http://www.youtube.com/xml/schemas/2015",
      "media": "http://search.yahoo.com/mrss/",
      "atom":  "http://www.w3.org/2005/Atom"}

def parse_feed(xml_bytes):
    try:
        root = ET.fromstring(xml_bytes)
    except Exception:
        return []
    # atom:title is "Videos" for playlist feeds; author/name has the real channel name
    channel_name = root.findtext("atom:author/atom:name", default="?", namespaces=NS)
    entries = []
    for entry in root.findall("atom:entry", NS)[:MAX_VIDEOS]:
        vid_id    = entry.findtext("yt:videoId", default="", namespaces=NS)
        title     = entry.findtext("atom:title", default="(no title)", namespaces=NS)
        published = entry.findtext("atom:published", default="", namespaces=NS)
        entries.append({
            "id":       vid_id,
            "title":    title,
            "channel":  channel_name,
            "url":      f"https://www.youtube.com/watch?v={vid_id}",
            "thumb":    f"https://i.ytimg.com/vi/{vid_id}/mqdefault.jpg",
            "date":     published[:10] if published else "",
            "category": "",   # filled in by fetch_all
        })
    return entries

def load_rss_cache():
    try:
        with open(RSS_CACHE_FILE) as f: return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def save_rss_cache(cache):
    try:
        with open(RSS_CACHE_FILE, "w") as f: json.dump(cache, f)
    except Exception:
        pass

def fetch_all(channel_pairs, force=False):
    """Fetch all feeds. channel_pairs = [(feed_id, category)]."""
    rss_cache = load_rss_cache()
    cat_map   = {fid: cat for fid, cat in channel_pairs}
    now       = time.time()
    videos    = []
    stale     = []

    for fid, cat in channel_pairs:
        entry = rss_cache.get(fid)
        if not force and entry and now - entry["ts"] < RSS_TTL:
            parsed = parse_feed(entry["xml"].encode())
            for v in parsed: v["category"] = cat
            videos.extend(parsed)
        else:
            stale.append(fid)

    if stale:
        with ThreadPoolExecutor(max_workers=8) as ex:
            futures = {ex.submit(fetch_rss, fid): fid for fid in stale}
            for fut in as_completed(futures):
                fid  = futures[fut]
                data = fut.result()
                if data:
                    rss_cache[fid] = {"ts": now, "xml": data.decode("utf-8", errors="replace")}
                    parsed = parse_feed(data)
                    for v in parsed: v["category"] = cat_map[fid]
                    videos.extend(parsed)
        save_rss_cache(rss_cache)

    videos.sort(key=lambda v: v["date"], reverse=True)
    return videos

# ── Filtering ──────────────────────────────────────────────────────────────────

def apply_filters(source, search_str, category=None):
    out = source
    if category:
        out = [v for v in out if v.get("category") == category]
    if search_str:
        q = search_str.lower()
        out = [v for v in out if q in v["title"].lower() or q in v["channel"].lower()]
    return out

# ── List view ──────────────────────────────────────────────────────────────────

ENTRY_H = THUMB_H + 1

def _entry_text(video, row, selected, cols, dur_cache):
    dur = fmt_duration(dur_cache.get(video["id"]))
    bar = REV if selected else ""
    rst = RESET

    title = video["title"]
    max_t = cols - TEXT_COL - 1
    if len(title) > max_t:
        title = title[:max_t - 1] + "…"

    move(row + 1, TEXT_COL)
    sys.stdout.write(f"{bar}{BOLD}{HILIGHT}{title}{rst}"); erase_line()

    move(row + 2, TEXT_COL)
    dur_str = f"  {dur}" if dur else ""
    sys.stdout.write(f"{MUTED}{video['channel']}   {DIM}{video['date']}{dur_str}{rst}"); erase_line()

    move(row + 3, TEXT_COL); erase_line()
    if selected:
        sys.stdout.write(f"{ACCENT}► Enter: play  o: browser  d: detail  q: quit{rst}")

def _statusbar(cursor, total, cols, search_str, category=None):
    parts = []
    if category:
        parts.append(f"{ACCENT}[{category}]{RESET}")
    if search_str:
        parts.append(f"{ACCENT}/{search_str}{RESET}")
    suffix = ("  " + "  ".join(parts)) if parts else ""
    bar = (f" {cursor+1}/{total}"
           f"  j/k: scroll  ↵: play  o: browser  d: detail"
           f"  c: category  R: random  /: filter  r: refresh  q: quit")
    erase_line()
    sys.stdout.write(f"{DIM}{bar[:cols-1]}{RESET}{suffix}")

def render_list_full(videos, cursor, offset, rows, cols, dur_cache, search_str, category=None):
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()

    visible = max(1, (rows - 2) // ENTRY_H)
    slots, procs = [], []

    for i in range(visible):
        idx = offset + i
        if idx >= len(videos):
            break
        path = download_thumb(videos[idx]["id"], videos[idx]["thumb"])
        row  = i * ENTRY_H + 1
        slots.append((idx, row))
        if path:
            procs.append(_icat_popen(path, row))
        if idx + 1 < len(videos):
            preload_thumb(videos[idx + 1])

    for p in procs:
        p.wait()

    for idx, row in slots:
        _entry_text(videos[idx], row, idx == cursor, cols, dur_cache)
    move(rows, 1)
    _statusbar(cursor, len(videos), cols, search_str, category)
    sys.stdout.flush()

def render_list_cursor(videos, old_cursor, new_cursor, offset, rows, cols, dur_cache, search_str, category=None):
    visible = max(1, (rows - 2) // ENTRY_H)
    for cur in (old_cursor, new_cursor):
        slot = cur - offset
        if 0 <= slot < visible:
            _entry_text(videos[cur], slot * ENTRY_H + 1, cur == new_cursor, cols, dur_cache)
    move(rows, 1)
    _statusbar(new_cursor, len(videos), cols, search_str, category)
    sys.stdout.flush()

# ── Category picker ────────────────────────────────────────────────────────────

def prompt_category(categories, current_cat, rows, cols):
    """Centered popup with j/k navigation. Returns chosen category or None for all."""
    items  = [None] + list(categories)   # None = "all"
    labels = ["all"] + list(categories)

    try:
        sel = items.index(current_cat)
    except ValueError:
        sel = 0

    box_w    = max(len(l) for l in labels) + 8
    max_vis  = min(len(items), rows - 8)   # cap visible rows to fit screen
    box_h    = max_vis + 4                 # border top + header + divider + rows + border bot
    r0       = max(1, (rows - box_h) // 2)
    c0       = max(1, (cols - box_w) // 2)
    inner    = box_w - 2
    scroll   = max(0, sel - max_vis // 2)  # start scroll so selection is centred

    def _draw():
        move(r0, c0)
        sys.stdout.write(f"{BOLD}{ACCENT}┌{'─' * inner}┐{RESET}")
        move(r0 + 1, c0)
        sys.stdout.write(f"{BOLD}{ACCENT}│{RESET}{DIM}{'category':^{inner}}{RESET}{BOLD}{ACCENT}│{RESET}")
        move(r0 + 2, c0)
        sys.stdout.write(f"{BOLD}{ACCENT}├{'─' * inner}┤{RESET}")
        for i in range(max_vis):
            idx = scroll + i
            move(r0 + 3 + i, c0)
            if idx >= len(items):
                sys.stdout.write(f"{BOLD}{ACCENT}│{RESET}{' ' * inner}{BOLD}{ACCENT}│{RESET}")
                continue
            active = idx == sel
            style  = HILIGHT if active else MUTED
            mark   = "▶" if active else " "
            text   = f" {mark}  {labels[idx]}"
            sys.stdout.write(
                f"{BOLD}{ACCENT}│{RESET}{style}{text:<{inner}}{RESET}{BOLD}{ACCENT}│{RESET}"
            )
        move(r0 + 3 + max_vis, c0)
        sys.stdout.write(f"{BOLD}{ACCENT}└{'─' * inner}┘{RESET}")
        sys.stdout.flush()

    _draw()

    while True:
        key = getch()
        if key in ("j", "\x1b[B"):
            if sel < len(items) - 1:
                sel += 1
                if sel >= scroll + max_vis:
                    scroll += 1
                _draw()
        elif key in ("k", "\x1b[A"):
            if sel > 0:
                sel -= 1
                if sel < scroll:
                    scroll -= 1
                _draw()
        elif key in ("\r", "\n"):
            return items[sel]
        elif key in ("\x1b", "c", "q"):
            return current_cat   # cancel — no change

# ── Detail view ────────────────────────────────────────────────────────────────

def fetch_detail(url):
    try:
        r = subprocess.run(
            ["yt-dlp", "--dump-json", "--no-playlist", url],
            capture_output=True, text=True, timeout=15
        )
        if r.returncode == 0:
            return json.loads(r.stdout)
    except Exception:
        pass
    return None

def render_detail(video, rows, cols, dur_cache):
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()

    path = download_thumb(video["id"], video["thumb"])
    if path:
        _icat_popen(path, 1).wait()

    dur     = fmt_duration(dur_cache.get(video["id"]))
    dur_str = f"  {dur}" if dur else ""

    move(1, TEXT_COL)
    title = video["title"]
    if len(title) > cols - TEXT_COL - 1:
        title = title[:cols - TEXT_COL - 2] + "…"
    sys.stdout.write(f"{BOLD}{HILIGHT}{title}{RESET}")

    move(2, TEXT_COL)
    sys.stdout.write(f"{MUTED}{video['channel']}   {video['date']}{dur_str}{RESET}")

    move(3, TEXT_COL)
    sys.stdout.write(f"{ACCENT}{video['url']}{RESET}")

    move(5, TEXT_COL)
    sys.stdout.write(f"{DIM}Loading metadata…{RESET}")
    sys.stdout.flush()

    data = fetch_detail(video["url"])
    move(5, TEXT_COL); erase_line()

    row = 5
    if data:
        if data.get("duration") and video["id"] not in dur_cache:
            dur_cache[video["id"]] = data["duration"]
            save_dur_cache(dur_cache)

        desc = (data.get("description") or "")[:400]
        for i, line in enumerate(desc.splitlines()[:6]):
            move(row + i, TEXT_COL)
            sys.stdout.write(f"{MUTED}{line[:cols - TEXT_COL - 1]}{RESET}")
        row += 8

        for ch in (data.get("chapters") or [])[:8]:
            t  = int(ch.get("start_time", 0))
            ts = f"{t//60}:{t%60:02d}"
            move(row, TEXT_COL)
            sys.stdout.write(f"{DIM}{ts}  {MUTED}{ch['title'][:cols - TEXT_COL - 8]}{RESET}")
            row += 1

    move(rows, 1)
    sys.stdout.write(f"{DIM} ↵: play  b: back  q: quit{RESET}")
    sys.stdout.flush()

# ── Input ──────────────────────────────────────────────────────────────────────

def getch():
    fd  = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            result = ch
            while select.select([sys.stdin], [], [], 0.05)[0]:
                result += sys.stdin.read(1)
            return result
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

def prompt_filter(rows, cols):
    move(rows, 1)
    sys.stdout.write(f"{RESET}{' ' * (cols - 1)}")
    move(rows, 1)
    sys.stdout.write(f"{ACCENT}/ {RESET}")
    sys.stdout.flush()
    show_cursor()
    query = ""
    fd  = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        while True:
            ch = sys.stdin.read(1)
            if ch in ("\r", "\n"):
                break
            elif ch in ("\x7f", "\x08"):
                query = query[:-1]
            elif ch == "\x1b":
                query = ""
                break
            else:
                query += ch
            move(rows, 3)
            sys.stdout.write(f"{HILIGHT}{query}{' ' * (cols - 4 - len(query))}{RESET}")
            sys.stdout.flush()
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    hide_cursor()
    return query.lower()

# ── Playback ───────────────────────────────────────────────────────────────────

def play(url):
    with open(MPV_LOG, "w") as log:
        subprocess.Popen(
            ["mpv", "--no-terminal", "--hwdec=no", "--gpu-api=opengl", url],
            stdin=subprocess.DEVNULL, stdout=log, stderr=log,
        )

# ── Main loop ──────────────────────────────────────────────────────────────────

def run():
    signal.signal(signal.SIGINT, lambda *_: (
        sys.stdout.write(f"{ESC}[2J{ESC}[H"), show_cursor(), sys.exit(0),
    ))
    hide_cursor()

    channel_pairs = load_channels()
    if not channel_pairs:
        show_cursor()
        print(f"No channels found.\nAdd YouTube channel IDs to:\n  {CHANNELS_FILE}")
        return

    # Ordered unique categories (preserves order from file, deduplicates)
    categories = list(dict.fromkeys(cat for _, cat in channel_pairs if cat))

    rows, cols = term_size()
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    move(rows // 2, cols // 2 - 12)
    sys.stdout.write(f"{DIM}Fetching feeds…{RESET}")
    sys.stdout.flush()

    all_videos = fetch_all(channel_pairs)
    dur_cache  = load_dur_cache()

    if not all_videos:
        sys.stdout.write(f"{ESC}[2J{ESC}[H")
        show_cursor()
        print("No videos found. Check channel IDs in channels.txt.")
        return

    search_str   = ""
    current_cat  = None
    filtered     = apply_filters(all_videos, search_str, current_cat)
    cursor, offset = 0, 0
    mode = "list"

    render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

    last_key = None
    while True:
        rows, cols = term_size()
        visible    = max(1, (rows - 2) // ENTRY_H)
        key        = getch()

        if mode == "list":
            if key in ("j", "\x1b[B"):
                if cursor < len(filtered) - 1:
                    old_cursor, old_offset = cursor, offset
                    cursor += 1
                    if cursor >= offset + visible:
                        offset += 1
                    if offset != old_offset:
                        render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)
                    else:
                        render_list_cursor(filtered, old_cursor, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key in ("k", "\x1b[A"):
                if cursor > 0:
                    old_cursor, old_offset = cursor, offset
                    cursor -= 1
                    if cursor < offset:
                        offset -= 1
                    if offset != old_offset:
                        render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)
                    else:
                        render_list_cursor(filtered, old_cursor, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key == "g":
                if last_key == "g" and filtered:
                    cursor, offset = 0, 0
                    render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key == "G":
                if filtered:
                    cursor = len(filtered) - 1
                    offset = max(0, cursor - visible + 1)
                    render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])

            elif key == "d":
                if filtered:
                    mode = "detail"
                    render_detail(filtered[cursor], rows, cols, dur_cache)

            elif key == "c":
                if categories:
                    new_cat = prompt_category(categories, current_cat, rows, cols)
                    if new_cat != current_cat:
                        current_cat = new_cat
                        filtered    = apply_filters(all_videos, search_str, current_cat)
                        cursor, offset = 0, 0
                    render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key == "R":
                if filtered:
                    play(random.choice(filtered)["url"])

            elif key == "/":
                search_str = prompt_filter(rows, cols)
                filtered   = apply_filters(all_videos, search_str, current_cat)
                cursor, offset = 0, 0
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key == "o":
                if filtered:
                    subprocess.Popen(
                        ["xdg-open", filtered[cursor]["url"]],
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )

            elif key == "r":
                move(rows, 1)
                sys.stdout.write(f"{DIM} Refreshing…{RESET}"); sys.stdout.flush()
                all_videos = fetch_all(channel_pairs, force=True)
                filtered   = apply_filters(all_videos, search_str, current_cat)
                cursor, offset = 0, 0
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)

            elif key in ("q", "\x03"):
                break

        elif mode == "detail":
            if key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])
            elif key == "b":
                mode = "list"
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str, current_cat)
            elif key in ("q", "\x03"):
                break

        last_key = key

    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    show_cursor()

if __name__ == "__main__":
    run()
