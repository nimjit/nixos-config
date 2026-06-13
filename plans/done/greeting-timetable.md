# Plan: Redesigned zsh greeting — daily agenda layout

**Status: COMPLETED** (gen 98, 2026-06-12)

## Context

The greeting works but: (1) truncates calendar events (`head -3`/`head -2`), (2) shows static time that goes stale, (3) lacks the structured daily-agenda feel the user wants — date, weather/quote, all events, deadline list, hourly timetable alongside habits/todos.

---

## Design decisions

**Schedule column — two sources merged:**
The timetable shows both khal calendar events (automatic) AND manually written schedule items from a `## Schedule` section in today's daily note. Format for manual entries: `HH:MM Description` (one per line). This lets you plan study blocks like `14:00 RQM homework` without adding them to the calendar. Khal events take the left slot; daily note entries appear alongside or as additional rows.

**Multiple events in the same hour:**
When two events land at the same hour slot, the first shows on the `HH:00 │` row, subsequent ones show as continuation rows `       │ Event B` with no hour label. This keeps the column width predictable without losing events.

**Long events:**
Displayed only at their start hour — no spanning across rows. A morning overview doesn't need Gantt-chart precision.

**ToDo section — `## ToDo` header in daily note:**
Parse lines under a `## ToDo` header in today's daily note (up to the next `##` section or EOF). Expects `- ` prefixed lines. The `#ToDo` tag approach was for general vault work and is not used here.

**Uni deadlines** → already in `UNI/Deadines/*.md` and `UNI/Assignments/*.md` frontmatter. Parse in bash.

**Journal section in greeting:** No — stays in daily notes only.

---

## Implemented layout

```
  Friday 12 June 2026

  🌤️ +16°C · Leiden          "The only way to do great work..."

  Today                                Tomorrow
  12:00  L. Sasja                      10:00  Meeting prof
  19:00  L. Lotte afspreken?
  19:30  Kracht Training workout

         │ Schedule              Dailies
   09:00 │                       □ Brush teeth
   10:00 │                       □ Eat vegetables
   11:00 │                       □ Put on deodorant
   12:00 │ L. Sasja               □ Write in journal
   13:00 │
   14:00 │ RQM homework          Deadlines
   15:00 │                       in  4d  (16 Jun)  aQM — pres.
   16:00 │                       in  5d  (17 Jun)  Stats — report
   17:00 │
   18:00 │                       ToDo
   19:00 │ L. Lotte                · Finish reading ch. 3
         │ Kracht Training         · Email supervisor
   20:00 │
   21:00 │
   22:00 │

  today  vault-work  uni-work  messages  music  cal
```

---

## Files changed

| File | Change |
|------|--------|
| `home/zsh.nix` | Full replacement of `_greeting()` and `_deadlines()` functions |
| `home/dotfiles/neovim/init.lua` | `DailyNote` command reads shared vault template |
| `~/vault/Templates/Daily Note.md` | Shared `{{date}}` template for both `cap()` and `DailyNote` |
| `generations.md` | Created; correlates all generations with git commits |
| `CLAUDE.md` | Updated workflow section with generation log instructions |

---

## Key bugs fixed during implementation

- `local var` inside loop prints value if already set — moved all `local` declarations before the loop
- `printf '%s\n' "${empty_array[@]}"` emits one empty line in zsh — guarded with `(( ${#results[@]} > 0 )) || return`
- `date -d "DD-MM-YYYY"` fails — detect format with regex and convert to ISO before parsing
- `completed: True` / `completed: "true"` not caught — case-insensitive via `${val:l}`
- `class:` field truncated by `awk '{print $2}'` — replaced with `sed 's/^class:[[:space:]]*//'`
- `│` column misaligned — fixed spaces in header row to match hour rows
