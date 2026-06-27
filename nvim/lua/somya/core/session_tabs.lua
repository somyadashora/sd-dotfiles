-- Reliable tab layout persistence for auto-session.
--
-- :mksession is flaky with our project tabs: it drops tabs whose only window is
-- an empty buffer or the alpha dashboard (so <leader>TP tabs with no file open
-- vanish), and it can't carry our tab-local `name`/`is_notes_tab` vars at all.
--
-- So we don't let mksession own tab structure — we own it. capture() records the
-- full ordered layout (per-tab name, cwd, is_notes flag, open files). On restore
-- the session's companion x.vim parks that layout via set_pending(); once
-- nvim-tree has loaded, post_restore_cmds calls reconcile_pending(), which
-- rebuilds every tab from scratch in order. Rebuilding (rather than correlating
-- with whatever mksession produced) is what makes restore deterministic — see
-- reconcile() for why matching restored tabs was hopelessly ambiguous. Wired from
-- plugins/auto-session.lua (save_extra_cmds + post_restore_cmds).

local M = {}

-- Collect the real-file buffers shown in a tabpage (skip tree/special/empty).
local function tab_files(tp)
  local files = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
    local b = vim.api.nvim_win_get_buf(w)
    local bn = vim.api.nvim_buf_get_name(b)
    if bn ~= "" and vim.bo[b].buftype == "" and vim.fn.filereadable(bn) == 1 then
      files[#files + 1] = bn
    end
  end
  return files
end

-- Snapshot the current tab layout as an ordered, serializable table.
function M.capture()
  local layout = { tabs = {}, current = vim.fn.tabpagenr() }
  for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tp)
    local name
    local okn, n = pcall(vim.api.nvim_tabpage_get_var, tp, "name")
    if okn and type(n) == "string" and n ~= "" then name = n end
    local is_notes = false
    local okz, z = pcall(vim.api.nvim_tabpage_get_var, tp, "is_notes_tab")
    if okz and z then is_notes = true end
    table.insert(layout.tabs, {
      name = name,
      cwd = vim.fn.getcwd(-1, nr), -- tab-local cwd (:tcd), or global if none
      is_notes = is_notes,
      files = tab_files(tp),
    })
  end
  return layout
end

-- A single-line Lua literal for embedding in the session's x.vim.
function M.serialize(layout)
  return vim.inspect(layout, { newline = " ", indent = "" })
end

-- Stash the layout NOW, before pre_save closes any trees. A tab whose only
-- window is the nvim-tree explorer is destroyed when that tree is closed (it's
-- the tab's last window), so capture must happen first. save_extra_cmds then
-- serializes this stash, not a fresh (post-close) capture.
function M.stash()
  M._stash = M.capture()
end

function M.stashed_serialized()
  return M.serialize(M._stash or M.capture())
end

local function is_float(w)
  return vim.api.nvim_win_get_config(w).relative ~= ""
end

-- Close nvim-tree windows before saving so the session holds no NvimTree windows
-- (restoring them triggers E367). But DON'T destroy a tab whose only real window
-- is the tree — swap that window to an empty buffer so the tab (and its place in
-- the layout) survives. Floating windows (e.g. smear-cursor) don't count as real.
function M.close_trees()
  if not package.loaded["nvim-tree"] then return end
  for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
    local normal, trees = 0, {}
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
      if not is_float(w) then
        normal = normal + 1
        if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "NvimTree" then
          trees[#trees + 1] = w
        end
      end
    end
    for _, w in ipairs(trees) do
      if normal > #trees then
        pcall(vim.api.nvim_win_close, w, true) -- other real windows remain
      else
        pcall(vim.api.nvim_win_call, w, function() vim.cmd("enew") end) -- keep the tab
      end
    end
  end
end

-- The captured layout is parked here by the session's x.vim (set_pending) and
-- consumed once nvim-tree is ready (reconcile_pending, from post_restore_cmds).
-- This decouples "what to build" (known synchronously, mid-restore) from "build
-- it" (deferred until after the tree plugin loads), which is what makes the
-- result deterministic.
M._pending = nil

function M.set_pending(layout)
  M._pending = layout
end

function M.reconcile_pending()
  local layout = M._pending
  M._pending = nil
  M.reconcile(layout)
end

-- Rebuild the tab layout from scratch to exactly match the saved one.
--
-- We deliberately do NOT try to reuse / correlate whatever :mksession restored:
-- it drops no-file tabs, can't carry our tab-local name/is_notes vars, and any
-- cwd-based matching is ambiguous (the global cwd, the `nvim .` launch tab, and
-- recreated tabs all collapse to the same cwd) — that ambiguity was the source
-- of non-deterministic tab loss. Instead we collapse to one tab and build each
-- saved tab in order. Every tab gets a LISTED empty buffer as an anchor before
-- its tree opens, so the explorer splits beside the anchor instead of replacing
-- a lone window (a tree as a tab's only window is fragile — closing it kills the
-- tab). Runs from post_restore_cmds, after nvim-tree is loaded.
function M.reconcile(layout)
  if not (layout and layout.tabs and #layout.tabs > 0) then return end

  local api = package.loaded["nvim-tree"] and require("nvim-tree.api") or nil

  -- Collapse to a single tab, but DON'T reuse it to build the first saved tab:
  -- the leftover restore/launch tab carries odd state (a stale NvimTree buffer
  -- from `nvim .`, etc.) that left the first tab treeless and fragile. Build every
  -- saved tab as a fresh `tabnew` (uniform — they all then behave like the tabs
  -- that worked), and drop the leftover at the end.
  pcall(vim.cmd, "silent! tabonly!")
  local leftover = vim.api.nvim_get_current_tabpage()

  for _, t in ipairs(layout.tabs) do
    vim.cmd("tabnew")
    vim.cmd("enew") -- fresh LISTED empty buffer = stable anchor for the tree
    if t.cwd and t.cwd ~= "" then
      pcall(vim.cmd, "tcd " .. vim.fn.fnameescape(t.cwd))
    end
    if t.files and #t.files > 0 then
      for _, f in ipairs(t.files) do
        if vim.fn.filereadable(f) == 1 then
          pcall(vim.cmd, "edit " .. vim.fn.fnameescape(f))
        end
      end
    end
    -- Set name/flag on the current tab (handle 0) — unambiguous, we're on it.
    if t.name then pcall(vim.api.nvim_tabpage_set_var, 0, "name", t.name) end
    if t.is_notes then pcall(vim.api.nvim_tabpage_set_var, 0, "is_notes_tab", true) end
    if api then pcall(api.tree.open) end -- [tree + anchor/file], survives toggling
  end

  if vim.api.nvim_tabpage_is_valid(leftover) then
    pcall(vim.api.nvim_set_current_tabpage, leftover)
    pcall(vim.cmd, "tabclose")
  end

  if layout.current then pcall(vim.cmd, "silent! tabnext " .. layout.current) end
end

return M
