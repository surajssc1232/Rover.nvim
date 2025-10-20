# Rover

Rover is a Neovim plugin that leverages Google's Gemini AI to automatically generate comprehensive technical documentation for selected code snippets. It provides Rust-style documentation comments, displays them in a floating window with syntax highlighting, and supports multiple programming languages for enhanced developer productivity.

## Features

- Generate Rust-style documentation for code snippets
- Floating window display with syntax highlighting
- Support for multiple programming languages
- Configurable API settings

## Requirements

- Neovim 0.8+
- A Google Gemini API key

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  '~/path/to/rover',
  config = function()
    require('rover').setup({
      api_key = 'your-gemini-api-key-here'
    })
  end
}
```

## Configuration

Call `require('rover').setup()` with your options:

```lua
require('rover').setup({
  api_key = 'your-gemini-api-key-here',
  window_width = 150,
  window_height = 25,
  model = 'gemini-2.5-flash'
})
```

## Usage

Select text in visual mode and run `:Rover` to generate documentation.

## Keybindings

The plugin creates the `:Rover` command. Optionally, you can add a keymap:

```lua
vim.keymap.set('v', '<leader>rd', ':Rover<CR>', { desc = "Rover: Show documentation" })
```

## License

MIT