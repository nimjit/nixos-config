# Ereader Export — typst/markdown → PDF → device

## Goal

One command (or neovim keybinding) that compiles the current typst or markdown file
to PDF and transfers it to the ereader — so study notes can be read in the sun without
any manual steps.

---

## Current manual workflow

1. `typst compile file.typ` → `file.pdf`
2. Copy `file.pdf` to the ereader (USB mount or app)

---

## Compile step

### Typst files (`.typ`)

```bash
typst compile "$file" "${file%.typ}.pdf"
```

`typst` is already available as a package. Output lands next to the source file.

### Markdown files (`.md`)

Option A — pandoc with a typst backend (cleanest, matches existing tooling):
```bash
pandoc "$file" -o "${file%.md}.pdf" --pdf-engine=typst
```

Option B — pandoc with LaTeX (heavier but more control over page layout):
```bash
pandoc "$file" -o "${file%.md}.pdf" --pdf-engine=lualatex -V geometry:margin=2cm
```

Option A is preferable if typst is already installed. The output will use typst's
default styling, which is clean and readable on ereaders.

---

## Transfer step

Open question: **how is the ereader connected?**

| Method | Transfer command |
|--------|-----------------|
| USB mass storage (mounts as `/dev/sdX`) | `cp file.pdf /run/media/thijmen/<device>/` |
| KOReader with SSH/HTTP | `curl -X POST http://<device-ip>:8080/upload -F file=@file.pdf` |
| Calibre wireless | `calibredb add file.pdf --with-library <library>` |
| Syncthing shared folder | Copy to synced dir; Syncthing pushes automatically |

**Syncthing** is already configured on this system — if the ereader also runs
Syncthing (KOReader supports it), this is zero-friction: just drop PDFs into a
synced folder and they appear on the device.

---

## Neovim integration

Add a `<leader>E` (Export) keybinding to `init.lua` that:
1. Detects filetype (`vim.bo.filetype`)
2. Runs the appropriate compile command via `vim.fn.jobstart()`
3. On success, copies to the transfer destination

```lua
vim.keymap.set("n", "<leader>E", function()
  local src = vim.fn.expand("%:p")
  local ft  = vim.bo.filetype
  local pdf
  if ft == "typst" then
    pdf = src:gsub("%.typ$", ".pdf")
    vim.fn.jobstart({"typst", "compile", src, pdf}, {
      on_exit = function(_, code)
        if code == 0 then
          vim.fn.jobstart({"cp", pdf, EREADER_PATH})
          vim.notify("Exported to ereader")
        else
          vim.notify("Compile failed", vim.log.levels.ERROR)
        end
      end
    })
  elseif ft == "markdown" then
    pdf = src:gsub("%.md$", ".pdf")
    vim.fn.jobstart({"pandoc", src, "-o", pdf, "--pdf-engine=typst"}, {
      on_exit = function(_, code)
        if code == 0 then
          vim.fn.jobstart({"cp", pdf, EREADER_PATH})
          vim.notify("Exported to ereader")
        else
          vim.notify("Compile failed", vim.log.levels.ERROR)
        end
      end
    })
  else
    vim.notify("Not a typst or markdown file")
  end
end, { desc = "Export to ereader" })
```

`EREADER_PATH` would be a local variable pointing to the Syncthing folder or USB mount.

---

## Open questions

- What ereader model / OS? (Kindle, Kobo, PocketBook, KOReader?)
- Does it read PDF natively? (All of the above do)
- Preferred transfer method: USB, Syncthing, KOReader HTTP, or Calibre wireless?
- Should the PDF stay next to the source file, or go to a dedicated `~/Documents/ereader/` folder?
- Page size: A5 is common for ereaders — add `-V papersize:a5` or typst equivalent?

---

## Status

- [ ] Confirm ereader model and transfer method
- [ ] Decide on page size (A4 vs A5)
- [ ] Add typst and pandoc to packages if not already present
- [ ] Write the neovim `<leader>E` binding
- [ ] Test end-to-end with a typst physics file
