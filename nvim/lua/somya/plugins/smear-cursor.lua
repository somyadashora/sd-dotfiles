-- smear-cursor.nvim – animated cursor movement
-- Four profiles cycled with <leader>cs, or jumped to with <leader>c1/c2/c3/c4
--
-- Profiles:
--   1  default   – stock smear (stiffness 0.6, trailing 0.45)
--   2  fast      – snappier smear (stiffness 0.8, trailing 0.65, damping 0.95)
--   3  smooth    – single-block glide, no comet trail (max_length 1)
--   4  comet     – long tail + fast head (stiffness 0.9, max_length 40)

return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  config = function()
    local smear = require("smear_cursor")

    -- ─── Profile definitions ──────────────────────────────────────────────
    local profiles = {
      {
        id    = "default",
        label = "Default smear",
        -- Standard out-of-the-box feel
        stiffness                    = 0.6,
        trailing_stiffness           = 0.45,
        damping                      = 0.85,
        trailing_exponent            = 3,
        max_length                   = 25,
        distance_stop_animating      = 0.1,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
      {
        id    = "fast",
        label = "Fast smear",
        -- Higher stiffness/damping → snappier, shorter comet tail
        stiffness                    = 0.8,
        trailing_stiffness           = 0.65,
        damping                      = 0.95,
        trailing_exponent            = 3,
        max_length                   = 12,
        distance_stop_animating      = 0.1,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
      {
        id    = "smooth",
        label = "Smooth (no smear)",
        -- max_length=1 collapses the trail; cursor glides as a single block
        stiffness                    = 0.5,
        trailing_stiffness           = 0.5,
        damping                      = 0.9,
        trailing_exponent            = 1,
        max_length                   = 1,
        distance_stop_animating      = 0.05,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = false,
      },
      {
        id    = "comet",
        label = "Comet (long tail, fast)",
        -- High head stiffness for snap; low trailing stiffness lets the tail stretch far
        stiffness                    = 0.9,
        trailing_stiffness           = 0.2,
        damping                      = 0.85,
        trailing_exponent            = 5,
        max_length                   = 40,
        distance_stop_animating      = 0.1,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
    }

    -- ─── Apply a profile by index ─────────────────────────────────────────
    local current_idx = 1

    local function apply(idx)
      local p = profiles[idx]
      smear.setup({
        stiffness                    = p.stiffness,
        trailing_stiffness           = p.trailing_stiffness,
        damping                      = p.damping,
        trailing_exponent            = p.trailing_exponent,
        max_length                   = p.max_length,
        distance_stop_animating      = p.distance_stop_animating,
        smear_between_buffers        = p.smear_between_buffers,
        smear_between_neighbor_lines = p.smear_between_neighbor_lines,
      })
      current_idx = idx
      vim.notify("Cursor › " .. p.label, vim.log.levels.INFO, { title = "smear-cursor" })
    end

    -- Start with default profile
    apply(1)

    -- ─── Keybindings ──────────────────────────────────────────────────────
    -- Cycle through all profiles
    vim.keymap.set("n", "<leader>cs", function()
      apply((current_idx % #profiles) + 1)
    end, { desc = "Cursor: cycle style" })

    -- Jump directly to a profile
    vim.keymap.set("n", "<leader>c1", function() apply(1) end,
      { desc = "Cursor: default smear" })
    vim.keymap.set("n", "<leader>c2", function() apply(2) end,
      { desc = "Cursor: fast smear" })
    vim.keymap.set("n", "<leader>c3", function() apply(3) end,
      { desc = "Cursor: smooth (no smear)" })
    vim.keymap.set("n", "<leader>c4", function() apply(4) end,
      { desc = "Cursor: comet (long tail, fast)" })
  end,
}
