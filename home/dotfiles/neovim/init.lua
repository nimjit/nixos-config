vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd [[colorscheme Ukiyo]]
vim.api.nvim_set_hl(0, "Directory", { link = "Type", underline = true })
vim.api.nvim_set_hl(0, "netrwSymlink", { link = "Type", underline = true })
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- ── Colour overrides ─────────────────────────────────────────────────────────
-- Applied after Stylix's base16 colorscheme. Philosophy: grey as the base,
-- gold/orange for structure, soft warm-red for content. No green or cyan.
--
-- Palette (from Ukiyo.lua, consistent with the terminal / kitty theme):
--   fg     #ccc2b7  main text — most identifiers live here
--   dim    #868074  comments, delimiters, secondary
--   gold   #e0ba86  types, headings, links   (base0D)
--   orange #da9517  numbers, constants, operators, preprocessor
--   kw     #ce631c  keywords / control flow  (bold orange-red)
--   str    #da7b5f  strings, italic text     (soft warm red, replaces green)
local function set_color_overrides()
    local fg     = "#ccc2b7"
    local dim    = "#868074"
    local gold   = "#e0ba86"
    local orange = "#da9517"
    local kw     = "#ce631c"
    local str    = "#da7b5f"

    -- ── Traditional vim syntax groups ─────────────────────────────────────
    vim.api.nvim_set_hl(0, "Comment",      { fg = dim,    italic = true })
    vim.api.nvim_set_hl(0, "String",       { fg = str,    italic = true })
    vim.api.nvim_set_hl(0, "Character",    { fg = str,    italic = true })
    vim.api.nvim_set_hl(0, "Number",       { fg = orange })
    vim.api.nvim_set_hl(0, "Float",        { fg = orange })
    vim.api.nvim_set_hl(0, "Boolean",      { fg = orange, bold   = true })
    vim.api.nvim_set_hl(0, "Constant",     { fg = orange })
    vim.api.nvim_set_hl(0, "Identifier",   { fg = fg })
    vim.api.nvim_set_hl(0, "Function",     { fg = fg,     italic = true })
    vim.api.nvim_set_hl(0, "Statement",    { fg = kw,     bold   = true })
    vim.api.nvim_set_hl(0, "Keyword",      { fg = kw,     bold   = true })
    vim.api.nvim_set_hl(0, "Conditional",  { fg = kw,     bold   = true })
    vim.api.nvim_set_hl(0, "Repeat",       { fg = kw,     bold   = true })
    vim.api.nvim_set_hl(0, "Exception",    { fg = str })
    vim.api.nvim_set_hl(0, "Operator",     { fg = fg })
    vim.api.nvim_set_hl(0, "Delimiter",    { fg = dim })
    vim.api.nvim_set_hl(0, "PreProc",      { fg = orange })
    vim.api.nvim_set_hl(0, "Include",      { fg = orange })
    vim.api.nvim_set_hl(0, "Define",       { fg = orange })
    vim.api.nvim_set_hl(0, "Macro",        { fg = orange })
    vim.api.nvim_set_hl(0, "Type",         { fg = gold })
    vim.api.nvim_set_hl(0, "StorageClass", { fg = gold })
    vim.api.nvim_set_hl(0, "Structure",    { fg = gold })
    vim.api.nvim_set_hl(0, "Typedef",      { fg = gold })
    vim.api.nvim_set_hl(0, "Special",      { fg = orange })   -- replaces cyan
    vim.api.nvim_set_hl(0, "SpecialChar",  { fg = str })
    vim.api.nvim_set_hl(0, "Tag",          { fg = gold })
    vim.api.nvim_set_hl(0, "Underlined",   { fg = gold,   underline = true })
    vim.api.nvim_set_hl(0, "htmlItalic",   { fg = str,    italic = true })
    vim.api.nvim_set_hl(0, "htmlBold",     { fg = gold,   bold   = true })

    -- ── Treesitter groups (future-proof; also used by neovim built-ins) ───
    vim.api.nvim_set_hl(0, "@comment",                { fg = dim,    italic = true })
    vim.api.nvim_set_hl(0, "@string",                 { fg = str,    italic = true })
    vim.api.nvim_set_hl(0, "@string.escape",          { fg = str,    italic = true })
    vim.api.nvim_set_hl(0, "@number",                 { fg = orange })
    vim.api.nvim_set_hl(0, "@float",                  { fg = orange })
    vim.api.nvim_set_hl(0, "@boolean",                { fg = orange, bold   = true })
    vim.api.nvim_set_hl(0, "@constant",               { fg = orange })
    vim.api.nvim_set_hl(0, "@constant.builtin",       { fg = orange, bold   = true })
    vim.api.nvim_set_hl(0, "@variable",               { fg = fg })
    vim.api.nvim_set_hl(0, "@variable.builtin",       { fg = fg,     bold = true })
    vim.api.nvim_set_hl(0, "@function",               { fg = fg,     italic = true })
    vim.api.nvim_set_hl(0, "@function.call",          { fg = fg,     italic = true })
    vim.api.nvim_set_hl(0, "@function.builtin",       { fg = gold,   italic = true })
    vim.api.nvim_set_hl(0, "@method",                 { fg = fg,     italic = true })
    vim.api.nvim_set_hl(0, "@method.call",            { fg = fg,     italic = true })
    vim.api.nvim_set_hl(0, "@keyword",                { fg = kw,     bold = true })
    vim.api.nvim_set_hl(0, "@keyword.control",        { fg = kw,     bold = true })
    vim.api.nvim_set_hl(0, "@keyword.import",         { fg = orange })
    vim.api.nvim_set_hl(0, "@keyword.operator",       { fg = kw })
    vim.api.nvim_set_hl(0, "@type",                   { fg = gold })
    vim.api.nvim_set_hl(0, "@type.builtin",           { fg = gold })
    vim.api.nvim_set_hl(0, "@operator",               { fg = fg })
    vim.api.nvim_set_hl(0, "@punctuation.delimiter",  { fg = dim })
    vim.api.nvim_set_hl(0, "@punctuation.bracket",    { fg = dim })
    vim.api.nvim_set_hl(0, "@tag",                    { fg = gold })
    vim.api.nvim_set_hl(0, "@attribute",              { fg = orange })

    -- ── Markdown: vim-syntax groups, html chain, and treesitter ──────────
    -- Italic → str (soft warm red)   Bold → gold   Links → gold underline
    vim.api.nvim_set_hl(0, "markdownItalic",          { fg = str,  italic = true })
    vim.api.nvim_set_hl(0, "markdownBold",            { fg = gold, bold   = true })
    vim.api.nvim_set_hl(0, "markdownBoldItalic",      { fg = gold, bold = true, italic = true })
    vim.api.nvim_set_hl(0, "markdownLinkText",        { fg = gold, underline = true })
    vim.api.nvim_set_hl(0, "markdownUrl",             { fg = gold, underline = true })
    vim.api.nvim_set_hl(0, "markdownLink",            { fg = gold })
    vim.api.nvim_set_hl(0, "markdownIdDeclaration",   { fg = gold })
    vim.api.nvim_set_hl(0, "@markup.italic",          { fg = str,  italic = true })
    vim.api.nvim_set_hl(0, "@markup.strong",          { fg = gold, bold   = true })
    vim.api.nvim_set_hl(0, "@markup.link",            { fg = gold })
    vim.api.nvim_set_hl(0, "@markup.link.label",      { fg = gold })
    vim.api.nvim_set_hl(0, "@markup.link.url",        { fg = gold, underline = true })
    vim.api.nvim_set_hl(0, "@text.emphasis",          { fg = str,  italic = true })
    vim.api.nvim_set_hl(0, "@text.strong",            { fg = gold, bold   = true })
    vim.api.nvim_set_hl(0, "@text.reference",         { fg = gold })
    vim.api.nvim_set_hl(0, "@text.uri",               { fg = gold, underline = true })
