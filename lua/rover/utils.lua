local M = {}

M.get_visual_selection = function()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local start_col = start_pos[3]
	local end_line = end_pos[2]
	local end_col = end_pos[3]

	local lines = vim.fn.getline(start_line, end_line)

	if #lines == 0 then
		return ""
	end

	if #lines == 1 then
		return string.sub(lines[1], start_col, end_col)
	end

	lines[1] = string.sub(lines[1], start_col)
	lines[#lines] = string.sub(lines[#lines], 1, end_col)

	return table.concat(lines, "\n")
end

M.get_filetype = function()
	return vim.bo.filetype
end

M.get_lsp_hover = function(callback)
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local position_encoding = clients[1] and clients[1].server_capabilities.positionEncoding or "utf-16"
	local params = vim.lsp.util.make_position_params(0, position_encoding)
	local called = false
	vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result, ctx, config)
		if called then return end
		called = true
		if err or not result or not result.contents then
			callback(nil)
			return
		end
		local contents = result.contents
		local text = ""
		if type(contents) == "string" then
			text = contents
		elseif contents.kind == "markdown" then
			text = contents.value
		elseif contents.kind == "plaintext" then
			text = contents.value
		else
			local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)
			text = table.concat(lines, "\n")
		end
		callback(text)
	end)
end

return M