-- ══════════════════════════════════════════════════════
--  USER NOTES  ← add your own lines below
-- ══════════════════════════════════════════════════════
local user_notes = {
  -- "• example: <leader>xx does something I keep forgetting",
}

-- ──────────────────────────────────────────────────────

local sections = {
  -- ── Plugin sections ────────────────────────────────
  {
    title = "MARKS  (marks.nvim)",
    entries = {
      { "mx  /  m,",    "set mark x / next available letter mark" },
      { "'x  /  `x",    "jump to line start / exact col of mark x" },
      { "m]  /  m[",    "next / prev mark in buffer" },
      { "dm<Space>",    "delete all marks in buffer" },
      { "<leader>fM",   "telescope marks picker" },
    },
  },
  {
    title = "JUMPLIST",
    entries = {
      { "<C-o>  /  <C-i>",  "jump back / forward through jumplist" },
      { "<leader>fJ",        "telescope jumplist" },
    },
  },
  {
    title = "CHANGELIST",
    entries = {
      { "g;  /  g,",  "jump to older / newer change position" },
      { ":changes",    "view the full changelist" },
    },
  },
  {
    title = "LOCLIST / QUICKFIX  (Trouble)",
    entries = {
      { "<leader>xl",  "location list" },
      { "<leader>xq",  "quickfix list" },
      { "<leader>xw",  "workspace diagnostics" },
      { "<leader>xd",  "buffer diagnostics" },
      { "<leader>xT",  "all todos (workspace)" },
    },
  },
  {
    title = "QUICKFIX  (nvim-bqf — keys below work inside the qf window)",
    entries = {
      { "<leader>qo  /  qc", "toggle / close quickfix list" },
      { "<leader>qf",         "focus / jump to quickfix window" },
      { "<leader>Q",          "open quickfix list in fzf picker" },
      { "<leader>ql",         "append current line to quickfix" },
      { "]q  /  [q",          "next / prev quickfix item" },
      { "]Q  /  [Q",          "last / first quickfix item" },
      { "<C-q>  (telescope)", "send marked entries to quickfix" },
      { "zf",                  "fzf fuzzy-filter the quickfix list (needs fzf binary)" },
      { "z,",                  "toggle preview normal / maximized" },
      { "<C-f>  /  <C-b>",    "scroll preview down / up" },
      { "<C-n>  /  <C-p>",    "preview next / prev file" },
      { "o",                   "open item and close quickfix" },
      { "<C-v>  /  <C-x>",    "open item in vertical / horizontal split" },
      { "── bulk edit ──",    "run a command over the whole quickfix list" },
      { ":cdo {cmd}",          "run {cmd} on every ENTRY (matched line)" },
      { ":cfdo {cmd}",         "run {cmd} once per FILE in the list" },
      { ":cdo s/old/new/g | update",   "replace on each entry, then save" },
      { ":cfdo %s/old/new/g | update", "replace across each file, then save" },
      { ":cdo normal @q",      "run macro q on every entry" },
    },
  },
  {
    title = "FOLDS  (nvim-ufo)",
    entries = {
      { "za  /  zA",  "toggle fold / toggle all nested folds" },
      { "zc  /  zo",  "close / open fold under cursor" },
      { "zR  /  zM",  "open all / close all folds" },
    },
  },
  {
    title = "GIT  (gitsigns + lazygit)",
    entries = {
      { "]h  /  [h",          "next / prev hunk" },
      { "<leader>hs  /  hr",  "stage / reset hunk" },
      { "<leader>hp",         "preview hunk inline" },
      { "<leader>hb",         "blame line (full)" },
      { "<leader>hq  /  hQ",  "hunks → quickfix (buffer / all files)" },
      { "<leader>lg",         "open lazygit" },
    },
  },
  {
    title = "BUFFERS  (bufferline)",
    entries = {
      { "<S-h>  /  <S-l>",   "prev / next buffer" },
      { "<leader>B",          "telescope buffer picker (normal mode, d=close)" },
      { "<leader>bp  /  bn", "prev / next buffer" },
      { "<leader>bg  /  bC", "pick buffer / pick buffer to close" },
      { "<C-q>",              "close buffer, stay on active" },
    },
  },
  {
    title = "NVIM-TREE  (full help: <leader>eh)",
    entries = {
      { "<leader>ee",        "toggle tree" },
      { "<leader>ef",        "reveal current file in tree" },
      { "<leader>ec  /  er", "collapse / refresh tree" },
      { "<leader>e=  /  e-", "widen / narrow tree" },
      { "<CR>  /  <C-v>",    "open / open in vertical split" },
      { "a  /  d  /  r",     "create / delete / rename" },
      { "y  /  gy",          "copy filename / absolute path" },
      { "I  /  H",           "toggle gitignored / dotfiles" },
    },
  },
  {
    title = "CODE REVIEW  (code-review.nvim)",
    entries = {
      { "<leader>ra",        "add comment — quick single-line prompt" },
      { "<leader>rA",        "add comment — floating buffer (multi-line)" },
      { "<leader>re",        "edit comment nearest to cursor" },
      { "<leader>rd",        "delete comment on current line" },
      { "<leader>rl",        "list all comments" },
      { "<leader>rx",        "clear all comments" },
      { "<leader>rt",        "toggle annotation visibility" },
      { "]r  /  [r",         "next / prev comment in file" },
    },
  },
  {
    title = "SURROUND  (nvim-surround)",
    entries = {
      { "ys{motion}{c}",  "add surround  →  ysiw(  ysiw\"" },
      { "ds{c}",           "delete surround  →  ds(" },
      { "cs{c}{r}",        "change surround  →  cs([" },
      { "S{c}",            "(visual) surround selection with c" },
    },
  },
  {
    title = "ALIGN  (align.nvim — visual select first)",
    entries = {
      { "<leader>Ac",   "align to 1-char (with preview)" },
      { "<leader>A2c",  "align to 2-chars" },
      { "<leader>As",   "align to string" },
      { "<leader>Ar",   "align to regex" },
      { "<leader>Ap",   "(normal) align paragraph to string" },
    },
  },
  {
    title = "TODO COMMENTS",
    entries = {
      { "]t  /  [t",   "next / prev todo" },
      { "<leader>fT",  "telescope todos" },
      { "<leader>xT",  "trouble todos (workspace)" },
      { "keywords:",   "TODO  FIXME  REVIEW  PERF  SPEC  NOTE" },
    },
  },
  {
    title = "LSP / DIAGNOSTICS",
    entries = {
      { "gd  /  gD",    "definition / declaration" },
      { "gR",            "references (telescope)" },
      { "K",             "hover docs" },
      { "<leader>va",    "code action" },
      { "<leader>vr",    "smart rename" },
      { "<leader>vi",    "LSP info (active clients)" },
      { "<leader>vR",    "restart LSP" },
      { "[d  /  ]d",     "prev / next diagnostic" },
      { "<leader>d",     "line diagnostic float" },
    },
  },
  {
    title = "SLANG / SYSTEMVERILOG LSP  (:UseSlang to activate)",
    entries = {
      { ":UseSlang / :UseVerible", "switch active SV language server" },
      { "<leader>vd",   "trace signal drivers (slang only, incoming calls → quickfix)" },
      { "<leader>vl",   "trace signal loads (slang only, outgoing calls → quickfix)" },
    },
  },
  {
    title = "SV LSP PROJECT SETUP  (shell, run once at repo root)",
    entries = {
      { "slang-init",              "build .slang/server.json + .f filelist (def/refs/diags)" },
      { "slang-init -d . -t TOP",  "scan cwd, set top + build → enables cone tracing" },
      { "slang-init --regen-only", "rebuild only the .f after adding/removing files" },
      { "verible-init",            "build verible.filelist (.sv/.svh/.v) at repo root" },
      { "verible-init -d . --rules", "scan cwd + scaffold .rules.verible_lint" },
      { "<both> --force",          "overwrite existing config files" },
    },
  },

  -- ── Practical Vim tips ─────────────────────────────
  {
    title = "DOT COMMAND & REPETITION",
    entries = {
      { ".",          "repeat last change" },
      { "@:",         "repeat last Ex command" },
      { "&",          "repeat last :substitute on current line" },
      { "*  then cgn  then .", "find word → change → repeat for each match" },
    },
  },
  {
    title = "INDENT SCOPE  (mini.indentscope)",
    entries = {
      { "[i  /  ]i",  "jump to top / bottom of current indent scope" },
      { "ii",          "text object: inner indent scope  (e.g. dii, vii, >ii)" },
      { "ai",          "text object: around indent scope (includes border lines)" },
    },
  },
  {
    title = "TEXT OBJECTS  (work with any operator)",
    entries = {
      { "iw  /  aw",   "inner / around word" },
      { "is  /  as",   "inner / around sentence" },
      { "ip  /  ap",   "inner / around paragraph" },
      { 'i"  /  a"',   "inner / around double quotes  (also ' `)" },
      { "i(  /  a(",   "inner / around parens  (also [  {  <)" },
      { "it  /  at",   "inner / around HTML/XML tag" },
    },
  },
  {
    title = "REGISTERS",
    entries = {
      { '"0p',           "paste last yank (not clobbered by delete)" },
      { '"_d',           "delete to black hole — leaves registers clean" },
      { '"+y  /  "+p',  "yank to / paste from system clipboard" },
      { '"ay  /  "ap',  "yank / paste with named register a" },
      { "q:  /  q/",    "cmd-line history window / search history window" },
    },
  },
  {
    title = "MACROS",
    entries = {
      { "qq  …  q",    "record macro into register q" },
      { "@q  /  @@",   "replay q / replay last-used macro" },
      { "10@q",         "run macro 10 times" },
      { ":g/pat/@q",    "run macro on every line matching pat" },
    },
  },
  {
    title = "SEARCH & GLOBAL",
    entries = {
      { "*  /  #",           "search word under cursor fwd / back" },
      { "gn",                 "select next search match as a motion" },
      { ":%s/foo/bar/gc",     "substitute with confirm" },
      { ":g/pat/d",           "delete all lines matching pat" },
      { ":v/pat/d",           "delete all lines NOT matching pat" },
      { ":g/pat/norm @q",     "run macro q on every matching line" },
    },
  },
  {
    title = "INSERT MODE",
    entries = {
      { "<C-w>  /  <C-u>",  "delete back one word / to line start" },
      { "<C-r>{reg}",        "paste from register (e.g. <C-r>0 for yank)" },
      { "<C-o>{cmd}",        "run one normal cmd then return to insert" },
      { "<C-a>",             "insert text of last insert" },
    },
  },
  {
    title = "MOTIONS & TRICKS",
    entries = {
      { "%",          "jump to matching bracket / brace / tag" },
      { "ge  /  gE",  "back to end of prev word (lower / upper)" },
      { "H / M / L",  "cursor to screen top / middle / bottom" },
      { "gf",          "go to file path under cursor" },
      { "gv",          "reselect last visual selection" },
      { "xp",          "transpose two characters" },
      { "ddp",         "swap current line with the one below" },
    },
  },
}

