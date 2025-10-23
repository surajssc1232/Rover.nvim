-- plugin/rover.lua
-- This file runs automatically when Neovim starts

-- Prevent loading twice
if vim.g.loaded_rover then
	return
end
vim.g.loaded_rover = true

-- Create the :Rover command
vim.api.nvim_create_user_command('Rover', function(opts)
	require('rover').show_docs()
end, {
	range = true,
	desc = "Generate and display comprehensive technical documentation for selected code snippets using Google's Gemini AI, with syntax highlighting in a floating window"
})

-- Create the :RoverAsk command
vim.api.nvim_create_user_command('RoverAsk', function(opts)
	require('rover').ask_question()
end, {
	desc = "Ask a general question and display the response in a floating window with markdown formatting"
})

-- Optional: Create a keymap for quick access
-- Uncomment the line below to enable <leader>rd in visual mode
-- vim.keymap.set('v', '<leader>rd', ':Rover<CR>', { desc = "Rover: Show documentation" })
