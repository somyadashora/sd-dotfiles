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
    title = "BOOKMARKS  (bookmarks.nvim — persistent, SQLite; help: <leader>m?)",
    entries = {
      { "<leader>mm",  "mark current line / rename bookmark" },
      { "<leader>mo",  "go to a bookmark in the active list (picker)" },
      { "<leader>md",  "add / edit description on bookmark" },
      { "<leader>mc",  "command palette — every bookmark action" },
      { "<leader>mv",  "toggle bookmark signs over code (show / hide)" },
      { "<leader>mt",  "toggle tree view of all lists / bookmarks" },
      { "<leader>ml  /  mn", "select active list / new list" },
      { "<leader>ms",  "grep across bookmarked files" },
      { "<leader>m]  /  m[", "next / prev bookmark" },
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
    title = "TROUBLE  (keys below work inside the Trouble window)",
    entries = {
      { "<leader>xw",  "diagnostics (workspace)" },
      { "<leader>xd",  "diagnostics (document)" },
      { "<leader>xs",  "symbols outline (right sidebar)" },
      { "<leader>xr",  "LSP defs/refs/impls for symbol (right)" },
      { "<leader>xq",  "quickfix list (Trouble view)" },
      { "<leader>xl",  "location list (Trouble view)" },
      { "<leader>xt  /  xT", "todos (document / workspace)" },
      { "<leader>xm",  "marks → Trouble (a–z this buffer, A–Z global)" },
      { "── inside Trouble window ──", "" },
      { "<cr>  /  o",        "jump to item / jump and close" },
      { "<C-s>  /  <C-v>",  "open item in split / vsplit" },
      { "dd  /  (v)d",      "delete item(s) from the Trouble list (view only)" },
      { "}  ]]  /  {  [[",  "next / prev item" },
      { "p  /  P",          "preview / toggle auto-preview" },
      { "zo  zc  za",        "fold open / close / toggle" },
      { "r  /  R",          "refresh / toggle auto-refresh" },
    },
  },
  {
    title = "QUICKFIX  (nvim-bqf — keys below work inside the qf window)",
    entries = {
      { "<leader>qo  /  qc", "toggle / close quickfix list" },
      { "<leader>qf",         "focus / jump to quickfix window" },
      { "<leader>Q",          "open quickfix list in fzf picker" },
      { "<leader>ql",         "append current line to quickfix" },
      { "<leader>qm",         "marks → quickfix (a–z this buffer, A–Z global; skips builtins/numbered)" },
      { "<leader>qx",         "clear (empty) the quickfix list" },
      { "<leader>qF",         "format every file in the quickfix list (conform), then save" },
      { "]q  /  [q",          "next / prev quickfix item" },
      { "]Q  /  [Q",          "last / first quickfix item" },
      { "<leader>q[ / q]",    "older / newer quickfix list (:colder/:cnewer, refreshes Trouble)" },
      { "<leader>qS / qL / qD", "save / load / delete a NAMED quickfix list (persists to disk)" },
      { "<C-q>  (telescope)", "send marked entries to quickfix" },
      { "<C-y>  (telescope)", "yank marked/current entries to unnamed register" },
      { "── inside qf window (nvim-bqf) ──", "" },
      { "<Tab> / <S-Tab>",    "mark / unmark entry, move down / up" },
      { "z<Tab>",              "clear all marks" },
      { "zn",                  "new list from MARKED entries (old list kept in stack)" },
      { "zN",                  "new list from UNMARKED entries" },
      { "zf",                  "fzf fuzzy-filter the quickfix list (needs fzf binary)" },
      { "o",                   "open item and close quickfix" },
      { "<C-v>  /  <C-x>",    "open item in vertical / horizontal split" },
      { "<C-t>",               "open item in new tab" },
      { "── bulk edit ──",    "run a command over the whole quickfix list" },
      { "<leader>qh",          "full :cdo / :cfdo examples in a help window" },
      { ":cdo {cmd}",          "run {cmd} on every ENTRY (matched line)" },
      { ":cfdo {cmd}",         "run {cmd} once per FILE in the list" },
      { ":cdo normal gcc → :wall",     "toggle-comment every entry's line" },
      { ":cdo s/old/new/g | update",   "replace on each entry, then save" },
      { ":cfdo %s/old/new/g | update", "replace across each file, then save" },
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
      { "]h  /  [h",          "next / prev hunk (echoes \"Change 1 of 5\")" },
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
    title = "SNEAK  (vim-sneak — motions cross lines)",
    entries = {
      { "f{c}  /  F{c}",  "to char, forward / back — multi-line" },
      { "t{c}  /  T{c}",  "till char, forward / back — multi-line" },
      { "s{ab}  /  S{ab}", "2-char sneak, forward / back" },
      { ";  /  ,",         "repeat last f/t/s, next / prev (crosses lines)" },
      { "Z{ab}",           "(visual) 2-char sneak back — S stays surround" },
      { "z / Z {ab}",      "(operator) 2-char sneak  →  dzab" },
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
    title = "YANK RING  (yanky.nvim — history of yanks & deletes)",
    entries = {
      { "y  /  p  /  P",  "work as normal, but tracked in the ring (y keeps cursor put)" },
      { "[y  /  ]y",       "right after a put: swap pasted text for prev / next entry" },
      { "gp  /  gP",       "put, leaving cursor after the pasted text" },
      { "<leader>y",       "telescope yank-history picker (<CR> put, <C-x> delete)" },
      { "d / c / x",       "deletes enter the ring too — recover via <leader>y" },
      { ":YankyClearHistory", "wipe the ring (persists via shada otherwise)" },
      { "<leader>Yy / Ya", "yank file:line ref, relative / absolute path (visual: file:10-20)" },
      { "<leader>Yc",      "yank file:line:col + the line's text (visual: ref header + lines)" },
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
      { "]t  /  [t",   "next / prev todo (echoes \"TODO 3 of 4\")" },
      { "<leader>fT",  "telescope todos" },
      { "<leader>xT",  "trouble todos (workspace)" },
      { "keywords:",   "TODO  FIXME  REVIEW  PERF  SPEC  NOTE" },
    },
  },
  {
    title = "LSP / DIAGNOSTICS",
    entries = {
      { "gd",            "definition (telescope)" },
      { "gR",            "references (telescope)" },
      { "gO",            "document symbols (nvim built-in)" },
      { "gri / grt / grn", "impl / type-def / rename (nvim built-in defaults)" },
      { "K",             "hover docs" },
      { "<leader>va",    "code action" },
      { "<leader>vr",    "smart rename" },
      { "<leader>vi",    "LSP info (active clients)" },
      { "<leader>vR",    "restart LSP" },
      { "<leader>vF",    "format file/range (auto formatter, LSP fallback)" },
      { "<leader>vf",    "format & align with Verible (SystemVerilog)" },
      { "[d  /  ]d",     "prev / next diagnostic (echoes \"Warn 2 of 7\")" },
      { "<leader>d",     "line diagnostic float" },
    },
  },
  {
    title = "SLANG / SYSTEMVERILOG LSP  (:UseSlang to activate)",
    entries = {
      { ":UseSlang / :UseVerible", "switch active SV language server" },
      { "<leader>vd",   "trace signal drivers (slang only, incoming calls → Trouble)" },
      { "<leader>vl",   "trace signal loads (slang only, outgoing calls → Trouble)" },
      { "<leader>vm",   "instances of module under cursor (hier paths → Trouble)" },
      { "<leader>vp",   "yank hier path of instance under cursor (top.u_a.u_b)" },
      { "<leader>vs",   "browse scope: ports/params/nets + resolved values" },
      { "<leader>vx",   "expand macros in this file (scratch buffer, side by side)" },
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
    title = "MOVE & COPY LINES  (:m = :move, :t = :copy)",
    entries = {
      { ":t 23",          "copy current line to BELOW line 23" },
      { ":m +5",          "move current line DOWN 5 lines" },
      { ":m +17",         "move current line down 17 lines" },
      { ":m -2",          "move current line UP one line" },
      { ":t .",           "duplicate current line (copy below itself)" },
      { ":t 0  /  :m 0",  "copy / move line to TOP of file" },
      { ":t $  /  :m $",  "copy / move line to BOTTOM of file" },
      { ":t `m",          "copy current line below mark m's line" },
      { ":m `m-1",        "move current line just ABOVE mark m" },
      { ":m 'a",          "move current line below mark a's line" },
      { ":'<,'>m 0",      "(visual) move selection to top of file" },
      { ":'<,'>t .",      "(visual) duplicate selection below itself" },
      { ":t/pat/",        "copy current line below next /pat/ match" },
      { "── pull another line/range HERE (dest = . ) ──", "" },
      { ":23m .",         "move line 23 to below current line" },
      { ":23t .",         "copy line 23 to below current line" },
      { ":23m .-1",       "move line 23 to ABOVE current line" },
      { ":10,15m .",      "move lines 10-15 below current line" },
      { ":10,15t .",      "copy lines 10-15 below current line" },
      { ":'a,'bm .",      "move marked range 'a-'b below current" },
      { ":/pat/m .",      "move next /pat/ line below current" },
    },
  },
  {
    title = "FIND & SEARCH  (telescope)",
    entries = {
      { "── leader mirrors native, widens to repo ──", "" },
      { "*  →  <leader>*",  "word under cursor: buffer / repo (grep)" },
      { "/  →  <leader>/",  "search: buffer / repo (live grep)" },
      { "<leader>fb",        "fuzzy line search in current buffer" },
      { "<leader>fs",        "live grep in cwd (repo)" },
      { "── files ──", "" },
      { "<leader>ff  /  fi", "find files (cwd / + hidden & ignored)" },
      { "<leader>fr",         "recent files (oldfiles)" },
      { "<leader>fT",         "find TODOs" },
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
    title = "INSERT — EXIT",
    entries = {
      { "<Esc>  /  <C-[>",  "back to normal mode (identical)" },
      { "<C-c>",             "exit insert, skip abbrev + InsertLeave" },
    },
  },
  {
    title = "INSERT — DELETE",
    entries = {
      { "<C-h>",  "delete char before cursor (backspace)" },
      { "<C-w>",  "delete word before cursor" },
      { "<C-u>",  "delete to line start before cursor" },
    },
  },
  {
    title = "INSERT — MOVE & INDENT",
    entries = {
      { "<Up>/<Down>/<Left>/<Right>",  "move cursor by char / line" },
      { "<C-g>j  /  <C-g>k", "line down / up, to insert-start column" },
      { "<C-t>",  "indent line one shiftwidth" },
      { "<C-d>",  "outdent line one shiftwidth" },
    },
  },
  {
    title = "INSERT — COPY & PASTE",
    entries = {
      { "<C-r>{reg}",  "paste register (e.g. <C-r>0, <C-r>+)" },
      { "<C-r>=",       "expression register — eval math/logic" },
      { "<C-y>",        "copy char directly above cursor" },
      { "<C-e>",        "copy char directly below cursor" },
    },
  },
  {
    title = "INSERT — CMD & COMPLETION",
    entries = {
      { "<C-o>{cmd}",      "run one normal cmd, return to insert" },
      { "<C-n>  /  <C-p>", "keyword completion: down / up" },
      { "<C-x>",            "completion submode (<C-x><C-f> path, <C-o> omni)" },
      { "<C-v>{char}",     "insert next key literally" },
      { "<C-a>",            "re-insert text of last insert session" },
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
-- Focused :cdo / :cfdo quickfix batch-command help (opened with <leader>qh).
-- Same renderer as the full cheatsheet, just a different dataset + window size.
local qf_sections = {
  {
    title = "BASICS",
    entries = {
      { ":cdo {cmd}",   "run {cmd} once per ENTRY (every matched line)" },
      { ":cfdo {cmd}",  "run {cmd} once per FILE in the list" },
      { ":ldo / :lfdo", "same, but for the LOCATION list" },
      { "save after",   "edits leave buffers modified → finish with :wall" },
      { "rule of thumb", "line-specific → :cdo   •   whole-file → :cfdo" },
    },
  },
  {
    title = "NORMAL-MODE KEYS  (wrap mapped keys in :normal, not normal!)",
    entries = {
      { ":cdo normal gcc",        "toggle-comment each qf line        (then :wall)" },
      { ":cdo normal A;<Esc>",    "append ';' to each line            (then :wall)" },
      { ":cdo normal I// <Esc>",  "prepend '// ' to each line         (then :wall)" },
      { ":cdo normal @q",         "replay macro q on each entry       (then :wall)" },
      { ":cfdo normal gg=G",      "reindent each whole file           (then :wall)" },
      { "why 'normal'",           "normal! ignores mappings — gcc needs plain normal" },
    },
  },
  {
    title = ":execute  (quote :normal so you can chain a save with | )",
    entries = {
      { [[:cdo execute "normal gcc" | update]],     "comment + save, per entry" },
      { [[:cdo execute "normal A;\<Esc>" | update]], "append ';' + save, per entry" },
      { [[:cfdo execute "normal gg=G" | update]],   "reindent + save, per file" },
      { "the gotcha",  "bare :normal eats the rest of the line, so a trailing" },
      { "",            "| update would become keystrokes — :execute fixes it" },
    },
  },
  {
    title = "EX COMMANDS  (no :normal — | update works directly)",
    entries = {
      { [[:cdo s/\<TODO\>/DONE/g | update]],        "substitute on each entry's line" },
      { [[:cfdo %s/old_api/new_api/g | update]],    "rename across every file in the list" },
      { [[:cfdo %!sort | update]],                  "pipe each whole file through `sort`" },
      { [[:cdo s/$/;/ | update]],                   "append ';' to each entry's line (no :normal)" },
      { [[:cfdo g/^\s*$/d | update]],               "delete blank lines in each file (careful)" },
    },
  },
  {
    title = "COMMENT THE WHOLE LIST  (Comment.nvim)",
    entries = {
      { ":cdo normal gcc   →  :wall",  "toggle — may cancel out on duplicate lines" },
      { ":cdo lua require('Comment.api').comment.linewise.current()", "" },
      { "   →  :wall",                  "always COMMENTS (no toggle) — safe with dups" },
      { ":cdo lua require('Comment.api').uncomment.linewise.current()", "" },
      { "   →  :wall",                  "always uncomments each entry's line" },
    },
  },
  {
    title = "GOTCHAS",
    entries = {
      { "per entry vs file",  ":cdo = each line  •  :cfdo = each file (once)" },
      { "normal vs normal!",  "normal uses your mappings (gcc); normal! does not" },
      { ":normal / :lua",     "consume the line → use :execute, or a trailing :wall" },
      { "needs 'hidden'",     "(on here) so it can hop modified buffers before save" },
      { "no line-shifting",   "avoid dd/J in :cdo — later entries' lnums go stale" },
      { "stops on error",     "prefix with silent! to push past failures" },
    },
  },
}

-- ──────────────────────────────────────────────────────

local function make_sep(title, sep_width)
  local prefix = "  ── " .. title .. " "
  return prefix .. string.rep("─", math.max(4, (sep_width or 84) - #prefix))
end

-- Render a list of {title, entries={{key, desc}, …}} sections into a float.
-- opts: include_user_notes, footer, title, max_width, key_col, sep_width.
-- An entry with an empty desc renders as a key-only line (for sub-headers /
-- long commands that don't need a trailing description column).
local function build_lines(secs, opts)
  opts = opts or {}
  local key_col = opts.key_col or 26
  local sep_width = opts.sep_width or 84
  local lines = {}
  local hl_title = {}

  if opts.include_user_notes and #user_notes > 0 then
    table.insert(lines, make_sep("USER NOTES", sep_width))
    table.insert(hl_title, #lines)
    for _, note in ipairs(user_notes) do
      table.insert(lines, "  " .. note)
    end
    table.insert(lines, "")
  end

  for _, section in ipairs(secs) do
    table.insert(lines, make_sep(section.title, sep_width))
    table.insert(hl_title, #lines)
    for _, entry in ipairs(section.entries) do
      local key, desc = entry[1], entry[2] or ""
      if desc == "" then
        table.insert(lines, "  " .. key)
      else
        local pad = string.rep(" ", math.max(2, key_col - #key))
        table.insert(lines, "  " .. key .. pad .. desc)
      end
    end
    table.insert(lines, "")
  end

  if opts.footer then
    table.insert(lines, opts.footer)
  end

  return lines, hl_title
end

local function open(secs, opts)
  opts = opts or {}
  local lines, hl_title = build_lines(secs, opts)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width  = math.min(opts.max_width or 92, math.floor(vim.o.columns * 0.92))
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
    title     = opts.title or "  Cheatsheet  ",
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

-- ── NvChad-style grid cheatsheet (for <leader>fH) ──────
-- Each section becomes a colored "card"; cards are packed into balanced columns
-- that fill the window, like NvChad's NvCheatsheet.

local N_HEAD = 8
local function set_grid_hl()
  local heads = { "#f7768e", "#e0af68", "#9ece6a", "#7dcfff", "#bb9af7", "#7aa2f7", "#2ac3de", "#ff9e64" }
  for i, c in ipairs(heads) do
    vim.api.nvim_set_hl(0, "SdCheatHead" .. i, { fg = "#16161e", bg = c, bold = true })
  end
  vim.api.nvim_set_hl(0, "SdCheatKey", { fg = "#16161e", bg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "SdCheatKey2", { fg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "SdCheatDesc", { fg = "#c0caf5" })
  vim.api.nvim_set_hl(0, "SdCheatDivider", { fg = "#7f8bb0", italic = true })
end

-- Replace ambiguous-width glyphs with ASCII. strdisplaywidth() trusts
-- 'ambiwidth' (single) and counts these as 1, but many terminals render them as
-- 2 cells, which desyncs the grid and clips the right column. Keeping the grid
-- pure-ASCII makes nvim's width math match what the terminal actually draws.
local ascii_map = {
  { "→", "->" }, { "←", "<-" }, { "—", "-" }, { "–", "-" },
  { "…", "..." }, { "·", "-" }, { "─", "-" }, { "•", "*" },
}
local function to_ascii(s)
  for _, m in ipairs(ascii_map) do
    s = s:gsub(m[1], m[2])
  end
  return s
end

local function dwidth(s) return vim.fn.strdisplaywidth(s) end
local function dpad(s, w)
  local d = dwidth(s)
  return d >= w and s or (s .. string.rep(" ", w - d))
end
local function dtrunc(s, w)
  if dwidth(s) <= w then return s end
  for i = vim.fn.strchars(s), 1, -1 do
    local part = vim.fn.strcharpart(s, 0, i)
    if dwidth(part) <= w - 3 then return part .. "..." end
  end
  return "..."
end

-- Build the padded cell-lines (each exactly col_w wide) for one section card.
-- Every entry is a single line so the cards stay uniform (NvChad-style): the
-- description sits left and the key sits in a pill on the right, with the
-- description truncated to whatever space the key leaves.
local function build_card(section, col_w, color_idx)
  local cells = {}
  local head_hl = "SdCheatHead" .. ((color_idx - 1) % N_HEAD + 1)
  local title = dtrunc(to_ascii(section.title), col_w - 2)
  local lpad = math.floor((col_w - dwidth(title)) / 2)
  local htext = dpad(string.rep(" ", lpad) .. title, col_w)
  table.insert(cells, { text = htext, hls = { { head_hl, 0, #htext } } })

  for _, e in ipairs(section.entries) do
    local is_div = (e[1]):find("──", 1, true) ~= nil
    local key, desc = to_ascii(e[1]), to_ascii(e[2] or "")
    if is_div then -- in-section sub-divider
      local t = dpad(" " .. dtrunc(key, col_w - 1), col_w)
      table.insert(cells, { text = t, hls = { { "SdCheatDivider", 0, #t } } })
    elseif key == "" then -- desc-only line (e.g. user notes)
      local t = dpad(" " .. dtrunc(desc, col_w - 1), col_w)
      table.insert(cells, { text = t, hls = { { "SdCheatDesc", 1, #t } } })
    elseif desc == "" then -- key/command-only line
      local t = dpad(" " .. dtrunc(key, col_w - 1), col_w)
      table.insert(cells, { text = t, hls = { { "SdCheatKey2", 1, #t } } })
    else -- desc left (truncated), key pill right — always one line
      local keyt = dtrunc(key, col_w - 6)
      local keyp = " " .. keyt .. " "
      local maxdesc = math.max(1, col_w - dwidth(keyp) - 2)
      local desc_t = dtrunc(desc, maxdesc)
      local left = dpad(" " .. desc_t, col_w - dwidth(keyp))
      table.insert(cells, {
        text = left .. keyp,
        hls = { { "SdCheatDesc", 1, 1 + #desc_t }, { "SdCheatKey", #left, #left + #keyp } },
      })
    end
  end
  return cells
end

-- Stretch columns to fill the window: pick a column count from the available
-- width (min ~40 wide, up to 3 columns) then widen each column to fill.
local function open_grid(secs, win_title)
  set_grid_hl()
  local gap = 3
  local avail = math.min(vim.o.columns - 6, math.floor(vim.o.columns * 0.92))
  local ncols = math.max(1, math.min(3, math.floor(avail / (40 + gap))))
  local col_w = math.floor((avail - (ncols - 1) * gap) / ncols)
  local win_w = ncols * col_w + (ncols - 1) * gap

  -- optional user-notes card first
  local cards = {}
  if #user_notes > 0 then
    local notes = { title = "USER NOTES", entries = {} }
    for _, n in ipairs(user_notes) do
      table.insert(notes.entries, { "", n })
    end
    table.insert(cards, notes)
  end
  for _, s in ipairs(secs) do
    table.insert(cards, s)
  end

  -- pack each card into the currently-shortest column
  local cols, heights = {}, {}
  for i = 1, ncols do cols[i], heights[i] = {}, 0 end
  for idx, section in ipairs(cards) do
    local cells = build_card(section, col_w, idx)
    local mi = 1
    for i = 2, ncols do if heights[i] < heights[mi] then mi = i end end
    for _, cell in ipairs(cells) do table.insert(cols[mi], cell) end
    table.insert(cols[mi], { text = string.rep(" ", col_w), hls = {} }) -- spacer row
    heights[mi] = heights[mi] + #cells + 1
  end
  local maxh = 0
  for i = 1, ncols do maxh = math.max(maxh, heights[i]) end

  -- assemble rows side by side, collecting byte-accurate highlights
  local blank = string.rep(" ", col_w)
  local lines, hls = {}, {}
  for r = 1, maxh do
    local row, line_idx = "", #lines
    for c = 1, ncols do
      local cell = cols[c][r] or { text = blank, hls = {} }
      local start = #row
      row = row .. cell.text
      for _, h in ipairs(cell.hls) do
        table.insert(hls, { h[1], line_idx, start + h[2], start + h[3] })
      end
      if c < ncols then row = row .. string.rep(" ", gap) end
    end
    table.insert(lines, row)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local height = math.min(#lines, math.floor(vim.o.lines * 0.85))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_w,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - win_w) / 2),
    style = "minimal",
    border = "rounded",
    title = win_title,
    title_pos = "center",
  })
  vim.wo.wrap = false
  vim.wo.cursorline = false
  -- 'style=minimal' clears the gutters once, but plugins re-enable a sign/fold
  -- column after attach, which shifts the no-wrap rows right and clips the last
  -- column. Force every gutter off and kill side-scroll so the grid stays put.
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.sidescrolloff = 0
  vim.wo.scrolloff = 0

  local ns = vim.api.nvim_create_namespace("somya_cheatsheet_grid")
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, h[1], h[2], h[3], h[4])
  end
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
  end
end

-- Full keymap cheatsheet (NvChad-style grid)
local function open_cheatsheet()
  open_grid(sections, "  sd-nvim cheatsheet  ")
end

-- Focused :cdo / :cfdo quickfix batch-command help
local function open_qf_help()
  open(qf_sections, {
    footer = "  Full keymap reference: <leader>fH",
    max_width = 100,
    key_col = 50,
    sep_width = 96,
    title = "  :cdo / :cfdo — quickfix batch commands  ",
  })
end

vim.keymap.set("n", "<leader>fH", open_cheatsheet, { desc = "Open cheatsheet" })
vim.keymap.set("n", "<leader>qh", open_qf_help, { desc = "Quickfix :cdo/:cfdo help" })

-- Commands so other UI (e.g. the alpha dashboard buttons) can trigger these.
vim.api.nvim_create_user_command("Cheatsheet", open_cheatsheet, { desc = "Open the keymap cheatsheet" })
vim.api.nvim_create_user_command("QfHelp", open_qf_help, { desc = "Open the :cdo/:cfdo quickfix help" })

-- Expose the float renderers so other modules can render their own help popups
-- with the same look (e.g. telekasten's <leader>Z? notes help). `open` takes a
-- list of {title, entries={{key, desc}, …}} sections + an opts table (title,
-- max_width, key_col, sep_width, footer, include_user_notes).
return { open = open, open_grid = open_grid }
