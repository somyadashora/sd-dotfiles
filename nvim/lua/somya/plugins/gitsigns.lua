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

			-- Navigation. gitsigns' own "Hunk 1 of 5" counter is suppressed
			-- (navigation_message = false) and re-echoed through
			-- core/navmsg.lua, so ]h reads in the same voice as ]d and ]t:
			-- labelled by hunk TYPE and coloured by the matching GitSigns
			-- group ("Change 1 of 5"), rather than an uncoloured "Hunk".
			-- Also moves off next_hunk/prev_hunk, which gitsigns deprecated
			-- in favour of nav_hunk.
			local navmsg = require("somya.core.navmsg")
			local hunk_hl = {
				add = "GitSignsAdd",
				change = "GitSignsChange",
				delete = "GitSignsDelete",
			}
			local function nav_hunk(direction)
				return function()
					-- nav_hunk is async; its callback fires once the cursor has
					-- moved and any hunk preview has been drawn.
					gs.nav_hunk(direction, {
						count = vim.v.count1,
						navigation_message = false,
					}, function()
						vim.schedule(function()
							local hunks = gs.get_hunks(bufnr) or {}
							local line = vim.api.nvim_win_get_cursor(0)[1]
							local idx, best
							for i, h in ipairs(hunks) do
								-- A delete hunk adds no lines, so it collapses to
								-- the single row it sits on.
								local first = h.added.start
								local last = first + math.max(h.added.count - 1, 0)
								if line >= first and line <= last then
									idx = i
									break
								end
								-- EOF deletes get their cursor row clamped into
								-- the buffer, landing outside the hunk; fall back
								-- to whichever hunk is nearest.
								local dist = math.min(math.abs(line - first), math.abs(line - last))
								if not best or dist < best then
									best, idx = dist, i
								end
							end
							local h = idx and hunks[idx]
							if not h then return end
							local label = h.type:sub(1, 1):upper() .. h.type:sub(2)
							navmsg.echo(label, idx, #hunks, hunk_hl[h.type])
						end)
					end)
				end
			end

			map("n", "]h", nav_hunk("next"), "Next Hunk")
			map("n", "[h", nav_hunk("prev"), "Prev Hunk")

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
