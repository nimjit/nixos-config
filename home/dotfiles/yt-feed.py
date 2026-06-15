#!/usr/bin/env python3
"""
yt-feed — terminal YouTube feed viewer
Reads channel IDs from ~/.config/yt-feed/channels.txt
  Format: CHANNEL_ID    # optional comment / blank lines for grouping
Fetches RSS, renders with kitty icat thumbnails, j/k nav, Enter → mpv
"""

import os
import sys
import json
import time
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
RSS_BASE       = "https://www.youtube.com/feeds/videos.xml?channel_id="
RSS_TTL        = 2 * 3600   # seconds before re-fetching a channel's feed
MAX_VIDEOS     = 50
LONG_MIN_SECS  = 5 * 60   # ≥ 5 min = "long"

# Layout
LEFT_MARGIN = 20   # columns from left edge before thumbnail starts
THUMB_W     = 38   # thumbnail width in terminal columns
# THUMB_H: mqdefault.jpg is 320×180 (16:9). Typical kitty cell ≈ 10×20 px.
# height_px = THUMB_W * 10 * (9/16) ≈ 213 px → 213/20 ≈ 10.7 rows → 11
THUMB_H     = 11
TEXT_COL    = LEFT_MARGIN + THUMB_W + 3   # text starts after thumbnail + gap

os.makedirs(CACHE_DIR, exist_ok=True)

# ── ANSI helpers ───────────────────────────────────────────────────────────────

ESC   = "\x1b"
RESET = f"{ESC}[0m"
BOLD  = f"{ESC}[1m"
DIM   = f"{ESC}[2m"
REV   = f"{ESC}[7m"

def fg(r, g, b):    return f"{ESC}[38;2;{r};{g};{b}m"
def move(row, col): print(f"{ESC}[{row};{col}H", end="", flush=True)
def clear():        print(f"{ESC}[2J{ESC}[H", end="", flush=True)
def hide_cursor():  print(f"{ESC}[?25l", end="", flush=True)
def show_cursor():  print(f"{ESC}[?25h", end="", flush=True)

ACCENT  = fg(204, 153, 102)
MUTED   = fg(140, 120, 110)
HILIGHT = fg(230, 210, 190)

# ── Terminal size ──────────────────────────────────────────────────────────────

def term_size():
    sz = shutil.get_terminal_size()
    return sz.lines, sz.columns

# ── Duration cache ─────────────────────────────────────────────────────────────

