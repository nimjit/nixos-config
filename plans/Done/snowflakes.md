# Snowflake Visualizations

## What was built

Three standalone HTML files rendered as D3.js radial graphs. Each node is a
file/folder; edges are parent-child relationships. Fully self-contained (D3 inlined),
open in any browser. A systemd user timer regenerates all three 2 min after login.

## Scripts and outputs

| Script | Location | Output | Open |
|--------|----------|--------|------|
| `nixos_snowflake.py` | `/etc/nixos/nixos_snowflake.py` | `/etc/nixos/nixos_snowflake.html` | `SPC o n` in emacs |
| `vault_snowflake.py` | `.../Renaissance_Vault_Structure/vault_snowflake.py` | `.../vault_snowflake.html` | `SPC o v` |
| `uni_snowflake.py` | `.../Uni/Obsidian/uni_snowflake.py` | `.../uni_snowflake.html` | `SPC o u` |

Regenerate manually: `SPC o V` (runs all three) or `python3 <script>` directly.

Systemd timer: `systemd.user.timers.snowflake-regen` in `home/default.nix` (fires 2 min after login).

## Sections mapped

- **nixos**: modules/ (orange), home/ (teal), hosts/ (blue), plans/ (yellow)
- **vault**: Knowledge (by subject), Sources, People — maps the BACKUP Obsidian vault
- **uni**: Classes (by subject), Lectures, Assignments — maps the BACKUP Uni vault

## Notes

vault_snowflake.py and uni_snowflake.py point to `~/Documents/BACKUP/` (the Markdown
archive), not any live active vault. If emacs/org-mode becomes the primary editor,
a new `org_snowflake.py` pointing to `~/org/` would be needed.

The `[g]` key in the neovim vault dashboard currently opens vault_snowflake.html in
Firefox. A neovim-native graph view is planned — see `dashboard-graphs.md`.