end
set_color_overrides()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_color_overrides })
-- Syntax autocmd fires AFTER markdown.vim's `hi def link` commands — the
-- only hook guaranteed to run after the syntax file sets its defaults.
vim.api.nvim_create_autocmd("Syntax", {
    pattern = "markdown",
    callback = set_color_overrides,
})
-- Stylix appends `require('mini.base16').setup({...})` after this file,
-- overwriting all our highlight groups. VimEnter fires after that block
-- runs, giving us the final word on every startup.
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = set_color_overrides,
})

-- image.nvim — inline image rendering via kitty graphics protocol
-- Only active when running inside kitty; silently skipped otherwise.
pcall(function()
    require("image").setup({
        backend = "kitty",
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = true,
                download_remote_images = false,
                only_render_image_at_cursor = true,
                enabled = false,  -- disable auto-render; images shown explicitly via <leader>z
                filetypes = { "markdown" },
            },
        },
        max_height_window_percentage = 40,
        window_overlap_clear_enabled = true,
        editor_only_render_when_focused = true,
    })
end)

                    -- Vim Settings --
                    
-- See `:help vim.o`
-- Set Linenumbers background
vim.o.cursorline = true
vim.o.cursorlineopt = "number,line"
-- Search hl
vim.o.hlsearch = true
vim.o.incsearch = true      -- Show search matches as you type
vim.o.ignorecase = true     -- Ignore case in search...
vim.o.smartcase = true      -- ...unless I use an uppercase letter
-- Numbers
vim.wo.number = true
vim.wo.relativenumber = true
-- Mouse
vim.o.mouse = "a"
-- Indent
vim.o.breakindent = true
vim.o.smartindent = true    -- Insert indents automatically
vim.o.expandtab = true      -- Convert tabs to spaces
vim.o.shiftwidth = 4        -- Size of an indent
vim.o.tabstop = 4           -- Number of spaces tabs count for
-- Backup and Undo
vim.o.undofile = true
-- Performance
vim.wo.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300
vim.o.completeopt = "menuone,noselect"
-- Scroll
vim.o.scrolloff = 8         -- Lines of context above/below cursor
vim.o.sidescrolloff = 8     -- Columns of context left/right of cursor


