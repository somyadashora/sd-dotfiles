return {
  -- Harpoon 2: a curated, persistent "working set" of files you jump between with
  -- one keystroke. Telescope is for *discovery* (find any file); Harpoon is for
  -- the handful of files you're actively juggling — an RTL module, its TB, the
  -- Makefile, a tcl flow script. The list is per project root (cwd) and survives
  -- across sessions, so reopening a project restores your pinned files.
  --
  -- All maps live under the <leader>h ("+Harpoon") group so they're discoverable
  -- via which-key and don't collide with anything else.
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc })
    end

    -- Manage the list
    map("<leader>ha", function() harpoon:list():add() end, "Harpoon: add current file")
    map("<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Harpoon: toggle menu")

    -- Jump straight to a pinned slot (order shown in the menu)
    for i = 1, 4 do
      map("<leader>h" .. i, function() harpoon:list():select(i) end, "Harpoon: go to file " .. i)
    end

    -- Cycle through the list without opening the menu
    map("<leader>hn", function() harpoon:list():next() end, "Harpoon: next file")
    map("<leader>hp", function() harpoon:list():prev() end, "Harpoon: prev file")
  end,
}
