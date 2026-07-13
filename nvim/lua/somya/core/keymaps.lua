vim.g.mapleader = " " -- set leader key to space

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- Close buffer and switch to previous, or just close if last buffer
keymap.set("n", "<C-q>", function()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs > 1 then
    vim.cmd("bp | bd #")
  else
    vim.cmd("bd")
  end
end, { desc = "Close buffer, stay on active buffer" })

-- Disable arrow keys in normal, insert, and visual modes
local arrow_keys = { "<Up>", "<Down>", "<Left>", "<Right>" }
for _, key in ipairs(arrow_keys) do
  keymap.set({ "n", "i", "v" }, key, "<Nop>", { desc = "Disabled arrow key" })
end

-- Insert-mode STICKY cursor movement. Press <C-g> ONCE, then <C-h>/<C-j>/<C-k>/
-- <C-l> move left/down/up/right and REPEAT freely — you stay in insert mode and
-- never re-press <C-g>. The moment you type any other character (or leave insert
-- mode) the sub-mode ends and that key is handled normally.
--
-- The arrow keys are disabled above and Vim has no native Ctrl-hjkl movement in
-- insert mode, so this fills that gap. <C-g> is a good host: bare <C-g> only
-- prints the file name and has no completion sub-mode (no timeout ambiguity like
-- <C-x>), and it's a clean control code — no Alt/Esc-prefix, no tmux M-hjkl clash
-- (Alt+hjkl navigates panes, see tmux/.tmux.conf).
--
-- Implemented with TRANSIENT buffer-local maps, NOT a getcharstr() loop: looping
-- on getcharstr() inside an insert-mode mapping never returns until you exit, so
-- Neovim can't draw the insert cursor at its real column during the wait — it
-- parks at col 0 / the command line (the "cursor jumped to the bottom" bug). Real
-- maps dispatch normally, so the cursor tracks live. A vim.on_key watcher tears
-- the maps down on the first non-movement key (restoring <C-j>/<C-k> for cmp and
-- <C-h> for backspace); an autocmd covers leaving insert mode / the buffer. RHS
-- is the built-in arrow (noremap), so the <Nop> arrow maps above don't eat these.
local sticky = {
  active = false,
  buf = nil,
  ns = vim.api.nvim_create_namespace("insert_sticky_move"),
  aug = vim.api.nvim_create_augroup("InsertStickyMove", { clear = true }),
}
local sticky_rhs = { ["<C-h>"] = "<Left>", ["<C-j>"] = "<Down>", ["<C-k>"] = "<Up>", ["<C-l>"] = "<Right>" }
-- Raw bytes for the keys that KEEP the sub-mode alive (the four moves + <C-g>).
local sticky_keep = {}
for _, k in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<C-g>" }) do
  sticky_keep[vim.keycode(k)] = true
end

local function sticky_stop()
  if not sticky.active then return end
  sticky.active = false
  vim.on_key(nil, sticky.ns) -- remove the watcher
  vim.api.nvim_clear_autocmds({ group = sticky.aug })
  for lhs in pairs(sticky_rhs) do
    pcall(vim.keymap.del, "i", lhs, { buffer = sticky.buf })
  end
  sticky.buf = nil
end

local function sticky_start()
  if sticky.active then return end
  sticky.active = true
  sticky.buf = vim.api.nvim_get_current_buf()
  for lhs, rhs in pairs(sticky_rhs) do
    keymap.set("i", lhs, rhs, { buffer = sticky.buf, desc = "Sticky move " .. rhs:sub(2, -2):lower() })
  end
  -- End on the first user-typed key that isn't a move chord. Keys emitted BY our
  -- own maps arrive with typed == "" and are ignored. on_key is a fast context
  -- (deleting maps / clearing the watcher there isn't allowed), so defer teardown.
  vim.on_key(function(_, typed)
    if typed and typed ~= "" and not sticky_keep[typed] then
      vim.schedule(sticky_stop)
    end
  end, sticky.ns)
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = sticky.aug,
    buffer = sticky.buf,
    callback = sticky_stop,
  })
