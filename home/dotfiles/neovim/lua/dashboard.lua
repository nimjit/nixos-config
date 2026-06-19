-- dashboard.lua — vault and uni information dashboards
-- Pure Lua, no plugin dependencies.

local M = {}

local VAULT       = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure"
local UNI         = "/home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni"
local WEIGHTS_FILE = VAULT .. "/Knowledge/Body & Movement/Bodybuilding/Stats/Weights list.md"

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function parse_frontmatter(path)
    local f = io.open(path, "r")
    if not f then return {} end
    local data = {}
    local in_front = false
    local first = true
    for line in f:lines() do
        if line == "---" then
            if first and not in_front then in_front = true; first = false
            elseif in_front then break end
        elseif in_front then
            local k, v = line:match("^([%w_%-]+):%s*(.*)")
            if k and v ~= "" then data[k] = v end
        end
        first = false
    end
    f:close()
    return data
end

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

local function parse_date(s)
    if not s then return nil end
    s = s:match("^%s*(.-)%s*$")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then return { year = tonumber(y), month = tonumber(m), day = tonumber(d) } end
    d, m, y = s:match("^(%d%d)-(%d%d)-(%d%d%d%d)$")
    if y then return { year = tonumber(y), month = tonumber(m), day = tonumber(d) } end
    return nil
end

local function days_from_today(dt)
    if not dt then return nil end
    local target = os.time({ year = dt.year, month = dt.month, day = dt.day, hour = 12 })
    return math.floor((target - os.time()) / 86400)
end

local function is_completed(val)
    if not val or val == "" then return false end
    if val:lower() == "false" then return false end
    return true
end

local MONTHS = { "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" }
local DAYS   = { "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday" }

