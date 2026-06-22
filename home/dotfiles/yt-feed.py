#!/usr/bin/env python3
"""
yt-feed — terminal YouTube feed viewer
Reads channel IDs from ~/.config/yt-feed/channels.txt
  Format: CHANNEL_ID    # optional comment / blank lines for grouping
Fetches RSS (UULF prefix = long-form only), renders with kitty native image protocol.
"""

import os
import sys
import json
import time
import base64
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
RSS_TTL        = 2 * 3600
MAX_VIDEOS     = 50

# Layout
LEFT_MARGIN = 20   # 1-indexed terminal column where thumbnail starts
THUMB_W     = 38   # thumbnail width in terminal columns
THUMB_H     = 11   # thumbnail height in terminal rows (≈ 16:9 at 10×20 px/cell)
TEXT_COL    = LEFT_MARGIN + THUMB_W + 3

os.makedirs(CACHE_DIR, exist_ok=True)

# ── ANSI helpers ───────────────────────────────────────────────────────────────

ESC   = "\x1b"
RESET = f"{ESC}[0m"
BOLD  = f"{ESC}[1m"
DIM   = f"{ESC}[2m"
REV   = f"{ESC}[7m"

def fg(r, g, b): return f"{ESC}[38;2;{r};{g};{b}m"

def move(row, col):
    sys.stdout.write(f"{ESC}[{row};{col}H")

def erase_line():
    sys.stdout.write(f"{ESC}[K")

def hide_cursor():
    sys.stdout.write(f"{ESC}[?25l")
    sys.stdout.flush()

def show_cursor():
    sys.stdout.write(f"{ESC}[?25h")
    sys.stdout.flush()

ACCENT  = fg(204, 153, 102)
MUTED   = fg(140, 120, 110)
HILIGHT = fg(230, 210, 190)

# ── Terminal size ──────────────────────────────────────────────────────────────

def term_size():
    sz = shutil.get_terminal_size()
    return sz.lines, sz.columns

# ── Kitty native image protocol ────────────────────────────────────────────────
#
# Two-phase rendering: transmit once (image data → kitty GPU cache), then
# place/delete using just ~50-byte escape sequences — no subprocess, no re-upload.
#
# t=f: kitty reads file from disk directly (fastest path; handles JPEG natively).
# q=2: suppress all terminal responses (fire-and-forget).
# d=A: delete all visible image placements; stored data stays in kitty by ID.

_img_ids    = {}    # vid_id → kitty image ID (stable for process lifetime)
_uploaded   = set() # image IDs whose data is in kitty's store
_id_seq     = [0]

def _img_id(vid_id):
    if vid_id not in _img_ids:
        _id_seq[0] += 1
        _img_ids[vid_id] = _id_seq[0]
    return _img_ids[vid_id]

def _apc(payload):
    sys.stdout.write(f"{ESC}_{payload}{ESC}\\")

def icat_transmit(img_id, path):
    encoded = base64.standard_b64encode(path.encode()).decode()
    _apc(f"Ga=T,t=f,i={img_id},q=2;{encoded}")
    _uploaded.add(img_id)

def icat_place(img_id, row, col, w_cols, h_rows):
    move(row, col)
    _apc(f"Ga=p,i={img_id},c={w_cols},r={h_rows},q=2;")

def icat_delete_all():
    _apc("Ga=d,d=A,q=2;")

def show_thumb(vid_id, thumb_url, row):
    path = download_thumb(vid_id, thumb_url)
    if not path:
        return
    iid = _img_id(vid_id)
    if iid not in _uploaded:
        icat_transmit(iid, path)
    icat_place(iid, row, LEFT_MARGIN, THUMB_W, THUMB_H)

# ── Duration cache (still used for detail view metadata) ──────────────────────

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

def fmt_duration(secs):
    if secs is None:
        return ""
    h, r = divmod(int(secs), 3600)
    m, s = divmod(r, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"

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
    # UULF prefix = long-form only feed; YouTube strips Shorts server-side
    feed_id = "UULF" + channel_id[2:] if channel_id.startswith("UC") else channel_id
    try:
        with urllib.request.urlopen(RSS_BASE + feed_id, timeout=8) as r:
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
            "thumb":   f"https://i.ytimg.com/vi/{vid_id}/mqdefault.jpg",
            "date":    published[:10] if published else "",
        })
    return entries

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

def fetch_all(channel_ids, force=False):
    rss_cache = load_rss_cache()
    now       = time.time()
    videos    = []
    stale     = []

    for cid in channel_ids:
        entry = rss_cache.get(cid)
        if not force and entry and now - entry["ts"] < RSS_TTL:
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
    threading.Thread(
        target=download_thumb,
        args=(video["id"], video["thumb"]),
        daemon=True
    ).start()

# ── List view ──────────────────────────────────────────────────────────────────

ENTRY_H = THUMB_H + 1