end
keymap.set("i", "<C-g>", sticky_start, { desc = "Insert-mode sticky hjkl movement" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights"})

-- Toggle line wrap (off by default — see core/options.lua). Window-local so it
-- only affects the current buffer's view. Lives under the <leader>u "UI / Theme"
-- group. With wrap off, scroll horizontally with zl/zh (one col), zL/zH (half
-- screen), zs/ze (cursor to left/right edge).
keymap.set("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("Wrap: " .. (vim.wo.wrap and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Toggle line wrap" })

-- Toggle virtualedit=all (off by default — see core/options.lua). Lets the
-- cursor roam past line ends / into tabs for free-form navigation and block
-- edits. Under the <leader>u "UI / Theme" group.
keymap.set("n", "<leader>uv", function()
  local on = vim.o.virtualedit == "all"
  vim.o.virtualedit = on and "" or "all"
  vim.notify("Virtualedit: " .. (on and "off" or "on"), vim.log.levels.INFO)
end, { desc = "Toggle virtualedit (free cursor)" })

-- Toggle the fold-arrow column (off by default — ufo.lua sets foldcolumn=0 so
-- the gutter stays narrow). Window-local; statuscol draws its fold segment only
-- while foldcolumn ~= 0 (see plugins/statuscol.lua). Folding itself (za/zR/zM)
-- works either way. Under the <leader>u "UI / Theme" group.
keymap.set("n", "<leader>uf", function()
  local on = vim.wo.foldcolumn ~= "0"
  vim.wo.foldcolumn = on and "0" or "1"
  vim.notify("Fold column: " .. (on and "off" or "on"), vim.log.levels.INFO)
end, { desc = "Toggle fold column" })

-- Yank a "file:line" reference to the clipboard — for pasting into AI prompts
-- and reviews ("look at foo.sv:42"). Under <leader>Y ("Yank file ref"): Yy is
-- the cwd-relative path (tabs are tcd'd to the project root, so this is
-- repo-relative), Ya the absolute one. In visual mode the reference becomes a
-- range, "file:10-20". Lands in the system clipboard AND the unnamed register.
local function yank_ref(abs)
  return function()
    local path = vim.fn.expand(abs and "%:p" or "%:.")
    if path == "" then
      vim.notify("No file name for this buffer", vim.log.levels.WARN)
      return
    end
    local ref
    if vim.fn.mode():match("[vV\22]") then
      local s, e = vim.fn.line("v"), vim.fn.line(".")
      if s > e then s, e = e, s end
      ref = path .. ":" .. (s == e and s or (s .. "-" .. e))
      -- leave visual mode so the yank feels like a normal y
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    else
      ref = path .. ":" .. vim.fn.line(".")
    end
    vim.fn.setreg("+", ref)
    vim.fn.setreg('"', ref)
    vim.notify("Yanked: " .. ref, vim.log.levels.INFO)
  end
end
keymap.set({ "n", "x" }, "<leader>Yy", yank_ref(false), { desc = "Yank file:line (relative path)" })
keymap.set({ "n", "x" }, "<leader>Ya", yank_ref(true), { desc = "Yank file:line (absolute path)" })

-- <leader>Yc includes the code itself: "file:line:col: <line text>" for the
-- cursor line; in visual mode a "file:start-end:" header followed by the
-- selected lines. Relative path, like Yy.
keymap.set({ "n", "x" }, "<leader>Yc", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    vim.notify("No file name for this buffer", vim.log.levels.WARN)
    return
  end
  local ref, shown
  if vim.fn.mode():match("[vV\22]") then
    local s, e = vim.fn.line("v"), vim.fn.line(".")
    if s > e then s, e = e, s end
    local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
    shown = path .. ":" .. (s == e and s or (s .. "-" .. e))
    ref = shown .. ":\n" .. table.concat(lines, "\n")
    shown = shown .. " (+" .. #lines .. (#lines == 1 and " line)" or " lines)")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  else
    local l, c = unpack(vim.api.nvim_win_get_cursor(0))
    ref = ("%s:%d:%d: %s"):format(path, l, c + 1, vim.api.nvim_get_current_line())
    shown = ("%s:%d:%d (+content)"):format(path, l, c + 1)
  end
  vim.fn.setreg("+", ref)
  vim.fn.setreg('"', ref)
  vim.notify("Yanked: " .. shown, vim.log.levels.INFO)
end, { desc = "Yank file:line:col + content" })

-- Linter control
keymap.set("n", "<leader>ld", ":lua vim.diagnostic.enable(false)<CR>", { desc = "disable lint messages" })
keymap.set("n", "<leader>le", ":lua vim.diagnostic.enable(true)<CR>", { desc = "enable lint messages" })

-- Cycle line-number modes: hybrid -> absolute -> relative -> two-column -> ...
-- The first three just toggle 'number'/'relativenumber'. The fourth sets the
-- window var `ln_twocol`, which statuscol.nvim reads to render absolute + hybrid
-- side by side (see plugins/statuscol.lua). statuscol keeps the git column on
-- the right in every mode.
keymap.set("n", "<leader>ln", function()
  if vim.w.ln_twocol then                               -- two-column -> hybrid
    vim.w.ln_twocol = false
    vim.wo.number, vim.wo.relativenumber = true, true
    vim.notify("Line numbers: hybrid", vim.log.levels.INFO)
  elseif vim.wo.number and vim.wo.relativenumber then   -- hybrid -> absolute
    vim.wo.number, vim.wo.relativenumber = true, false
    vim.notify("Line numbers: absolute", vim.log.levels.INFO)
  elseif vim.wo.number then                             -- absolute -> relative
    vim.wo.number, vim.wo.relativenumber = false, true
    vim.notify("Line numbers: relative", vim.log.levels.INFO)
  else                                                  -- relative -> two-column
    vim.w.ln_twocol = true
    vim.wo.number, vim.wo.relativenumber = true, false  -- ensure the gutter draws
    vim.notify("Line numbers: two columns (absolute + hybrid)", vim.log.levels.INFO)
  end
  vim.cmd("redraw!") -- statuscolumn doesn't re-eval on a window-var change alone
end, { desc = "Cycle line numbers (hybrid/absolute/relative/two-column)" })

-- Delete mark (dm{char}, mirrors m{char} to set)
keymap.set("n", "dm", function()
  local char = vim.fn.getcharstr()
  vim.cmd("delm " .. char)
end, { desc = "Delete mark" })

-- Spellcheck control
keymap.set("n", "<leader>Sp", ":setlocal spell!<CR>", { desc = "Toggle spellcheck" })
keymap.set("n", "<leader>Sn", "]s", { desc = "Next misspelled word" })
keymap.set("n", "<leader>Sb", "[s", { desc = "Prev misspelled word" })
keymap.set("n", "<leader>Sa", "zg", { desc = "Add word to spellfile" })
keymap.set("n", "<leader>S?", "z=", { desc = "Suggest spelling corrections" })

-- Move the visual selection up/down, keeping it selected and reindenting (gv=gv).
-- Visual-mode only — moving a single line in normal mode isn't worth a keymap.
-- J=down, K=up (intuitive). In visual mode this overrides the builtin join (J)
-- and keywordprg (K); join is still available via :'<,'>join.
keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>To", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>Tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>Tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>Tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>Tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Open a new tab scoped to a project dir: tab-local cwd (:tcd) isolates the
-- explorer root and Telescope find/grep/buffers to that dir. nvim-tree re-roots
-- via sync_root_with_cwd; Telescope pickers default their cwd to getcwd().
vim.api.nvim_create_user_command("TabProject", function(opts)
  -- Name the tab we're leaving by its cwd basename if it has no name yet, so the
  -- original/first tab stops showing a bare "1" once a second (named) tab appears.
  if not vim.t.name or vim.t.name == "" then
    vim.t.name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  end
  vim.cmd("tabnew")
  vim.cmd("tcd " .. vim.fn.fnameescape(opts.args))
  -- Name the tab after the project dir's basename so bufferline's right-side
  -- tabpage indicator shows e.g. "cva6" instead of a bare number (it renders the
  -- tab-local `name` var). Derive from getcwd() AFTER :tcd — it's normalized with
  -- no trailing slash, so :t always yields the basename (fnamemodify on the raw
  -- arg returns "" when the picker hands us a path with a trailing slash, which
  -- renders a blank tab label). Rename later with :BufferLineTabRename <name>.
  vim.t.name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  require("nvim-tree.api").tree.open()
end, { nargs = 1, complete = "dir", desc = "New tab scoped to a project dir" })

-- <leader>TP: fuzzy-pick a directory (fd --type d, rooted at the current cwd) and
-- open it as a scoped project tab. <CR> on a dir runs :TabProject on it. Falls
-- back to a typed vim.ui.input prompt if fd isn't installed.
keymap.set("n", "<leader>TP", function()
  local fd = vim.fn.executable("fd") == 1 and "fd" or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)
  if not fd then
    vim.ui.input({ prompt = "Project dir: ", completion = "dir" }, function(dir)
      if dir and dir ~= "" then vim.cmd("TabProject " .. vim.fn.fnameescape(dir)) end
    end)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local cwd = vim.fn.getcwd()

  pickers.new(require("telescope.themes").get_ivy(), {
    prompt_title = "Project dir → new scoped tab",
    cwd = cwd,
    finder = finders.new_oneshot_job(
      { fd, "--type", "d", "--hidden", "--exclude", ".git" },
      { cwd = cwd, entry_maker = require("telescope.make_entry").gen_from_file({ cwd = cwd }) }
    ),
    sorter = conf.file_sorter({}),
    previewer = false,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          vim.cmd("TabProject " .. vim.fn.fnameescape(entry.path or (cwd .. "/" .. entry.value)))
        end
      end)
      return true
    end,
  }):find()
