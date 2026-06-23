# yt-feed v2 — Plan

Building on the existing `~/.local/bin/yt-feed` (see `plans/Done/youtube-frontend.md`).
Goal: make it feel more like a real YouTube frontend, not just a feed reader.

---

## What we're building

Four improvements, independent enough to land one at a time:

1. **Scrolling performance** — stop re-rendering thumbnails on every keypress
2. **Homepage grid view** — 2-column grid layout, new view mode
3. **Shorts exclusion via RSS** — replace slow yt-dlp duration fetch with a smarter approach
4. **Channel categories** — filter by group (tech, music, etc.)

---

## 1. Scrolling Performance

### Root cause

`render_list` calls `clear()` then re-renders *all* visible entries including all
their thumbnails via `kitten icat` subprocess on every `j`/`k` keypress. With 4
visible entries, that's 4× subprocess fork + image upload on each keystroke.

### Fix: split cursor update from full redraw

Track `last_offset` and `last_cursor`. On `j`/`k`:

- **Viewport didn't shift** (same set of visible videos):
  - Only redraw text at the two affected rows (previous cursor row → deselect, new
    cursor row → select). Zero thumbnail re-renders.
  - `render_entry_text(video, row, selected)` — no `show_thumb` call

- **Viewport shifted by one**:
  - The old first/last entry scrolled out; a new one scrolled in.
  - Erase the departed thumbnail with `kitten icat --clear` at its position.
  - Render ONE new thumbnail at the entering position.
  - Update text for all visible entries (cursor highlight moved anyway).

- **Jump (large scroll, resize, filter change)**:
  - Full redraw as today.

### Stretched goal: kitty APC escape codes

Kitty's image protocol can be driven purely via stdout escape sequences (no subprocess
at all). Format: `\x1b_Ga=T,f=32,...;<base64 data>\x1b\\`. Eliminates all subprocess
overhead for thumbnails. Non-trivial to implement but the right long-term direction.
Worth a separate PR once the viewport-tracking fix is done.

---

## 2. Homepage Grid View

### What it looks like

Two columns, each cell roughly 55 cols × 9 rows. Aim for 3-4 rows visible at once
(6-8 videos on screen). Cleaner than YouTube — no sidebar, no ads, just thumbnails
+ essential info.

```
  yt ─────────────────────────────────────────────────  Home · 47 videos

  ┌──────────────────────────┐  ┌──────────────────────────┐
  │  ░░░░░░░░░░░░░░░░░░░░░░  │  │  ░░░░░░░░░░░░░░░░░░░░░░  │
  │  ░░░░░░░░░░░░░░░░░░░░░░  │  │  ░░░░░░░░░░░░░░░░░░░░░░  │
  │  ░░░░░░░░░░░░░░░░░░░░░░  │  │  ░░░░░░░░░░░░░░░░░░░░░░  │
  │  ░░░░░░░░░░░░░░░░░░░░░░  │  │  ░░░░░░░░░░░░░░░░░░░░░░  │
  │  Title of the video here │  │  Title of the video here │
  │  Channel · 12:33         │  │  Channel · 12:33         │
  └──────────────────────────┘  └──────────────────────────┘

  ▶ selected cell highlighted with accent border or dimmed others

  ─────────────────────────────────────────────────────────────
   hjkl · ↵ play · o browser · d detail · Tab: switch view
```

### Grid cell sizing

Terminal cell assumptions (kitty default): ~10px wide, ~20px tall.
Target thumbnail: `24 cols × 7 rows` (240×140px rendered, close to 16:9).
Gap between columns: 4 cols.
Column width: `24 + 4 (text padding) + ~28 (title text) = 56` cols → fits in ~120 col terminal.

For narrow terminals (<100 cols): fall back to 1-column grid.

### Navigation

```
h / l   move left/right between columns
j / k   move down/up one row (skips 2 videos)
Tab     switch between Grid view and Feed (list) view
Enter   open detail view
```

Grid cursor = `(row, col)`, videos indexed as `videos[row*2 + col]`.

### Data source

Use the existing RSS aggregation — same data as the feed view, just rendered
as a grid. No new data pipeline needed. The "homepage" is essentially "latest
videos from all subscriptions" in a prettier layout.

**Why not yt-dlp cookies for real YouTube homepage?**
- Requires browser login state (brittle, breaks on cookie expiry)
- Would bring back algorithmic recommendations, which the old plan specifically avoided
- RSS gives chronological subscription feed — arguably better for intentional watching

