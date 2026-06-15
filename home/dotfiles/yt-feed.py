#!/usr/bin/env python3
"""
yt-feed — terminal YouTube feed viewer
Reads channel IDs from ~/.config/yt-feed/channels.txt (one per line, # = comment)
Fetches RSS, renders with kitty icat thumbnails, j/k navigation, Enter → mpv
"""

import os
import sys
import json
import signal
import shutil
import tempfile
import subprocess
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

# ── Config ─────────────────────────────────────────────────────────────────────

CHANNELS_FILE = os.path.expanduser("~/.config/yt-feed/channels.txt")
CACHE_DIR     = os.path.expanduser("~/.cache/yt-feed")
RSS_BASE      = "https://www.youtube.com/feeds/videos.xml?channel_id="
MAX_VIDEOS    = 6   # per channel
THUMB_W       = 38  # terminal cols for thumbnail
THUMB_H       = 11  # terminal rows for thumbnail

os.makedirs(CACHE_DIR, exist_ok=True)

# ── ANSI helpers ───────────────────────────────────────────────────────────────

ESC   = "\x1b"
RESET = f"{ESC}[0m"
BOLD  = f"{ESC}[1m"
DIM   = f"{ESC}[2m"
REV   = f"{ESC}[7m"

def fg(r, g, b):  return f"{ESC}[38;2;{r};{g};{b}m"
def bg(r, g, b):  return f"{ESC}[48;2;{r};{g};{b}m"
def move(row, col): print(f"{ESC}[{row};{col}H", end="", flush=True)
def clear():        print(f"{ESC}[2J{ESC}[H", end="", flush=True)
def hide_cursor():  print(f"{ESC}[?25l", end="", flush=True)
def show_cursor():  print(f"{ESC}[?25h", end="", flush=True)

ACCENT  = fg(204, 153, 102)   # warm amber
MUTED   = fg(140, 120, 110)
HILIGHT = fg(230, 210, 190)

# ── Terminal size ──────────────────────────────────────────────────────────────

def term_size():
    sz = shutil.get_terminal_size()
    return sz.lines, sz.columns

# ── Data fetching ──────────────────────────────────────────────────────────────

