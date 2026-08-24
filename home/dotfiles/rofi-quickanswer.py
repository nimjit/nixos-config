#!/usr/bin/env python3
"""
rofi-quickanswer — DuckDuckGo instant answers via rofi -dmenu.

Standalone: opens a rofi prompt to type a query.
From launcher (rofi-launcher.sh): called with the query as argv[1],
  skips the initial prompt and shows the answer directly.

Backends:
  1. Local cache  (~/.cache/rofi-quickanswer/cache.json, 24h TTL)
  2. DuckDuckGo Instant Answer API (free, no key)

Optional: wl-copy or xclip for "Copy answer".
"""

import json
import os
import subprocess
import sys
import textwrap
import time
import urllib.parse
import urllib.request

CACHE_DIR  = os.path.expanduser("~/.cache/rofi-quickanswer")
CACHE_FILE = os.path.join(CACHE_DIR, "cache.json")
CACHE_TTL  = 86400  # 24h
WRAP_WIDTH = 60


THEME = "/etc/nixos/home/dotfiles/rofi/ukiyo.rasi"

def rofi_dmenu(prompt, options=None, message=None):
    cmd = ["rofi", "-dmenu", "-p", prompt, "-theme", THEME]
    if message:
        cmd += ["-mesg", message]
    inp = "\n".join(options) if options else ""
    try:
        result = subprocess.run(cmd, input=inp, capture_output=True, text=True)
    except FileNotFoundError:
        sys.exit(1)
    if result.returncode != 0:
        return None
    out = result.stdout.rstrip("\n")
    return out if out else None


def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_cache(cache):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f)


def cache_get(cache, query):
    e = cache.get(query.lower())
    if e and time.time() - e["ts"] < CACHE_TTL:
        return e["answer"], e["source"] + " (cached)"
    return None, None


def cache_set(cache, query, answer, source):
    cache[query.lower()] = {"answer": answer, "source": source, "ts": time.time()}
    save_cache(cache)


def try_duckduckgo(query):
    params = urllib.parse.urlencode(
        {"q": query, "format": "json", "no_html": "1", "skip_disambig": "1"}
    )
    try:
        with urllib.request.urlopen(
            f"https://api.duckduckgo.com/?{params}", timeout=4
        ) as r:
            data = json.load(r)
    except Exception:
        return None, None
    for field, label in (
        ("Answer",       "instant answer"),
        ("Definition",   "definition"),
        ("AbstractText", "abstract"),
    ):
        if t := (data.get(field) or "").strip():
            return t, label
    return None, None


def get_answer(query, cache):
    a, s = cache_get(cache, query)
    if a:
        return a, s
    a, s = try_duckduckgo(query)
    if a:
        cache_set(cache, query, a, s)
    return a, s


def copy_to_clipboard(text):
    for cmd in (["wl-copy"], ["xclip", "-selection", "clipboard"]):
        try:
            subprocess.run(cmd, input=text, text=True, check=True)
            return
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue


def open_in_browser(query):
    subprocess.Popen(
        ["xdg-open", "https://duckduckgo.com/?q=" + urllib.parse.quote(query)]
    )


def show_answer(query, cache):
    answer, source = get_answer(query, cache)

    if not answer:
        message = "No instant answer found."
        options = ["Open in browser", "New search"]
    else:
        body = "\n".join(textwrap.wrap(answer, WRAP_WIDTH)) or answer
        message = body
        options = ["Copy answer", "Open in browser", "New search"]

    choice = rofi_dmenu(query, options=options, message=message)

    if choice == "Copy answer" and answer:
        copy_to_clipboard(answer)
    elif choice == "Open in browser":
        open_in_browser(query)
    elif choice == "New search":
        return True  # signal: ask for new query
    return False


def main():
    cache = load_cache()

    # Called from rofi-launcher with a pre-typed query
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        show_answer(query, cache)
        return

    # Standalone: ask for a query first
    while True:
        query = rofi_dmenu("?")
        if not query:
            return
        want_new = show_answer(query, cache)
        if not want_new:
            return


if __name__ == "__main__":
    main()
