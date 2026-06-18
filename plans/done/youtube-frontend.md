# YouTube Frontend

A self-hosted HTML page served at `localhost:808x` that replaces the YouTube browser
tab for subscriptions and playback. Extends the same pattern as the new tab page.

Motivation: current Firefox setup needs Stylus (CSS maintenance), uBlock filters (YouTube
specific, fragile), and several extensions to reach a usable state. A custom frontend
owns the design entirely, is maintained in Python/CSS you can read, and opens videos in
mpv — no browser player, no ads, no JavaScript from YouTube running at all.

**This is also a stepping stone to qutebrowser.** The two main blockers for switching
away from Firefox are uBlock's YouTube-specific ad/element filtering and Stylus theming.
Once YouTube plays through this frontend + mpv, neither blocker applies. Qutebrowser
becomes viable for everything else (documentation, occasional web use), since it handles
normal websites fine without extension support. See `plans/` for the qutebrowser
considerations noted earlier.

---

## Architecture

```
YouTube RSS feeds ──► Python server (localhost) ──► HTML page (Ukiyo CSS)
                                                         │
                                                         └──► click ──► mpv ytdl://URL
```

- **Data source**: YouTube's native RSS feeds. Every channel exposes one at
  `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`. No API key,
  no scraping, no authentication. Returns the 15 most recent uploads.
- **Server**: Small Python script, same `http.server` / Flask pattern as the new tab
  page. Reads a local list of channel IDs, fetches feeds in parallel, renders HTML.
- **Playback**: Links open `mpv ytdl://URL`. mpv is already installed and handles
  YouTube natively via yt-dlp. Optionally add the SponsorBlock mpv Lua script
  (`mpv-sponsorblock`) to skip sponsors automatically.
- **Theming**: Plain CSS file — Ukiyo palette, no rounded corners, no transparency,
  no profile photos, no shorts. You own every pixel.

Served at `localhost:8081` (next to the new tab page at 8080), accessible from any
browser or from the new tab page as a link.

---

## What this covers well

| Feature | How |
|---------|-----|
| Subscription feed | RSS feeds, sorted by date |
| Ad-free playback | mpv, no YouTube player |
| SponsorBlock | mpv-sponsorblock Lua script |
| Your color scheme | Plain CSS, full control |
| No shorts | Filter by duration or title in Python |
| No recommendations sidebar | Not rendered |
| No comments / profile photos | Not fetched |
| NixOS managed | Config in `/etc/nixos`, server as systemd user service |

---

## The homepage problem

YouTube's home tab is a personalized algorithmic feed based on watch history. This is
the one part that is genuinely hard to replicate:

- **YouTube Data API v3**: Official Google API. Requires API key + OAuth for personalized
  results. The personalized recommendations endpoint was removed from the public API —
  only trending is accessible without auth. Quota limits apply.
- **yt-dlp scraping**: `yt-dlp --flat-playlist "https://youtube.com/feed/recommended"`
  works if logged in via cookies, but is fragile and slow. YouTube changes the page
  structure regularly.
- **Reverse engineering**: Fragile, against TOS, not worth maintaining.

### Practical alternatives to the homepage

**Option A — Subscriptions only (recommended starting point)**
The "Subscriptions" tab on YouTube IS the RSS feed. If most of your actual YouTube usage
is watching channels you already follow, the RSS feed is your homepage. You do not need
the algorithm.

**Option B — Trending via Invidious API**
Invidious (public instance or self-hosted) exposes a trending endpoint:
`https://invidious.snopyta.org/api/v1/trending?region=NL`
Add a "Trending" section below subscriptions. Non-personalized but better than nothing
for discovery. Depends on a public Invidious instance being up; self-hosting is an
option but requires Docker/infrastructure.

**Option C — "Unwatched from channels" prioritisation**
Track which videos have been opened in mpv (mpv writes a `watch_later` directory) and
surface uploads from channels where you haven't watched anything in a while. Rough
approximation of freshness-based discovery without any algorithm.

