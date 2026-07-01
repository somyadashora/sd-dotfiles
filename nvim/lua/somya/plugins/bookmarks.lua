-- Persistent bookmarks: LintaoAmons/bookmarks.nvim.
--
-- A richer, PERSISTENT complement to marks.nvim's ephemeral `'a`-style marks —
-- SQLite-backed bookmarks that survive across sessions, carry names/descriptions,
-- group into named lists, and are browsable via Telescope, a tree view, or grep.
--
-- CONFLICT NOTE (why <leader>m and not bare m): the plugin's own recommended maps
-- (mm/mo/ma/md) sit on the BARE `m` prefix, which marks.nvim owns (mx, m,, m], m[,
-- dm*, …). Every binding here lives under <leader>m ("+Bookmarks") — that's
-- Space-then-m, a different namespace from the bare `m`, so the two never collide.
-- marks.nvim's OWN overlapping numbered-bookmark feature (m0-m9, m}/m{, dm=) is
-- disabled in marks.lua so bookmarks.nvim is the single "bookmark" concept.
--
-- LOOK: the gutter mark, its full-line background, and the tree's list icons are
-- all catppuccin Mauve (#cba6f7 — the repo's "neon purple", also used by lualine /
-- toggleterm / dashboard) so a bookmark never gets confused with a diagnostic or
-- git sign. <leader>mv toggles all of that over the code without touching the DB.
--
-- Storage: a per-machine SQLite DB at stdpath("data")/bookmarks.sqlite.db (never
-- pushed) — same per-machine philosophy as the telekasten vault. Needs sqlite.lua
-- + the system libsqlite3 at runtime.

local MAUVE = "#cba6f7"   -- catppuccin Mauve — the repo's neon purple
local LINE_BG = "#2a1d3d" -- dark mauve line background (repo toggleterm "purple" bg)

-- Tree side-panel palette (catppuccin, mauve-tinted so it reads as a distinct
-- "bookmarks panel" — a touch lighter than the dark editor, not just black).
local PANEL_BG   = "#262234" -- lifted, faintly-purple panel background
local PANEL_CL   = "#2f2a40" -- cursorline within the panel (a shade lighter)
local ACTIVE_BAR = "#372e50" -- background bar behind the ACTIVE list row
local LIST_NAME  = "#b4befe" -- catppuccin Lavender — list / folder names
local ORDER_NUM  = "#7f849c" -- catppuccin Overlay1 — muted bookmark order prefix
local NAME_TEXT  = "#cdd6f4" -- catppuccin Text — bookmark name / note text

-- Help popup (reuses the cheatsheet float renderer, like telekasten's <leader>Z?).
local function bookmarks_help()
  require("somya.cheatsheet").open({
    {
      title = "BOOKMARKS  (<leader>m — bookmarks.nvim, persistent/SQLite)",
      entries = {
        { "<leader>mm",  "mark current line / rename bookmark (n,v)" },
        { "<leader>mo",  "go to a bookmark in the active list (picker)" },
        { "<leader>md",  "add / edit description on bookmark under cursor" },
        { "<leader>mc",  "command palette — every bookmark action" },
        { "<leader>mv",  "toggle bookmark signs over code (show / hide)" },
        { "── lists & views ──", "" },
        { "<leader>mt",  "toggle tree view (open / close from anywhere)" },
        { "<leader>ml",  "select the active list" },
        { "<leader>mn",  "create a new list" },
        { "<leader>ms",  "grep across bookmarked files" },
        { "<leader>mi",  "plugin status / DB info" },
        { "── navigate ──", "" },
        { "<leader>m]",  "go to next bookmark" },
        { "<leader>m[",  "go to previous bookmark" },
        { "── inside the tree view ──", "" },
        { "o",           "toggle fold / go to bookmark" },
        { "a  /  D  /  r", "new list / delete node / rename node" },
        { "g  /  ?",      "go to bookmark location / help panel" },
        { "── storage (per-machine, never pushed) ──", "" },
        { vim.fn.stdpath("data") .. "/bookmarks.sqlite.db", "" },
      },
    },
  }, {
    title = "  Bookmarks (persistent)  ",
    max_width = 82,
    key_col = 16,
    sep_width = 78,
  })
end

return {
  "LintaoAmons/bookmarks.nvim",
  version = "^4.0.0", -- stay on v4 — back up the SQLite DB before a major upgrade
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-telescope/telescope.nvim", -- already in the tree; picker backend below
  },
  cmd = {
    "BookmarksMark", "BookmarksGoto", "BookmarksDesc", "BookmarksCommands",
    "BookmarksTree", "BookmarksLists", "BookmarksNewList", "BookmarksGrep",
    "BookmarksInfo", "BookmarksGotoNext", "BookmarksGotoPrev",
  },
  keys = {
    "<leader>mm", "<leader>mo", "<leader>md", "<leader>mc", "<leader>mv",
    "<leader>mt", "<leader>ml", "<leader>mn", "<leader>ms", "<leader>mi",
    "<leader>m]", "<leader>m[", "<leader>m?",
  },
  config = function()
    require("bookmarks").setup({
      -- Repo uses telescope, not snacks, as the picker everywhere else.
      picker = {
        picker_backend = "telescope",
      },
      -- Neon-purple mark so it never blends with diagnostic / git / todo signs.
      -- `color` tints both the gutter icon and the inline description; `line_bg`
      -- is the full-line background of a bookmarked line.
      signs = {
        mark = {
          icon = "󰃁",
          color = MAUVE,
          line_bg = LINE_BG,
        },
      },
      -- Tree view: color the ACTIVE list row mauve-bold on a subtle bar so the
      -- current list pops. This is the plugin's own highlight hook (deep-merged,
      -- so the tree keymaps/icon defaults are preserved); it re-applies each time
      -- the tree opens. The rest of the panel styling is done window-locally in
      -- the FileType autocmd below.
      treeview = {
        highlights = {
          active_list = { fg = MAUVE, bg = ACTIVE_BAR, bold = true },
        },
      },
    })

    -- Re-apply our highlight groups. The plugin defines the sign / line hls once
    -- inside setup(), but a colorscheme reload (styler.nvim swaps schemes per
    -- filetype) runs `hi clear` and wipes them — so re-assert on ColorScheme, the
    -- same way the rest of the config re-applies custom hls. BookmarksListIcon is
    -- our OWN group for the tree's list icons (the plugin exposes none).
    local function apply_hl()
      vim.api.nvim_set_hl(0, "BookmarksNvimSign", { fg = MAUVE })
      vim.api.nvim_set_hl(0, "BookmarksNvimLine", { bg = LINE_BG })
      vim.api.nvim_set_hl(0, "BookmarksListIcon", { fg = MAUVE, bold = true })
      -- Tree side-panel groups (winhighlight targets + content matches below).
      vim.api.nvim_set_hl(0, "BookmarksPanel",    { bg = PANEL_BG })
      vim.api.nvim_set_hl(0, "BookmarksPanelEob", { fg = PANEL_BG, bg = PANEL_BG }) -- hide ~ tildes
      vim.api.nvim_set_hl(0, "BookmarksPanelCL",  { bg = PANEL_CL })
      vim.api.nvim_set_hl(0, "BookmarksListName", { fg = LIST_NAME, bold = true })
      vim.api.nvim_set_hl(0, "BookmarksOrder",    { fg = ORDER_NUM })
      vim.api.nvim_set_hl(0, "BookmarksName",     { fg = NAME_TEXT })
      -- Mirror the plugin's active-list hl so it survives a ColorScheme wipe
      -- between tree opens (the plugin also re-applies it on each open).
      vim.api.nvim_set_hl(0, "BookmarksTreeActiveList", { fg = MAUVE, bg = ACTIVE_BAR, bold = true })
    end
    apply_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("SdBookmarksHl", { clear = true }),
      callback = apply_hl,
    })

    -- Tree view styling. The plugin ships no gutter cleanup, background, or
    -- content highlighting, so we do it window-locally in the BookmarksTree
    -- filetype (a fresh buffer+window each open, so matches don't leak or stack):
    --   • drop the gutter — statuscol is told to ignore this ft (see
    --     plugins/statuscol.lua), and we hard-off signcolumn/fold/number here too;
    --   • lift the background to a mauve-tinted panel via winhighlight (contained
    --     to this window — NormalNC keeps it lit when focus is in the code);
    --   • color the content by row type. Patterns use \zs so they're disjoint:
    --     the icons, a non-active list NAME (negative-lookahead skips the active
    --     row so the plugin's mauve active-list hl shows through), the bookmark
    --     order number, and the bookmark name/note text.
    -- Hook BufWinEnter (not FileType): the plugin sets the buffer's filetype
    -- BEFORE it's shown in a window, so at FileType time the current window is
    -- still the code window — styling would land there. BufWinEnter fires when the
    -- tree buffer actually enters its window (during the plugin's win_set_buf), so
    -- the current window IS the tree. Guard on filetype since the pattern is "*".
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "*",
      group = vim.api.nvim_create_augroup("SdBookmarksTree", { clear = true }),
      callback = function()
        if vim.bo.filetype ~= "BookmarksTree" then return end
        local w = vim.api.nvim_get_current_win()
        vim.wo[w].signcolumn = "no"
        vim.wo[w].foldcolumn = "0"
        vim.wo[w].number = false
        vim.wo[w].relativenumber = false
        vim.wo[w].numberwidth = 1
        vim.wo[w].wrap = false
        vim.wo[w].cursorline = true
        vim.wo[w].winhighlight = table.concat({
          "Normal:BookmarksPanel",
          "NormalNC:BookmarksPanel",
          "EndOfBuffer:BookmarksPanelEob",
          "CursorLine:BookmarksPanelCL",
          "SignColumn:BookmarksPanel",
        }, ",")
        pcall(vim.fn.matchadd, "BookmarksListIcon", "[▸▾󰮔]")
        pcall(vim.fn.matchadd, "BookmarksListName", "[▾▸] \\%(󰮔\\)\\@!\\zs.*")
        pcall(vim.fn.matchadd, "BookmarksOrder", "^\\s*\\zs\\d\\+: ")
        pcall(vim.fn.matchadd, "BookmarksName", "^\\s*\\d\\+: \\zs.*")
      end,
    })

    -- Fix :qa being blocked by a modified "[No Name]" buffer. The plugin's popups
    -- (BookmarksInfo, and BookmarksDesc while open) are created as NORMAL, unnamed
    -- buffers, filled with text (→ modified), and Info never sets buftype=nofile or
    -- bufhidden=wipe — so after you view it, a modified [No Name] buffer lingers and
    -- :qa errors (E162). Neutralize the plugin's popups: an unlisted + unnamed
    -- markdown scratch buffer is always one of these (real .md files are listed and
    -- named, so telekasten / render-markdown are untouched) — make it a wipe-on-hide
    -- nofile buffer so it can't block quit and cleans itself up.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      group = vim.api.nvim_create_augroup("SdBookmarksPopupFix", { clear = true }),
      callback = function(ev)
        if vim.bo[ev.buf].buflisted or vim.api.nvim_buf_get_name(ev.buf) ~= "" then
          return -- a real markdown file, leave it alone
        end
        vim.bo[ev.buf].buftype = "nofile"
        vim.bo[ev.buf].bufhidden = "wipe"
        vim.bo[ev.buf].swapfile = false
      end,
    })

    -- Toggle the bookmark visuals over code (gutter sign + line bg + inline desc).
    -- The plugin redraws signs on WinEnter/BufEnter/InsertLeave via its own
    -- autocmd, so a one-shot clean() won't stick. Instead swap the sign module's
    -- refresh fn: while hidden, every refresh (manual or autocmd-driven) just
    -- cleans the buffer, so bookmarks stay hidden as you move around; toggling
    -- back restores the real refresh and redraws. The DB is untouched — this only
    -- hides the visuals, the bookmarks and their lists all persist.
    local sign = require("bookmarks.sign")
    local real_refresh = sign.safe_refresh_signs
    local shown = true
    local function toggle_visibility()
      shown = not shown
      if shown then
        sign.safe_refresh_signs = real_refresh
        pcall(sign.safe_refresh_signs)
        vim.notify("Bookmarks: signs shown", vim.log.levels.INFO, { title = "Bookmarks" })
      else
        sign.safe_refresh_signs = function() pcall(sign.clean) end
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          pcall(vim.api.nvim_win_call, win, function() pcall(sign.clean) end)
        end
        vim.notify("Bookmarks: signs hidden", vim.log.levels.INFO, { title = "Bookmarks" })
      end
    end

    -- True toggle for the tree from ANY window. The built-in :BookmarksTree
    -- (tree.toggle) only closes when the tree window is itself focused — from a
    -- code window it just jumps to the open tree, so it never feels like a toggle.
    -- Close the tree wherever it's open, else open it. We must clear the plugin's
    -- tree context BEFORE closing: the tree buffer is bufhidden=wipe, and
    -- nvim_win_close fires WinEnter *synchronously*, whose autocmd schedules a
    -- re-render that reads vim.g.bookmark_tree_view_ctx.buf — a stale ctx points
    -- at the (wiping) buffer and throws "Invalid buffer id" from the async
    -- callback (outside the plugin's pcall). Nil-ing it first makes that
    -- re-render bail synchronously inside the guarded pcall, so no error escapes.
    local function toggle_tree()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "BookmarksTree" then
          vim.g.bookmark_tree_view_ctx = nil
          pcall(vim.api.nvim_win_close, win, true)
          return
        end
      end
      vim.cmd("BookmarksTree")
    end

    -- Normal-mode map, optionally also visual (for the mark/goto/desc actions
    -- that can operate on a visual range).
    local function map(lhs, rhs, desc, visual)
      vim.keymap.set(visual and { "n", "v" } or "n", lhs, rhs, { desc = desc })
    end

    map("<leader>mm", "<cmd>BookmarksMark<cr>",     "Bookmarks: mark / rename line", true)
    map("<leader>mo", "<cmd>BookmarksGoto<cr>",     "Bookmarks: go to bookmark", true)
    map("<leader>md", "<cmd>BookmarksDesc<cr>",     "Bookmarks: add description", true)
    map("<leader>mc", "<cmd>BookmarksCommands<cr>", "Bookmarks: command palette")
    map("<leader>mv", toggle_visibility,            "Bookmarks: toggle sign visibility")
    map("<leader>mt", toggle_tree,                  "Bookmarks: toggle tree view")
    map("<leader>ml", "<cmd>BookmarksLists<cr>",    "Bookmarks: select active list")
    map("<leader>mn", "<cmd>BookmarksNewList<cr>",  "Bookmarks: new list")
    map("<leader>ms", "<cmd>BookmarksGrep<cr>",     "Bookmarks: grep bookmarked files")
    map("<leader>mi", "<cmd>BookmarksInfo<cr>",     "Bookmarks: info / status")
    map("<leader>m]", "<cmd>BookmarksGotoNext<cr>", "Bookmarks: next bookmark")
    map("<leader>m[", "<cmd>BookmarksGotoPrev<cr>", "Bookmarks: prev bookmark")

    map("<leader>m?", bookmarks_help, "Bookmarks: help popup")
  end,
}
