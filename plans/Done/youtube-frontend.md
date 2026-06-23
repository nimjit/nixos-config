# YouTube Frontend (yt-feed)

`~/.local/bin/yt-feed` — a Python TUI that shows YouTube subscription feeds
in the terminal with thumbnail images via the kitty graphics protocol.

**Installed**: `home.file.".local/bin/yt-feed"` in `home/default.nix`.
**Source**: `home/dotfiles/yt-feed.py`

---

## What it looks like

Feed view (░ = image cell, ▶ = selected row):

```
  yt ──────────────────────────────────────────  Philosophy · 12 videos

   ░░░░░░░░░░░░░░░░░░░░░  Searching for the BEST Minimal Web Browser    12:33
   ░░░░░░░░░░░░░░░░░░░░░  BreadOnPenguins
   ░░░░░░░░░░░░░░░░░░░░░  148K views · 6 years ago

 ▶ ░░░░░░░░░░░░░░░░░░░░░  Doom Emacs For Noobs                           5:49
   ░░░░░░░░░░░░░░░░░░░░░  DistroTube
   ░░░░░░░░░░░░░░░░░░░░░  106K views · 9 years ago

   ░░░░░░░░░░░░░░░░░░░░░  Wot Hot American Summer - re:View              26:24
   ░░░░░░░░░░░░░░░░░░░░░  RedLetterMedia
   ░░░░░░░░░░░░░░░░░░░░░  565K views · 2 days ago

 ─────────────────────────────────────────────────────────────────────────────
  j k · ↵ open · / filter · c category · R random · o browser · q quit
```

Detail view (press `Enter` on a video — shows description + chapters before committing to watch):

```
  ← b ───────────────────────────────────────────────────────────  ↵ play  q

  Doom Emacs For Noobs                                                   5:49
  DistroTube · 106K views · 9 years ago

  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Chapters
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  00:00  Introduction
  ░░░░  larger thumbnail  ░░░░░░░░░░░  01:23  Getting Started
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  03:45  Configuration

  In this video I go through setting up Doom Emacs from scratch,
  covering installation, basic configuration, and the most useful
  keybindings to get you productive quickly.
```

Press `Enter` again to launch mpv. `b` goes back to the feed.

---

## Keybindings

| Key | Action |
|-----|--------|
| `j / k` | move selection up/down |
| `Enter` | open detail view |
| `Enter` (in detail) | launch in mpv |
| `b` | back to feed |
| `/` | live title filter (`/doom█` filters as you type) |
| `c` | open category picker (j/k to navigate, Enter to select) |
| `R` | play a random video from the current filtered list in mpv |
| `o` | open in browser |
| `q` | quit |

---

## How it works

**Data**: YouTube's native RSS feeds — no API key, no scraping. Channels use
the UULF playlist feed (`feeds/videos.xml?playlist_id=UULF{id_suffix}`) which
returns only long-form videos, filtering out Shorts at the source. Regular
playlists (`PL...`) use the standard `playlist_id=` parameter directly.

**Thumbnails**: All visible thumbnails are rendered in parallel via multiple
`kitten icat --transfer-mode=file` subprocesses launched simultaneously. The
`file` transfer mode sends only a path (~200 bytes) rather than raw pixel data,
making parallel launches safe. After all subprocesses finish, text is written.

**Scroll optimisation**: Two render paths:
- `render_list_full` — full redraw with parallel image rendering (on viewport shift or filter change)
- `render_list_cursor` — text-only redraw (on cursor move within same viewport, zero subprocess calls)

**Detail view**: `yt-dlp --dump-json URL` fetches chapters and description (once
per video, cached). mpv receives chapter data automatically — use default mpv
bindings to jump between chapters.

**mpv playback**: Launched with `--gpu-api=opengl` to avoid DMA-buf presentation
failures on NVIDIA under Wayland.

**Channel list**: `~/.config/yt-feed/channels.txt` — not in git (personal data).

---

## channels.txt format

Channels are grouped by category using `# [name]` headers. Plain `# comment`
lines are ignored. Playlist IDs (`PL...`) work alongside channel IDs (`UC...`).

```
# [Philosophy]
UC2PA-AKmVpU6NKCGtZq_rKQ    # Philosophy Tube
UC358urzyldvD78E9o2sR-Og    # The Leftist Cooks

# [Minecraft]
UCUBsjvdHcwZd3ztdY1Zadcw    # GeminiTay

# [Priority]
PLJ_TJFLc25JR3VZ7Xe-cmt4k3bMKBZ5Tm    # Best Of The Worst (playlist)
```

Press `c` in the feed to open the category picker and filter by group.
`0` / selecting "all" shows everything.

---

## Dependencies

- `yt-dlp` — metadata fetch (detail view) + mpv playback backend
- `mpv` — video playback
- `sponsorblock` mpv script — in `home/mpv.nix`; skips sponsors automatically
- kitty graphics protocol — for thumbnails (works natively in kitty)

---

## What this intentionally does not do

- No personalized recommendations (the algorithm is the problem, not the solution)
- No comments (not read anyway; require Google OAuth to fetch)
- No live streams (open browser for these)
- No search — use `yt: query` in qutebrowser or `yt-dlp ytsearch10:query`
- No Shorts — filtered at the RSS level via UULF playlist feeds

---

## Potential features and known bugs

**Known bugs**

- Thumbnails occasionally show raw escape codes instead of an image. Happens
  rarely with parallel `--transfer-mode=file` rendering — a non-atomic TTY write
  from one of the icat subprocesses. Not yet fixed.

**Potential features**

- **Homepage / grid view** — 2-column grid layout using the same RSS data, navigated
  with hjkl. Would look more like YouTube's front page. The hard part is thumbnail
  performance; the `render_list_cursor` split render path would need to be extended
  to the grid layout. Shelved for now.
- **Native kitty APC protocol** — drive image rendering via `\x1b_G...\x1b\\` escape
  sequences directly to stdout instead of spawning `kitten icat` subprocesses.
  Eliminates subprocess overhead entirely. Attempted and reverted — APC sequences
  through Python's stdout don't reliably reach kitty in all TTY contexts.
- **Channel page** — show all videos from a single channel, launched from the feed.
- **Watch history** — mark videos as seen, hide them on subsequent runs.
