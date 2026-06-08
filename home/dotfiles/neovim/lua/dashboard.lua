-- dashboard.lua — vault and uni information dashboards
-- Pure Lua, no plugin dependencies.

local M = {}

local VAULT = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure"
local UNI   = "/home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni"

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Parse YAML front matter from a markdown file. Returns a flat key→string table.
local function parse_frontmatter(path)
    local f = io.open(path, "r")
    if not f then return {} end
    local data = {}
    local in_front = false
    local first = true
    for line in f:lines() do
        if line == "---" then
            if first and not in_front then
                in_front = true
                first = false
            elseif in_front then
                break
            end
        elseif in_front then
            local k, v = line:match("^([%w_%-]+):%s*(.*)")
            if k and v ~= "" then
                data[k] = v
            end
        end
        first = false
    end
    f:close()
    return data
end

-- Walk a directory (non-recursive) and return all .md files with their frontmatter.
local function scan_dir(dir)
    local results = {}
    local handle = io.popen('find ' .. vim.fn.shellescape(dir) .. ' -maxdepth 1 -name "*.md" -type f 2>/dev/null')
    if not handle then return results end
    for path in handle:lines() do
        local fm = parse_frontmatter(path)
        fm._path = path
        fm._name = path:match("([^/]+)%.md$") or path
        results[#results + 1] = fm
    end
    handle:close()
    return results
end

-- Parse a date string in either YYYY-MM-DD or DD-MM-YYYY format.
-- Returns {year, month, day} or nil.
local function parse_date(s)
    if not s then return nil end
    s = s:match("^%s*(.-)%s*$") -- trim
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then return { year = tonumber(y), month = tonumber(m), day = tonumber(d) } end
    d, m, y = s:match("^(%d%d)-(%d%d)-(%d%d%d%d)$")
    if y then return { year = tonumber(y), month = tonumber(m), day = tonumber(d) } end
    return nil
end

-- Days from today to a {year,month,day} table. Negative = past.
local function days_from_today(dt)
    if not dt then return nil end
    local now = os.time()
    local target = os.time({ year = dt.year, month = dt.month, day = dt.day, hour = 12 })
    return math.floor((target - now) / 86400)
end

local function ordinal_suffix(n)
    n = n % 100
    if n >= 11 and n <= 13 then return "th" end
    local r = n % 10
    if r == 1 then return "st" elseif r == 2 then return "nd" elseif r == 3 then return "rd" end
    return "th"
end

local MONTHS = { "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" }
local DAYS   = { "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday" }

-- ── Data functions ────────────────────────────────────────────────────────────

function M.birthdays_this_month(people_dir)
    local now = os.date("*t")
    local results = {}
    local files = scan_dir(people_dir)
    for _, fm in ipairs(files) do
        local dt = parse_date(fm.birthday)
        if dt and dt.month == now.month then
            local age = now.year - dt.year
            -- Calculate days offset: birthday this year
            local bday_this_year = os.time({ year = now.year, month = dt.month, day = dt.day, hour = 12 })
            local diff = math.floor((bday_this_year - os.time()) / 86400)
            results[#results + 1] = {
                name   = fm.name or fm._name,
                day    = dt.day,
                month  = dt.month,
                age    = age,
                diff   = diff,
                path   = fm._path,
            }
        end
    end
    table.sort(results, function(a, b) return a.day < b.day end)
    return results
end

-- "completed" field can be: empty/"", "false", "true", "True", a timestamp, etc.
local function is_completed(val)
    if not val or val == "" then return false end
    local lower = val:lower()
    if lower == "false" then return false end
    return true
end

function M.upcoming_deadlines(deadlines_dir)
    local results = {}
    local files = scan_dir(deadlines_dir)
    for _, fm in ipairs(files) do
        if not is_completed(fm.completed) then
            local dt = parse_date(fm.date)
            if dt then
                local diff = days_from_today(dt)
                -- Only show upcoming (today or future)
                if diff and diff >= 0 then
                    local display_name
                    if fm.class and fm.class ~= "" and fm.title and fm.title ~= "" then
                        display_name = fm.class .. " — " .. fm.title
                    else
                        display_name = fm.title or fm._name
                    end
                    results[#results + 1] = {
                        name      = display_name,
                        class     = fm.class or "",
                        date_str  = fm.date or "",
                        time_str  = fm.startTime or "",
                        diff      = diff,
                        path      = fm._path,
                    }
                end
            end
        end
    end
    table.sort(results, function(a, b)
        return (a.diff or 9999) < (b.diff or 9999)
    end)
    return results
end

function M.active_assignments(assignments_dir)
    local results = {}
    local files = scan_dir(assignments_dir)
    for _, fm in ipairs(files) do
        if not is_completed(fm.grade) then
            local dt = parse_date(fm.deadline)
            results[#results + 1] = {
                name      = fm._name,
                class     = fm.class or "",
                atype     = fm.type or "",
                date_str  = fm.deadline or "",
                diff      = dt and days_from_today(dt) or nil,
                path      = fm._path,
            }
        end
    end
    table.sort(results, function(a, b)
        return (a.diff or 9999) < (b.diff or 9999)
    end)
    return results
end

function M.all_classes(classes_dir)
    local results = {}
    local files = scan_dir(classes_dir)
    for _, fm in ipairs(files) do
        results[#results + 1] = {
            name  = fm._name,
            year  = fm.year or "",
            Q     = fm.Q or "",
            code  = fm.code or "",
            path  = fm._path,
        }
    end
    -- Sort by Q then name
    table.sort(results, function(a, b)
        if a.Q == b.Q then return a.name < b.name end
        return (a.Q or "") < (b.Q or "")
    end)
    return results
end

-- Returns the 3 most-recently modified .md files per top-level subfolder,
-- limited to the N most active folders.
function M.recent_projects(vault_dir, n_folders)
    n_folders = n_folders or 3
    local handle = io.popen(
        'find ' .. vim.fn.shellescape(vault_dir) ..
        ' -name "*.md" -not -path "*/.obsidian/*" -not -path "*/Templates/*"' ..
        ' -not -path "*/Attachments/*" -printf "%T@ %p\\n" 2>/dev/null' ..
        ' | sort -rn | head -40'
    )
    if not handle then return {} end

    local by_folder = {}
    local folder_mtime = {}

    for line in handle:lines() do
        local mtime, path = line:match("^(%S+)%s+(.+)$")
        if mtime and path then
            -- folder = immediate subdirectory under vault_dir
            local rel = path:sub(#vault_dir + 2)
            local folder = rel:match("^([^/]+)/") or "root"
            -- skip root-level files (like dashboard itself)
            if folder ~= "root" then
                local mt = tonumber(mtime)
                if not folder_mtime[folder] or mt > folder_mtime[folder] then
                    folder_mtime[folder] = mt
                end
                if not by_folder[folder] then
                    by_folder[folder] = { path = path, name = path:match("([^/]+)%.md$") or path, mtime = mt }
                end
            end
        end
    end
    handle:close()

    -- Sort folders by most-recent activity
    local folders = {}
    for k, mt in pairs(folder_mtime) do
        folders[#folders + 1] = { folder = k, mtime = mt, file = by_folder[k] }
    end
    table.sort(folders, function(a, b) return a.mtime > b.mtime end)

    local results = {}
    for i = 1, math.min(n_folders, #folders) do
        local f = folders[i]
        local diff = math.floor((os.time() - f.mtime) / 86400)
        local age
        if diff == 0 then age = "today"
        elseif diff == 1 then age = "yesterday"
        elseif diff < 7 then age = diff .. " days ago"
        elseif diff < 14 then age = "1 week ago"
        else age = math.floor(diff / 7) .. " weeks ago" end
        results[#results + 1] = {
            folder = f.folder,
            name   = f.file.name,
            path   = f.file.path,
            age    = age,
        }
    end
    return results
end

-- Read lines from Uni MOC between # Planning header and end of file.
function M.read_planning_table(uni_moc_path)
    local f = io.open(uni_moc_path, "r")
    if not f then return { "  (Uni MOC not found)" } end
    local lines = {}
    local in_section = false
    for line in f:lines() do
        if line:match("^# Planning") then
            in_section = true
        elseif in_section then
            -- stop at next # heading
            if line:match("^# ") then break end
            lines[#lines + 1] = line
        end
    end
    f:close()
    -- Trim leading/trailing blank lines
    while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    return lines
end

-- ── Buffer renderer ───────────────────────────────────────────────────────────

-- sections = list of { header = "SECTION", lines = { {text, path?} } }
-- Returns bufnr. Caller is responsible for displaying it.
function M.render_buffer(title, subtitle, sections, footer_keys)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype    = "nofile"
    vim.bo[buf].bufhidden  = "wipe"
    vim.bo[buf].swapfile   = false
    vim.bo[buf].modifiable = true

    local raw_lines = {}   -- text
    local path_map  = {}   -- line_number → path

    local function push(text, path)
        raw_lines[#raw_lines + 1] = text
        if path then path_map[#raw_lines] = path end
    end

    -- Title bar
    local date_str = os.date("%Y-%m-%d  ") .. DAYS[tonumber(os.date("%w")) + 1]
    local pad = math.max(0, 68 - #title - #date_str)
    push(" " .. title .. string.rep(" ", pad) .. date_str)
    push("")

    for _, section in ipairs(sections) do
        push(" " .. section.header)
        if #section.lines == 0 then
            push("   — none —")
        else
            for _, entry in ipairs(section.lines) do
                push(entry.text, entry.path)
            end
        end
        push("")
    end

    -- Footer
    if footer_keys and #footer_keys > 0 then
        push(" " .. table.concat(footer_keys, "   "))
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, raw_lines)
    vim.bo[buf].modifiable = false

    -- <CR> opens the file for the current line
    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local path = path_map[lnum]
        if path then
            vim.cmd("edit " .. vim.fn.fnameescape(path))
        end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf, nowait = true })

    return buf, path_map
end

-- ── Vault dashboard ───────────────────────────────────────────────────────────

function M.open_vault()
    local people_dir     = VAULT .. "/People"
    local vault_snowflake = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.html"

    -- Birthdays
    local bdays = M.birthdays_this_month(people_dir)
    local bday_lines = {}
    for _, b in ipairs(bdays) do
        local when
        if b.diff == 0 then when = "today!"
        elseif b.diff > 0 then when = "in " .. b.diff .. " days"
        else when = math.abs(b.diff) .. " days ago" end
        local text = string.format("   %-28s  %s %2d   (%s, turning %d)",
            b.name, MONTHS[b.month], b.day, when, b.age)
        bday_lines[#bday_lines + 1] = { text = text, path = b.path }
    end

    -- Continue working on
    local projects = M.recent_projects(VAULT, 3)
    local proj_lines = {}
    for _, p in ipairs(projects) do
        local text = string.format("   %-18s  %-30s  %s", p.folder, p.name, p.age)
        proj_lines[#proj_lines + 1] = { text = text, path = p.path }
    end

    -- Recent dailies
    local daily_dir = VAULT .. "/Dailies"
    local handle = io.popen('find ' .. vim.fn.shellescape(daily_dir) ..
        ' -name "*.md" -printf "%T@ %f %p\\n" 2>/dev/null | sort -rn | head -5')
    local daily_lines = {}
    if handle then
        for line in handle:lines() do
            local name, path = line:match("^%S+%s+(%S+)%.md%s+(.+)$")
            if name then
                daily_lines[#daily_lines + 1] = { text = "   " .. name, path = path }
            end
        end
        handle:close()
    end

    -- Knowledge navigator
    local know_dir = VAULT .. "/Knowledge"
    local kh = io.popen('find ' .. vim.fn.shellescape(know_dir) ..
        ' -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort')
    local know_lines = {}
    local know_row = ""
    if kh then
        for dir_path in kh:lines() do
            local folder = dir_path:match("([^/]+)$")
            local count_h = io.popen('find ' .. vim.fn.shellescape(dir_path) .. ' -name "*.md" 2>/dev/null | wc -l')
            local count = count_h and count_h:read("*l") or "?"
            if count_h then count_h:close() end
            count = count and count:match("%d+") or "?"
            local entry = folder .. " (" .. count .. ")"
            if #know_row + #entry + 3 > 68 then
                know_lines[#know_lines + 1] = { text = "   " .. know_row }
                know_row = entry
            else
                know_row = know_row == "" and entry or know_row .. "  " .. entry
            end
        end
        kh:close()
        if know_row ~= "" then
            know_lines[#know_lines + 1] = { text = "   " .. know_row }
        end
    end

    local sections = {
        { header = "BIRTHDAYS THIS MONTH", lines = bday_lines },
        { header = "CONTINUE",             lines = proj_lines },
        { header = "RECENT DAILY NOTES",   lines = daily_lines },
        { header = "KNOWLEDGE",            lines = know_lines },
    }

    local footer = { "[f] browse files", "[g] knowledge graph", "[d] daily note" }

    local buf, _ = M.render_buffer("VAULT", "", sections, footer)

    -- Custom keymaps for vault dashboard
    local function km(k, fn) vim.keymap.set("n", k, fn, { buffer = buf, nowait = true }) end

    km("f", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        local tmp = vim.fn.tempname()
        vim.cmd("cd " .. vim.fn.fnameescape(VAULT))
        vim.cmd("terminal yazi --chooser-file=" .. tmp)
        local term_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd("TermClose", {
            buffer = term_buf, once = true,
            callback = function()
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(term_buf) then
                        vim.api.nvim_buf_delete(term_buf, { force = true })
                    end
                    local fi = io.open(tmp, "r")
                    if fi then
                        local chosen = fi:read("*l"); fi:close(); os.remove(tmp)
                        if chosen and chosen ~= "" then
                            vim.cmd("edit " .. vim.fn.fnameescape(chosen))
                        end
                    end
                end)
            end,
        })
        vim.cmd("startinsert")
    end)

    km("g", function()
        vim.fn.system("xdg-open " .. vim.fn.shellescape(vault_snowflake) .. " &")
    end)

    km("d", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd("DailyNote")
    end)

    return buf
end

-- ── Uni dashboard ─────────────────────────────────────────────────────────────

function M.open_uni()
    local deadlines_dir   = UNI .. "/Deadines"  -- note: folder has typo in vault
    local assignments_dir = UNI .. "/Assignments"
    local classes_dir     = UNI .. "/Classes"
    local uni_moc_path    = UNI .. "/Uni MOC.md"
    local uni_snowflake   = UNI .. "/uni_snowflake.html"

    -- Deadlines
    local deadlines = M.upcoming_deadlines(deadlines_dir)
    local deadline_lines = {}
    for _, d in ipairs(deadlines) do
        local when
        if not d.diff then when = "?"
        elseif d.diff == 0 then when = "TODAY"
        elseif d.diff > 0 then when = "in " .. d.diff .. " days"
        else when = math.abs(d.diff) .. " days ago" end
        local time_part = d.time_str ~= "" and ("  " .. d.time_str) or ""
        local text = string.format("   %-40s  %s%s   (%s)",
            d.name, d.date_str, time_part, when)
        deadline_lines[#deadline_lines + 1] = { text = text, path = d.path }
    end

    -- Active assignments
    local assignments = M.active_assignments(assignments_dir)
    local assign_lines = {}
    for _, a in ipairs(assignments) do
        local when
        if not a.diff then when = "?"
        elseif a.diff == 0 then when = "TODAY"
        elseif a.diff > 0 then when = "in " .. a.diff .. " days"
        else when = math.abs(a.diff) .. " days ago" end
        local text = string.format("   %-35s  %-12s  %s   (%s)",
            a.name, a.atype, a.date_str, when)
        assign_lines[#assign_lines + 1] = { text = text, path = a.path }
    end

    -- Courses
    local classes = M.all_classes(classes_dir)
    local class_lines = {}
    for _, c in ipairs(classes) do
        local text = string.format("   %-40s  Q%-6s  %s", c.name, c.Q, c.code)
        class_lines[#class_lines + 1] = { text = text, path = c.path }
    end

    -- Planning table (raw from Uni MOC)
    local plan_raw = M.read_planning_table(uni_moc_path)
    local plan_lines = {}
    for _, l in ipairs(plan_raw) do
        plan_lines[#plan_lines + 1] = { text = l }
    end

    local sections = {
        { header = "UPCOMING DEADLINES",        lines = deadline_lines },
        { header = "ACTIVE ASSIGNMENTS",         lines = assign_lines },
        { header = "COURSES",                    lines = class_lines },
        { header = "PLANNING (from Uni MOC)",    lines = plan_lines },
    }

    local footer = { "[f] browse files", "[g] uni graph", "[n] new lecture" }

    local buf, _ = M.render_buffer("UNI", "", sections, footer)

    local function km(k, fn) vim.keymap.set("n", k, fn, { buffer = buf, nowait = true }) end

    km("f", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        local tmp = vim.fn.tempname()
        vim.cmd("cd " .. vim.fn.fnameescape(UNI))
        vim.cmd("terminal yazi --chooser-file=" .. tmp)
        local term_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd("TermClose", {
            buffer = term_buf, once = true,
            callback = function()
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(term_buf) then
                        vim.api.nvim_buf_delete(term_buf, { force = true })
                    end
                    local fi = io.open(tmp, "r")
                    if fi then
                        local chosen = fi:read("*l"); fi:close(); os.remove(tmp)
                        if chosen and chosen ~= "" then
                            vim.cmd("edit " .. vim.fn.fnameescape(chosen))
                        end
                    end
                end)
            end,
        })
        vim.cmd("startinsert")
    end)

    km("g", function()
        vim.fn.system("xdg-open " .. vim.fn.shellescape(uni_snowflake) .. " &")
    end)

    km("n", function()
        local class = vim.fn.input("Class name: ")
        if class == "" then return end
        local template = UNI .. "/Templates/Lecture.md"
        local date = os.date("%Y-%m-%d")
        local target = UNI .. "/Lecture/" .. class .. " " .. date .. ".md"
        -- Read template and substitute
        local tf = io.open(template, "r")
        local content = tf and tf:read("*a") or ("# " .. class .. "\n\nDate: " .. date .. "\n\n")
        if tf then tf:close() end
        -- Write new lecture file
        local nf = io.open(target, "w")
        if nf then nf:write(content); nf:close() end
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd("edit " .. vim.fn.fnameescape(target))
    end)

    return buf
end

return M
