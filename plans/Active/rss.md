# RSS — terminal feed reader

## Goal

Read newsletters and blogs in the terminal. Keep email for messages that need
a reply; everything one-way and subscription-based goes here instead.

---

## Tool choice: newsboat

Several terminal RSS readers exist in nixpkgs. The main contenders:

| Tool | Language | Style | Notes |
|------|----------|-------|-------|
| **newsboat** | C++ | ncurses, 2-pane | De-facto standard; vim keys; highly configurable |
| sfeed | C | Unix pipes | Parser only — you build the UI in shell; very hackable |
| canto | Python | curses | Older, less maintained |
| Custom (yt-feed style) | Python | Full-screen TUI | Good for thumbnails; overkill for text |

**Recommendation: newsboat.**

Why not a custom yt-feed-style TUI: yt-feed is custom because YouTube has no
official API, thumbnails need kitty icat rendering, and the card layout adds real
value for video. For text articles none of that applies — newsboat already has
exactly the right feature set and is actively maintained.

What newsboat covers:
- Vim keybindings (j/k/l/h, g/G, / to search) out of the box
- Fully configurable colors → can match Ukiyo palette
- Tags for grouping feeds by category
- Macros to open URLs in mpv, w3m, or browser
- Home-manager module (`programs.newsboat`)
- Podcast support (future)
- Sync with Miniflux/Inoreader if a web UI is ever wanted

What it does not cover:
- Thumbnail preview (not needed for text)
- Stylix auto-theming (configure colors manually, same as khal)

---

## Architecture

```
feeds defined in ~/.config/newsboat/urls
newsboat fetches + caches → ~/.local/share/newsboat/cache.db
newsboat opens articles in:
  - w3m   (HTML newsletters, rendered in terminal)
  - mpv   (podcast/video links)
  - browser  (fallback for anything complex)
```

No sync service needed for single-machine use. Add Miniflux (self-hosted) later
if multi-device sync is wanted.

---

## Feed organisation

Tags group feeds in the sidebar. Suggested categories:

| Tag | Content |
|-----|---------|
| `tech` | Programming, Linux, software |
| `science` | Research, physics, general science |
| `news` | Current events (use sparingly — prefer depth over firehose) |
| `blogs` | Personal blogs, essays |
| `newsletters` | Migrated email newsletters |
| `podcasts` | Audio feeds (future) |

Feeds defined in `~/.config/newsboat/urls`:
```
https://example.com/feed.xml "~Tech" tech
https://newsletter.example.com/rss "~Newsletter: Name" newsletters
```

The `~` prefix makes newsboat show the custom name instead of the feed title.

---

## Key bindings (planned)

| Key | Action |
|-----|--------|
| `j` / `k` | Up / down |
| `l` / `Enter` | Open article |
| `h` / `q` | Back |
| `o` | Open in browser |
| `O` | Open in w3m |
| `,m` | Open in mpv (for video/podcast links) |
| `r` | Reload current feed |
| `R` | Reload all feeds |
| `t` | Filter by tag |
| `u` | Mark all read |
| `/` | Search |
| `?` | Help |

---

## Theming

Newsboat uses `color` directives in `~/.config/newsboat/config`.
Match the Ukiyo base16 palette (same approach as khal's `[palette]` section):

```
color background      default   default
color listnormal      color251  default        # text ccc2b7
color listfocus       color235  color179       # dark on amber (selected)
color listnormal_unread color222 default bold  # gold e0ba86, unread
color listfocus_unread color235  color222 bold # dark on gold, unread+selected
color info            color179  default        # amber ba945f
color article         color251  default        # body text
```

---

## Nix config outline

```nix
programs.newsboat = {
  enable = true;
  autoReload = true;
  reloadTime = 60;  # minutes
  urls = [];  # manage ~/.config/newsboat/urls manually (contains feed URLs, not a secret but personal)
  extraConfig = ''
    browser "xdg-open %u"
    macro m set browser "mpv %u" ; open-in-browser ; set browser "xdg-open %u"
    macro w set browser "w3m %u" ; open-in-browser ; set browser "xdg-open %u"
    bind-key h quit
    bind-key l open
    # color config here
  '';
};
```

The urls file is managed outside nix (like `~/.config/vdirsyncer/config`) — it's
personal preference data, not system config.

---

## Integration with the rest of the system

| System | Interaction |
|--------|-------------|
| **email** | Newsletters migrated here. When clearing Gmail: find the feed URL, add to newsboat, unsubscribe from email. |
| **mpv** | Podcast / video links opened via `,m` macro |
| **w3m** | HTML articles rendered with `wb`-style inline reading |
| **greeting** | Could show unread feed count (e.g. `find ~/.local/share/newsboat/ ...`) |
| **browser** | Fallback for anything newsboat can't render |
| **kitty** | Newsboat runs in a kitty tab, same pattern as `music` and `messages` aliases |

Add a `feeds` alias to zsh (opens newsboat in a kitty tab, same pattern as `music`/`messages`).

---

## Migration path

1. Install newsboat, write basic config + Ukiyo colors
2. Add first feeds manually — start with 3–5 that you actually want to read
3. As Gmail newsletters arrive, find their RSS feed:
   - Most Substack newsletters: `https://author.substack.com/feed`
   - Most blogs: try `/rss`, `/feed`, `/atom.xml`
   - Use `rss-bridge` (self-hosted, nixpkgs) if a site has no feed
4. Add to newsboat urls file, unsubscribe from email
5. Build the habit before scaling up the feed list

---

## Status

- [ ] Add newsboat to `home/default.nix` (or new `home/rss.nix`)
- [ ] Write Ukiyo color config
- [ ] Write keybinding macros (mpv, w3m)
- [ ] Add `feeds` kitty-tab alias to zsh
- [ ] Seed urls file with first 5 feeds
- [ ] Begin newsletter migration from Gmail