def load_channels():
    if not os.path.exists(CHANNELS_FILE):
        os.makedirs(os.path.dirname(CHANNELS_FILE), exist_ok=True)
        open(CHANNELS_FILE, "w").close()
        return []
    channels = []
    with open(CHANNELS_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                channels.append(line)
    return channels

def fetch_rss(channel_id):
    url = RSS_BASE + channel_id
    try:
        with urllib.request.urlopen(url, timeout=8) as r:
            return r.read()
    except Exception:
        return None

NS = {"yt": "http://www.youtube.com/xml/schemas/2015",
      "media": "http://search.yahoo.com/mrss/",
      "atom": "http://www.w3.org/2005/Atom"}

def parse_feed(xml_bytes):
    try:
        root = ET.fromstring(xml_bytes)
    except Exception:
        return []
    channel_name = root.findtext("atom:title", default="?", namespaces=NS)
    entries = []
    for entry in root.findall("atom:entry", NS)[:MAX_VIDEOS]:
        vid_id   = entry.findtext("yt:videoId", default="", namespaces=NS)
        title    = entry.findtext("atom:title", default="(no title)", namespaces=NS)
        published = entry.findtext("atom:published", default="", namespaces=NS)
        thumb    = ""
        m = entry.find("media:group/media:thumbnail", NS)
        if m is not None:
            thumb = m.get("url", "")
        entries.append({
            "id":      vid_id,
            "title":   title,
            "channel": channel_name,
            "url":     f"https://www.youtube.com/watch?v={vid_id}",
            "thumb":   thumb,
            "date":    published[:10] if published else "",
        })
    return entries

def fetch_all(channel_ids):
    videos = []
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {ex.submit(fetch_rss, cid): cid for cid in channel_ids}
        for fut in as_completed(futures):
            xml_bytes = fut.result()
            if xml_bytes:
                videos.extend(parse_feed(xml_bytes))
    videos.sort(key=lambda v: v["date"], reverse=True)
    return videos

# ── Thumbnail download + display ───────────────────────────────────────────────

def thumb_path(vid_id):
    return os.path.join(CACHE_DIR, f"{vid_id}.jpg")

def download_thumb(url, vid_id):
    path = thumb_path(vid_id)
    if os.path.exists(path):
        return path
    try:
        urllib.request.urlretrieve(url, path)
        return path
    except Exception:
        return None

def show_thumb(path, row, col, w=THUMB_W, h=THUMB_H):
    if path and os.path.exists(path):
        subprocess.run(
            ["kitty", "+kitten", "icat", "--silent",
             "--place", f"{w}x{h}@{col}x{row}",
             "--transfer-mode=stream", path],
            stdout=sys.stdout
        )

def clear_thumb(row, col, w=THUMB_W, h=THUMB_H):
    subprocess.run(
        ["kitty", "+kitten", "icat", "--silent", "--clear",
         "--place", f"{w}x{h}@{col}x{row}",
         "--transfer-mode=stream"],
        stdout=sys.stdout
    )

# ── List view rendering ────────────────────────────────────────────────────────

ENTRY_H  = THUMB_H + 1   # rows each entry occupies
TEXT_COL = THUMB_W + 3   # text starts after thumbnail + gap

def render_entry(idx, video, row, selected, cols):
    move(row + 1, 1)

    thumb_file = download_thumb(video["thumb"], video["id"])
    show_thumb(thumb_file, row, 0, THUMB_W, THUMB_H)

    bar = REV if selected else ""
    rst = RESET

    move(row + 1, TEXT_COL)
    title = video["title"]
    max_title = cols - TEXT_COL - 1
    if len(title) > max_title:
        title = title[:max_title - 1] + "…"
    print(f"{bar}{BOLD}{HILIGHT}{title}{rst}", end="", flush=True)

    move(row + 2, TEXT_COL)
    print(f"{MUTED}{video['channel']}   {DIM}{video['date']}{rst}", end="", flush=True)

    if selected:
        move(row + 3, TEXT_COL)
        print(f"{ACCENT}► Enter to play  d: detail  q: quit{rst}", end="", flush=True)

def render_list(videos, cursor, offset, rows, cols):
    clear()
    visible = (rows - 2) // ENTRY_H
    for i in range(visible):
        idx = offset + i
        if idx >= len(videos):
            break
        render_entry(idx, videos[idx], i * ENTRY_H + 1, idx == cursor, cols)

    # Status bar
    move(rows, 1)
    status = f" {cursor+1}/{len(videos)}  j/k: nav  Enter: play  d: detail  /: filter  q: quit"
    print(f"{DIM}{status[:cols-1]}{RESET}", end="", flush=True)

# ── Detail view ────────────────────────────────────────────────────────────────

def fetch_detail(url):
    try:
        result = subprocess.run(
            ["yt-dlp", "--dump-json", "--no-playlist", url],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception:
        pass
    return None

def render_detail(video, rows, cols):
    clear()
    thumb_file = download_thumb(video["thumb"], video["id"])
    show_thumb(thumb_file, 1, 0, THUMB_W, THUMB_H)

    move(1, TEXT_COL)
    title = video["title"]
    max_t = cols - TEXT_COL - 1
    if len(title) > max_t:
        title = title[:max_t-1] + "…"
    print(f"{BOLD}{HILIGHT}{title}{RESET}", end="", flush=True)

    move(2, TEXT_COL)
    print(f"{MUTED}{video['channel']}   {video['date']}{RESET}", end="", flush=True)

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
        desc = (data.get("description") or "")[:400]
        for i, line in enumerate(desc.splitlines()[:6]):
            move(row + i, TEXT_COL)
            print(f"{MUTED}{line[:cols - TEXT_COL - 1]}{RESET}", end="", flush=True)
        row += 8

        chapters = data.get("chapters") or []
        if chapters:
            move(row, TEXT_COL)
            print(f"{HILIGHT}Chapters:{RESET}", end="", flush=True)
            row += 1
            for ch in chapters[:8]:
                t = int(ch.get("start_time", 0))
            ts = f"{t//60}:{t%60:02d}"
            move(row, TEXT_COL)
            print(f"{DIM}{ts}  {MUTED}{ch['title'][:cols-TEXT_COL-8]}{RESET}", end="", flush=True)
            row += 1

    move(rows, 1)
    print(f"{DIM} Enter: play  b: back  q: quit{RESET}", end="", flush=True)

# ── Input ──────────────────────────────────────────────────────────────────────

import tty
import termios

def getch():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            ch2 = sys.stdin.read(1)
            ch3 = sys.stdin.read(1)
            return ch + ch2 + ch3
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

# ── Filter ─────────────────────────────────────────────────────────────────────

def prompt_filter(rows, cols):
    move(rows, 1)
    print(f"{RESET}{' '*( cols-1)}", end="", flush=True)
    move(rows, 1)
    print(f"{ACCENT}/ {RESET}", end="", flush=True)
    show_cursor()
    query = ""
    fd = sys.stdin.fileno()
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

# ── Main loop ──────────────────────────────────────────────────────────────────

def play(url):
    subprocess.Popen(["mpv", f"ytdl://{url}"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def run():
    signal.signal(signal.SIGINT, lambda *_: (show_cursor(), sys.exit(0)))
    hide_cursor()

    channels = load_channels()
    if not channels:
        print(f"No channels found.\nAdd YouTube channel IDs (one per line) to:\n  {CHANNELS_FILE}")
        show_cursor()
        return

    rows, cols = term_size()
    clear()
    move(rows // 2, cols // 2 - 10)
    print(f"{DIM}Fetching feeds…{RESET}", end="", flush=True)

    all_videos = fetch_all(channels)
    filtered   = all_videos[:]

    if not filtered:
        clear()
        print("No videos found. Check channel IDs in channels.txt.")
        show_cursor()
        return

    cursor = 0
    offset = 0
    visible = max(1, (rows - 2) // ENTRY_H)
    mode    = "list"  # "list" | "detail"

    render_list(filtered, cursor, offset, rows, cols)

    while True:
        rows, cols = term_size()
        visible = max(1, (rows - 2) // ENTRY_H)
        key = getch()

        if mode == "list":
            if key in ("j", "\x1b[B"):
                if cursor < len(filtered) - 1:
                    cursor += 1
                    if cursor >= offset + visible:
                        offset += 1
                render_list(filtered, cursor, offset, rows, cols)

            elif key in ("k", "\x1b[A"):
                if cursor > 0:
                    cursor -= 1
                    if cursor < offset:
                        offset -= 1
                render_list(filtered, cursor, offset, rows, cols)

            elif key in ("\r", "\n"):
                play(filtered[cursor]["url"])

            elif key == "d":
                mode = "detail"
                render_detail(filtered[cursor], rows, cols)

            elif key == "/":
                q = prompt_filter(rows, cols)
                if q:
                    filtered = [v for v in all_videos
                                if q in v["title"].lower() or q in v["channel"].lower()]
                else:
                    filtered = all_videos[:]
                cursor = 0
                offset = 0
                render_list(filtered, cursor, offset, rows, cols)

            elif key in ("q", "\x03"):
                break

        elif mode == "detail":
            if key in ("\r", "\n"):
                play(filtered[cursor]["url"])
            elif key == "b":
                mode = "list"
                render_list(filtered, cursor, offset, rows, cols)
            elif key in ("q", "\x03"):
                break

    clear()
    show_cursor()

if __name__ == "__main__":
    run()
