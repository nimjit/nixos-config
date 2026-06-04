vim.cmd [[colorscheme Ukiyo]]
vim.api.nvim_set_hl(0, "Directory", { link = "Type", underline = true })
vim.api.nvim_set_hl(0, "netrwSymlink", { link = "Type", underline = true })
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

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
vim.o.conceallevel = 2
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
vim.keymap.set("n", "<leader>?", function()
    local lines = {
        "  Key           Action                    ",
        " ─────────────────────────────────────── ",
        "  <leader>?     This help popup           ",
        " ─────────────────────────────────────── ",
        "  Files & Navigation                      ",
        "  <leader>f     Yazi file picker          ",
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
        "  Windows                                 ",
        "  <C-h/j/k/l>   Navigate windows          ",
        "  <C-↑↓←→>      Resize windows            ",
        " ─────────────────────────────────────── ",
        "  q / <Esc>     Close this popup          ",
        " ─────────────────────────────────────── ",
        "  Workflows (shell aliases)               ",
        "  uni-work      Uni Obsidian vault        ",
        "  uni-code      Current coding project    ",
        "  vault-work    Personal vault + Claude   ",
        "  nixos-work    NixOS config + Claude     ",
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
-- Update uni_code_path each course
vim.g.uni_code_path = "/home/thijmen/Documents/BACKUP/Uni/Master/Computational Physics"

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

vim.api.nvim_create_user_command("WorkflowUni", function()
    workflow_open("/home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni", nil)
end, {})

vim.api.nvim_create_user_command("WorkflowCode", function()
    workflow_open(vim.g.uni_code_path, nil)
end, {})

vim.api.nvim_create_user_command("WorkflowVault", function()
    workflow_open("/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure", function()
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

