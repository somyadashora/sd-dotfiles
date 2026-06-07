return {
	"scristobal/code-review.nvim",
	config = function()
		local function set_hl()
			vim.api.nvim_set_hl(0, "CodeReviewComment", {
				bg = "#453000",
				fg = "#f9e2af",
				italic = true,
				bold = true,
			})
			vim.api.nvim_set_hl(0, "CodeReviewSign", { fg = "#f9e2af" })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("code_review_hl", { clear = true }),
			callback = set_hl,
		})

		-- <leader>ra: plugin's own vim.ui.input (single-line, quick)
		-- <leader>rA: our floating buffer (multi-line, full editor)
		require("review").setup({
			keys = {
				add = "<leader>ra",
				delete = "<leader>rd",
				list = "<leader>rl",
				clear = "<leader>rx",
			},
			sign = { text = "▐", hl = "CodeReviewSign" },
			virt_text = { hl = "CodeReviewComment" },
		})

		local ns = vim.api.nvim_create_namespace("code_review")
		local review = require("review")
		local visible = true
		vim.g.code_review_visible = true

		local function restyle(bufnr)
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then return end
				local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
				for _, mark in ipairs(marks) do
					local id, row, col, d = mark[1], mark[2], mark[3], mark[4]
					if d.virt_text then
						local text = vim.trim(d.virt_text[1] and d.virt_text[1][1] or "")
						local line_len = #(vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or "")
						vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
							id = id,
							virt_text = { { " 󰍉  " .. text .. " ", "CodeReviewComment" } },
							virt_text_win_col = math.max(line_len + 2, 120),
							priority = 20,
						})
					end
				end
			end)
		end

		-- Patch _render so add/delete/BufEnter all go through styling (and respect toggle)
		local orig_render = review._render
		review._render = function(bufnr)
			if not visible then
				vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
				return
			end
			orig_render(bufnr)
			restyle(bufnr)
		end

		-- Reach into the plugin's closure to get the live comments table
		local function get_comments_table()
			local i = 1
			while true do
				local name, val = debug.getupvalue(review.add, i)
				if not name then break end
				if name == "comments" and type(val) == "table" then return val end
				i = i + 1
			end
		end

		-- Open a floating scratch buffer for composing or editing a review comment.
		-- :wq commits; q (normal mode) / :q! cancels.
		-- Pass edit_idx (index into the live comments table) to edit an existing comment.
		local function open_review_float(line_start, line_end, target_bufnr, target_file, edit_idx)
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(buf, "review://comment")
			vim.bo[buf].buftype   = "acwrite"
			vim.bo[buf].bufhidden = "wipe"
			vim.bo[buf].swapfile  = false
			vim.bo[buf].filetype  = "markdown"

			if edit_idx then
				local tbl = get_comments_table()
				if tbl and tbl[edit_idx] then
					vim.api.nvim_buf_set_lines(buf, 0, -1, false, { tbl[edit_idx].text })
				end
			end

			local width  = math.floor(vim.o.columns * 0.55)
			local height = math.floor(vim.o.lines   * 0.35)
			local win = vim.api.nvim_open_win(buf, true, {
				relative  = "editor",
				width     = width,
				height    = height,
				row       = math.floor((vim.o.lines   - height) / 2),
				col       = math.floor((vim.o.columns - width)  / 2),
				style     = "minimal",
				border    = "rounded",
				title     = edit_idx
					and " Edit Comment  :wq save · q cancel "
					or  " Review Comment  :wq save · q cancel ",
				title_pos = "center",
			})
			-- style=minimal disables these; re-enable explicitly
			vim.wo[win].number = true
			vim.wo[win].wrap   = false

			vim.cmd("startinsert")

			-- Shadow global insert-mode <Esc> mappings (autopairs etc.)
			vim.keymap.set("i", "<Esc>", "<Esc>", { buffer = buf, nowait = true })
			-- Re-assert focus after every InsertLeave so "Np paste works on all rounds
			vim.api.nvim_create_autocmd("InsertLeave", {
				buffer = buf,
				callback = function()
					if vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_set_current_win(win)
					end
				end,
			})
			-- Only q cancels in normal mode
			vim.keymap.set("n", "q", "<cmd>q!<cr>", { buffer = buf, nowait = true })

			vim.api.nvim_create_autocmd("BufWriteCmd", {
				buffer = buf,
				callback = function()
					local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
					while #lines > 0 and vim.trim(lines[#lines]) == "" do
						table.remove(lines)
					end
					local text = table.concat(lines, " ")
					if text ~= "" then
						local tbl = get_comments_table()
						if tbl then
							if edit_idx then
								tbl[edit_idx].text = text
							else
								table.insert(tbl, {
									file       = target_file,
									line_start = line_start,
									line_end   = line_end,
									text       = text,
									bufnr      = target_bufnr,
								})
							end
							review._render(target_bufnr)
							review._sync_file()
						end
					end
					vim.cmd("setlocal nomodified")
				end,
			})
		end

		vim.keymap.set("n", "<leader>rA", function()
			open_review_float(
				vim.fn.line("."), vim.fn.line("."),
				vim.api.nvim_get_current_buf(), vim.fn.expand("%:.")
			)
		end, { desc = "Review: add comment" })

		vim.keymap.set("x", "<leader>rA", function()
			local s = vim.fn.getpos("v")[2]
			local e = vim.fn.getpos(".")[2]
			if s > e then s, e = e, s end
			local bufnr = vim.api.nvim_get_current_buf()
			local file  = vim.fn.expand("%:.")
			vim.schedule(function() open_review_float(s, e, bufnr, file) end)
			return "<Esc>"
		end, { expr = true, desc = "Review: add comment on selection (float)" })

		vim.keymap.set("n", "<leader>re", function()
			local tbl = get_comments_table()
			if not tbl or #tbl == 0 then
				vim.notify("No review comments to edit", vim.log.levels.INFO)
				return
			end
			local cur_file = vim.fn.expand("%:.")
			local cur_line = vim.fn.line(".")
			local best_idx, best_dist = nil, math.huge
			for i, c in ipairs(tbl) do
				if c.file == cur_file then
					local dist = math.abs(c.line_start - cur_line)
					if dist < best_dist then
						best_dist = dist
						best_idx = i
					end
				end
			end
			if not best_idx then
				vim.notify("No review comments in this file", vim.log.levels.INFO)
				return
			end
			local c = tbl[best_idx]
			open_review_float(c.line_start, c.line_end, c.bufnr or vim.api.nvim_get_current_buf(), c.file, best_idx)
		end, { desc = "Review: edit comment nearest to cursor" })

		-- Parse .code-review.md and populate the plugin's internal comments table so
		-- annotations survive a Neovim restart without needing to re-add them.
		local function load_from_file()
			if vim.fn.filereadable(".code-review.md") == 0 then return end
			local lines = vim.fn.readfile(".code-review.md")
			local tbl = get_comments_table()
			if not tbl then return end

			for idx, line in ipairs(lines) do
				local file, ls, le = line:match("^## %d+%. (.+):(%d+)%-(%d+)$")
				if not file then
					file, ls = line:match("^## %d+%. (.+):(%d+)$")
					le = ls
				end
				if file then
					ls, le = tonumber(ls), tonumber(le)
					local in_code, text = false, nil
					for j = idx + 1, math.min(idx + 20, #lines) do
						local l = lines[j]
						if l:match("^```") then
							in_code = not in_code
						elseif not in_code and l ~= "" and not l:match("^%-%-%-") then
							text = l
							break
						end
					end
					if text then
						table.insert(tbl, {
							file       = file,
							line_start = ls,
							line_end   = le,
							text       = text,
							bufnr      = vim.fn.bufadd(file),
						})
					end
				end
			end
		end

		load_from_file()

		-- The plugin's built-in watcher only clears on deletion (filereadable == 0).
		-- This watcher also handles the case where the agent empties the file without deleting it.
		local review_path = vim.fn.fnamemodify(".code-review.md", ":p")
		local w = vim.uv.new_fs_event()
		local function watch_review_file()
			w:stop()
			w:start(vim.fn.fnamemodify(review_path, ":h"), {}, function(err, filename)
				if err or filename ~= ".code-review.md" then return end
				vim.schedule(function()
					if vim.fn.getfsize(review_path) <= 0 and review.count() > 0 then
						review.clear()
					end
					watch_review_file()
				end)
			end)
		end
		watch_review_file()

		-- Jump to next/prev comment in the current file, wrapping around
		local function jump_comment(direction)
			if not visible then
				vim.notify("Review annotations are hidden", vim.log.levels.WARN)
				return
			end
			local tbl = get_comments_table()
			if not tbl or #tbl == 0 then
				vim.notify("No review comments", vim.log.levels.INFO)
				return
			end
			local cur_file = vim.fn.expand("%:.")
			local cur_line = vim.fn.line(".")
			local file_comments = vim.tbl_filter(function(c) return c.file == cur_file end, tbl)
			if #file_comments == 0 then
				vim.notify("No review comments in this file", vim.log.levels.INFO)
				return
			end
			table.sort(file_comments, function(a, b) return a.line_start < b.line_start end)
			if direction == "next" then
				for _, c in ipairs(file_comments) do
					if c.line_start > cur_line then
						vim.fn.cursor(c.line_start, 1)
						return
					end
				end
				vim.fn.cursor(file_comments[1].line_start, 1)
			else
				for i = #file_comments, 1, -1 do
					if file_comments[i].line_start < cur_line then
						vim.fn.cursor(file_comments[i].line_start, 1)
						return
					end
				end
				vim.fn.cursor(file_comments[#file_comments].line_start, 1)
			end
		end

		vim.keymap.set("n", "]r", function() jump_comment("next") end, { desc = "Review: next comment" })
		vim.keymap.set("n", "[r", function() jump_comment("prev") end, { desc = "Review: prev comment" })

		-- Toggle visibility across all loaded buffers
		vim.keymap.set("n", "<leader>rt", function()
			visible = not visible
			vim.g.code_review_visible = visible
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
					if visible then
						review._render(buf)
					else
						vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
					end
				end
			end
			vim.notify("Review annotations " .. (visible and "shown" or "hidden"), vim.log.levels.INFO)
		end, { desc = "Review: toggle annotations" })
	end,
}
