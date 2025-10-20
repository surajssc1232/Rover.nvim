local M = {}

local config = require('rover.config')
local api = require('rover.api')
local ui = require('rover.ui')
local utils = require('rover.utils')

local is_processing = false

M.setup = config.setup

M.show_docs = function()
	if is_processing or ui.is_window_open() then
		vim.notify("Rover: Already processing a request or window is open", vim.log.levels.WARN)
		return
	end

	local keyword = utils.get_visual_selection()

	if keyword == "" or keyword == nil then
		vim.notify("Rover: No text selected", vim.log.levels.WARN)
		return
	end

	local language = utils.get_filetype()
	if language == "" then
		language = "general"
	end

	is_processing = true
	vim.notify(string.format("Fetching documentation for '%s'...", keyword), vim.log.levels.INFO)

	utils.get_lsp_hover(function(hover_docs)
		api.generate_docs(keyword, language, hover_docs, function(content)
			ui.create_docs_window(content, language)
			is_processing = false
		end)
	end)
end

return M