-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

                    -- Panel Settings --
-- Window resizing
local function smart_resize(vertical, direction)
    local win_num = vim.fn.winnr()
    local delta = 2
    if win_num > 1 then
        direction = -direction
    end
    local command = vertical and "vertical resize " or "resize "
    local sign = direction > 0 and "+" or "-"
    vim.cmd(command .. sign .. delta)
end

-- Keymaps: Ctrl + Arrows
vim.keymap.set('n', '<C-Up>',    function() smart_resize(false, 1) end)
vim.keymap.set('n', '<C-Down>',  function() smart_resize(false, -1) end)
vim.keymap.set('n', '<C-Left>',  function() smart_resize(true, -1) end)
vim.keymap.set('n', '<C-Right>', function() smart_resize(true, 1) end)
-- Window hopping
vim.keymap.set('n','<C-h>', '<C-w>h')
vim.keymap.set('n','<C-j>', '<C-w>j')
vim.keymap.set('n','<C-k>', '<C-w>k')
vim.keymap.set('n','<C-l>', '<C-w>l')
-- Same binds from terminal mode (<C-\><C-n> exits terminal mode first)
vim.keymap.set('t','<C-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set('t','<C-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set('t','<C-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set('t','<C-l>', '<C-\\><C-n><C-w>l')

                   -- Netrw settings --
-- Better symlinks
vim.o.conceallevel = 0
vim.g.netrw_symlink_target = 0 -- This often helps hide the target path
-- Hide dumb files
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+,^NTUSER.*,^ntuser.*,.*\.ini$,anaconda*,OneDrive*,NetHood*,PrintHood*,Recent*,SendTo*,Templates*]]
-- Netrw keymappings
local netrw_mouse_group = vim.api.nvim_create_augroup("NetrwMouse", { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'netrw',
  callback = function()
    local bind = function(lhs, rhs)
      vim.keymap.set('n', lhs, rhs, { remap = false, buffer = true })
    end
    vim.o.mouse = ""
    bind('h', '<plug>NetrwBrowseUpDir')
    bind('l', '<plug>NetrwLocalBrowseCheck')
    bind('<Space>', ':call netrw#BrowseX(netrw#GX(), 0)<cr>', { silent = true, buffer = true })

    bind('<C-h>', '<C-w>h')
    bind('<C-j>', '<C-w>j')
    bind('<C-k>', '<C-w>k')
    bind('<C-l>', '<C-w>l')
  end
})

