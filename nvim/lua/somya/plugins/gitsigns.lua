return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function(_, opts)
		require("gitsigns").setup(opts)
		-- Neon chrome for gitsigns' floating popups (preview_hunk, blame_line),
		-- noice.nvim-inspired: electric-cyan rounded border + a solid neon title
		-- pill on a near-black base (SdGitPopup* in core/theme.lua), plus neon
		-- green/red diff rows via GitSignsAdd/DeletePreview there. popup.create
		-- is the single choke point every gitsigns popup goes through; gitsigns
		-- has no styling hook, so wrap it once. The title survives the plugin's
		-- own WinScrolled reposition (set_config with absent keys keeps them).
		local titles = { hunk = " 󰊢 hunk ", blame = " 󰊢 blame " }
		local popup = require("gitsigns.popup")
		local popup_create = popup.create
		popup.create = function(lines_spec, wopts, id)
			local winid, bufnr = popup_create(lines_spec, wopts, id)
			if winid and vim.api.nvim_win_is_valid(winid) then
				vim.wo[winid].winhighlight =
					"NormalFloat:SdGitPopupNormal,FloatBorder:SdGitPopupBorder"
				pcall(vim.api.nvim_win_set_config, winid, {
					title = { { titles[id] or " 󰊢 git ", "SdGitPopupTitle" } },
					title_pos = "center",
				})
			end
			return winid, bufnr
		end
	end,
	opts = {
		-- Rounded border so the neon frame (see config above) reads like the
		-- noice popups; merged over gitsigns' default cursor-relative placement.
		preview_config = { border = "rounded" },
		-- Git signs render in their own dedicated gutter column (right of the
		-- line number) via statuscol.nvim, so sign_priority no longer affects
		-- placement — see plugins/statuscol.lua.
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns

			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
			end

			-- Navigation
			map("n", "]h", gs.next_hunk, "Next Hunk")
			map("n", "[h", gs.prev_hunk, "Prev Hunk")

			-- Actions
			map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
			map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
			map("v", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Stage hunk")
			map("v", "<leader>hr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Reset hunk")

			map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
			map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

			map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")

			map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")

			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, "Blame line")
			map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")

			map("n", "<leader>hd", gs.diffthis, "Diff this")
			map("n", "<leader>hD", function()
				gs.diffthis("~")
			end, "Diff this ~")

			-- Send changed hunks to the quickfix list
			map("n", "<leader>hq", function()
				gs.setqflist(0)
			end, "Hunks to quickfix (buffer)")
			map("n", "<leader>hQ", function()
				gs.setqflist("all")
			end, "Hunks to quickfix (all files)")

			-- Text object
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
		end,
	},
}
