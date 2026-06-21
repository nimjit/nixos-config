# YouTube Frontend (yt-feed)

## What was built

`~/.local/bin/yt-feed` — a Python TUI that shows YouTube subscription feeds
in the terminal with thumbnail images via the kitty graphics protocol.

**Installed**: `home.file.".local/bin/yt-feed"` in `home/default.nix`.

---

## What it looks like

Feed view (░ = image cell, ▶ = selected row):

```
  yt ──────────────────────────────────────────────────  Subscriptions · 47 new

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
  j k · ↵ open · / filter · o browser · q quit
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
| `o` | open in browser |
| `q` | quit |

---

## How it works

**Data**: YouTube's native RSS feeds — no API key, no scraping. Every channel
exposes one at `youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`. Returns
the 15 most recent uploads.

**Thumbnails**: `kitten icat --place 24x13@0x2 thumbnail.jpg` renders a 24-column
× 13-row image at a specific cell position. ANSI cursor sequences position text
to the right of it. Python reads raw keypresses via `tty`/`termios`.

**Detail view**: `yt-dlp --dump-json URL` fetches chapters and description (once
per video, cached). mpv receives chapter data automatically — use default mpv
bindings to jump between chapters.

**Channel list**: `~/.config/yt-feed/channels.txt` — one `channel_id` per line,
not in git (personal data). Export from YouTube: `youtube.com/feed/channels → export`.

---

## Dependencies

- `yt-dlp` — in packages; metadata + mpv playback backend
- `mpv` — in packages
- `sponsorblock` mpv script — in `home/mpv.nix`; skips sponsors automatically
- kitty graphics protocol — for thumbnails (works natively in kitty)

---

## What this intentionally does not do

- No personalized recommendations (the algorithm is the problem, not the solution)
- No comments (not read anyway; require Google OAuth to fetch)
- No live streams (open browser for these)
- No search — use `yt: query` in qutebrowser or `yt-dlp ytsearch10:query`