The grid view *looks like* YouTube; the algorithm stays out.

### View state

Add `mode` values: `"list"` (current), `"grid"` (new), `"detail"` (current).
`Tab` cycles list ↔ grid. Detail is entered from either.
Store `grid_cursor = [row, col]` and `grid_offset` separately from list cursor.

---

## 3. Shorts Exclusion

### Current approach (slow)

`long_only` filter uses `dur_cache` populated by background `yt-dlp` calls — one
subprocess per video, results arrive minutes after startup. Until then, all videos
pass through with unknown duration.

### Better approach: RSS-time heuristics

At `parse_feed` time, tag each video:

```python
def is_short(entry):
    title = entry.get("title", "").lower()
    if any(tag in title for tag in ("#shorts", "#short", "#ytshorts")):
        return True
    # Shorts thumbnails from RSS have a specific URL path in some cases
    # (not reliable but worth checking)
    return False
```

Also check the `media:content` height from the RSS feed — Shorts are portrait (9:16)
while long videos are landscape (16:9). The `mqdefault` thumbnail is always 16:9 but
the `media:content` element may carry the original dimensions. Worth inspecting one
channel's RSS that posts Shorts to verify.

**Duration filter (keep as secondary):** Once `dur_cache` has an entry, still apply
`LONG_MIN_SECS = 5*60`. But uncached videos that pass the hashtag heuristic are
shown rather than hidden — better UX than waiting for yt-dlp.

**Status bar indicator:** Show `[long]` when long_only is on (as today), but also
show `[~N filtered]` to indicate how many shorts were heuristically excluded.

**Note on "RSS type=l parameter":** Investigated — YouTube's RSS feed
(`feeds/videos.xml?channel_id=ID`) does not support a `type=l` query parameter.
The `type=l` filter exists on the web channel page only and requires JavaScript
rendering. Not usable here.

---

## 4. Channel Categories

### channels.txt format extension

Current format:
```
CHANNEL_ID    # Channel name
```

New format (backwards compatible — existing files still work):
```
# [tech]
UCxxxxxx    # Fireship
UCxxxxxx    # ThePrimeagen

# [music]
UCxxxxxx    # Lofi Girl

# [misc]
UCxxxxxx    # Random channel
```

`# [name]` lines (square brackets) mark a new category. Plain `# comment` lines
(no brackets) remain grouping comments as before.

### Implementation

In `load_channels()`, return `[(channel_id, category)]` pairs. At parse time, each
video gets `"category": "tech"` etc. (empty string for uncategorised).

In `apply_filters()`, add `category_filter: str | None`. When set, only show videos
matching that category.

### TUI controls

```
1 2 3 …    filter by category 1, 2, 3 (ordered as they appear in channels.txt)
0          show all categories
```

Status bar shows the active category:
```
 47/312  tech  j/k: nav  Enter: play  …
```

Categories are discovered at startup (no hardcoding). Up to 9 numbered.

---

## Implementation order

| Step | What | Why first |
|------|------|-----------|
| 1 | Shorts heuristic at parse time | Quick win, standalone, improves current experience |
| 2 | Scrolling — cursor-only update path | Core UX issue; pure refactor, no new features |
| 3 | Category support | Extends channels.txt parsing, then filter logic |
| 4 | Grid / homepage view | Most complex; builds on the stable scroll foundation |
| 5 | Kitty APC direct protocol | Stretch goal; replaces all icat subprocesses |

---

## What we looked at (other TUIs)

| Project | Lang | Approach | Interesting |
|---------|------|----------|-------------|
| xytz | Go / Bubble Tea | yt-dlp backend, cookie auth | Browser cookie extraction for restricted content |
| ytviewer | Go / Bubble Tea | YouTube Data API v3 | 30min caching, watch history tracking |
| ytui | Go | OAuth + Invidious proxy | fuzzy-finder navigation, SOCKS5 proxy |
| youtube-tui | Rust | Launcher pattern (mpv/yt-dlp) | Sixel image rendering, offline library |

None have a homepage/grid view. All use text-only lists — probably exactly because
thumbnail rendering performance is the hard part. We have a head start with the
kitty protocol already working; the viewport-tracking optimisation makes it viable.

---

## Files to touch

- `~/.local/bin/yt-feed` — the whole script
- `home/default.nix` — if the script moves or gains new dependencies
- `~/.config/yt-feed/channels.txt` — user adds `# [category]` headers (manual step)

No new Nix packages needed. All dependencies already in the system.