-- ── Table renderer ────────────────────────────────────────────────────────────
-- Converts markdown pipe tables to unicode box-drawing chars with aligned columns.
function M.render_md_table(lines)
    if not lines or #lines == 0 then return lines end

    local has_table = false
    for _, l in ipairs(lines) do
        if l:match("^%s*|") then has_table = true; break end
    end
    if not has_table then return lines end

    local function is_sep(line) return line:match("^%s*|%s*[-:]+%s*|") ~= nil end

    local function split_cells(line)
        local cells = {}
        for cell in line:gmatch("|([^|]*)") do
            cells[#cells + 1] = cell:match("^%s*(.-)%s*$")
        end
        while #cells > 0 and cells[#cells] == "" do table.remove(cells) end
        return cells
    end

    -- Measure column widths from data rows
    local col_widths = {}
    for _, line in ipairs(lines) do
        if line:match("^%s*|") and not is_sep(line) then
            for i, cell in ipairs(split_cells(line)) do
                local w = #cell
                if not col_widths[i] or w > col_widths[i] then col_widths[i] = w end
            end
        end
    end

    local ncols = #col_widths
    if ncols == 0 then return lines end

    local result = {}
    for _, line in ipairs(lines) do
        if is_sep(line) then
            local parts = {}
            for i = 1, ncols do parts[#parts + 1] = string.rep("─", (col_widths[i] or 1) + 2) end
            result[#result + 1] = "├" .. table.concat(parts, "┼") .. "┤"
        elseif line:match("^%s*|") then
            local cells = split_cells(line)
            local parts = {}
            for i = 1, ncols do
                local cell = cells[i] or ""
                parts[#parts + 1] = " " .. cell .. string.rep(" ", (col_widths[i] or #cell) - #cell + 1)
            end
            result[#result + 1] = "│" .. table.concat(parts, "│") .. "│"
        else
            result[#result + 1] = line
        end
    end
    return result
end

-- ── Data functions ────────────────────────────────────────────────────────────

function M.birthdays_this_month(people_dir)
    local now = os.date("*t")
    local results = {}
    local files = scan_dir(people_dir)
    for _, fm in ipairs(files) do
        local dt = parse_date(fm.birthday)
        if dt and dt.month == now.month then
            local age = now.year - dt.year
            local bday_this_year = os.time({ year = now.year, month = dt.month, day = dt.day, hour = 12 })
            local diff = math.floor((bday_this_year - os.time()) / 86400)
            results[#results + 1] = {
                name  = fm.name or fm._name,
                day   = dt.day,
                month = dt.month,
                age   = age,
                diff  = diff,
                path  = fm._path,
            }
        end
    end
    table.sort(results, function(a, b) return a.day < b.day end)
    return results
end

function M.upcoming_deadlines(deadlines_dir)
    local results = {}
    local files = scan_dir(deadlines_dir)
    for _, fm in ipairs(files) do
        if not is_completed(fm.completed) then
            local dt = parse_date(fm.date)
            if dt then
                local diff = days_from_today(dt)
                if diff and diff >= 0 then
                    local display_name
                    if fm.class and fm.class ~= "" and fm.title and fm.title ~= "" then
                        display_name = fm.class .. " — " .. fm.title
                    else
                        display_name = fm.title or fm._name
                    end
                    results[#results + 1] = {
                        name     = display_name,
                        class    = fm.class or "",
                        date_str = fm.date or "",
                        time_str = fm.startTime or "",
                        diff     = diff,
                        path     = fm._path,
                    }
                end
            end
        end
    end
    table.sort(results, function(a, b) return (a.diff or 9999) < (b.diff or 9999) end)
    return results
end

function M.active_assignments(assignments_dir)
    local results = {}
    local files = scan_dir(assignments_dir)
    for _, fm in ipairs(files) do
        if not is_completed(fm.grade) then
            local dt = parse_date(fm.deadline)
            results[#results + 1] = {
                name     = fm._name,
                class    = fm.class or "",
                atype    = fm.type or "",
                date_str = fm.deadline or "",
                diff     = dt and days_from_today(dt) or nil,
                path     = fm._path,
            }
        end
    end
    table.sort(results, function(a, b) return (a.diff or 9999) < (b.diff or 9999) end)
    return results
end

function M.all_classes(classes_dir)
    local results = {}
    local files = scan_dir(classes_dir)
    for _, fm in ipairs(files) do
        results[#results + 1] = {
            name      = fm._name,
            year      = fm.year or "",
            Q         = fm.Q or "",
            code      = fm.code or "",
            shorthand = fm.shorthand or fm._name,
            path      = fm._path,
        }
    end
    table.sort(results, function(a, b)
        if a.Q == b.Q then return a.name < b.name end
        return (a.Q or "") < (b.Q or "")
    end)
    return results
end

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
            local rel = path:sub(#vault_dir + 2)
            local folder = rel:match("^([^/]+)/") or "root"
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

function M.read_planning_table(uni_moc_path)
    local f = io.open(uni_moc_path, "r")
    if not f then return { "  (Uni MOC not found)" } end
    local lines = {}
    local in_section = false
    for line in f:lines() do
        if line:match("^# Planning") then
            in_section = true
        elseif in_section then
            if line:match("^# ") then break end
            lines[#lines + 1] = line
        end
    end
    f:close()
    while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    return M.render_md_table(lines)
end

-- ── Weight logging ────────────────────────────────────────────────────────────

function M.log_weight(weight_str)
    local new_weight = tonumber(weight_str)
    if not new_weight then
        vim.notify("Invalid weight: " .. tostring(weight_str), vim.log.levels.ERROR)
        return
    end

    local f = io.open(WEIGHTS_FILE, "r")
    if not f then
        vim.notify("Weights file not found:\n" .. WEIGHTS_FILE, vim.log.levels.ERROR)
        return
    end
    local content = f:read("*a")
    f:close()

    -- Parse existing date/weight pairs
    local history = {}
    for line in content:gmatch("[^\n]+") do
        local cells = {}
        for cell in line:gmatch("|([^|]+)") do
            cells[#cells + 1] = cell:match("^%s*(.-)%s*$")
        end
        if #cells >= 2 then
            local dt = parse_date(cells[1])
            local w  = tonumber(cells[2])
            if dt and w then
                history[#history + 1] = {
                    ts     = os.time({ year = dt.year, month = dt.month, day = dt.day, hour = 12 }),
                    weight = w,
                }
            end
        end
    end

    local today_ts = os.time()

    -- Add today's entry for MA calculation
    history[#history + 1] = { ts = today_ts, weight = new_weight }

    local function moving_avg(days)
        local cutoff = today_ts - days * 86400
        local sum, n = 0, 0
        for _, e in ipairs(history) do
            if e.ts >= cutoff then sum = sum + e.weight; n = n + 1 end
        end
        return n > 0 and string.format("%.2f", sum / n) or "0.00"
    end

    local date_str = os.date("%Y-%m-%d")
    local new_row = string.format("| %s | %s | %s | %s | %s |",
        date_str, tostring(new_weight), moving_avg(7), moving_avg(21), moving_avg(30))

    local new_content = content:gsub("%s*$", "") .. "\n" .. new_row .. "\n"
    local wf = io.open(WEIGHTS_FILE, "w")
    if not wf then
        vim.notify("Cannot write to weights file", vim.log.levels.ERROR)
        return
    end
    wf:write(new_content)
    wf:close()

    vim.notify("Weight logged: " .. tostring(new_weight) .. " kg  (" .. date_str .. ")", vim.log.levels.INFO)
end

-- ── Buffer renderer ───────────────────────────────────────────────────────────

-- sections = list of { header, lines = { {text, path?, callback?} } }
-- Lines with a path get "→" prefix and <CR> edits the file.
-- Lines with a callback get "→" prefix and <CR> calls the callback instead.
function M.render_buffer(title, sections, footer_keys)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype    = "nofile"
    vim.bo[buf].bufhidden  = "wipe"
    vim.bo[buf].swapfile   = false
    vim.bo[buf].modifiable = true

    local raw_lines    = {}
    local path_map     = {}
    local callback_map = {}

    local function push(text, path, callback)
        raw_lines[#raw_lines + 1] = text
        if path     then path_map[#raw_lines]     = path     end
        if callback then callback_map[#raw_lines] = callback end
    end

    -- Title bar
    local date_str = os.date("%Y-%m-%d") .. "  " .. DAYS[tonumber(os.date("%w")) + 1]
    push("# " .. title .. "  ·  " .. date_str)
    push("")

    for _, section in ipairs(sections) do
        push("## " .. section.header)
        if #section.lines == 0 then
            push("  — none —")
        else
            for _, entry in ipairs(section.lines) do
                local interactive = entry.path or entry.callback
                local prefix = interactive and "- → " or "- "
                push(prefix .. entry.text, entry.path, entry.callback)
            end
        end
        push("")
    end

    if footer_keys and #footer_keys > 0 then
        push("---")
        push("*" .. table.concat(footer_keys, "   ") .. "*")
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, raw_lines)
    vim.bo[buf].filetype   = "markdown"
    vim.bo[buf].modifiable = false

    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local cb = callback_map[lnum]
        if cb then cb(); return end
        local path = path_map[lnum]
        if path then vim.cmd("edit " .. vim.fn.fnameescape(path)) end
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf, nowait = true })

    return buf, path_map
end

-- ── Weight chart (inline via image.nvim) ─────────────────────────────────────

local function show_weight_chart(buf)
    local script = vim.fn.expand("~/.local/bin/plot-weights")
    local cols   = math.max(vim.o.columns - 6, 60)
    local out    = {}
    vim.fn.jobstart({ script, "--cols", tostring(cols) }, {
        stdout_buffered = true,
        on_stdout = function(_, data) out = data end,
        on_exit = function(_, code)
            if code ~= 0 then return end
            local png = vim.trim(table.concat(out, "\n"))
            if png == "" then return end
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                local wins = vim.fn.win_findbuf(buf)
                if #wins == 0 then return end
                local win = wins[1]

                -- Find existing ## WEIGHT line or append one
                local img_row  -- 0-indexed buffer row where image renders
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                for i, l in ipairs(lines) do
                    if l == "## WEIGHT" then
                        img_row = i  -- 0-indexed: header is at i-1, canvas line at i
                        break
                    end
                end
                if not img_row then
                    local n = #lines
                    vim.bo[buf].modifiable = true
                    vim.api.nvim_buf_set_lines(buf, n, n, false, { "", "## WEIGHT", "" })
                    vim.bo[buf].modifiable = false
                    img_row = n + 2  -- 0-indexed canvas line after header
                end

                local ok, image_api = pcall(require, "image")
                if not ok then return end
                local img = image_api.from_file(png, {
                    id                   = "weight_chart",
                    buffer               = buf,
                    window               = win,
                    with_virtual_padding = true,
                })
                img:render({ x = 0, y = img_row })
            end)
        end,
    })
end

-- ── Yazi picker (shared) ──────────────────────────────────────────────────────

local function open_yazi(dir)
    local tmp = vim.fn.tempname()
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
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
end

-- ── Vault dashboard ───────────────────────────────────────────────────────────

function M.open_vault()
    local vault_snowflake = "/home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/vault_snowflake.html"

    -- Birthdays
    local bdays = M.birthdays_this_month(VAULT .. "/People")
    local bday_lines = {}
    for _, b in ipairs(bdays) do
        local when
        if b.diff == 0 then when = "today!"
        elseif b.diff > 0 then when = "in " .. b.diff .. " days"
        else when = math.abs(b.diff) .. " days ago" end
        local text = string.format("%-28s  %s %2d   (%s, turning %d)",
            b.name, MONTHS[b.month], b.day, when, b.age)
        bday_lines[#bday_lines + 1] = { text = text, path = b.path }
    end

    -- Continue
    local projects = M.recent_projects(VAULT, 3)
    local proj_lines = {}
    for _, p in ipairs(projects) do
        local text = string.format("%-18s  %-32s  %s", p.folder, p.name, p.age)
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
            if name then daily_lines[#daily_lines + 1] = { text = name, path = path } end
        end
        handle:close()
    end

    -- Knowledge navigator
    local kh = io.popen('find ' .. vim.fn.shellescape(VAULT .. "/Knowledge") ..
        ' -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort')
    local know_lines = {}
    local know_row = ""
    if kh then
        for dir_path in kh:lines() do
            local folder = dir_path:match("([^/]+)$")
            local ch = io.popen('find ' .. vim.fn.shellescape(dir_path) .. ' -name "*.md" 2>/dev/null | wc -l')
            local count = ch and ch:read("*l") or "?"
            if ch then ch:close() end
            count = count and count:match("%d+") or "?"
            local entry = folder .. " (" .. count .. ")"
            if #know_row + #entry + 3 > 68 then
                know_lines[#know_lines + 1] = { text = know_row }
                know_row = entry
            else
                know_row = know_row == "" and entry or know_row .. "  " .. entry
            end
        end
        kh:close()
        if know_row ~= "" then know_lines[#know_lines + 1] = { text = know_row } end
    end

    local sections = {
        { header = "BIRTHDAYS THIS MONTH", lines = bday_lines },
        { header = "CONTINUE",             lines = proj_lines },
        { header = "RECENT DAILY NOTES",   lines = daily_lines },
        { header = "KNOWLEDGE",            lines = know_lines },
    }

    local footer = { "[f] browse", "[g] knowledge graph", "[d] daily note", "[w] log weight" }
    local buf, _ = M.render_buffer("VAULT", sections, footer)
    show_weight_chart(buf)

    local function km(k, fn) vim.keymap.set("n", k, fn, { buffer = buf, nowait = true }) end

    km("f", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        open_yazi(VAULT)
    end)

    km("g", function()
        vim.fn.system("firefox --new-tab " .. vim.fn.shellescape(vault_snowflake) .. " &")
    end)

    km("d", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd("DailyNote")
    end)

    km("w", function()
        local weight = vim.fn.input("Weight (kg): ")
        if weight ~= "" then
            M.log_weight(weight)
            show_weight_chart(buf)
        end
    end)

    return buf
end

-- ── Uni dashboard ─────────────────────────────────────────────────────────────

function M.open_uni()
    local uni_snowflake = UNI .. "/uni_snowflake.html"
    local uni_moc_path  = UNI .. "/Uni MOC.md"

    local deadlines   = M.upcoming_deadlines(UNI .. "/Deadines")
    local deadline_lines = {}
    for _, d in ipairs(deadlines) do
        local when = d.diff == 0 and "TODAY" or "in " .. d.diff .. " days"
        local time_part = d.time_str ~= "" and ("  " .. d.time_str) or ""
        local text = string.format("%-44s  %s%s   (%s)",
            d.name, d.date_str, time_part, when)
        deadline_lines[#deadline_lines + 1] = { text = text, path = d.path }
    end

    local assignments = M.active_assignments(UNI .. "/Assignments")
    local assign_lines = {}
    for _, a in ipairs(assignments) do
        local when
        if not a.diff then when = "?"
        elseif a.diff == 0 then when = "TODAY"
        elseif a.diff > 0 then when = "in " .. a.diff .. " days"
        else when = math.abs(a.diff) .. "d ago" end
        local text = string.format("%-35s  %-14s  %s   (%s)",
            a.name, a.atype, a.date_str, when)
        assign_lines[#assign_lines + 1] = { text = text, path = a.path }
    end

    local classes = M.all_classes(UNI .. "/Classes")
    local class_lines = {}
    for _, c in ipairs(classes) do
        local text = string.format("%-40s  Q%-8s  %s", c.name, c.Q, c.code)
        local course = c
        class_lines[#class_lines + 1] = { text = text, callback = function() M.course_view(course) end }
    end

    local plan_raw = M.read_planning_table(uni_moc_path)
    local plan_lines = {}
    for _, l in ipairs(plan_raw) do plan_lines[#plan_lines + 1] = { text = l } end

    local sections = {
        { header = "UPCOMING DEADLINES",      lines = deadline_lines },
        { header = "ACTIVE ASSIGNMENTS",       lines = assign_lines },
        { header = "COURSES",                  lines = class_lines },
        { header = "PLANNING (from Uni MOC)",  lines = plan_lines },
    }

    local footer = { "[f] browse", "[g] uni graph", "[n] new lecture" }
    local buf, _ = M.render_buffer("UNI", sections, footer)

    local function km(k, fn) vim.keymap.set("n", k, fn, { buffer = buf, nowait = true }) end

    km("f", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        open_yazi(UNI)
    end)

    km("g", function()
        vim.fn.system("firefox --new-tab " .. vim.fn.shellescape(uni_snowflake) .. " &")
    end)

    km("n", function()
        local class = vim.fn.input("Class name: ")
        if class == "" then return end
        local template = UNI .. "/Templates/Lecture.md"
        local date = os.date("%Y-%m-%d")
        local target = UNI .. "/Lecture/" .. class .. " " .. date .. ".md"
        local tf = io.open(template, "r")
        local content = tf and tf:read("*a") or ("# " .. class .. "\n\nDate: " .. date .. "\n\n")
        if tf then tf:close() end
        local nf = io.open(target, "w")
        if nf then nf:write(content); nf:close() end
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd("edit " .. vim.fn.fnameescape(target))
    end)

    return buf
end

-- ── Course view ───────────────────────────────────────────────────────────────
-- Opens a buffer listing all lecture notes for a given course.
-- Matches by class frontmatter (shorthand, name, or code) with filename fallback.

function M.course_view(course)
    local shorthand = course.shorthand or course.name
    local lecture_dir = UNI .. "/Lecture"

    local function class_matches(fm, fname)
        local cls = fm.class or ""
        return cls == shorthand
            or cls == course.name
            or cls == course.code
            or (shorthand ~= "" and fname:lower():find(shorthand:lower(), 1, true) == 1)
    end

    -- Lectures
    local handle = io.popen('find ' .. vim.fn.shellescape(lecture_dir) ..
        ' -name "*.md" -type f 2>/dev/null')
    local lectures = {}
    if handle then
        for path in handle:lines() do
            local fm = parse_frontmatter(path)
            local fname = path:match("([^/]+)%.md$") or ""
            if class_matches(fm, fname) then
                local date_str = fm.date or fname:match("%d%d%d%d%-%d%d%-%d%d") or ""
                local dt = parse_date(date_str)
                lectures[#lectures + 1] = {
                    name = fm.title or fname, path = path, date_str = date_str, dt = dt,
                }
            end
        end
        handle:close()
    end
    table.sort(lectures, function(a, b)
        local ta = a.dt and os.time({ year=a.dt.year, month=a.dt.month, day=a.dt.day, hour=12 }) or 0
        local tb = b.dt and os.time({ year=b.dt.year, month=b.dt.month, day=b.dt.day, hour=12 }) or 0
        return ta < tb
    end)
    local lec_lines = {}
    for i, lec in ipairs(lectures) do
        local date_part = lec.date_str ~= "" and lec.date_str or "—"
        lec_lines[#lec_lines + 1] = { text = string.format("%2d.  %-13s  %s", i, date_part, lec.name), path = lec.path }
    end

    -- Assignments for this course (ungraded)
    local all_assign = M.active_assignments(UNI .. "/Assignments")
    local assign_lines = {}
    for _, a in ipairs(all_assign) do
        if class_matches({ class = a.class }, "") then
            local when
            if not a.diff then when = "?"
            elseif a.diff == 0 then when = "TODAY"
            elseif a.diff > 0 then when = "in " .. a.diff .. " days"
            else when = math.abs(a.diff) .. "d ago" end
            local text = string.format("%-35s  %-14s  %s  (%s)", a.name, a.atype, a.date_str, when)
            assign_lines[#assign_lines + 1] = { text = text, path = a.path }
        end
    end

    -- Summary file: UNI/Summary/<course.name> Summary.md
    local summary_lines = {}
    local summary_candidates = {
        UNI .. "/Summary/" .. course.name .. " Summary.md",
        UNI .. "/Summary/" .. shorthand .. " Summary.md",
    }
    for _, sp in ipairs(summary_candidates) do
        if vim.fn.filereadable(sp) == 1 then
            summary_lines[#summary_lines + 1] = { text = sp:match("([^/]+)%.md$") or sp, path = sp }
            break
        end
    end

    local title = course.name .. "  (" .. course.code .. ")"
    local sections = {
        { header = "SUMMARY",                      lines = summary_lines },
        { header = "ASSIGNMENTS",                  lines = assign_lines },
        { header = "LECTURES  (" .. #lectures .. ")", lines = lec_lines },
    }

    local footer = { "[n] new lecture", "[f] browse", "[q] close" }
    local buf, _ = M.render_buffer(title, sections, footer)
    vim.api.nvim_set_current_buf(buf)
    local function km(k, fn) vim.keymap.set("n", k, fn, { buffer = buf, nowait = true }) end

    km("f", function()
        vim.api.nvim_buf_delete(buf, { force = true })
        open_yazi(lecture_dir)
    end)

    km("n", function()
        local date = os.date("%Y-%m-%d")
        local template = UNI .. "/Templates/Lecture.md"
        local target = lecture_dir .. "/" .. shorthand .. " " .. date .. ".md"
        local tf = io.open(template, "r")
        local content = tf and tf:read("*a")
            or ("---\nclass: " .. shorthand .. "\ndate: " .. date .. "\n---\n\n# Lecture\n\n")
        if tf then tf:close() end
        local nf = io.open(target, "w")
        if nf then nf:write(content); nf:close() end
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd("edit " .. vim.fn.fnameescape(target))
    end)

    return buf
end

-- ── Vault search ─────────────────────────────────────────────────────────────

function M.vault_search(query)
    if not query then
        vim.ui.input({ prompt = "Search vault: " }, function(q)
            if q and q ~= "" then M.vault_search(q) end
        end)
        return
    end

    local buf_path = vim.fn.expand("%:p")
    local vault = buf_path:find(UNI, 1, true) and UNI or VAULT

    local cmd = string.format(
        "grep -rn --include='*.md'"
        .. " --exclude-dir=Attachments --exclude-dir=Templates --exclude-dir=.obsidian"
        .. " -i %s %s 2>/dev/null",
        vim.fn.shellescape(query),
        vim.fn.shellescape(vault)
    )
    local raw = vim.fn.systemlist(cmd)

    local entries = {}
    for _, line in ipairs(raw) do
        local file, lnum, text = line:match("^(.-):(%d+):(.*)")
        if file then
            local short = file:gsub(vim.pesc(vault) .. "/", "")
            local snippet = text:match("^%s*(.-)%s*$"):sub(1, 55)
            entries[#entries + 1] = {
                display = string.format("  %-42s %s", short .. ":" .. lnum, snippet),
                path    = file,
                lnum    = tonumber(lnum),
            }
        end
    end

    local result_lines = {}
    for _, e in ipairs(entries) do
        result_lines[#result_lines + 1] = {
            text = e.display,
            callback = function()
                vim.cmd("edit +" .. e.lnum .. " " .. vim.fn.fnameescape(e.path))
            end,
        }
    end

    local sections = {
        { header = "RESULTS FOR: " .. query, lines = result_lines },
    }
    M.render_buffer("SEARCH", sections, { "[q] close" })
end

return M