def _entry_text(video, row, selected, cols, dur_cache):
    """Write the text lines for one entry. Never touches thumbnails."""
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

def _statusbar(cursor, total, cols, search_str):
    filt = f"  {ACCENT}/{search_str}{RESET}" if search_str else ""
    bar  = f" {cursor+1}/{total}  j/k: nav  Enter: play  o: browser  d: detail  /: filter  r: refresh  q: quit"
    erase_line()
    sys.stdout.write(f"{DIM}{bar[:cols-1]}{RESET}{filt}")

def render_list_full(videos, cursor, offset, rows, cols, dur_cache, search_str):
    """Full redraw: delete all images, clear screen, re-place everything."""
    icat_delete_all()
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    visible = max(1, (rows - 2) // ENTRY_H)
    for i in range(visible):
        idx = offset + i
        if idx >= len(videos):
            break
        row = i * ENTRY_H + 1
        show_thumb(videos[idx]["id"], videos[idx]["thumb"], row)
        _entry_text(videos[idx], row, idx == cursor, cols, dur_cache)
        if idx + 1 < len(videos):
            preload_thumb(videos[idx + 1])
    move(rows, 1)
    _statusbar(cursor, len(videos), cols, search_str)
    sys.stdout.flush()

def render_list_cursor(videos, old_cursor, new_cursor, offset, rows, cols, dur_cache, search_str):
    """Viewport unchanged: only redraw text at the two affected rows."""
    visible = max(1, (rows - 2) // ENTRY_H)
    for cur in (old_cursor, new_cursor):
        slot = cur - offset
        if 0 <= slot < visible:
            _entry_text(videos[cur], slot * ENTRY_H + 1, cur == new_cursor, cols, dur_cache)
    move(rows, 1)
    _statusbar(new_cursor, len(videos), cols, search_str)
    sys.stdout.flush()

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
    icat_delete_all()
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()

    show_thumb(video["id"], video["thumb"], 1)

    dur = fmt_duration(dur_cache.get(video["id"]))
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
    sys.stdout.write(f"{DIM} Enter: play  b: back  q: quit{RESET}")
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

# ── Filter prompt ──────────────────────────────────────────────────────────────

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
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=log,
        )

# ── Main loop ──────────────────────────────────────────────────────────────────

def apply_filters(source, search_str):
    if not search_str:
        return source
    q = search_str.lower()
    return [v for v in source
            if q in v["title"].lower() or q in v["channel"].lower()]

def run():
    def _exit(*_):
        icat_delete_all()
        sys.stdout.write(f"{ESC}[2J{ESC}[H")
        show_cursor()
        sys.exit(0)

    signal.signal(signal.SIGINT, _exit)
    hide_cursor()

    channels = load_channels()
    if not channels:
        show_cursor()
        print(f"No channels found.\nAdd YouTube channel IDs to:\n  {CHANNELS_FILE}")
        return

    rows, cols = term_size()
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    move(rows // 2, cols // 2 - 12)
    sys.stdout.write(f"{DIM}Fetching feeds…{RESET}")
    sys.stdout.flush()

    all_videos = fetch_all(channels)
    dur_cache  = load_dur_cache()

    if not all_videos:
        sys.stdout.write(f"{ESC}[2J{ESC}[H")
        show_cursor()
        print("No videos found. Check channel IDs in channels.txt.")
        return

    search_str     = ""
    filtered       = apply_filters(all_videos, search_str)
    cursor, offset = 0, 0
    mode           = "list"

    render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)

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
                        render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)
                    else:
                        render_list_cursor(filtered, old_cursor, cursor, offset, rows, cols, dur_cache, search_str)

            elif key in ("k", "\x1b[A"):
                if cursor > 0:
                    old_cursor, old_offset = cursor, offset
                    cursor -= 1
                    if cursor < offset:
                        offset -= 1
                    if offset != old_offset:
                        render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)
                    else:
                        render_list_cursor(filtered, old_cursor, cursor, offset, rows, cols, dur_cache, search_str)

            elif key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])

            elif key == "d":
                if filtered:
                    mode = "detail"
                    render_detail(filtered[cursor], rows, cols, dur_cache)

            elif key == "/":
                search_str     = prompt_filter(rows, cols)
                filtered       = apply_filters(all_videos, search_str)
                cursor, offset = 0, 0
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)

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
                all_videos  = fetch_all(channels, force=True)
                filtered    = apply_filters(all_videos, search_str)
                cursor, offset = 0, 0
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)

            elif key in ("q", "\x03"):
                break

        elif mode == "detail":
            if key in ("\r", "\n"):
                if filtered:
                    play(filtered[cursor]["url"])
            elif key == "b":
                mode = "list"
                render_list_full(filtered, cursor, offset, rows, cols, dur_cache, search_str)
            elif key in ("q", "\x03"):
                break

    icat_delete_all()
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    show_cursor()

if __name__ == "__main__":
    run()
