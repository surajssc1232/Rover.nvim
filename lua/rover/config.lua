local M = {}

M.defaults = {
	api_key = nil,
	window_width = 150,
	window_height = 25,
	model = "gemini-2.5-flash-lite",
}

M.config = vim.deepcopy(M.defaults)

M.setup = function(opts)
	M.config = vim.tbl_extend('force', M.config, opts or {})

	if not M.config.api_key then
		vim.notify("Rover: Please set your Gemini API key in setup()", vim.log.levels.WARN)
	end
end

return M