def load_dur_cache():
    try:
        with open(DUR_CACHE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def save_dur_cache(cache):
    try:
        with open(DUR_CACHE_FILE, "w") as f:
            json.dump(cache, f)
    except Exception:
        pass

# ── RSS cache ──────────────────────────────────────────────────────────────────

def load_rss_cache():
    try:
        with open(RSS_CACHE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def save_rss_cache(cache):
    try:
        with open(RSS_CACHE_FILE, "w") as f:
            json.dump(cache, f)
    except Exception:
        pass

def fetch_duration(vid_id):
    try:
        r = subprocess.run(
            ["yt-dlp", "--no-playlist", "--print", "duration",
             f"https://www.youtube.com/watch?v={vid_id}"],
            capture_output=True, text=True, timeout=20
        )
        return int(r.stdout.strip()) if r.returncode == 0 else None
    except Exception:
        return None

def fmt_duration(secs):
    if secs is None:
        return "?:??"
    h, r = divmod(secs, 3600)
    m, s = divmod(r, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"

def enrich_durations(videos, cache):
    """Background thread: fetch durations for uncached videos, save cache."""
    missing = [v["id"] for v in videos if v["id"] not in cache]
    if not missing:
        return
    with ThreadPoolExecutor(max_workers=6) as ex:
        futures = {ex.submit(fetch_duration, vid_id): vid_id for vid_id in missing}
        for fut in as_completed(futures):
            vid_id = futures[fut]
            result = fut.result()
            if result is not None:
                cache[vid_id] = result
    save_dur_cache(cache)

# ── Channel loading ────────────────────────────────────────────────────────────

def load_channels():
    if not os.path.exists(CHANNELS_FILE):
        os.makedirs(os.path.dirname(CHANNELS_FILE), exist_ok=True)
        open(CHANNELS_FILE, "w").close()
        return []
    channels = []
    with open(CHANNELS_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            channels.append(line.split()[0])
    return channels

# ── RSS fetching ───────────────────────────────────────────────────────────────

def fetch_rss(channel_id):
    try:
        with urllib.request.urlopen(RSS_BASE + channel_id, timeout=8) as r:
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
    channel_name = root.findtext("atom:title", default="?", namespaces=NS)
    entries = []
    for entry in root.findall("atom:entry", NS)[:MAX_VIDEOS]:
        vid_id    = entry.findtext("yt:videoId", default="", namespaces=NS)
        title     = entry.findtext("atom:title", default="(no title)", namespaces=NS)
        published = entry.findtext("atom:published", default="", namespaces=NS)
        entries.append({
            "id":      vid_id,
            "title":   title,
            "channel": channel_name,
            "url":     f"https://www.youtube.com/watch?v={vid_id}",
            # mqdefault = 320×180, guaranteed 16:9 (hqdefault from RSS is 4:3)
            "thumb":   f"https://i.ytimg.com/vi/{vid_id}/mqdefault.jpg",
            "date":    published[:10] if published else "",
        })
    return entries

def fetch_all(channel_ids):
    rss_cache = load_rss_cache()
    now       = time.time()
    videos    = []
    stale     = []

    for cid in channel_ids:
        entry = rss_cache.get(cid)
        if entry and now - entry["ts"] < RSS_TTL:
            videos.extend(parse_feed(entry["xml"].encode()))
        else:
            stale.append(cid)

    if stale:
        with ThreadPoolExecutor(max_workers=8) as ex:
            futures = {ex.submit(fetch_rss, cid): cid for cid in stale}
            for fut in as_completed(futures):
                cid  = futures[fut]
                data = fut.result()
                if data:
                    rss_cache[cid] = {"ts": now, "xml": data.decode("utf-8", errors="replace")}
                    videos.extend(parse_feed(data))
        save_rss_cache(rss_cache)

    videos.sort(key=lambda v: v["date"], reverse=True)
    return videos

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
    """Fire-and-forget background thumbnail download."""
    threading.Thread(
        target=download_thumb,
        args=(video["id"], video["thumb"]),
        daemon=True
    ).start()

def show_thumb(path, row):
    if path and os.path.exists(path):
        subprocess.run(
            ["kitty", "+kitten", "icat", "--silent",
             "--place", f"{THUMB_W}x{THUMB_H}@{LEFT_MARGIN}x{row}",
             "--transfer-mode=stream", path],
            stdout=sys.stdout
        )

# ── List view ──────────────────────────────────────────────────────────────────

ENTRY_H = THUMB_H + 1

def render_entry(video, row, selected, cols, dur_cache):
    show_thumb(download_thumb(video["id"], video["thumb"]), row)

    bar = REV if selected else ""
    rst = RESET
    dur = fmt_duration(dur_cache.get(video["id"]))

    move(row + 1, TEXT_COL)
    title   = video["title"]
    max_t   = cols - TEXT_COL - 1
    if len(title) > max_t:
        title = title[:max_t - 1] + "…"
    print(f"{bar}{BOLD}{HILIGHT}{title}{rst}", end="", flush=True)

    move(row + 2, TEXT_COL)
    print(f"{MUTED}{video['channel']}   {DIM}{video['date']}  {dur}{rst}", end="", flush=True)

    if selected:
        move(row + 3, TEXT_COL)
        print(f"{ACCENT}► Enter: play  o: browser  d: detail  q: quit{rst}", end="", flush=True)

def render_list(videos, cursor, offset, rows, cols, dur_cache, long_only):
    clear()
    visible = max(1, (rows - 2) // ENTRY_H)
    for i in range(visible):
        idx = offset + i
        if idx >= len(videos):
            break
        render_entry(videos[idx], i * ENTRY_H + 1, idx == cursor, cols, dur_cache)
        # preload the thumbnail one ahead
        if idx + 1 < len(videos):
            preload_thumb(videos[idx + 1])

    move(rows, 1)
    flag = f"  {ACCENT}[long only]{RESET}" if long_only else ""
    bar  = f" {cursor+1}/{len(videos)}  j/k: nav  Enter: play  o: browser  d: detail  L: long  /: filter  r: refresh  q: quit"
    print(f"{DIM}{bar[:cols-1]}{RESET}{flag}", end="", flush=True)

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
    clear()
    show_thumb(download_thumb(video["id"], video["thumb"]), 1)

    dur = fmt_duration(dur_cache.get(video["id"]))
    move(1, TEXT_COL)
    title = video["title"]
    max_t = cols - TEXT_COL - 1
    if len(title) > max_t:
        title = title[:max_t - 1] + "…"
    print(f"{BOLD}{HILIGHT}{title}{RESET}", end="", flush=True)

    move(2, TEXT_COL)
    print(f"{MUTED}{video['channel']}   {video['date']}  {dur}{RESET}", end="", flush=True)

    move(3, TEXT_COL)
    print(f"{ACCENT}{video['url']}{RESET}", end="", flush=True)

    move(5, TEXT_COL)
    print(f"{DIM}Loading metadata…{RESET}", end="", flush=True)
    sys.stdout.flush()

    data = fetch_detail(video["url"])

    move(5, TEXT_COL)
    print(" " * (cols - TEXT_COL), end="", flush=True)

    row = 5
    if data:
        if data.get("duration") and video["id"] not in dur_cache:
            dur_cache[video["id"]] = data["duration"]
            save_dur_cache(dur_cache)

        desc = (data.get("description") or "")[:400]
        for i, line in enumerate(desc.splitlines()[:6]):
            move(row + i, TEXT_COL)
            print(f"{MUTED}{line[:cols - TEXT_COL - 1]}{RESET}", end="", flush=True)
        row += 8

        for ch in (data.get("chapters") or [])[:8]:
            t  = int(ch.get("start_time", 0))
            ts = f"{t//60}:{t%60:02d}"
            move(row, TEXT_COL)
            print(f"{DIM}{ts}  {MUTED}{ch['title'][:cols-TEXT_COL-8]}{RESET}", end="", flush=True)
            row += 1

    move(rows, 1)
    print(f"{DIM} Enter: play  b: back  q: quit{RESET}", end="", flush=True)

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

# ── Filter prompt ──────────────────────────────────────────────────────────────

def prompt_filter(rows, cols):
    move(rows, 1)
    print(f"{RESET}{' '*(cols-1)}", end="", flush=True)
    move(rows, 1)
    print(f"{ACCENT}/ {RESET}", end="", flush=True)
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
            print(f"{HILIGHT}{query}{' '*(cols-4-len(query))}{RESET}", end="", flush=True)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    hide_cursor()
    return query.lower()

# ── Playback ───────────────────────────────────────────────────────────────────

def play(url):
    with open(MPV_LOG, "w") as log:
        subprocess.Popen(
            ["mpv", "--no-terminal", url],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=log,
        )

# ── Main loop ──────────────────────────────────────────────────────────────────

def apply_filters(source, search_str, long_only, dur_cache):
    out = source
    if search_str:
        out = [v for v in out
               if search_str in v["title"].lower() or search_str in v["channel"].lower()]
    if long_only:
        # uncached videos pass through (duration unknown); press r after bg fetch
        out = [v for v in out
               if dur_cache.get(v["id"], LONG_MIN_SECS) >= LONG_MIN_SECS]
    return out

def run():
    signal.signal(signal.SIGINT, lambda *_: (show_cursor(), sys.exit(0)))
    hide_cursor()

    channels = load_channels()
    if not channels:
        show_cursor()
        print(f"No channels found.\nAdd YouTube channel IDs to:\n  {CHANNELS_FILE}\nFormat: CHANNEL_ID    # Channel name")
        return

    rows, cols = term_size()
    clear()
    move(rows // 2, cols // 2 - 12)
    print(f"{DIM}Fetching feeds…{RESET}", end="", flush=True)

    all_videos = fetch_all(channels)
    dur_cache  = load_dur_cache()

    if not all_videos:
        clear()
        show_cursor()
        print("No videos found. Check channel IDs in channels.txt.")
        return

    threading.Thread(target=enrich_durations, args=(all_videos, dur_cache), daemon=True).start()

    search_str = ""
    long_only  = True   # default: show long-form videos only

    filtered       = apply_filters(all_videos, search_str, long_only, dur_cache)
    cursor, offset = 0, 0
    mode           = "list"

    render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

    while True:
        rows, cols = term_size()
        visible    = max(1, (rows - 2) // ENTRY_H)
        key        = getch()

        if mode == "list":
            if key in ("j", "\x1b[B"):
                if cursor < len(filtered) - 1:
                    cursor += 1
                    if cursor >= offset + visible:
                        offset += 1
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

            elif key in ("k", "\x1b[A"):
                if cursor > 0:
                    cursor -= 1
                    if cursor < offset:
                        offset -= 1
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

            elif key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])

            elif key == "d":
                if filtered:
                    mode = "detail"
                    render_detail(filtered[cursor], rows, cols, dur_cache)

            elif key == "L":
                long_only      = not long_only
                filtered       = apply_filters(all_videos, search_str, long_only, dur_cache)
                cursor, offset = 0, 0
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

            elif key == "/":
                search_str     = prompt_filter(rows, cols)
                filtered       = apply_filters(all_videos, search_str, long_only, dur_cache)
                cursor, offset = 0, 0
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

            elif key == "o":
                if filtered:
                    subprocess.Popen(
                        ["xdg-open", filtered[cursor]["url"]],
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )

            elif key == "r":
                filtered = apply_filters(all_videos, search_str, long_only, dur_cache)
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)

            elif key in ("q", "\x03"):
                break

        elif mode == "detail":
            if key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])
            elif key == "b":
                mode = "list"
                render_list(filtered, cursor, offset, rows, cols, dur_cache, long_only)
            elif key in ("q", "\x03"):
                break

    clear()
    show_cursor()

if __name__ == "__main__":
    run()