**Option D — Manual discovery list**
A second config file listing channels explicitly marked as "discovery" — channels you
trust for recommendations. Their latest uploads appear in a separate section. Curated,
low-maintenance.

The honest answer is: Options A + B cover most real usage. Options C and D are nice-to-
have refinements. True personalized recommendations are not worth building.

---

## Implementation steps

1. **Channel list**: Gather channel IDs for all current subscriptions. YouTube's
   subscription export (`youtube.com/feed/channels` → export) gives a CSV with channel
   IDs.
2. **Python server**: Fetch RSS feeds in parallel (`concurrent.futures`), parse with
   `xml.etree.ElementTree` (stdlib), render to HTML template. ~100 lines.
3. **HTML/CSS**: Ukiyo palette, grid layout of thumbnails + titles, no sidebar,
   no profiles. Thumbnails come from `media:thumbnail` in the RSS feed.
4. **mpv link handler**: `<a href="mpv://...">` needs a custom URL scheme handler, OR
   use a small redirect: clicking a video sends a request to the local server which runs
   `subprocess.Popen(['mpv', 'ytdl://URL'])` and returns immediately.
5. **Systemd user service**: Same pattern as `newtab-server` in `home/default.nix`.
   Auto-starts on login, restarts on failure.
6. **SponsorBlock**: Add `mpv-sponsorblock` (in nixpkgs) to packages. Zero config
   needed — detects sponsors and skips automatically during playback.

---

## What this does not replace

- **Search**: You'd open a browser or use `yt-dlp --search` for discovery searches.
- **Playlists / watch later**: Would need extra work to track locally.
- **Comments**: Not fetched; open in browser if needed.
- **Live streams**: RSS does not include live streams; these would need a browser.

---

## Terminal frontend — pure Python TUI (no browser needed)

The most terminal-native version needs no browser or HTML at all. A Python script renders
directly to the terminal using the kitty graphics protocol for thumbnails and plain text
for everything else.

**How image placement works:**
`kitten icat --place 24x13@0x2 thumbnail.jpg` renders a 24-column × 13-row image at
a specific cell position. ANSI cursor sequences then position text to the right of it.
A Python script can orchestrate this per video entry.

**Feed view mockup** (░ = image cell, ▶ = cursor):

```
  yt ──────────────────────────────────────────────────  Subscriptions · 47 new

   ░░░░░░░░░░░░░░░░░░░░░  Searching for the BEST Minimal Web Browser    12:33
   ░░░░░░░░░░░░░░░░░░░░░  BreadOnPenguins
   ░░░░░░░░░░░░░░░░░░░░░  148K views · 6 years ago

 ▶ ░░░░░░░░░░░░░░░░░░░░░  Doom Emacs For Noobs                           5:49
   ░░░░░░░░░░░░░░░░░░░░░  DistroTube
   ░░░░░░░░░░░░░░░░░░░░░  106K views · 9 years ago

   ░░░░░░░░░░░░░░░░░░░░░  [VERTICAL] Testing EasySnapX: A Free CleanShot 12:55
   ░░░░░░░░░░░░░░░░░░░░░  EasySnaps
   ░░░░░░░░░░░░░░░░░░░░░  13K views · 17 minutes ago

   ░░░░░░░░░░░░░░░░░░░░░  Wot Hot American Summer - re:View               26:24
   ░░░░░░░░░░░░░░░░░░░░░  RedLetterMedia
   ░░░░░░░░░░░░░░░░░░░░░  565K views · 2 days ago

   ░░░░░░░░░░░░░░░░░░░░░  Recommended Configuration Settings              10:23
   ░░░░░░░░░░░░░░░░░░░░░  BreadOnPenguins
   ░░░░░░░░░░░░░░░░░░░░░  306K views · 6 days ago

 ─────────────────────────────────────────────────────────────────────────────
  j k · ↵ open · / filter · o browser · q quit
```

With `/` active the bottom bar becomes a live filter prompt: `/doom█`

The selected entry (▶) renders its title line in gold (Ukiyo accent). Everything else
stays grey. Cursor is one integer; re-renders on each keypress.

