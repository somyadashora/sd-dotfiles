-- marks.nvim's OWN numbered-bookmark feature (m0-m9, m}/m{, dm=, annotate)
-- overlaps with bookmarks.nvim (see plugins/bookmarks.lua), which is now the
-- single "bookmark" concept — persistent, named, list-organized, under <leader>m.
-- Disable every bookmark-group mapping here so the two don't collide conceptually;
-- regular letter marks (mx, m,, m;, m], m[, dm*) and `builtin_marks` stay.
local function disable_bookmark_mappings()
  local m = {
    delete_bookmark = false, -- dm=
    next_bookmark = false,   -- m}
    prev_bookmark = false,   -- m{
    annotate = false,
  }
  for i = 0, 9 do
    m["set_bookmark" .. i] = false    -- m0-m9
    m["delete_bookmark" .. i] = false -- dm0-dm9
    m["next_bookmark" .. i] = false
    m["prev_bookmark" .. i] = false
  end
  return m
end

return {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {
      default_mappings = true,
      mappings = disable_bookmark_mappings(),
      -- Trimmed: dropped [ ] ^ . so they don't crowd the 2-slot left sign
      -- column (shared with diagnostics/TODO; git has its own column via
      -- statuscol). The marks still work for jumping (`[, `], etc), they just
      -- no longer paint a sign. Keep visual bounds + last-jump.
      builtin_marks = { "<", ">", "'" },
      -- Never decorate scratch buffers: LSP hover/preview floats are nofile
      -- with signcolumn=auto, so a builtin-mark sign (') appearing on focus
      -- pops the gutter open and shifts the whole float's text sideways.
      excluded_buftypes = { "nofile" },
      cyclic = true,
      sign_priority = { lower = 15, upper = 20, builtin = 12, bookmark = 25 },
    },
  }


    -- mx              Set mark x
    -- m,              Set the next available alphabetical (lowercase) mark
    -- m;              Toggle the next available mark at the current line
    -- dmx             Delete mark x
    -- dm-             Delete all marks on the current line
    -- dm<space>       Delete all marks in the current buffer
    -- m]              Move to next mark
    -- m[              Move to previous mark
    -- m:              Preview mark. This will prompt you for a specific mark to
    --                 preview; press <cr> to preview the next mark.
    --
    -- (marks.nvim's m0-m9 / m} / m{ / dm= bookmark GROUPS are disabled above —
    -- persistent bookmarks now live in bookmarks.nvim under <leader>m.)