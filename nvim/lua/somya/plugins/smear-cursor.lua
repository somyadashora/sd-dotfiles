-- smear-cursor.nvim – animated cursor movement
-- Five profiles cycled with <leader>cs, or jumped to with <leader>c1–c5
--
-- Profiles:
--   1  default   – stock smear (stiffness 0.6, trailing 0.45)
--   2  fast      – snappier smear (stiffness 0.8, trailing 0.65, damping 0.95)
--   3  smooth    – single-block glide, no comet trail (max_length 1)
--   4  comet     – long tail + fast head (stiffness 0.9, max_length 40)
--   5  ember     – particles + orange cursor, elastic feel

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
        stiffness                    = 0.6,
        trailing_stiffness           = 0.45,
        damping                      = 0.85,
        trailing_exponent            = 3,
        max_length                   = 25,
        distance_stop_animating      = 0.1,
        cursor_color                 = "auto",
        particles_enabled            = false,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
      {
        id    = "fast",
        label = "Fast smear",
        stiffness                    = 0.8,
        trailing_stiffness           = 0.65,
        damping                      = 0.95,
        trailing_exponent            = 3,
        max_length                   = 12,
        distance_stop_animating      = 0.1,
        cursor_color                 = "auto",
        particles_enabled            = false,
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
        cursor_color                 = "auto",
        particles_enabled            = false,
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
        cursor_color                 = "auto",
        particles_enabled            = false,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
      {
        id                           = "ember",
        label                        = "Ember (particles, light blue)",
        stiffness                    = 0.8,
        trailing_stiffness           = 0.6,
        stiffness_insert_mode        = 0.7,
        damping                      = 0.85,
        time_interval                = 7,
        cursor_color                 = "#00d4ff",
        particles_enabled            = true,
        particle_count               = 1,
        smear_between_buffers        = true,
        smear_between_neighbor_lines = true,
      },
    }

    -- ─── Cursor colour palette (bright, visible over all highlights) ──────
    local cursor_colors = {
      { name = "Cyan",    color = "#00d4ff" },
      { name = "Magenta", color = "#ff79c6" },
      { name = "Red",     color = "#ff5555" },
      { name = "White",   color = "#f8f8f2" },
      { name = "Purple",  color = "#bd93f9" },
    }
    local current_color_idx = 3 -- default: red

    -- ─── Apply a profile by index ─────────────────────────────────────────
    local current_idx = 1

    local function apply(idx)
      local p = profiles[idx]
      local cfg = {}
      for k, v in pairs(p) do
        if k ~= "id" and k ~= "label" then
          cfg[k] = v
        end
      end
      local color = cursor_colors[current_color_idx].color
      cfg.cursor_color = color
      smear.setup(cfg)
      current_idx = idx
    end

    -- Start with comet profile
    apply(4)

    -- Patch smear-cursor's unhide so the resting cursor also shows our colour.
    -- animation.lua calls color.unhide_real_cursor() via the shared module table,
    -- so replacing it here affects every call site.
    local smear_color = require("smear_cursor.color")
    smear_color.unhide_real_cursor = function()
      vim.api.nvim_set_hl(0, "SmearCursorHideable", {
        fg   = "none",
        bg   = cursor_colors[current_color_idx].color,
        blend = 0,
      })
    end

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
    vim.keymap.set("n", "<leader>c5", function() apply(5) end,
      { desc = "Cursor: ember (particles, orange)" })

    -- Cycle cursor colour through palette
    vim.keymap.set("n", "<leader>cC", function()
      current_color_idx = (current_color_idx % #cursor_colors) + 1
      apply(current_idx)
      vim.notify(cursor_colors[current_color_idx].name, vim.log.levels.INFO, { title = "cursor colour" })
    end, { desc = "Cursor: cycle colour" })
  end,
}