-- Netrw Globals 
-- vim.g.netrw_liststyle = 3   -- Tree view
-- vim.g.netrw_banner = 0      -- Hide help banner
vim.g.netrw_winsize = 75    -- Sidebar width
vim.g.netrw_browse_split = 2 
vim.o.splitright = true

vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*",
    group = netrw_mouse_group,
    callback = function()
        -- Re-enable mouse when leaving netrw (adjust "a" to your preferred mode)
        if vim.bo.filetype == "netrw" then
            vim.o.mouse = "a"
        end
    end
})

                  -- Python runner
vim.g.python_path = '/run/current-system/sw/bin/python3'

vim.keymap.set("n", "<leader>r", function()
    vim.cmd("w")
    vim.cmd("split | terminal " .. vim.g.python_path .. " '" .. vim.fn.expand("%:p") .. "'")
end)

--"Cell" runner (like notebooks)
-- Define cell marker: # %%
vim.keymap.set("n", "<leader>c", function()
    local py = vim.g.python_path

    local start = vim.fn.search("^# %%", "bnW")
    local stop = vim.fn.search("^# %%", "nW")

    if start == 0 then start = 1 end
    if stop == 0 then stop = vim.fn.line("$") end

    vim.cmd(start .. "," .. stop .. "w !" .. py)
end)

                   -- Quick terminal
vim.keymap.set("n", "<leader>t", ":split | terminal<CR>")

                   -- Yazi file picker
-- Opens yazi in a split; selecting a file (q to confirm) opens it in neovim.
-- Uses --chooser-file so no plugin is needed.
vim.keymap.set("n", "<leader>f", function()
    local tmp = vim.fn.tempname()
    vim.cmd("split | terminal yazi --chooser-file=" .. tmp)
    local term_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd("TermClose", {
        buffer = term_buf,
        once = true,
        callback = function()
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(term_buf) then
                    vim.api.nvim_buf_delete(term_buf, { force = true })
                end
                local f = io.open(tmp, "r")
                if f then
                    local chosen = f:read("*l")
                    f:close()
                    os.remove(tmp)
                    if chosen and chosen ~= "" then
                        vim.cmd("edit " .. vim.fn.fnameescape(chosen))
                    end
                end
            end)
        end,
    })
    vim.cmd("startinsert")
end)

                   -- Hotkey reference
vim.keymap.set("n", "<leader>/", function()
    local lines = {
        "  Key           Action                    ",
        " ─────────────────────────────────────── ",
        "  <Space> = leader key                    ",
        "  <leader>/     This help popup           ",
        " ─────────────────────────────────────── ",
        "  Files & Navigation                      ",
        "  <leader>f     Yazi file picker          ",
        "  <leader>d     Back to dashboard         ",
        "  <leader>s     Search vault              ",
        " ─────────────────────────────────────── ",
        "  Python                                  ",
        "  <leader>r     Run file                  ",
        "  <leader>c     Run cell (# %%)           ",
        " ─────────────────────────────────────── ",
        "  Terminal                                ",
        "  <leader>t     Open terminal split       ",
        " ─────────────────────────────────────── ",
        "  Git                                     ",
        "  <leader>gs    git status                ",
        "  <leader>gd    git diff                  ",
        "  <leader>gp    git pull                  ",
        "  <leader>gP    git push                  ",
        "  <leader>gc    git commit                ",
        "  <leader>gu    git fetch + status        ",
        " ─────────────────────────────────────── ",
        "  Media / External                        ",
        "  <leader>z     Open PDF/image in panel   ",
        "  <leader>m     Music player (rmpc)       ",
        " ─────────────────────────────────────── ",
        "  Typst                                   ",
        "  <leader>tp    Render typst block inline ",
        "  <leader>ta    Render all typst blocks   ",
        " ─────────────────────────────────────── ",
        "  Windows                                 ",
        "  <C-h/j/k/l>   Navigate windows          ",
        "  <C-↑↓←→>      Resize windows            ",
        " ─────────────────────────────────────── ",
        "  q / <Esc>     Close this popup          ",
        " ─────────────────────────────────────── ",
        "  Workflows (shell aliases)               ",
        "  uni-work      Uni dashboard             ",
        "  uni-code      Current coding project    ",
        "  vault-work    Personal vault + Claude   ",
        "  nixos-work    NixOS config + Claude     ",
        "  today         Today's daily note        ",
        "  messages      WhatsApp (nchat)          ",
        "  music         Music player (rmpc)       ",
        "  cal           Calendar (khal)           ",
        "  cap           Quick capture → daily note ",
    }
    local width = 48
    local height = #lines
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
    })
    for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, function()
            vim.api.nvim_win_close(win, true)
        end, { buffer = buf, nowait = true })
    end
