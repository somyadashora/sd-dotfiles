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
    end
    apply_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("SdBookmarksHl", { clear = true }),
      callback = apply_hl,
    })

    -- Tree view: paint every list icon (fold markers ▸/▾ + the active-list icon
    -- 󰮔) neon purple. The tree exposes no highlight group for these, so match them
    -- in the BookmarksTree buffer. The active list's own line keeps its special
    -- highlight — it's drawn as an extmark that wins over these window matches.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "BookmarksTree",
      group = vim.api.nvim_create_augroup("SdBookmarksTree", { clear = true }),
      callback = function()
        pcall(vim.fn.matchadd, "BookmarksListIcon", "[▸▾󰮔]")
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
