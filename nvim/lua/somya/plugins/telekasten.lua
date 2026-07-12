-- Note-taking: telekasten.nvim over a single local notes vault.
--
-- The vault lives at ~/.somyadashora/sd-notes (a LOCAL git repo — never pushed,
-- so notes stay per-machine) and starts life with one file, notes.md. Both the
-- repo and the file are bootstrapped on first use (ensure_repo), so there's no
-- manual setup: the first <leader>Zz creates the dir, `git init`s it, and writes
-- a notes.md header if missing. Commits are manual (git -C <vault> commit).
--
-- All maps live under <leader>Z ("+Notes"). The headline pair:
--   <leader>Zz  jump to a dedicated notes TAB (open notes.md, scoped via :tcd)
--   <leader>Zr  return to whatever tab you jumped from
-- The notes tab is identified by a tab-local flag (vim.t.is_notes_tab) and
-- labeled with the vault's base dir name ("sd-notes") via the tab-local `name`
-- var, which bufferline's right-side tabpage indicator renders in place of the
-- tab number (Neovim tabs have no native name of their own) — same convention
-- as :TabProject tabs.
-- The rest are telekasten actions (find/search/links/daily/backlinks/panel) plus
-- the calendar (calendar-vim) and a <leader>Z? help popup.

local home = vim.fn.expand("~/.somyadashora/sd-notes")
local notes_file = home .. "/notes.md"
local weekly_template = home .. "/templates/weekly.md"

-- ── Bootstrap: make the vault a local git repo with a notes file ─────────────
-- Also seeds vault/templates/ (telekasten fills {{placeholders}} when creating
-- a note from a template — see :h telekasten or the README's template list:
-- {{title}} {{date}} {{hdate}} {{week}} {{year}} {{monday}}..{{sunday}} …).
-- Each file is written only if missing, so per-machine edits to a template are
-- never overwritten — edit vault/templates/weekly.md freely.
local function ensure_repo()
  -- Create the vault plus its subdirs up front — telekasten otherwise stops
  -- to ask "folder does not exist, create?" on the first Zd/Zw.
  for _, dir in ipairs({ home, home .. "/daily", home .. "/weekly", home .. "/templates" }) do
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end
  if vim.fn.isdirectory(home .. "/.git") == 0 and vim.fn.executable("git") == 1 then
    vim.fn.system({ "git", "-C", home, "init", "-q" })
  end
  if vim.fn.filereadable(notes_file) == 0 then
    local host = vim.loop.os_gethostname() or "this machine"
    vim.fn.writefile({
      "# Notes — " .. host,
      "",
      "Local notes for the work on this machine. Created " .. os.date("%Y-%m-%d") .. ".",
      "",
    }, notes_file)
  end
  if vim.fn.filereadable(weekly_template) == 0 then
    vim.fn.mkdir(home .. "/templates", "p")
    vim.fn.writefile({
      "# {{title}}",
      "",
      "Week {{week}} of {{year}} · {{monday}} → {{sunday}}",
      "",
      "## Accomplishments this week",
      "",
      "- ",
      "",
      "## Plans",
      "",
      "- ",
      "",
      "## Other comments — insights, challenges",
      "",
      "- ",
      "",
    }, weekly_template)
  end
end

-- ── Notes tab: jump to a tagged tab and back to where you came from ──────────
local origin_tab = nil

local function find_notes_tab()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local ok, v = pcall(vim.api.nvim_tabpage_get_var, tab, "is_notes_tab")
    if ok and v then return tab end
  end
  return nil
end

local function goto_notes()
  ensure_repo()
  local cur = vim.api.nvim_get_current_tabpage()
  local nt = find_notes_tab()
  if nt then
    if nt ~= cur then
      origin_tab = cur
      vim.api.nvim_set_current_tabpage(nt)
    end
  else
    origin_tab = cur
    vim.cmd("tabnew")
    vim.t.is_notes_tab = true
    -- bufferline's tabpage indicator (right side) shows the tab-local `name` var
    -- if set, else the tab number. Label it with the vault's base dir name
    -- ("sd-notes") — same convention as :TabProject tabs (fnamemodify cwd :t).
    vim.t.name = vim.fn.fnamemodify(home, ":t")
    vim.cmd("tcd " .. vim.fn.fnameescape(home)) -- scope explorer/pickers to the vault
    vim.cmd("edit " .. vim.fn.fnameescape(notes_file))
  end
end

local function return_to_origin()
  if origin_tab and vim.api.nvim_tabpage_is_valid(origin_tab) then
    vim.api.nvim_set_current_tabpage(origin_tab)
  else
    vim.notify("No origin tab to return to", vim.log.levels.INFO, { title = "Notes" })
  end