-- ──────────────────────────────────────────────────────

local KEY_COL = 26  -- key column width; increase if keys get truncated

local function make_sep(title)
  local prefix = "  ── " .. title .. " "
  return prefix .. string.rep("─", math.max(4, 84 - #prefix))
end

local function build_lines()
  local lines = {}
  local hl_title = {}

  if #user_notes > 0 then
    table.insert(lines, make_sep("USER NOTES"))
    table.insert(hl_title, #lines)
    for _, note in ipairs(user_notes) do
      table.insert(lines, "  " .. note)
    end
    table.insert(lines, "")
  end

  for _, section in ipairs(sections) do
    table.insert(lines, make_sep(section.title))
    table.insert(hl_title, #lines)
    for _, entry in ipairs(section.entries) do
      local key, desc = entry[1], entry[2]
      local pad = string.rep(" ", math.max(2, KEY_COL - #key))
      table.insert(lines, "  " .. key .. pad .. desc)
    end
    table.insert(lines, "")
  end

  table.insert(lines, "  Add notes: edit user_notes at the top of lua/somya/cheatsheet.lua")

  return lines, hl_title
end

local function open()
  local lines, hl_title = build_lines()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width  = math.min(92, math.floor(vim.o.columns * 0.92))
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.90))
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "rounded",
    title     = "  Cheatsheet  ",
    title_pos = "center",
  })

  local ns = vim.api.nvim_create_namespace("somya_cheatsheet")
  for _, lnum in ipairs(hl_title) do
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", lnum - 1, 0, -1)
  end

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
  end
end

vim.keymap.set("n", "<leader>fH", open, { desc = "Open cheatsheet" })