end)

                   -- Workflow launchers
local dash = require('dashboard')

-- Update uni_code_path each course
vim.g.uni_code_path = "/home/thijmen/Documents/BACKUP/Uni/Master/Computational Physics"

-- Shared yazi picker used by WorkflowCode and WorkflowNixos
local function workflow_open(path, after)
    vim.cmd("cd " .. vim.fn.fnameescape(path))
    local tmp = vim.fn.tempname()
    vim.cmd("terminal yazi --chooser-file=" .. tmp)
    local term_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd("TermClose", {
        buffer = term_buf,
        once = true,
        callback = function()
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(term_buf) then
                    vim.api.nvim_buf_delete(term_buf, { force = true })
                end
                local f = io.open(tmp, "r")
                if f then
                    local chosen = f:read("*l")
                    f:close()
                    os.remove(tmp)
                    if chosen and chosen ~= "" then
                        vim.cmd("edit " .. vim.fn.fnameescape(chosen))
                    end
                end
                if after then after() end
            end)
        end,
    })
    vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("WorkflowVault", function()
    local buf = dash.open_vault()
    vim.api.nvim_set_current_buf(buf)
    vim.cmd("cd /home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure")
    -- Claude session in a right split
    vim.cmd("vsplit | terminal claude --continue")
    vim.cmd("1wincmd w")
end, {})

vim.api.nvim_create_user_command("WorkflowUni", function()
    local buf = dash.open_uni()
    vim.api.nvim_set_current_buf(buf)
    vim.cmd("cd /home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni")
end, {})

vim.api.nvim_create_user_command("WorkflowCode", function()
    workflow_open(vim.g.uni_code_path, function()
        vim.cmd("vsplit | terminal claude --continue")
        vim.cmd("1wincmd w")
    end)
end, {})

vim.api.nvim_create_user_command("WorkflowNixos", function()
    workflow_open("/etc/nixos", function()
        vim.cmd("vsplit | terminal claude --continue")
        vim.cmd("vsplit | terminal")
        vim.cmd("1wincmd w")
    end)
end, {})

-- Re-open the appropriate dashboard from any file; detects CWD.
vim.api.nvim_create_user_command("Dashboard", function()
    local cwd = vim.fn.getcwd()
    local buf
    if cwd:find("Uni/Obsidian/Uni", 1, true) or cwd:find("Uni/Master", 1, true) then
        buf = dash.open_uni()
    else
        buf = dash.open_vault()
    end
    vim.api.nvim_set_current_buf(buf)
end, {})

vim.keymap.set("n", "<leader>d", "<cmd>Dashboard<CR>", { silent = true })
vim.keymap.set("n", "<leader>s", function() dash.vault_search(nil) end, { silent = true })

                   -- Daily note + weight
local VAULT_DAILIES = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/Dailies"

vim.api.nvim_create_user_command("DailyNote", function()
    local date = os.date("%Y-%m-%d")
    local path = VAULT_DAILIES .. "/" .. date .. ".md"
    if vim.fn.filereadable(path) == 0 then
        local f = io.open(path, "w")
        if f then
            -- No weight section here — log weight with :LogWeight or [w] in vault dashboard
            f:write("# " .. date .. "\n\n## Today\n\n## Italian\n\n## Notes\n")
            f:close()
        end
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end, {})

vim.api.nvim_create_user_command("LogWeight", function(opts)
    local weight = opts.args ~= "" and opts.args or vim.fn.input("Weight (kg): ")
    if weight ~= "" then dash.log_weight(weight) end
end, { nargs = "?" })

                   -- Typst inline rendering (<leader>tp = current block, <leader>ta = all blocks)
