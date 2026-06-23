return {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {
      default_mappings = true,
      -- Trimmed: dropped [ ] ^ . so they don't crowd the 2-slot left sign
      -- column (shared with diagnostics/TODO; git has its own column via
      -- statuscol). The marks still work for jumping (`[, `], etc), they just
      -- no longer paint a sign. Keep visual bounds + last-jump.
      builtin_marks = { "<", ">", "'" },
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
                    
    -- m[0-9]          Add a bookmark from bookmark group[0-9].
    -- dm[0-9]         Delete all bookmarks from bookmark group[0-9].
    -- m}              Move to the next bookmark having the same type as the bookmark under
    --                 the cursor. Works across buffers.
    -- m{              Move to the previous bookmark having the same type as the bookmark under
    --                 the cursor. Works across buffers.
    -- dm=             Delete the bookmark under the cursor.