**Interactivity:** `j/k` moves cursor, `Enter` opens detail view, `q` quits, `/`
filters. Handled with Python `tty`/`termios` for raw keypress reading.

**What this needs:**
- `kitten icat` (already in kitty, no new package)
- `urllib.request` + `xml.etree.ElementTree` (Python stdlib — no dependencies)
- `subprocess.Popen(['mpv', 'ytdl://' + url])` for playback
- Temporary directory for thumbnail cache (deleted on exit)

Script lives at e.g. `~/.local/bin/yt`, aliased in `zsh.nix`. Around 150–200 lines of
Python you can read and modify.

### Detail view (Enter from feed)

Pressing Enter on a video opens a detail screen rather than immediately launching mpv.
This lets you read the description and see chapters before committing to watch.
Pressing Enter again launches mpv. `b` goes back to the feed.

```
  ← b ───────────────────────────────────────────────────────────  ↵ play  q

  Doom Emacs For Noobs                                                   5:49
  DistroTube · 106K views · 9 years ago

  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Chapters
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  00:00  Introduction
  ░░░░░  larger thumbnail  ░░░░░░░░░░  01:23  Getting Started
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  03:45  Configuration
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  05:12  Keybindings

  In this video I go through setting up Doom Emacs from scratch,
  covering installation, basic configuration, and the most useful
  keybindings to get you productive quickly. No prior Emacs knowledge
  required.
```

Chapters and description are fetched via `yt-dlp --dump-json URL` (run once on open,
cached). mpv receives chapter data automatically — you can jump between them with
its default bindings.

**Chawan as a simpler alternative:** the HTML localhost page can also be opened in
chawan (in the kitty plan), which renders images via kitty protocol. Less control over
layout but less code. The pure Python TUI is the terminal-native version; chawan is the
fallback if the TUI feels like too much to build initially.

---

## What to actually replicate — blunt assessment

**Build this. It covers your real usage:**

| Feature | How | Effort |
|---------|-----|--------|
| Subscription feed | RSS, stdlib XML parsing | Low |
| Ad-free playback | mpv + yt-dlp | Zero (already works) |
| SponsorBlock | mpv-sponsorblock Lua script | Zero (one package) |
| Chapters | yt-dlp metadata → mpv | Low |
| Subtitles | mpv handles automatically | Zero |
| Description + detail view | yt-dlp --dump-json | Low |
| Watch history | mpv's watch_later dir | Zero (already written) |
| Filter by title | `/` in TUI | Low |

**Do not build this:**

- **Comments.** You said you don't read them. YouTube comments require OAuth. Zero value.
- **Personalized recommendations.** Not achievable without Google auth, and this is the
  part of YouTube that is actively bad for you. The algorithm is designed to maximise
  watch time, not to show you things you'd choose. Not having it is the point.
- **Likes/dislikes.** Dislike counts are available via ReturnYouTubeDislike API but you
  will never make a watching decision based on this.
- **Community posts.** Irrelevant.
- **Live streams.** Edge case — open browser for these. Not worth engineering around.

**Maybe, if it comes up:**

- **Search.** `yt-dlp ytsearch10:query` works fine. Only needed if you want to find
  something outside your subscriptions. Could be a `:` command in the TUI.
- **Channel view.** Pressing a channel name could show all uploads from that channel via
  yt-dlp `--flat-playlist`. Useful but not essential if subscriptions cover your usage.

**The honest summary:** the subscription feed + mpv + detail view replaces everything
you actually use YouTube for. The rest is either the algorithm (unwanted), comments
(unread), or edge cases (open browser). The goal is not to fully replace YouTube —
it is to replace the YouTube tab you keep open all day.

---

## Relation to existing setup

- Same Python server pattern as `newtab-server` in `home/default.nix`
- mpv already in `common.nix`
- yt-dlp available as `mpv`'s backend (installed implicitly); add explicitly if needed
- `mpv-sponsorblock` to add to `common.nix`
- Channel ID list lives in `~/.config/youtube-feed/channels.txt` (not in git — personal)