-- Compiles ```typ blocks and renders them inline via image.nvim (kitty graphics).
-- Falls back to a split preview if image.nvim is not available.

-- Typst preamble: Ukiyo dark background + text color so rendered images match the terminal theme.
local TYPST_PRE = table.concat({
    '#set page(width: auto, height: auto, margin: 6pt, fill: rgb("#372d29"))',
    '#set text(fill: rgb("#ccc2b7"), font: "JetBrainsMono Nerd Font Mono", size: 11pt)',
    "",
}, "\n")

-- Compiles a math expression (LaTeX $...$ or $$...$$) via typst, returns PNG path or nil.
local function compile_math_block(content, id)
    local src = "/tmp/nvim_typst_math_" .. id .. ".typ"
    local img = "/tmp/nvim_typst_math_" .. id .. ".png"
    local f = io.open(src, "w")
    if f then
        f:write(TYPST_PRE .. "$ " .. content .. " $\n")
        f:close()
    end
    vim.fn.system("typst compile --ppi 200 " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(img) .. " 2>&1")
    return vim.v.shell_error == 0 and img or nil
end

local function compile_typst_block(lines, start_line, end_line)
    local block = {}
    for i = start_line + 1, end_line - 1 do block[#block + 1] = lines[i] end
    local id    = tostring(start_line)
    local src   = "/tmp/nvim_typst_" .. id .. ".typ"
    local img   = "/tmp/nvim_typst_" .. id .. ".png"
    local f = io.open(src, "w")
    if f then f:write(TYPST_PRE .. table.concat(block, "\n")); f:close() end
    local out = vim.fn.system("typst compile --ppi 200 " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(img) .. " 2>&1")
    return vim.v.shell_error == 0 and img or nil, out
end

local function render_typst_inline(buf, win, img_path, after_line)
    local ok, image = pcall(require, "image")
    if ok then
        local img = image.from_file(img_path, {
            id     = "typst_" .. after_line,
            buffer = buf,
            window = win,
            with_virtual_padding = true,
        })
        img:render({ x = 0, y = after_line })
    else
        -- Fallback: split preview
        vim.cmd("vsplit | terminal kitten icat " .. vim.fn.shellescape(img_path) ..
            " ; read -r -p 'press enter to close'")
    end
end

vim.keymap.set("n", "<leader>tp", function()
    local buf   = vim.api.nvim_get_current_buf()
    local win   = vim.api.nvim_get_current_win()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor = vim.api.nvim_win_get_cursor(win)[1]

    -- If it's a .typ file, compile the whole file
    if vim.bo.filetype == "typst" or vim.fn.expand("%:e") == "typ" then
        local src = vim.fn.expand("%:p")
        local img = "/tmp/nvim_typst_file.png"
        vim.fn.system("typst compile " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(img))
        render_typst_inline(buf, win, img, cursor)
        return
    end

    -- Find enclosing ```typ ... ``` block
    local start_line, end_line
    for i = cursor, 1, -1 do
        if lines[i] and lines[i]:match("^```typ") then start_line = i; break end
    end
    for i = (start_line or cursor), #lines do
        if lines[i] and lines[i]:match("^```$") and i > (start_line or 0) then end_line = i; break end
    end

    if start_line and end_line then
        local img, err = compile_typst_block(lines, start_line, end_line)
        if not img then vim.notify("Typst error:\n" .. (err or ""), vim.log.levels.ERROR); return end
        render_typst_inline(buf, win, img, end_line)
        return
    end

    -- Check for $$ display math block around cursor
    local dstart, dend
    for i = cursor, 1, -1 do
        if lines[i] and lines[i]:match("^%s*%$%$$") then dstart = i; break end
    end
    if dstart then
        for i = dstart + 1, #lines do
            if lines[i] and lines[i]:match("^%s*%$%$$") then dend = i; break end
        end
    end
    if dstart and dend then
        local parts = {}
        for i = dstart + 1, dend - 1 do parts[#parts + 1] = lines[i] end
        local img = compile_math_block(table.concat(parts, " "), tostring(dstart))
        if img then render_typst_inline(buf, win, img, dend)
        else vim.notify("Math compile error", vim.log.levels.ERROR) end
        return
    end

    -- Check for $...$ inline math on current line
    local inline = (lines[cursor] or ""):match("%$([^$]+)%$")
    if inline then
        local img = compile_math_block(inline, tostring(cursor))
        if img then render_typst_inline(buf, win, img, cursor)
        else vim.notify("Math compile error", vim.log.levels.ERROR) end
        return
    end

    vim.notify("Not inside a ```typ, $$ or $...$ block", vim.log.levels.WARN)
end)