end, { desc = "Pick a dir (fd) → new scoped tab" }) -- isolated explorer + pickers

-- quickfix list navigation (enhanced by nvim-bqf)
keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })
keymap.set("n", "]Q", "<cmd>clast<CR>", { desc = "Last quickfix item" })
keymap.set("n", "[Q", "<cmd>cfirst<CR>", { desc = "First quickfix item" })
-- Find an open quickfix OR location-list window in the current tabpage (both
-- have win.quickfix == 1). Location-list windows look identical to quickfix but
-- :cclose/:copen don't act on them — so detect by winid and close by winid,
-- which works for either. (Without this, pressing <leader>qc on a loclist was a
-- no-op, and <leader>qo opened a 2nd quickfix window stacked under the loclist.)
local function find_list_win()
  local cur_tab = vim.fn.tabpagenr()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.tabnr == cur_tab and win.quickfix == 1 then
      return win.winid
    end
  end
  return nil
end
keymap.set("n", "<leader>qo", function()
  local win = find_list_win()
  if win then
    pcall(vim.api.nvim_win_close, win, false) -- close whichever list window is open
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix list" })
keymap.set("n", "<leader>qc", function()
  local win = find_list_win()
  if win then
    pcall(vim.api.nvim_win_close, win, false)
  end
end, { desc = "Close quickfix/loclist window" })
keymap.set("n", "<leader>qf", function()
  local win = find_list_win()
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd("copen") -- not open yet → open and focus
  end
end, { desc = "Focus quickfix window" })
keymap.set("n", "<leader>ql", function()
  vim.fn.setqflist({
    {
      bufnr = vim.api.nvim_get_current_buf(),
      lnum = vim.fn.line("."),
      col = vim.fn.col("."),
      text = vim.fn.getline("."),
    },
  }, "a") -- "a" = append to the existing list
end, { desc = "Add current line to quickfix" })
-- Quickfix list STACK: nvim keeps up to 10 lists. Filtering in bqf (zn/zN) or a
-- new :vimgrep pushes a new list and keeps the previous one — walk the stack here.
-- Trouble's quickfix view always mirrors the CURRENT list, but :colder/:cnewer
-- don't fire QuickFixCmdPost, so refresh any open Trouble window after switching.
local function switch_qf_list(cmd)
  vim.cmd("silent! " .. cmd)
  if package.loaded["trouble"] then
    require("trouble").refresh() -- no-op if no Trouble window is open
  end
end
keymap.set("n", "<leader>q[", function() switch_qf_list("colder") end, { desc = "Older quickfix list" })
keymap.set("n", "<leader>q]", function() switch_qf_list("cnewer") end, { desc = "Newer quickfix list" })
keymap.set("n", "<leader>qx", function()
  vim.fn.setqflist({}, "r") -- empty the current list (keeps its slot in the stack)
end, { desc = "Clear quickfix list" })
-- Format every FILE referenced in the quickfix list (once per file), then save.
-- This is the qf-wide counterpart to <leader>vf / <leader>vF (single buffer).
-- Generic per-entry/per-file commands stay manual via :cdo / :cfdo.
keymap.set("n", "<leader>qF", function()
  if vim.tbl_isempty(vim.fn.getqflist()) then
    vim.notify("Quickfix list is empty", vim.log.levels.WARN)
    return
  end
  local cur = vim.api.nvim_get_current_buf()
  local ok, err = pcall(vim.cmd,
    [[cfdo lua require('conform').format({ lsp_fallback = true, timeout_ms = 3000 }) vim.cmd('update')]])
  pcall(vim.api.nvim_set_current_buf, cur) -- return to where we started
  vim.notify(
    ok and "Formatted all files in quickfix list" or ("Format-qf error: " .. tostring(err)),
    ok and vim.log.levels.INFO or vim.log.levels.ERROR
  )
end, { desc = "Format all files in quickfix list" })

-- Marks → quickfix. Collects only user-set LETTER marks: a–z from the current
-- buffer (lowercase marks are buffer-local) and A–Z global file marks (across
-- files, possibly unloaded). The volatile builtins ('<>[]^.`" etc) and numbered
-- shada marks are skipped on purpose — they move every time you jump, yank, or
-- edit, so they'd make the list stale the moment you navigate. Pushes a NEW qf
-- list (title "Marks") rather than replacing, so the previous list survives in
-- the stack and is reachable with <leader>q[ (:colder).
local function marks_to_qf()
  local items = {}
  local function add(m, bufnr, filename)
    local lnum, col = m.pos[2], m.pos[3]
    local letter = m.mark:sub(2) -- strip the leading "'"
    local loaded = bufnr and bufnr ~= 0 and vim.api.nvim_buf_is_loaded(bufnr)
    local line = loaded and (vim.fn.getbufline(bufnr, lnum)[1] or "") or ""
    items[#items + 1] = {
      bufnr = (bufnr and bufnr ~= 0) and bufnr or nil,
      filename = (not bufnr or bufnr == 0) and filename or nil,
      lnum = lnum,
      col = col,
      text = ("[%s] %s"):format(letter, (line:gsub("^%s+", ""))),
    }
  end
  -- lowercase a–z: buffer-local to the current buffer
  local cur = vim.api.nvim_get_current_buf()
  for _, m in ipairs(vim.fn.getmarklist(cur)) do
    if m.mark:match("^'%l$") then add(m, cur, nil) end
  end
  -- uppercase A–Z: global file marks (pos[1] is the bufnr if loaded, else 0)
  for _, m in ipairs(vim.fn.getmarklist()) do
    if m.mark:match("^'%u$") then add(m, m.pos[1], m.file) end
  end
  if vim.tbl_isempty(items) then
    vim.notify("No letter marks set (a–z in this buffer, A–Z global)", vim.log.levels.WARN)
    return false
  end
  -- sort by file/buffer then line so each file reads top-to-bottom
  table.sort(items, function(a, b)
    local fa = a.filename or (a.bufnr and vim.api.nvim_buf_get_name(a.bufnr)) or ""
    local fb = b.filename or (b.bufnr and vim.api.nvim_buf_get_name(b.bufnr)) or ""
    if fa ~= fb then return fa < fb end
    return (a.lnum or 0) < (b.lnum or 0)
  end)
  vim.fn.setqflist({}, " ", { title = "Marks", items = items })
  return true
end
keymap.set("n", "<leader>qm", function()
  if marks_to_qf() then
    local win = find_list_win()
    if win then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd("copen")
    end
  end
end, { desc = "Marks → quickfix list" })
keymap.set("n", "<leader>xm", function()
  if marks_to_qf() then
    vim.cmd("Trouble qflist open")
  end
end, { desc = "Marks → Trouble (quickfix view)" })

-- Named, on-disk quickfix lists. The qf STACK (<leader>q[/q]) is session-only and
-- unnamed; these maps persist a list under a name so it can be recalled in any
-- future session. Storage is one JSON file keyed by name; each entry records its
-- cwd + timestamp so the load/delete picker can disambiguate lists saved in
-- different projects. Gotcha: qf item bufnr is meaningless across sessions, so we
-- store absolute FILENAMES on save and let setqflist re-resolve them on load.
local NAMED_QF_FILE = vim.fn.stdpath("state") .. "/named-qf.json"
local function named_qf_read()
  local f = io.open(NAMED_QF_FILE, "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  local ok, tbl = pcall(vim.json.decode, raw)
  return (ok and type(tbl) == "table") and tbl or {}
end
local function named_qf_write(store)
  local f = io.open(NAMED_QF_FILE, "w")
  if not f then
    vim.notify("Could not write " .. NAMED_QF_FILE, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(store))
  f:close()
end
-- Render "name · 23 items · /abs/cwd · 2026-06-25" rows for the pickers.
local function named_qf_label(name, entry)
  local n = entry.items and #entry.items or 0
  return ("%s · %d item%s · %s · %s"):format(
    name, n, n == 1 and "" or "s", entry.cwd or "?", entry.saved_at or "?")
end
-- Pick one saved list by name via vim.ui.select (prettified by dressing.nvim).
local function named_qf_pick(store, prompt, on_choice)
  local names = vim.tbl_keys(store)
  if vim.tbl_isempty(names) then
    vim.notify("No saved quickfix lists", vim.log.levels.WARN)
    return
  end
  table.sort(names)
  vim.ui.select(names, {
    prompt = prompt,
    format_item = function(name) return named_qf_label(name, store[name]) end,
  }, function(name)
    if name then on_choice(name) end
  end)
end
keymap.set("n", "<leader>qS", function()
  local cur = vim.fn.getqflist({ items = 1, title = 1 })
  if vim.tbl_isempty(cur.items) then
    vim.notify("Quickfix list is empty — nothing to save", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "Save quickfix list as: ", default = cur.title ~= "" and cur.title or nil },
    function(name)
      if not name or name:match("^%s*$") then return end
      name = vim.trim(name)
      local items = {}
      for _, it in ipairs(cur.items) do
        items[#items + 1] = {
          filename = it.bufnr ~= 0 and vim.api.nvim_buf_get_name(it.bufnr) or "",
          lnum = it.lnum,
          col = it.col,
          text = it.text,
          type = it.type,
        }
      end
      local store = named_qf_read()
      local existed = store[name] ~= nil
      store[name] = { cwd = vim.fn.getcwd(), saved_at = os.date("%Y-%m-%d %H:%M"), items = items }
      named_qf_write(store)
      vim.notify(("%s quickfix list %q (%d items)"):format(
        existed and "Overwrote" or "Saved", name, #items), vim.log.levels.INFO)
    end)
end, { desc = "Save quickfix list (named)" })
keymap.set("n", "<leader>qL", function()
  local store = named_qf_read()
  named_qf_pick(store, "Load quickfix list:", function(name)
    -- Push as a NEW list so the current one survives in the stack (<leader>q[).
    vim.fn.setqflist({}, " ", { title = name, items = store[name].items })
    if package.loaded["trouble"] then require("trouble").refresh() end
    local win = find_list_win()
    if win then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd("copen")
    end
  end)
end, { desc = "Load quickfix list (named)" })
keymap.set("n", "<leader>qD", function()
  local store = named_qf_read()
  named_qf_pick(store, "Delete saved quickfix list:", function(name)
    store[name] = nil
    named_qf_write(store)
    vim.notify(("Deleted saved quickfix list %q"):format(name), vim.log.levels.INFO)
  end)
end, { desc = "Delete saved quickfix list" })

