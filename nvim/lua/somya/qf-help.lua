-- Quickfix batch-command help (:cdo / :cfdo) — opened with <leader>qh.
-- Mirrors the look of somya.cheatsheet but focused on running commands over the
-- whole quickfix list. The generic per-entry/per-file power lives in these Ex
-- commands; the <leader>q* keymaps cover the common one-shot operations.

local sections = {
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

local KEY_COL = 50 -- command column width; long commands fall back to a 2-space gap

local function make_sep(title)
  local prefix = "  ── " .. title .. " "
  return prefix .. string.rep("─", math.max(4, 96 - #prefix))
end

local function build_lines()
  local lines = {}
  local hl_title = {}
  for _, section in ipairs(sections) do
    table.insert(lines, make_sep(section.title))
    table.insert(hl_title, #lines)
    for _, entry in ipairs(section.entries) do
      local key, desc = entry[1], entry[2]
      if desc == "" then
        table.insert(lines, "  " .. key)
      else
        local pad = string.rep(" ", math.max(2, KEY_COL - #key))
        table.insert(lines, "  " .. key .. pad .. desc)
      end
    end
    table.insert(lines, "")
  end
  table.insert(lines, "  Full keymap reference: <leader>fH")
  return lines, hl_title
end

local function open()
  local lines, hl_title = build_lines()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(100, math.floor(vim.o.columns * 0.95))
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.90))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "  :cdo / :cfdo — quickfix batch commands  ",
    title_pos = "center",
  })

  local ns = vim.api.nvim_create_namespace("somya_qf_help")
  for _, lnum in ipairs(hl_title) do
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", lnum - 1, 0, -1)
  end

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
  end
end

vim.keymap.set("n", "<leader>qh", open, { desc = "Quickfix :cdo/:cfdo help" })
