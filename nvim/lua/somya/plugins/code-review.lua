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

		local function restyle(bufnr)
			vim.schedule(function()
				local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
				for _, mark in ipairs(marks) do
					local id, row, col, d = mark[1], mark[2], mark[3], mark[4]
					if d.virt_text then
						local text = vim.trim(d.virt_text[1] and d.virt_text[1][1] or "")
						vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
							id = id,
							virt_text = { { " 󰍉  " .. text .. " ", "CodeReviewComment" } },
							virt_text_pos = "right_align",
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
					-- Comment text follows the closing ``` fence
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
							file = file,
							line_start = ls,
							line_end = le,
							text = text,
							bufnr = vim.fn.bufadd(file),
						})
					end
				end
			end
		end

		-- Load persisted annotations at startup; BufEnter → patched _render will display them
		load_from_file()

		-- Toggle visibility across all loaded buffers
		vim.keymap.set("n", "<leader>rt", function()
			visible = not visible
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