-- Render ALL typst blocks in the current buffer
vim.keymap.set("n", "<leader>ta", function()
    local buf   = vim.api.nvim_get_current_buf()
    local win   = vim.api.nvim_get_current_win()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local start_line = nil
    local count = 0
    for i, line in ipairs(lines) do
        if line:match("^```typ") then
            start_line = i
        elseif start_line and line:match("^```$") then
            local img, err = compile_typst_block(lines, start_line, i)
            if img then
                render_typst_inline(buf, win, img, i)
                count = count + 1
            else
                vim.notify("Block at line " .. start_line .. " failed:\n" .. (err or ""), vim.log.levels.WARN)
            end
            start_line = nil
        end
    end
    -- Also render $$ display math blocks
    local dstart = nil
    for i, line in ipairs(lines) do
        if line:match("^%s*%$%$$") then
            if not dstart then
                dstart = i
            else
                local parts = {}
                for j = dstart + 1, i - 1 do parts[#parts + 1] = lines[j] end
                local img = compile_math_block(table.concat(parts, " "), tostring(dstart))
                if img then
                    render_typst_inline(buf, win, img, i)
                    count = count + 1
                end
                dstart = nil
            end
        end
    end

    if count > 0 then vim.notify("Rendered " .. count .. " typst block(s)", vim.log.levels.INFO) end
end)


                   -- PDF / image viewer (<leader>z)
-- Opens a kitty vsplit panel (real kitty window, not neovim terminal) so that
-- kitten icat can use the kitty graphics protocol without the pixel-query
-- limitation that breaks image rendering inside neovim :terminal buffers.
-- Requires allow_remote_control + listen_on in kitty.conf (already set).
-- Keys inside the PDF split: n/l next  p/h prev  :N goto  q quit
local function open_pdf_split(pdf_path)
    local script = string.format([[
#!/usr/bin/env bash
PDF=%s
PAGE=1
TOTAL=$(pdfinfo "$PDF" 2>/dev/null | awk '/Pages:/ {print $2}')
[ -z "$TOTAL" ] && TOTAL=999

CACHE=$(mktemp -d /tmp/nvim_pdf_XXXXXX)
trap 'kill "$BGPID" 2>/dev/null; rm -rf "$CACHE"' EXIT

prerender() {
    local p
    for p in $(seq 1 "$TOTAL"); do
        [ -f "$CACHE/$p.png" ] || pdftoppm -r 110 -f "$p" -l "$p" -singlefile -png "$PDF" "$CACHE/$p"
    done
}

# Render page 1 now so display is immediate; background renders the rest
pdftoppm -r 110 -f 1 -l 1 -singlefile -png "$PDF" "$CACHE/1"
prerender &
BGPID=$!

show_page() {
    clear
    local waited=0
    while [ ! -f "$CACHE/$PAGE.png" ] && [ "$waited" -lt 20 ]; do
        sleep 0.1; waited=$((waited+1))
    done
    [ -f "$CACHE/$PAGE.png" ] \
        && kitten icat --clear "$CACHE/$PAGE.png" \
        || echo "  (page $PAGE not yet rendered)"
    printf "\n  Page %%d/%%s   [h/p] prev  [l/n] next  [:N] goto  [q] quit\n" "$PAGE" "$TOTAL"
}

show_page
while IFS= read -rsn1 KEY; do
    case "$KEY" in
        n|l) [ "$PAGE" -lt "$TOTAL" ] && PAGE=$((PAGE+1)) && show_page ;;
        p|h) [ "$PAGE" -gt 1 ] && PAGE=$((PAGE-1)) && show_page ;;
        q)   clear; break ;;
        :)   printf "  Goto page: "; read -r N
             echo "$N" | grep -qE "^[0-9]+$" && [ "$N" -ge 1 ] && [ "$N" -le "$TOTAL" ] \
               && PAGE=$N && show_page ;;
    esac