end

-- ── Calendar: toggle the calendar-vim window (filetype "calendar") ───────────
local function toggle_calendar()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "calendar" then
      pcall(vim.api.nvim_win_close, win, false)
      return
    end
  end
  vim.cmd("Telekasten show_calendar")
end

-- ── Help popup (reuses the cheatsheet float renderer) ────────────────────────
local function notes_help()
  require("somya.cheatsheet").open({
    {
      title = "NOTES  (<leader>Z — telekasten)",
      entries = {
        { "<leader>Zz",  "jump to the notes tab (open notes.md)" },
        { "<leader>Zr",  "return to the tab you came from" },
        { "── telekasten ──", "" },
        { "<leader>Zf",  "find notes (telescope)" },
        { "<leader>Zs",  "search / grep notes" },
        { "<leader>Zn",  "new note" },
        { "<leader>Zd",  "today's daily note" },
        { "<leader>Zw",  "this week's weekly note" },
        { "<leader>Zl",  "insert [[link]]" },
        { "<leader>Zk",  "follow [[link]] under cursor" },
        { "<leader>Zb",  "show backlinks" },
        { "<leader>Zc",  "toggle calendar (calendar-vim)" },
        { "<leader>Zp",  "Telekasten panel (all commands)" },
        { "── inside the calendar window ──", "" },
        { "<CR>",        "open/create that day's daily note" },
        { "← / →",       "previous / next month" },
        { "↑ / ↓",       "previous / next year" },
        { "t  /  r  /  q", "today / redisplay / close" },
        { "?",           "calendar's own help" },
        { "── vault (local git repo, commit manually) ──", "" },
        { home,          "" },
        { "── templates (Zw uses templates/weekly.md; edit freely) ──", "" },
        { home .. "/templates", "" },
      },
    },
  }, {
    title = "  Notes / Zettelkasten  ",
    max_width = 78,
    key_col = 16,
    sep_width = 74,
  })
end

return {
  "nvim-telekasten/telekasten.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "renerocksai/calendar-vim", -- telekasten's calendar integration (<leader>Zc)
  },
  cmd = "Telekasten",
  keys = {
    "<leader>Zz", "<leader>Zr", "<leader>Zf", "<leader>Zs", "<leader>Zn",
    "<leader>Zd", "<leader>Zw", "<leader>Zl", "<leader>Zk", "<leader>Zb",
    "<leader>Zc", "<leader>Zp", "<leader>Z?",
  },
  config = function()
    ensure_repo()
    require("telekasten").setup({
      home = home,
      dailies = home .. "/daily",
      weeklies = home .. "/weekly",
      templates = home .. "/templates",
      -- <leader>Zw fills this template for a new week's note (bootstrapped
      -- into the vault by ensure_repo; edit the vault copy to taste).
      template_new_weekly = weekly_template,
      extension = ".md",
      new_note_filename = "title",
      follow_creates_nonexisting = true,
      dailies_create_nonexisting = true,
      weeklies_create_nonexisting = true,
      template_handling = "smart",
      new_note_location = "smart",
    })

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc })
    end

    -- Headline: jump to notes tab / return
    map("<leader>Zz", goto_notes, "Notes: jump to notes tab")
    map("<leader>Zr", return_to_origin, "Notes: return to previous tab")

    -- telekasten actions
    map("<leader>Zf", "<cmd>Telekasten find_notes<cr>",    "Notes: find notes")
    map("<leader>Zs", "<cmd>Telekasten search_notes<cr>",  "Notes: search notes")
    map("<leader>Zn", "<cmd>Telekasten new_note<cr>",      "Notes: new note")
    map("<leader>Zd", "<cmd>Telekasten goto_today<cr>",    "Notes: today's daily note")
    map("<leader>Zw", "<cmd>Telekasten goto_thisweek<cr>", "Notes: this week's weekly note")
    map("<leader>Zl", "<cmd>Telekasten insert_link<cr>",   "Notes: insert link")
    map("<leader>Zk", "<cmd>Telekasten follow_link<cr>",   "Notes: follow link")
    map("<leader>Zb", "<cmd>Telekasten show_backlinks<cr>","Notes: backlinks")
    map("<leader>Zc", toggle_calendar,                     "Notes: toggle calendar")
    map("<leader>Zp", "<cmd>Telekasten panel<cr>",         "Notes: panel")

    -- Help popup
    map("<leader>Z?", notes_help, "Notes: help popup")
  end,
}
