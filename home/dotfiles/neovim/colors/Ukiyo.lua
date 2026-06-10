
-- "Ukiyo" Dark Mode for Neovim
-- Inspired by Obsidian's Ukiyo

local colors = {
  bg          = "#372d29", -- standard dark brown bg color
  bg_alt      = "#413632", -- lighter accent background color
  fg          = "#dfc2a0", -- Light yellowy color
  dim         = "#868074", -- dim brownish color  
  orange      = "#da9517", -- Slightly stronger than fg
  bold_orange = "#ce631c", -- Slightly darker than red
  red         = "#da7b5f", -- <- These colors
  selection   = "#8a6624", -- Very nice golden orange

  accent      = "#8a6624", -- dim orangey brown color
  accent2     = "#f5ca6c", -- bright yellow color
  purple      = "#483652", -- Obsidian purple color
}

local theme = {
  -- Core UI
  Normal       = { fg = colors.fg, bg = colors.bg },
  NormalNC     = { fg = colors.fg, bg = colors.bg_alt },
  CursorLine   = { bg = colors.bg_alt },
  CursorLineNr = { fg = colors.orange, bold = true },
  LineNr       = { fg = colors.dim },
  VertSplit    = { fg = colors.bg_alt },
  WinSeparator = { fg = colors.accent },
  StatusLine   = { fg = colors.fg, bg = colors.bg_alt },
  StatusLineNC = { fg = colors.dim, bg = colors.bg_alt },
  Pmenu        = { fg = colors.fg, bg = colors.bg_alt },
  PmenuSel     = { fg = colors.bg, bg = colors.accent, bold = true },
  Visual       = { bg = colors.selection },
  Search       = { bg = colors.accent, fg = colors.bg },
  IncSearch    = { bg = colors.accent2, fg = colors.bg },
  MatchParen   = { fg = colors.selection, bold = true },
  Cursor       = { bg = colors.orange, fg = colors.bg },

  -- Syntax
  Comment      = { fg = colors.dim, italic = true },     
  Constant     = { fg = colors.orange },                
  String       = { fg = colors.red, italic = true },                    
  Character    = { fg = colors.orange },                 
  Number       = { fg = colors.bold_orange ,bold = true},
  Boolean      = { fg = colors.orange },                 
  Float        = { fg = colors.orange },                 
  Text         = { fg = colors.fg },

  Identifier   = { fg = colors.fg },
  Function     = { fg = colors.fg, italic = true },
  Statement    = { fg = colors.bold_orange, bold = true },
  Keyword      = { fg = colors.bold_orange, bold = true },
  Conditional  = { fg = colors.bold_orange },
  Repeat       = { fg = colors.bold_orange },
  Operator     = { fg = colors.orange},
  Exception    = { fg = colors.red },

  PreProc      = { fg = colors.orange },
  Type         = { fg = colors.accent2 },
  Structure    = { fg = colors.accent2 },
  Typedef      = { fg = colors.accent2 },

  Special      = { fg = colors.accent2 },
  Tag          = { fg = colors.accent, bg = colors.purple },
  Delimiter    = { fg = colors.fg },
  Bold         = { fg = colors.orange, bold = true },
  Italic       = { fg = colors.red, italic = true },
  Underlined   = { fg = colors.orange, underline = true },

  -- Diagnostics
  DiagnosticError = { fg = colors.red },
  DiagnosticWarn  = { fg = colors.bold_orange },
  DiagnosticInfo  = { fg = colors.accent2 },
  DiagnosticHint  = { fg = colors.accent },

  -- Diff
  DiffAdd    = { bg = "#3b2f20" },
  DiffChange = { bg = "#433122" },
  DiffDelete = { bg = "#4a1f1f" },
  DiffText   = { bg = "#55391f" },

  -- Git Signs
  GitGutterAdd    = { fg = colors.accent },
  GitGutterChange = { fg = colors.accent2 },
  GitGutterDelete = { fg = colors.red },
}

for group, opts in pairs(theme) do
  vim.api.nvim_set_hl(0, group, opts)
end

return theme


