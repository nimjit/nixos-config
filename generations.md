# NixOS Generation Log

Correlates system generations with git commits. Each row shows when `nixos-rebuild switch` was run and the most recent commit at that time.
Generated 2026-06-12. Keep updated: add a row after each rebuild going forward.

---

| Gen |       Date & Time | Commit  | Description                                                             |
|----:|------------------:|---------|-------------------------------------------------------------------------|
|   1 | 2026-05-19  18:05 | db03351 | font name change                                                        |
|   2 | 2026-05-19  18:48 | df85b2d | added NVIDIA card modules                                               |
|   3 | 2026-05-19  19:15 | 13241b5 | added config to hosts/desktop                                           |
|   4 | 2026-05-19  19:30 | 1ac127c | fix                                                                     |
|   5 | 2026-05-19  20:24 | 61303de | saved git credentials                                                   |
|   6 | 2026-05-20  23:18 | d026522 | maybe one day ill remember the ;                                        |
|   7 | 2026-05-20  23:21 | 15674b8 | added backup for home-manager                                           |
|   8 | 2026-05-20  23:23 | dffd9e2 | changed nvim alias                                                      |
|   9 | 2026-05-20  23:30 | c077737 | update python runner to linux                                           |
|  10 | 2026-05-20  23:39 | c5c9f80 | this should really work                                                 |
|  11 | 2026-05-20  23:42 | 0962068 | changed language and numbers to be correct                              |
|  12 | 2026-05-20  23:57 | a2050ee | changed color3 in kitty                                                 |
|  13 | 2026-05-21  09:10 | c93c8d8 | you knwo the deal                                                       |
|  14 | 2026-05-21  14:02 | dbbb4dd | fixed path location in python run command                               |
|  15 | 2026-05-21  14:13 | c907f3b | changed ukiyo theme colours                                             |
|  16 | 2026-05-22  18:47 | 9d8ffb1 | startup script: mistake /etc/nixos                                      |
|  17 | 2026-05-22  19:00 | 1895ee7 | startup script: defined something twice                                 |
|  18 | 2026-05-22  19:13 | e1cffa5 | added sleep between desktops switching                                  |
|  19 | 2026-05-23  00:27 | b93e69b | added automation so that startup does not interfere with session manager|
|  20 | 2026-05-23  00:49 | d77215d | hardcoded host name                                                     |
|  21 | 2026-05-23  02:12 | ed5047e | add cmu fonts                                                           |
|  22 | 2026-05-23  02:26 | ed5047e | add cmu fonts (re-run, no new commit)                                   |
|  23 | 2026-05-23  13:18 | 5adabd1 | disabled startup script; nvidia boot safeties                           |
|  24 | 2026-05-24  12:10 | bce5813 | added syncthing config                                                  |
|  25 | 2026-05-24  23:03 | b346113 | formatted and added HDD                                                 |
|  26 | 2026-06-04  01:15 | 3d99307 | added more tools (claude-code, switched to stable)                      |
|  27 | 2026-06-04  15:44 | 3d99307 | (same commit, re-run)                                                   |
|  28 | 2026-06-04  15:48 | 30b3cf0 | neovim: add yazi picker, fix terminal mode window navigation            |
|  29 | 2026-06-04  16:16 | bdec676 | added stuff to neovim.nix and open issues tab                           |
|  30 | 2026-06-04  16:25 | 34092c4 | changed alias to open yazi immediately                                  |
|  31 | 2026-06-04  16:44 | cce681c | added alias list for remembering inside zsh                             |
|  32 | 2026-06-05  00:00 | 6550b16 | updated userchrome.css                                                  |
|  33 | 2026-06-05  00:42 | 6550b16 | (same commit, re-run)                                                   |
|  34 | 2026-06-05  01:41 | 96249d0 | added workflow manager to nix and zsh config                            |
|  35 | 2026-06-05  01:45 | 761ac5c | added workflows to helpful popup                                        |
|  36 | 2026-06-05  11:51 | 037a39e | updated uni-code workflow                                               |
|  37 | 2026-06-05  23:23 | 9393553 | added cli tools (nchat, rmpc, etc.)                                     |
|  38 | 2026-06-05  23:54 | 41e891b | added config files for cli tools                                        |
|  39 | 2026-06-06  00:14 | aeac107 | moved more config files                                                 |
|  40 | 2026-06-06  00:22 | 70bbe05 | changed nchat config                                                    |
|  41 | 2026-06-06  13:08 | 8fd55e6 | updated syncthing config                                                |
|  42 | 2026-06-07  23:08 | 02df02a | added emacs config                                                      |
|  43 | 2026-06-07  23:30 | 9ce1ad9 | fix emacs config                                                        |
|  44 | 2026-06-07  23:44 | 9ce1ad9 | (same commit, re-run)                                                   |
|  45 | 2026-06-07  23:51 | 9ce1ad9 | (same commit, re-run)                                                   |
|  46 | 2026-06-08  00:06 | 9ce1ad9 | (same commit, re-run)                                                   |
|  47 | 2026-06-08  00:09 | 9ce1ad9 | (same commit, re-run)                                                   |
|  48 | 2026-06-08  00:58 | e9c28c8 | Emacs: byte-compile config.el after tangle                              |
|  49 | 2026-06-08  01:01 | 2c8666d | revert byte-compile: breaks general.el macro expansion                  |
|  50 | 2026-06-08  01:19 | 84ff7d7 | fix KWin 20Hz lag: PRIME reverseSync                                    |
|  51 | 2026-06-08  01:28 | 6ffe798 | fix KWin 20Hz lag (second attempt)                                      |
|  52 | 2026-06-08  11:22 | 4734567 | suppress org-gcal startup warning                                       |
|  53 | 2026-06-08  21:19 | 1428132 | add CLI migration and snowflakes plan files                             |
|  54 | 2026-06-08  21:21 | 1428132 | (same commit, re-run)                                                   |
|  55 | 2026-06-08  23:06 | ed3b50a | add dashboard system: vault/uni dashboards, daily notes, music          |
|  56 | 2026-06-08  23:08 | ed3b50a | (same commit, re-run)                                                   |
|  57 | 2026-06-08  23:37 | be7572c | add weight logging, image.nvim, typst inline, PDF opener                |
|  58 | 2026-06-09  00:22 | f15e6ff | add Dashboard command, aligned tables, math rendering, zathura          |
|  59 | 2026-06-09  00:38 | 86ef670 | fix leader key, typst colors, zathura tiling, cal scope                 |
|  60 | 2026-06-09  00:57 | a10ddc3 | add in-neovim PDF split viewer, fix ghostscript, fix music path         |
|  61 | 2026-06-09  01:13 | 80b74bd | suppress calcurse-caldav stderr in cal alias                            |
|  62 | 2026-06-09  01:22 | 73ef89f | add music neovim split and auto-queue on idle                           |
|  63 | 2026-06-09  01:40 | 2ffb0dd | switched to khal                                                        |
|  64 | 2026-06-09  02:04 | 3399d50 | fix khal config: correct palette format                                 |
|  65 | 2026-06-09  11:29 | 6794754 | added safeties for claude not to break system                           |
|  66 | 2026-06-09  11:45 | 0fff347 | fix boot: remove KWIN_DRM_DEVICES                                       |
|  67 | 2026-06-09  15:00 | c9c8795 | add course view: <CR> on course opens lecture list                      |
|  68 | 2026-06-09  15:04 | d44b4ac | fix course view: actually display the buffer                            |
|  69 | 2026-06-09  15:09 | ec7bd10 | fix image preview: disable auto-render, add <leader>z                  |
|  70 | 2026-06-09  15:22 | ff57025 | fix image/PDF preview: use kitty @ launch vsplit                        |
|  71 | 2026-06-09  15:36 | a994398 | kitty splits layout + nav keys; markdown colors; course view            |
|  72 | 2026-06-09  21:16 | eeaf22e | fix markdown highlights; lower PDF DPI                                  |
|  73 | 2026-06-10  01:37 | 01d5a7a | updated neovim markdown highlighting                                    |
|  74 | 2026-06-10  02:02 | 57b5fc5 | updated neovim markdown highlighting again                              |
|  75 | 2026-06-10  02:18 | 828563e | updated wrong naming                                                    |
|  76 | 2026-06-10  16:09 | 31f5677 | added minor upgrades                                                    |
|  77 | 2026-06-10  16:24 | 57dacc1 | fix cap to personal vault; archive finalized plans                      |
|  78 | 2026-06-10  16:42 | f8e914e | fix zsh.nix: '' in bash is Nix string terminator                        |
|  79 | 2026-06-11  22:07 | d6c77af | implement wikilink gf: handles spaces and alias/heading suffixes        |
|  80 | 2026-06-11  22:45 | 2054d6c | fix wikilink resolver: strip folder prefix before search                |
|  81 | 2026-06-12  01:12 | d35eb4b | more minor fixes                                                        |
|  82 | 2026-06-12  01:19 | d35eb4b | (same commit, re-run)                                                   |
|  83 | 2026-06-12  01:32 | f294ee4 | changes to working sway environment                                     |
|  84 | 2026-06-12  12:01 | 1396364 | fixed swap file error in neovim lua file                                |
|  85 | 2026-06-12  12:16 | 757d12c | updated lua/dashboard.lua                                               |
|  86 | 2026-06-12  13:59 | 757d12c | (same commit, re-run)                                                   |
|  87 | 2026-06-12  14:51 | 69b6f34 | nchat persistent via dtach; rofi bigger icons; kitty nav cleanup        |
|  88 | 2026-06-12  15:07 | 1f29970 | fix minor issues (nchat TERM, dtach, music)                             |
|  89 | 2026-06-12  15:39 | 1f29970 | (same commit, re-run)                                                   |
|  90 | 2026-06-12  15:56 | 1f29970 | (same commit, re-run)                                                   |
|  91 | 2026-06-12  16:16 | cce8031 | messages and music workspaces fix                                       |
|  92 | 2026-06-12  16:21 | 6bff7f3 | minor fixes                                                             |
|  93 | 2026-06-12  16:23 | 6bff7f3 | (same commit, re-run)                                                   |
|  94 | 2026-06-12  17:20 | 5cdc0a1 | changed neovim dashboards to render as markdown                         |
|  95 | 2026-06-12  18:43 | 5cdc0a1 | greeting redesign: timetable layout, deadlines, dailies                 |
|  96 | 2026-06-12  18:54 | 5cdc0a1 | greeting fixes: hh= debug output, deadlines DD-MM-YYYY parsing          |
|  97 | 2026-06-12  19:07 | 5cdc0a1 | deadline fixes: Assignments dir, completed field, right-column border   |
|  98 | 2026-06-12  19:20 | e45cb13 | daily note template in vault; generation log; CLAUDE.md workflow update |
|  99 | 2026-06-15  00:00 | 64147c3 | CLI batch: zoxide, eza, bat, rebuild(), nix status, wiki-tui K, math conceal, vim-kitty-navigator, yt-feed TUI |
| 100 | 2026-06-15  00:00 | 63be6d4 | fix ctrl+hjkl (CSI u in pass_keys.py), WorkflowNixos terminal, math conceal multi-match |
| 101 | 2026-06-15  00:00 | 3c6fdd3 | revert kitty ctrl+hjkl kitten; smart_nav in neovim is the nav layer |
| 102 | 2026-06-15  00:00 | 156ae03 | fix WorkflowNixos crash: jobstart instead of blocking system() for kitty @ |
| 103 | 2026-06-15  00:00 | e16cdd3 | revert workflow terminals fully to pre-session state |
| 104 | 2026-06-15  00:00 | eb713b6 | fix yt-feed channel ID parsing; add duration cache + L filter |
| 105 | 2026-06-15  00:00 | 44b8066 | yt-feed: 16:9 thumbs, enter-to-play, left margin, long default |
| 106 | 2026-06-16  00:12 | b5f68a2 | yt-feed: fix getch() ESC drain, RSS cache, mpv log, open-in-browser |
| 107 | 2026-06-16  00:19 | 2290096 | yt-feed: fix mpv playback on NVIDIA — add --hwdec=no |
| 108 | 2026-06-17  14:50 | 4e6723a | messages(): kitten @, exact title match, pgrep-aware 3-stage logic |
| 109 | 2026-06-17  21:30 | d3054ed | messages(): dtach -a (attach-only); service adds Restart=on-failure |
| 110 | 2026-06-17  21:45 | 65e062f | messages: fix service restart + Wayland-safe tab focus |
| 111 | 2026-06-17  22:00 | 1ffcf13 | pandoc + nbconvert/nbformat in Python env; <leader>E ereader export |
| 112 | 2026-06-18  02:04 | 86d5ecc | emacs: reset to minimal config (evil + which-key + theme) |
| 113 | 2026-06-18  16:39 | 41d8302 | updated generations |
| 114 | 2026-06-18  17:16 | 99516ec | qutebrowser: HM module, Ukiyo theme, CSS stylesheets, Greasemonkey list-view, ad blocking |
| 115 | 2026-06-18  17:31 | 327c0d8 | qutebrowser: fix stylesheet URL pattern error; restore scoped dim/flat rules |
| 116 | 2026-06-18  17:51 | 982402c | krohnkite: DWM tiling + Alt+HJKL positional focus KWin script |
| 114 | 2026-06-18  17:19 | 2396ad1 | updated generations |
| 116 | 2026-06-18  21:19 | 5d3e52d | updated generations |
| 117 | 2026-06-18  23:09 | 63f2c4d | generations update |
| 117 | 2026-06-18  23:14 | 556faf9 | working on kronkhite setup |
| 117 | 2026-06-18  23:21 | 556faf9 | (same commit, re-run) |
| 118 | 2026-06-18  23:45 | 556faf9 | (same commit, re-run) |
| 119 | 2026-06-19  00:10 | 556faf9 | (same commit, re-run) |
| 120 | 2026-06-19  00:14 | 556faf9 | (same commit, re-run) |
| 121 | 2026-06-19  00:28 | 556faf9 | (same commit, re-run) |
| 121 | 2026-06-19  00:30 | dc50ca4 | kronkhite+qutebrowser working on fixing |
| 122 | 2026-06-19  02:10 | dc50ca4 | (same commit, re-run) |
| 123 | 2026-06-19  12:21 | a82af59 | still working on qutebrowser config |
| 124 | 2026-06-19  12:29 | a82af59 | (same commit, re-run) |
| 125 | 2026-06-19  12:34 | a82af59 | (same commit, re-run) |
| 126 | 2026-06-19  12:41 | a82af59 | (same commit, re-run) |
| 127 | 2026-06-19  13:19 | a82af59 | weight chart: plot-weights.py → kitty hsplit in vault dashboard |
| 128 | 2026-06-19  15:40 | a82af59 | weight chart: inline image.nvim render, 4-series, N=85 matches vault graph |
| 129 | 2026-06-19  16:46 | a82af59 | vault graph view: collapsible ASCII tree + PNG overlay; w3m + wb(); [g] no longer opens Firefox |
| 130 | 2026-06-19  16:53 | a82af59 | vault graph PNG: full 3-flake snowflake (Knowledge+Sources+People), right-aligned, larger |
| 131 | 2026-06-19  17:01 | a82af59 | vault graph: fix bg colour (#372d29), fix size (70% pane width), fix right-align |
| 132 | 2026-06-19  17:30 | 56a298a | vault graph: use vim.o.columns for 70% right-aligned PNG (was using wrong win width) |
