Run a NixOS rebuild and log the new generation to generations.md.

Description of what this generation adds: $ARGUMENTS
(If no arguments were given, ask the user for a one-line description before proceeding.)

## Steps

**1. Rebuild**

Run: `sudo nh os switch /etc/nixos -H desktop`

Stream the output so progress is visible. `-H desktop` is correct — this command is always for the desktop host.

**2. On failure**

Show the relevant error lines from the output. Stop — do not update generations.md.
Common failure causes: nix eval error (syntax/type), package fetch failure, activation error.

**3. On success — log the generation**

Get the new generation number:
```
ls /nix/var/nix/profiles/ | grep -E '^system-[0-9]+-link$' | sort -t- -k2 -n | tail -1 | grep -oE '[0-9]+'
```

Get the current git short hash:
```
git -C /etc/nixos rev-parse --short HEAD
```

Get the current date and time:
```
date "+%Y-%m-%d  %H:%M"
```

Append to `/etc/nixos/generations.md` (match the existing column spacing):
```
| <gen> | <date>  <time> | <hash> | <description> |
```

**4. Commit and push**

```
git -C /etc/nixos add generations.md
git -C /etc/nixos commit -m "generations: log gen <N>"
git -C /etc/nixos push
```

**5. Report**

One line: `✓ Generation <N> — <description>`
