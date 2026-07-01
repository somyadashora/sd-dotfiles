return {
    "lukas-reineke/virt-column.nvim",
    event = {"BufReadPre", "BufNewFile"},
    config = function()
        local function set_virtcol_hl()
            local ok, normal = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
            local fg
            if ok and normal.bg then
                local bg = normal.bg
                local r = math.floor(bg / 65536) % 256
                local g = math.floor(bg / 256) % 256
                local b = bg % 256
                -- blend 60% towards neutral grey (160) for a faded inverted feel
                local t = 0.6
                r = math.floor(r + (160 - r) * t)
                g = math.floor(g + (160 - g) * t)
                b = math.floor(b + (160 - b) * t)
                fg = string.format("#%02x%02x%02x", r, g, b)
            else
                fg = "#555555"
            end
            vim.api.nvim_set_hl(0, "VirtColumn", { fg = fg, bg = "NONE" })
        end

        set_virtcol_hl()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = set_virtcol_hl })

        -- Rulers are driven by the shared text width (core/options.lua): the
        -- FIRST ruler sits exactly where comments/text auto-wrap, and the two
        -- secondary rulers trail at +20 / +21. Change g:sd_text_width to move
        -- both the wrap point and this primary ruler together.
        local tw = vim.g.sd_text_width or 100
        require("virt-column").setup({
            char = { "┆", "⸽", "┆" },
            virtcolumn = string.format("%d,%d,%d", tw, tw + 20, tw + 21),
            highlight = "VirtColumn",
        })
    end,
}