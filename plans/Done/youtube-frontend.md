# YouTube Frontend (yt-feed)

## What was built

`~/.local/bin/yt-feed` — a Python TUI that shows YouTube subscription feeds
in the terminal with thumbnail images via the kitty graphics protocol.

**Installed**: `home.file.".local/bin/yt-feed"` in `home/default.nix`.

## How it works

- Reads channel IDs from a local config (not in git — personal data)
- Fetches YouTube RSS feeds (no API key: `youtube.com/feeds/videos.xml?channel_id=ID`)
- Renders feed as a terminal list with kitty-protocol thumbnails
- `j/k` navigate, `Enter` opens mpv, `/` filters by title, `q` quits

## Keybindings

| Key | Action |
|-----|--------|
| `j/k` | navigate |
| `Enter` | open in mpv (no ads, yt-dlp backend) |
| `/` | live title filter |
| `o` | open in browser |
| `q` | quit |

## Dependencies

- `yt-dlp` — in packages; playback backend for mpv
- `mpv` — in packages
- kitty graphics protocol — thumbnails (works natively in kitty)
- `sponsorblock` mpv script — in `home/mpv.nix`; skips sponsors automatically

## What this doesn't do (by design)

- No personalized recommendations
- No comments, no live streams
- No search (use `yt: query` in qutebrowser or `yt-dlp ytsearch10:query`)