done
]], vim.fn.shellescape(pdf_path))

    local sf = "/tmp/nvim_pdfview.sh"
    local f = io.open(sf, "w")
    if f then f:write(script); f:close() end
    vim.fn.system("chmod +x " .. sf)
    vim.fn.system("kitty @ launch --type=window --location=vsplit --title pdf-preview bash " .. sf)
end

local IMG_EXTS = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "PNG", "JPG", "JPEG" }
local function is_image(name)
    for _, ext in ipairs(IMG_EXTS) do
        if name:lower():match("%." .. ext:lower() .. "$") then return true end
    end
    return false
end

local function open_image_split(img_path)
    local cmd = string.format(
        "kitty @ launch --type=window --location=vsplit --title img-preview" ..
        " bash -c %s",
        vim.fn.shellescape(
            "kitten icat --clear " .. vim.fn.shellescape(img_path) ..
            "; read -r -n1 -p '  [any key] close '"
        )
    )
    vim.fn.system(cmd)
end

vim.keymap.set("n", "<leader>z", function()
    local line = vim.api.nvim_get_current_line()
    local vault = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure"
    local uni   = "/home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni"

    -- Obsidian wiki link: ![[name]] or ![[name.ext]]
    local wiki = line:match("!?%[%[(.-)%]%]")
    if wiki then
        local function try_candidates(stem, exts)
            local dirs = { vault .. "/Attachments/", uni .. "/Attachments/", vim.fn.expand("%:h") .. "/" }
            for _, dir in ipairs(dirs) do
                for _, ext in ipairs(exts) do
                    local p = dir .. stem .. (ext ~= "" and ("." .. ext) or "")
                    if vim.fn.filereadable(p) == 1 then return p end
                end
            end
        end
        if wiki:match("%.pdf$") or wiki:match("%.PDF$") then
            local p = try_candidates(wiki:gsub("%.pdf$", ""):gsub("%.PDF$", ""), { "pdf", "PDF" })
                   or try_candidates(wiki, { "" })
            if p then open_pdf_split(p); return end
            vim.notify("PDF not found: " .. wiki, vim.log.levels.WARN); return
        end
        if is_image(wiki) then
            local p = try_candidates(wiki:match("(.+)%.[^.]+$") or wiki, { wiki:match("%.([^.]+)$") or "" })
                   or try_candidates(wiki, { "" })
            if p then open_image_split(p); return end
            vim.notify("Image not found: " .. wiki, vim.log.levels.WARN); return
        end
    end

    -- Standard markdown image: ![alt](path)
    local md_img = line:match("!%[.-%]%((.-)%)")
    if md_img and is_image(md_img) then
        local p = vim.fn.fnamemodify(vim.fn.expand("%:h") .. "/" .. md_img, ":p")
        if vim.fn.filereadable(p) == 1 then open_image_split(p); return end
        vim.notify("Image not found: " .. md_img, vim.log.levels.WARN); return
    end

    -- Fallback: prompt for a file path
    local path = vim.fn.input("File path: ", vim.fn.expand("%:h") .. "/", "file")
    if path == "" then return end
    if is_image(path) then open_image_split(path)
    else open_pdf_split(path) end
end)

                   -- Music split (<leader>m)
-- Opens rmpc in a narrow right split. If MPD queue is empty, queues the full
-- library shuffled and starts playback so something is always playing.
vim.keymap.set("n", "<leader>m", function()
    vim.fn.system(
        "mpc playlist | grep -q . || (mpc add / && mpc shuffle && mpc play) &"
    )
    vim.cmd("vsplit | terminal rmpc")
    vim.cmd("vertical resize 55")
    vim.cmd("startinsert")
end)

                   -- Git shortcuts
vim.keymap.set("n", "<leader>gs", ":!git status<CR>")
vim.keymap.set("n", "<leader>gd", ":!git diff<CR>")
vim.keymap.set("n", "<leader>gp", ":!git pull<CR>")
vim.keymap.set("n", "<leader>gP", ":!git push<CR>")
vim.keymap.set("n", "<leader>gc", ":!git commit<CR>")

-- Git "are we outdated?"
vim.keymap.set("n", "<leader>gu", function()
    vim.cmd("!git fetch")
    vim.cmd("!git status")
end)

