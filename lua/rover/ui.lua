local M = {}
local config = require('rover.config')

local current_win = nil

local function parse_markdown_content(content, language)
	local sections = {}
	local current_section = { type = "text", lines = {} }
	local in_code_block = false
	local code_lang = nil

	for line in content:gmatch("[^\r\n]+") do
		local fence_match = line:match("^```(%w*)")

		if fence_match ~= nil then
			if not in_code_block then
				-- Start code block
				if #current_section.lines > 0 then
					table.insert(sections, current_section)
				end
				in_code_block = true
				code_lang = fence_match ~= "" and fence_match or language
				current_section = { type = "code", lang = code_lang, lines = {} }
			else
				-- End code block
				table.insert(sections, current_section)
				in_code_block = false
				current_section = { type = "text", lines = {} }
			end
		else
			table.insert(current_section.lines, line)
		end
	end

	if #current_section.lines > 0 then
		table.insert(sections, current_section)
	end

	return sections
end

M.is_window_open = function()
	return current_win and vim.api.nvim_win_is_valid(current_win)
end

M.create_docs_window = function(content, language)
	if current_win and vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_win_close(current_win, true)
	end
	local buf = vim.api.nvim_create_buf(false, true)
	local sections = parse_markdown_content(content, language)

	local all_lines = {}
	local highlights = {}
	local current_line = 0

	for i, section in ipairs(sections) do
		if section.type == "code" then
			-- Add code section with language info for highlighting
			local code_start = current_line
			for _, line in ipairs(section.lines) do
				-- Preserve tabs and indentation in code blocks
				table.insert(all_lines, line)
				current_line = current_line + 1
			end
			table.insert(highlights, {
				start_line = code_start,
				end_line = current_line,
				lang = section.lang
			})
			-- Add separator after code blocks
			table.insert(all_lines, "")
			current_line = current_line + 1
		else
			-- Add text section with better spacing
			for _, line in ipairs(section.lines) do
				table.insert(all_lines, line)
				current_line = current_line + 1
			end
			-- Add consistent spacing between sections
			if i < #sections then
				table.insert(all_lines, "")
				current_line = current_line + 1
			end
		end
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)

	-- Set buffer filetype to markdown for proper formatting
	vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

	-- Set header colors with better hierarchy
	vim.api.nvim_set_hl(0, 'markdownH1', { fg = '#ffffff', bold = true, bg = '#303030' })
	vim.api.nvim_set_hl(0, 'markdownH2', { fg = '#87ceeb', bold = true })
	vim.api.nvim_set_hl(0, 'markdownH3', { fg = '#98fb98', bold = true })
	vim.api.nvim_set_hl(0, 'markdownH4', { fg = '#dda0dd', bold = true })
	vim.api.nvim_set_hl(0, 'markdownH5', { fg = '#f0e68c', bold = true })
	vim.api.nvim_set_hl(0, 'markdownH6', { fg = '#ffa07a', bold = true })

	-- Apply Treesitter highlighting for markdown
	local ok = pcall(function()
		vim.treesitter.start(buf, 'markdown')
	end)

	if not ok then
		-- Fallback: enable markdown syntax
		vim.api.nvim_buf_set_option(buf, 'syntax', 'markdown')
	end

	-- Apply Treesitter highlighting to code blocks
	for _, hl_info in ipairs(highlights) do
		if vim.treesitter.language.get_lang(hl_info.lang) then
			local ok = pcall(function()
				vim.treesitter.start(buf, hl_info.lang)
			end)

			if not ok then
				-- Fallback: set filetype for basic syntax highlighting
				vim.api.nvim_buf_set_option(buf, 'syntax', hl_info.lang)
			end
		end
	end

	-- Find separator line and highlight intro text
	local separator_line = -1
	for i, line in ipairs(all_lines) do
		if line:match("^%-+$") then
			separator_line = i - 1
			vim.api.nvim_buf_add_highlight(buf, -1, 'Comment', separator_line, 0, -1)
			break
		end
	end

	-- Make intro text (before separator) white
	if separator_line > 0 then
		for i = 0, separator_line - 1 do
			vim.api.nvim_buf_add_highlight(buf, -1, 'Normal', i, 0, -1)
		end
	end

	-- Set buffer options for proper indentation and tab handling
	vim.api.nvim_buf_set_option(buf, 'expandtab', false)
	vim.api.nvim_buf_set_option(buf, 'tabstop', 4)
	vim.api.nvim_buf_set_option(buf, 'shiftwidth', 4)
	vim.api.nvim_buf_set_option(buf, 'softtabstop', 4)
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)
	vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

	-- Calculate window size and position
	local width = config.config.window_width
	local height = config.config.window_height
	local ui = vim.api.nvim_list_uis()[1]

	local col = math.floor((ui.width - width) / 2)
	local row = math.floor((ui.height - height) / 2)

	-- Rust-style window options
	local opts = {
		relative = 'editor',
		width = width,
		height = height,
		col = col,
		row = row,
		style = 'minimal',
		border = 'rounded',
		title = ' 📚 Rover Documentation ',
		title_pos = 'center',
		footer = ' Press q or <Esc> to close ',
		footer_pos = 'center',
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Rust-style window settings with proper wrapping
	vim.api.nvim_win_set_option(win, 'wrap', true)
	vim.api.nvim_win_set_option(win, 'linebreak', true)
	vim.api.nvim_win_set_option(win, 'breakindent', true)
	vim.api.nvim_win_set_option(win, 'showbreak', '')
	vim.api.nvim_win_set_option(win, 'cursorline', false)
	vim.api.nvim_win_set_option(win, 'number', false)
	vim.api.nvim_win_set_option(win, 'relativenumber', false)
	vim.api.nvim_win_set_option(win, 'signcolumn', 'no')

	-- Set color scheme closer to Rust docs
	vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
	vim.api.nvim_win_set_option(win, 'winblend', 0)

	-- Key mappings
	local close_keys = { 'q', '<Esc>' }
	for _, key in ipairs(close_keys) do
		vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', {
			noremap = true,
			silent = true
		})
	end

	-- Scroll keybindings
	vim.api.nvim_buf_set_keymap(buf, 'n', 'j', 'j', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', 'k', 'k', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', '<C-d>', '<C-d>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', '<C-u>', '<C-u>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', 'g', 'gg', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', 'G', 'G', { noremap = true, silent = true })

	current_win = win
end

return M
